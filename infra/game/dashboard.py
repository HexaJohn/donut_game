"""Builds the admin dashboard page from the daily stats dashboard.sh downloads.

Usage: python3 dashboard.py <stats dir> <live tables>  (prints the page)
"""
import datetime
import html
import json
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
live = int(sys.argv[2]) if len(sys.argv) > 2 and sys.argv[2].isdigit() else 0


def load(folder):
    return {p.stem: json.loads(p.read_text()) for p in sorted((root / folder).glob('*.json'))}


days = load('days')
uniques = {day: set(doc.get('players', [])) for day, doc in load('uniques').items()}

today = datetime.datetime.now(datetime.timezone.utc).date()
window = [(today - datetime.timedelta(days=n)).isoformat() for n in range(29, -1, -1)]


def total(key, among=None):
    return sum(days.get(d, {}).get(key, 0) for d in (among if among is not None else days))


def players_over(n):
    seen = set()
    for d in window[-n:]:
        seen |= uniques.get(d, set())
    return len(seen)


def per_day(key):
    return [days.get(d, {}).get(key, 0) for d in window]


started = [p + q for p, q in zip(per_day('matchesStartedParty'), per_day('matchesStartedPublic'))]
finished_all = total('matchesFinished')
avg_minutes = round(total('matchMinutes') / finished_all, 1) if finished_all else 0
people = {n: total(f'matchesWith{n}People') for n in range(1, 8)}
people = {n: c for n, c in people.items() if c}

cards = [
    ('Playing now', live, 'tables active in the last 15 min'),
    ('Players today', len(uniques.get(window[-1], set())), 'unique installs'),
    ('Players, 7 days', players_over(7), 'unique installs'),
    ('Players, 30 days', players_over(30), 'unique installs'),
    ('Matches', total('matchesStartedParty') + total('matchesStartedPublic'), 'started, all time'),
    ('Hands', total('hands'), 'dealt, all time'),
    ('Average match', f'{avg_minutes} min', f'{finished_all} finished'),
    ('Chat messages', total('chats'), 'all time'),
]

rows = []
for d in reversed(window):
    doc = days.get(d, {})
    if not doc and not uniques.get(d):
        continue
    rows.append([d, len(uniques.get(d, set())), doc.get('tablesParty', 0), doc.get('tablesPublic', 0),
                 doc.get('matchesStartedParty', 0) + doc.get('matchesStartedPublic', 0), doc.get('matchesFinished', 0),
                 doc.get('hands', 0), doc.get('joinedByMatchmaking', 0), doc.get('chats', 0),
                 doc.get('droppedMidHand', 0)])

data = {
    'labels': [d[5:] for d in window],
    'players': [len(uniques.get(d, set())) for d in window],
    'party': per_day('matchesStartedParty'),
    'public': per_day('matchesStartedPublic'),
    'hands': per_day('hands'),
    'people': {'labels': [f'{n} {"person" if n == 1 else "people"}' for n in people], 'counts': list(people.values())},
}

card_html = ''.join(
    f'<div class="card"><div class="label">{html.escape(t)}</div><div class="value">{html.escape(str(v))}</div>'
    f'<div class="note">{html.escape(n)}</div></div>' for t, v, n in cards)
head = ['Day', 'Players', 'Parties', 'Public tables', 'Matches', 'Finished', 'Hands', 'Matchmade joins', 'Chats',
        'Mid-hand drops']
table_html = '<tr>' + ''.join(f'<th>{h}</th>' for h in head) + '</tr>' + ''.join(
    '<tr>' + ''.join(f'<td>{html.escape(str(c))}</td>' for c in r) + '</tr>' for r in rows)
if not rows:
    table_html += f'<tr><td colspan="{len(head)}" class="empty">No games in the last 30 days yet.</td></tr>'

print(f'''<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>Donut Admin</title>
<script src="https://cdnjs.cloudflare.com/ajax/libs/Chart.js/4.4.1/chart.umd.min.js"></script>
<style>
:root {{ --bg:#0f1420; --panel:#182032; --text:#eef1f7; --muted:#8b95ab; --accent:#e9b949; --accent2:#e0457b; --line:#2a3550; }}
@media (prefers-color-scheme: light) {{ :root {{ --bg:#f6f4ef; --panel:#fff; --text:#1d2230; --muted:#6b7385; --line:#e3e0d8; }} }}
* {{ box-sizing: border-box; }}
body {{ margin:0; background:var(--bg); color:var(--text); font:15px/1.4 -apple-system, system-ui, sans-serif; }}
main {{ max-width:1100px; margin:0 auto; padding:24px 16px 48px; }}
h1 {{ margin:0 0 4px; font-size:24px; }} .sub {{ color:var(--muted); margin-bottom:20px; }}
.cards {{ display:grid; grid-template-columns:repeat(auto-fill, minmax(190px, 1fr)); gap:12px; margin-bottom:20px; }}
.card, .panel {{ background:var(--panel); border:1px solid var(--line); border-radius:14px; padding:14px 16px; }}
.label {{ color:var(--muted); font-size:13px; }} .value {{ font-size:28px; font-weight:800; margin:2px 0; }}
.note {{ color:var(--muted); font-size:12px; }}
.charts {{ display:grid; grid-template-columns:repeat(auto-fit, minmax(320px, 1fr)); gap:12px; margin-bottom:20px; }}
.panel h2 {{ font-size:15px; margin:0 0 10px; }}
.scroll {{ overflow-x:auto; }} table {{ border-collapse:collapse; width:100%; font-size:14px; }}
th, td {{ text-align:right; padding:7px 10px; border-bottom:1px solid var(--line); white-space:nowrap; }}
th:first-child, td:first-child {{ text-align:left; }} th {{ color:var(--muted); font-weight:600; }}
.empty {{ text-align:center; color:var(--muted); padding:20px; }}
.foot {{ color:var(--muted); font-size:12px; margin-top:16px; }}
</style></head><body><main>
<h1>Donut admin</h1>
<div class="sub">Online play, built {datetime.datetime.now().strftime("%b %d, %Y %H:%M")}. Days are UTC.</div>
<div class="cards">{card_html}</div>
<div class="charts">
<div class="panel"><h2>Players per day</h2><canvas id="players" height="190"></canvas></div>
<div class="panel"><h2>Matches per day</h2><canvas id="matches" height="190"></canvas></div>
<div class="panel"><h2>Hands per day</h2><canvas id="hands" height="190"></canvas></div>
<div class="panel"><h2>People per match</h2><canvas id="people" height="190"></canvas></div>
</div>
<div class="panel"><h2>Last 30 days</h2><div class="scroll"><table>{table_html}</table></div></div>
<div class="foot">Counts only. Unique players are counted from hashed install ids that are deleted after 30 days;
no names, chat or other personal data is kept for this dashboard.</div>
</main>
<script>
const d = {json.dumps(data)};
if (window.Chart) {{
  const css = getComputedStyle(document.documentElement);
  const accent = css.getPropertyValue('--accent').trim(), accent2 = css.getPropertyValue('--accent2').trim();
  Chart.defaults.color = css.getPropertyValue('--muted').trim();
  Chart.defaults.borderColor = css.getPropertyValue('--line').trim();
  const opts = {{ plugins: {{ legend: {{ display: false }} }}, scales: {{ y: {{ beginAtZero: true, ticks: {{ precision: 0 }} }} }} }};
  new Chart(document.getElementById('players'), {{ type: 'line', data: {{ labels: d.labels, datasets: [{{ data: d.players, borderColor: accent, backgroundColor: accent, tension: .3 }}] }}, options: opts }});
  new Chart(document.getElementById('matches'), {{ type: 'bar', data: {{ labels: d.labels, datasets: [
    {{ label: 'Parties', data: d.party, backgroundColor: accent }}, {{ label: 'Public', data: d.public, backgroundColor: accent2 }}] }},
    options: {{ ...opts, plugins: {{ legend: {{ display: true }} }}, scales: {{ x: {{ stacked: true }}, y: {{ stacked: true, beginAtZero: true, ticks: {{ precision: 0 }} }} }} }} }});
  new Chart(document.getElementById('hands'), {{ type: 'bar', data: {{ labels: d.labels, datasets: [{{ data: d.hands, backgroundColor: accent }}] }}, options: opts }});
  new Chart(document.getElementById('people'), {{ type: 'bar', data: {{ labels: d.people.labels, datasets: [{{ data: d.people.counts, backgroundColor: accent2 }}] }}, options: opts }});
}}
</script></body></html>''')
