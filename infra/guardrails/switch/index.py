"""Switches cloud spending off when a guardrail trips, and back on by hand.

Two scopes:
  game     the Donut game: resources named GAME_PREFIX* in the home region,
           and CloudFront sites tagged app=donut
  account  everything in REGIONS: every Lambda function (but this one), every
           API Gateway stage and Amplify branch, every public S3 bucket and
           every CloudFront site

Before changing anything it records how each resource was in STATE_BUCKET,
so restoring puts things back exactly as they were. Shutting off twice keeps
the first record, so a second trip can't overwrite it with "off".

Invoke by hand with {"action": "off" | "restore", "scope": "game" | "account"}.
Messages on GAME_TOPIC or ACCOUNT_TOPIC switch that scope off.
"""
import base64
import json
import os
import secrets

import boto3
from botocore.exceptions import ClientError

HOME = os.environ.get('AWS_REGION', 'us-east-2')
SELF = os.environ.get('AWS_LAMBDA_FUNCTION_NAME', '')
PREFIX = os.environ.get('GAME_PREFIX', 'donut-game')
REGIONS = [r.strip() for r in os.environ.get('REGIONS', HOME).split(',') if r.strip()]
STATE_BUCKET = os.environ.get('STATE_BUCKET', '')
NOTIFY_TOPIC = os.environ.get('NOTIFY_TOPIC', '')
GAME_CONCURRENCY = int(os.environ.get('NORMAL_CONCURRENCY', '2'))
GAME_RATE = float(os.environ.get('NORMAL_RATE', '10'))
GAME_BURST = int(os.environ.get('NORMAL_BURST', '20'))

# What API Gateway allows when nothing narrower is set
DEFAULT_RATE = 10000.0
DEFAULT_BURST = 5000


def client(service, region=None):
    return boto3.client(service, region_name=region or HOME)


# --- Finding things ---------------------------------------------------------

def functions(region):
    lam = client('lambda', region)
    for page in lam.get_paginator('list_functions').paginate():
        for function in page['Functions']:
            yield function['FunctionName']


def http_apis(region):
    apis = client('apigatewayv2', region)
    token = None
    while True:
        page = apis.get_apis(**({'NextToken': token} if token else {}))
        yield from page.get('Items', [])
        token = page.get('NextToken')
        if not token:
            return


def rest_apis(region):
    for page in client('apigateway', region).get_paginator('get_rest_apis').paginate():
        yield from page.get('items', [])


def amplify_branches(region):
    amplify = client('amplify', region)
    token = None
    while True:
        page = amplify.list_apps(**({'nextToken': token} if token else {}))
        for app in page.get('apps', []):
            for branch in amplify.list_branches(appId=app['appId']).get('branches', []):
                yield app, branch
        token = page.get('nextToken')
        if not token:
            return


def public_buckets():
    """Buckets that serve the public: a public policy or website hosting."""
    s3 = client('s3')
    for bucket in s3.list_buckets().get('Buckets', []):
        name = bucket['Name']
        if name == STATE_BUCKET:
            continue
        try:
            if s3.get_bucket_policy_status(Bucket=name)['PolicyStatus']['IsPublic']:
                yield name
                continue
        except ClientError:
            pass
        try:
            s3.get_bucket_website(Bucket=name)
            yield name
        except ClientError:
            pass


def cloudfront_sites(game):
    """(id, name) of each CloudFront distribution in scope: every one, or
    just those tagged app=donut for the game."""
    cf = client('cloudfront', 'us-east-1')
    marker = None
    while True:
        page = cf.list_distributions(**({'Marker': marker} if marker else {}))['DistributionList']
        for item in page.get('Items', []):
            if game:
                tags = cf.list_tags_for_resource(Resource=item['ARN'])['Tags'].get('Items', [])
                if not any(tag['Key'] == 'app' and tag['Value'] == 'donut' for tag in tags):
                    continue
            yield item['Id'], (item.get('Aliases', {}).get('Items') or [item['DomainName']])[0]
        if not page.get('IsTruncated'):
            return
        marker = page['NextMarker']


def set_site_enabled(site_id, enabled):
    """Turns a distribution on or off. Returns whether it was on before."""
    cf = client('cloudfront', 'us-east-1')
    current = cf.get_distribution_config(Id=site_id)
    config = current['DistributionConfig']
    was = config['Enabled']
    if was != enabled:
        config['Enabled'] = enabled
        cf.update_distribution(Id=site_id, IfMatch=current['ETag'], DistributionConfig=config)
    return was


# --- Switching off ----------------------------------------------------------

def switch_off(scope):
    """Turns everything in [scope] off. Returns (undo, changed, notes)."""
    undo, changed, notes = [], [], []
    game = scope == 'game'
    for region in ([HOME] if game else REGIONS):
        lam = client('lambda', region)
        for name in functions(region):
            if name == SELF or (game and not name.startswith(PREFIX)):
                continue
            previous = lam.get_function_concurrency(FunctionName=name).get('ReservedConcurrentExecutions')
            lam.put_function_concurrency(FunctionName=name, ReservedConcurrentExecutions=0)
            undo.append({'kind': 'lambda', 'region': region, 'name': name, 'previous': previous})
            changed.append(f'{region}: function {name} blocked')

        v2 = client('apigatewayv2', region)
        for api in http_apis(region):
            if game and not api['Name'].startswith(PREFIX):
                continue
            for stage in v2.get_stages(ApiId=api['ApiId']).get('Items', []):
                settings = stage.get('DefaultRouteSettings', {})
                v2.update_stage(ApiId=api['ApiId'], StageName=stage['StageName'],
                                DefaultRouteSettings={'ThrottlingRateLimit': 0.0, 'ThrottlingBurstLimit': 0})
                undo.append({'kind': 'http-api', 'region': region, 'name': f"{api['ApiId']}/{stage['StageName']}",
                             'api': api['ApiId'], 'stage': stage['StageName'], 'game': api['Name'].startswith(PREFIX),
                             'rate': settings.get('ThrottlingRateLimit'), 'burst': settings.get('ThrottlingBurstLimit')})
                changed.append(f"{region}: API {api['Name']} ({stage['StageName']}) throttled to 0")

        if game:
            continue

        v1 = client('apigateway', region)
        for api in rest_apis(region):
            for stage in v1.get_stages(restApiId=api['id']).get('item', []):
                settings = stage.get('methodSettings', {}).get('*/*', {})
                v1.update_stage(restApiId=api['id'], stageName=stage['stageName'], patchOperations=[
                    {'op': 'replace', 'path': '/*/*/throttling/rateLimit', 'value': '0'},
                    {'op': 'replace', 'path': '/*/*/throttling/burstLimit', 'value': '0'},
                ])
                undo.append({'kind': 'rest-api', 'region': region, 'name': f"{api['id']}/{stage['stageName']}",
                             'api': api['id'], 'stage': stage['stageName'],
                             'rate': settings.get('throttlingRateLimit'), 'burst': settings.get('throttlingBurstLimit')})
                changed.append(f"{region}: API {api['name']} ({stage['stageName']}) throttled to 0")

        amplify = client('amplify', region)
        for app, branch in amplify_branches(region):
            locked = branch.get('enableBasicAuth', False)
            if not locked:
                password = secrets.token_urlsafe(12)
                amplify.update_branch(appId=app['appId'], branchName=branch['branchName'], enableBasicAuth=True,
                                      basicAuthCredentials=base64.b64encode(f'guardrails:{password}'.encode()).decode())
                notes.append(f"{app['name']} ({branch['branchName']}): sign in as guardrails / {password}")
            undo.append({'kind': 'amplify', 'region': region, 'name': f"{app['appId']}/{branch['branchName']}",
                         'app': app['appId'], 'branch': branch['branchName'], 'was_locked': locked})
            changed.append(f"{region}: site {app['name']} ({branch['branchName']}) password-locked")

    # CloudFront is global: its sites go dark everywhere
    for site_id, name in cloudfront_sites(game):
        was = set_site_enabled(site_id, False)
        undo.append({'kind': 'cloudfront', 'region': 'global', 'name': site_id, 'was_enabled': was})
        changed.append(f'site {name}: CloudFront distribution disabled')

    if not game:
        s3 = client('s3')
        for name in public_buckets():
            try:
                previous = s3.get_public_access_block(Bucket=name)['PublicAccessBlockConfiguration']
            except ClientError:
                previous = None
            s3.put_public_access_block(Bucket=name, PublicAccessBlockConfiguration={
                'BlockPublicAcls': True, 'IgnorePublicAcls': True,
                'BlockPublicPolicy': True, 'RestrictPublicBuckets': True,
            })
            undo.append({'kind': 's3', 'region': 'global', 'name': name, 'previous': previous})
            changed.append(f'bucket {name}: public access blocked')
    return undo, changed, notes


# --- Switching back on ------------------------------------------------------

def restore(undo):
    """Puts back everything [undo] recorded. Returns what changed."""
    changed = []
    for entry in reversed(undo):
        region, kind = entry['region'], entry['kind']
        if kind == 'lambda':
            lam = client('lambda', region)
            if entry['previous'] is None:
                lam.delete_function_concurrency(FunctionName=entry['name'])
            else:
                lam.put_function_concurrency(FunctionName=entry['name'],
                                             ReservedConcurrentExecutions=entry['previous'])
            changed.append(f"{region}: function {entry['name']} unblocked")
        elif kind == 'http-api':
            fallback = (GAME_RATE, GAME_BURST) if entry.get('game') else (DEFAULT_RATE, DEFAULT_BURST)
            client('apigatewayv2', region).update_stage(
                ApiId=entry['api'], StageName=entry['stage'], DefaultRouteSettings={
                    'ThrottlingRateLimit': entry['rate'] if entry['rate'] is not None else fallback[0],
                    'ThrottlingBurstLimit': entry['burst'] if entry['burst'] is not None else fallback[1],
                })
            changed.append(f"{region}: API {entry['name']} limits restored")
        elif kind == 'rest-api':
            rate = entry['rate'] if entry['rate'] is not None else DEFAULT_RATE
            burst = entry['burst'] if entry['burst'] is not None else DEFAULT_BURST
            client('apigateway', region).update_stage(restApiId=entry['api'], stageName=entry['stage'], patchOperations=[
                {'op': 'replace', 'path': '/*/*/throttling/rateLimit', 'value': str(rate)},
                {'op': 'replace', 'path': '/*/*/throttling/burstLimit', 'value': str(burst)},
            ])
            changed.append(f"{region}: API {entry['name']} limits restored")
        elif kind == 'amplify':
            if not entry['was_locked']:
                client('amplify', region).update_branch(appId=entry['app'], branchName=entry['branch'],
                                                        enableBasicAuth=False)
            changed.append(f"{region}: site {entry['name']} unlocked")
        elif kind == 'cloudfront':
            if entry['was_enabled']:
                set_site_enabled(entry['name'], True)
            changed.append(f"site {entry['name']}: CloudFront distribution as before")
        elif kind == 's3':
            s3 = client('s3')
            if entry['previous'] is None:
                s3.delete_public_access_block(Bucket=entry['name'])
            else:
                s3.put_public_access_block(Bucket=entry['name'], PublicAccessBlockConfiguration=entry['previous'])
            changed.append(f"bucket {entry['name']}: public access as before")
    return changed


# --- Records of what was switched off ---------------------------------------

def _key(scope):
    return f'state/{scope}.json'


def load(scope):
    try:
        body = client('s3').get_object(Bucket=STATE_BUCKET, Key=_key(scope))['Body'].read()
        return json.loads(body)
    except ClientError:
        return None


def save(scope, undo):
    client('s3').put_object(Bucket=STATE_BUCKET, Key=_key(scope), Body=json.dumps(undo).encode(),
                            ContentType='application/json')


def forget(scope):
    client('s3').delete_object(Bucket=STATE_BUCKET, Key=_key(scope))


def merged(earlier, later):
    """Keeps what [earlier] recorded for anything switched off twice, so the
    second time (when it was already off) can't overwrite the real setting."""
    seen = {(entry['kind'], entry['region'], entry['name']) for entry in earlier}
    return earlier + [e for e in later if (e['kind'], e['region'], e['name']) not in seen]


# --- Entry point -------------------------------------------------------------

def what_to_do(event):
    """(action, scope, reason) from an SNS message or a hand-made event."""
    records = event.get('Records') if isinstance(event, dict) else None
    if records:
        sns = records[0].get('Sns', {})
        scope = 'account' if sns.get('TopicArn') == os.environ.get('ACCOUNT_TOPIC') else 'game'
        reason = sns.get('Message', '')
        try:
            parsed = json.loads(reason)
            reason = parsed.get('AlarmDescription') or parsed.get('AlarmName') or reason
        except ValueError:
            pass
        return 'off', scope, reason or sns.get('Subject') or 'a guardrail tripped'
    scope = event.get('scope', 'game') if isinstance(event, dict) else 'game'
    action = event.get('action', 'off') if isinstance(event, dict) else 'off'
    return action, scope, 'switched by hand'


def handler(event, context):
    action, scope, reason = what_to_do(event)
    if scope not in ('game', 'account'):
        raise ValueError(f'Unknown scope {scope}')
    label = 'Donut game' if scope == 'game' else 'Whole AWS account'
    restore_command = ("aws lambda invoke --function-name guardrails-switch --cli-binary-format raw-in-base64-out "
                       f"--payload '{{\"action\":\"restore\",\"scope\":\"{scope}\"}}' /dev/stdout")
    if action == 'restore':
        undo = load(scope)
        changed = restore(undo) if undo else []
        # Clear the record even if it was empty: nothing is off any more
        if undo is not None:
            forget(scope)
        subject = f'{label} switched back on'
        body = 'Switched back on by hand.' if undo else 'Nothing was switched off, so nothing changed.'
        notes = []
    else:
        undo, changed, notes = switch_off(scope)
        save(scope, merged(load(scope) or [], undo))
        subject = f'{label} switched off to stop AWS charges'
        body = f'Reason: {reason}\n\nIt stays off until you switch it back on:\n{restore_command}'
    body += '\n\nChanged:\n' + ('\n'.join(changed) or '(nothing to change)')
    if notes:
        body += '\n\nLocked sites:\n' + '\n'.join(notes)
    if NOTIFY_TOPIC:
        client('sns').publish(TopicArn=NOTIFY_TOPIC, Subject=subject[:100], Message=body)
    return {'action': action, 'scope': scope, 'changed': changed}
