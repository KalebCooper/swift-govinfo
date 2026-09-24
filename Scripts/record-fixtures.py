#!/usr/bin/env python3
"""Opt-in recording of public GovInfo samples without overwriting prior evidence."""
import argparse
import datetime
import hashlib
import json
import os
from pathlib import Path
import urllib.error
import urllib.parse
import urllib.request

ROOT = Path(__file__).resolve().parents[1] / 'Sources/SwiftGovInfoDocumentsTestSupport/Fixtures'
SAMPLES = {
    'billstatus.xml': 'https://www.govinfo.gov/bulkdata/BILLSTATUS/119/hr/BILLSTATUS-119hr1.xml',
    'collections.json': '/collections',
    'dcpd-current.json': '/packages/DCPD-202600542/summary',
    'dcpd-historical.json': '/packages/DCPD-200900009/summary',
    'dcpd-mods.xml': 'https://www.govinfo.gov/metadata/pkg/DCPD-200900009/mods.xml',
    'dcpd.html': 'https://www.govinfo.gov/content/pkg/DCPD-202600542/html/DCPD-202600542.htm',
    'fr-historical.json': '/packages/FR-1936-03-14/summary',
    'fr.pdf': 'https://www.govinfo.gov/content/pkg/FR-1936-03-14/pdf/FR-1936-03-14.pdf',
    'packages.json': '/collections/CPD/2026-09-01T00:00:00Z/2026-09-23T00:00:00Z?offsetMark=*&pageSize=2',
    'ppp-book.json': '/packages/PPP-1929-book1/summary',
    'ppp-granules.json': '/packages/PPP-1929-book1/granules?offsetMark=*&pageSize=2',
    'ppp.xml': 'https://www.govinfo.gov/content/pkg/PPP-2009-book1/xml/PPP-2009-book1.xml',
    'published.json': '/published/1993-01-01/1993-01-11?collection=CPD&offsetMark=*&pageSize=2',
    'related-cpd.json': '/related/BILLS-119hr1enr/CPD',
    'relationships.json': '/related/BILLS-119hr1enr',
    'statute.json': '/packages/STATUTE-1/summary',
    'wcpd-granule.json': '/packages/WCPD-1993-01-11/granules/WCPD-1993-01-11-Pg1/summary',
    'wcpd-granules.json': '/packages/WCPD-1993-01-11/granules?offsetMark=*&pageSize=2',
    'wcpd-terminal.json': '/packages/WCPD-1993-01-11/granules?offsetMark=*&pageSize=100',
    'wcpd.json': '/packages/WCPD-1993-01-11/summary',
}


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, request, response, code, message, headers, new_url):
        return None


def record(name, location):
    if (ROOT / name).exists() or (ROOT / (name + '.receipt.json')).exists():
        raise SystemExit('Refusing to overwrite an existing fixture: ' + name)
    url = 'https://api.govinfo.gov' + location if location.startswith('/') else location
    parsed = urllib.parse.urlsplit(url)
    if parsed.scheme != 'https' or parsed.hostname not in {'api.govinfo.gov', 'www.govinfo.gov'} or parsed.username or parsed.password:
        raise SystemExit('Refusing an untrusted source URL')
    if any(key.lower() in {'api_key', 'apikey', 'key', 'x-api-key'} for key, _ in urllib.parse.parse_qsl(parsed.query)):
        raise SystemExit('Refusing a credential-bearing source URL')
    headers = {'User-Agent': '(swift-govinfo, https://github.com/KalebCooper/swift-govinfo)'}
    if url.startswith('https://api.govinfo.gov/'):
        headers['X-Api-Key'] = os.environ.get('GOVINFO_API_KEY', 'DEMO_KEY')
    request = urllib.request.Request(url, headers=headers)
    try:
        response = urllib.request.build_opener(NoRedirect).open(request, timeout=90)
    except urllib.error.HTTPError as error:
        response = error
    with response:
        data = response.read(32 * 1024 * 1024 + 1)
        if len(data) > 32 * 1024 * 1024:
            raise SystemExit('Recording exceeds 32 MiB; no partial fixture saved')
        receipt = {
            'byteCount': len(data), 'file': name,
            'headers': dict(sorted((key, value) for key, value in response.headers.items() if key.lower() not in {'authorization', 'x-api-key', 'set-cookie', 'cookie'})),
            'providerID': location.split('/packages/')[-1].split('/')[0] if '/packages/' in location else None,
            'retrievedAt': datetime.datetime.now(datetime.timezone.utc).isoformat(),
            'sha256': hashlib.sha256(data).hexdigest(),
            'status': response.status, 'url': url,
        }
    (ROOT / name).write_bytes(data)
    (ROOT / (name + '.receipt.json')).write_text(json.dumps(receipt, indent=2) + '\n')
    print(name, response.status, len(data), flush=True)
    if response.status in (401, 403, 429):
        raise SystemExit('Access refused; stop recording and retain evidence.')
    return data

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('samples', nargs='+', choices=sorted(SAMPLES), help='New recordings only; honor saved Retry-After before resuming API requests.')
    arguments = parser.parse_args()
    ROOT.mkdir(parents=True, exist_ok=True)
    for name in arguments.samples:
        data = record(name, SAMPLES[name])
        if name in ('packages.json', 'wcpd-granules.json'):
            next_page = json.loads(data).get('nextPage')
            if next_page:
                record(name.replace('.json', '-next.json'), next_page)
