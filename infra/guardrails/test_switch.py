"""Tests the guardrails switch against a fake AWS account.

Run: python3 infra/guardrails/test_switch.py
"""
import copy
import importlib
import json
import os
import sys
import types
import unittest


class ClientError(Exception):
    pass


def _fake_aws_libraries(account):
    """Stand-ins for boto3 and botocore, backed by [account]."""
    botocore = types.ModuleType('botocore')
    exceptions = types.ModuleType('botocore.exceptions')
    exceptions.ClientError = ClientError
    botocore.exceptions = exceptions
    boto3 = types.ModuleType('boto3')
    boto3.client = lambda service, region_name=None: FakeClient(account, service, region_name)
    sys.modules.update({'boto3': boto3, 'botocore': botocore, 'botocore.exceptions': exceptions})


class Paginator:
    def __init__(self, pages):
        self.pages = pages

    def paginate(self):
        return iter(self.pages)


class FakeClient:
    """Just enough of each AWS API for the switch."""

    def __init__(self, account, service, region):
        self.a, self.service, self.region = account, service, region

    # Lambda
    def get_paginator(self, name):
        if name == 'list_functions':
            return Paginator([{'Functions': [{'FunctionName': n} for n in self.a['lambda'].get(self.region, {})]}])
        if name == 'get_rest_apis':
            return Paginator([{'items': [{'id': i, 'name': api['name']}
                                         for i, api in self.a['rest'].get(self.region, {}).items()]}])
        raise NotImplementedError(name)

    def get_function_concurrency(self, FunctionName):
        value = self.a['lambda'][self.region][FunctionName]
        return {} if value is None else {'ReservedConcurrentExecutions': value}

    def put_function_concurrency(self, FunctionName, ReservedConcurrentExecutions):
        self.a['lambda'][self.region][FunctionName] = ReservedConcurrentExecutions

    def delete_function_concurrency(self, FunctionName):
        self.a['lambda'][self.region][FunctionName] = None

    # API Gateway v2
    def get_apis(self, **_):
        return {'Items': [{'ApiId': i, 'Name': api['name']} for i, api in self.a['http'].get(self.region, {}).items()]}

    def get_stages(self, ApiId=None, restApiId=None):
        if self.service == 'apigatewayv2':
            stages = self.a['http'][self.region][ApiId]['stages']
            return {'Items': [{'StageName': n, 'DefaultRouteSettings': dict(s)} for n, s in stages.items()]}
        stages = self.a['rest'][self.region][restApiId]['stages']
        return {'item': [{'stageName': n, 'methodSettings': {'*/*': dict(s)} if s else {}} for n, s in stages.items()]}

    def update_stage(self, ApiId=None, StageName=None, DefaultRouteSettings=None,
                     restApiId=None, stageName=None, patchOperations=None):
        if self.service == 'apigatewayv2':
            self.a['http'][self.region][ApiId]['stages'][StageName] = dict(DefaultRouteSettings)
            return
        stage = self.a['rest'][self.region][restApiId]['stages'][stageName]
        for op in patchOperations:
            key = 'throttlingRateLimit' if op['path'].endswith('rateLimit') else 'throttlingBurstLimit'
            stage[key] = float(op['value'])

    # Amplify
    def list_apps(self, **_):
        return {'apps': [{'appId': i, 'name': app['name']} for i, app in self.a['amplify'].get(self.region, {}).items()]}

    def list_branches(self, appId):
        branches = self.a['amplify'][self.region][appId]['branches']
        return {'branches': [{'branchName': n, 'enableBasicAuth': locked} for n, locked in branches.items()]}

    def update_branch(self, appId, branchName, enableBasicAuth, basicAuthCredentials=None):
        self.a['amplify'][self.region][appId]['branches'][branchName] = enableBasicAuth

    # S3
    def list_buckets(self):
        return {'Buckets': [{'Name': n} for n in self.a['s3']]}

    def get_bucket_policy_status(self, Bucket):
        if not self.a['s3'][Bucket]['public']:
            raise ClientError('NoSuchBucketPolicy')
        return {'PolicyStatus': {'IsPublic': True}}

    def get_bucket_website(self, Bucket):
        if not self.a['s3'][Bucket]['website']:
            raise ClientError('NoSuchWebsiteConfiguration')
        return {}

    def get_public_access_block(self, Bucket):
        block = self.a['s3'][Bucket]['block']
        if block is None:
            raise ClientError('NoSuchPublicAccessBlockConfiguration')
        return {'PublicAccessBlockConfiguration': dict(block)}

    def put_public_access_block(self, Bucket, PublicAccessBlockConfiguration):
        self.a['s3'][Bucket]['block'] = dict(PublicAccessBlockConfiguration)

    def delete_public_access_block(self, Bucket):
        self.a['s3'][Bucket]['block'] = None

    def get_object(self, Bucket, Key):
        if Key not in self.a['objects']:
            raise ClientError('NoSuchKey')
        body = self.a['objects'][Key]
        return {'Body': types.SimpleNamespace(read=lambda: body)}

    def put_object(self, Bucket, Key, Body, ContentType=None):
        self.a['objects'][Key] = Body

    def delete_object(self, Bucket, Key):
        self.a['objects'].pop(Key, None)

    # SNS
    def publish(self, TopicArn, Subject, Message):
        self.a['emails'].append((Subject, Message))


OPEN = {'BlockPublicAcls': False, 'IgnorePublicAcls': False, 'BlockPublicPolicy': False,
        'RestrictPublicBuckets': False}


def _account():
    return {
        'lambda': {
            'us-east-2': {'donut-game-api': 2, 'amplify-login-custom-message': None, 'office-reports': 5,
                          'guardrails-switch': 1},
            'eu-west-2': {'SmartTiltSNSUpdate': None},
        },
        'http': {'us-east-2': {'g1': {'name': 'donut-game-sockets', 'stages': {'live': {
            'ThrottlingRateLimit': 10.0, 'ThrottlingBurstLimit': 20}}}}},
        'rest': {
            'us-east-2': {'r1': {'name': 'SmartShutters', 'stages': {'prod': {}}}},
            'eu-west-2': {'r2': {'name': 'Elizabeth Henley', 'stages': {'dev': {
                'throttlingRateLimit': 50.0, 'throttlingBurstLimit': 100.0}}}},
        },
        'amplify': {'us-east-2': {
            'd8': {'name': 'acro_visuals', 'branches': {'main': False}},
            'd3': {'name': 'acrooffice', 'branches': {'main': False, 'staging': True}},
        }},
        's3': {
            'acrovisuals.com': {'public': True, 'website': True, 'block': OPEN},
            'www.acrovisuals.com': {'public': False, 'website': True, 'block': None},
            'acro-office': {'public': False, 'website': False, 'block': OPEN},
            'guardrails-state': {'public': False, 'website': False, 'block': None},
        },
        'objects': {},
        'emails': [],
    }


class SwitchTest(unittest.TestCase):
    def setUp(self):
        self.account = _account()
        _fake_aws_libraries(self.account)
        os.environ.update({
            'AWS_REGION': 'us-east-2', 'AWS_LAMBDA_FUNCTION_NAME': 'guardrails-switch',
            'REGIONS': 'us-east-2,eu-west-2', 'STATE_BUCKET': 'guardrails-state',
            'NOTIFY_TOPIC': 'arn:notify', 'ACCOUNT_TOPIC': 'arn:account-shutoff', 'GAME_PREFIX': 'donut-game',
        })
        sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'switch'))
        import index
        self.switch = importlib.reload(index)

    def sns(self, topic):
        return {'Records': [{'Sns': {'TopicArn': topic,
                                     'Message': json.dumps({'AlarmName': 'x', 'AlarmDescription': 'too much'})}}]}

    def test_game_shutoff_touches_only_the_game(self):
        before = copy.deepcopy(self.account)
        self.switch.handler(self.sns('arn:game-shutoff'), None)
        lam = self.account['lambda']['us-east-2']
        self.assertEqual(lam['donut-game-api'], 0)
        self.assertEqual(lam['office-reports'], 5)
        self.assertEqual(self.account['http']['us-east-2']['g1']['stages']['live']['ThrottlingRateLimit'], 0.0)
        self.assertEqual(self.account['amplify'], before['amplify'])
        self.assertEqual(self.account['s3'], before['s3'])
        self.assertIn('too much', self.account['emails'][-1][1])

    def test_account_shutoff_then_restore_puts_everything_back(self):
        before = copy.deepcopy(self.account)
        self.switch.handler(self.sns('arn:account-shutoff'), None)

        lam = self.account['lambda']
        self.assertEqual(lam['us-east-2']['donut-game-api'], 0)
        self.assertEqual(lam['us-east-2']['amplify-login-custom-message'], 0)
        self.assertEqual(lam['eu-west-2']['SmartTiltSNSUpdate'], 0)
        self.assertEqual(lam['us-east-2']['guardrails-switch'], 1, 'never switches itself off')
        self.assertEqual(self.account['rest']['eu-west-2']['r2']['stages']['dev']['throttlingRateLimit'], 0.0)
        self.assertTrue(self.account['amplify']['us-east-2']['d8']['branches']['main'])
        self.assertTrue(self.account['s3']['acrovisuals.com']['block']['BlockPublicPolicy'])
        self.assertTrue(self.account['s3']['www.acrovisuals.com']['block']['BlockPublicPolicy'])
        self.assertEqual(self.account['s3']['acro-office']['block'], OPEN, 'private buckets are left alone')
        self.assertIn('guardrails /', self.account['emails'][-1][1], 'the email has the site password')

        self.switch.handler({'action': 'restore', 'scope': 'account'}, None)
        after = {k: v for k, v in self.account.items() if k not in ('emails', 'objects')}
        expected = {k: v for k, v in before.items() if k not in ('emails', 'objects')}
        # SmartShutters had no stage limits; it comes back on API Gateway's defaults
        expected['rest']['us-east-2']['r1']['stages']['prod'] = {
            'throttlingRateLimit': 10000.0, 'throttlingBurstLimit': 5000.0}
        self.assertEqual(after, expected)
        self.assertEqual(self.account['objects'], {}, 'the record is cleared once restored')

    def test_a_second_shutoff_keeps_the_first_record(self):
        self.switch.handler(self.sns('arn:account-shutoff'), None)
        self.switch.handler(self.sns('arn:account-shutoff'), None)
        self.switch.handler({'action': 'restore', 'scope': 'account'}, None)
        self.assertEqual(self.account['lambda']['us-east-2']['office-reports'], 5)
        self.assertIsNone(self.account['lambda']['us-east-2']['amplify-login-custom-message'])
        self.assertFalse(self.account['amplify']['us-east-2']['d8']['branches']['main'])

    def test_switching_off_nothing_then_restoring_leaves_no_record(self):
        self.account['lambda']['us-east-2'].pop('donut-game-api')
        self.account['http'] = {}
        self.switch.handler({'action': 'off', 'scope': 'game'}, None)
        self.switch.handler({'action': 'restore', 'scope': 'game'}, None)
        self.assertEqual(self.account['objects'], {})

    def test_restoring_when_nothing_is_off_changes_nothing(self):
        before = copy.deepcopy(self.account)
        result = self.switch.handler({'action': 'restore', 'scope': 'game'}, None)
        self.assertEqual(result['changed'], [])
        self.assertEqual(self.account['lambda'], before['lambda'])


if __name__ == '__main__':
    unittest.main(verbosity=2)
