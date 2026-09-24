#!/usr/bin/env python3
"""Verify that every recorded body retains a credential-free, byte-exact source receipt."""
import argparse
import datetime
import hashlib
import json
from pathlib import Path
import tempfile
import urllib.parse

FIXTURES = Path(__file__).resolve().parents[1] / 'Sources/SwiftGovInfoDocumentsTestSupport/Fixtures'


def check(directory):
    bodies = sorted(path for path in directory.iterdir() if path.suffix in {'.html', '.json', '.pdf', '.xml'} and not path.name.endswith('.receipt.json'))
    assert bodies, 'No recorded bodies'
    for body in bodies:
        receipt = json.loads(body.with_name(body.name + '.receipt.json').read_text())
        data = body.read_bytes()
        assert receipt['file'] == body.name, f'{body.name}: filename mismatch'
        assert receipt['byteCount'] == len(data), f'{body.name}: byte count mismatch'
        assert receipt['sha256'] == hashlib.sha256(data).hexdigest(), f'{body.name}: digest mismatch'
        assert datetime.datetime.fromisoformat(receipt['retrievedAt']).utcoffset() is not None, 'Missing retrieval timezone'
        url = urllib.parse.urlsplit(receipt['url'])
        assert url.scheme == 'https' and url.hostname in {'api.govinfo.gov', 'www.govinfo.gov', 'raw.githubusercontent.com'}, 'Unexpected source origin'
        assert not url.username and not url.password and not url.fragment, 'Credential-bearing source URL'
        assert not any(key.lower() in {'api_key', 'apikey', 'key', 'x-api-key'} for key, _ in urllib.parse.parse_qsl(url.query)), 'Credential-bearing query'
        assert not any(key.lower() in {'authorization', 'x-api-key', 'set-cookie', 'cookie'} for key in receipt['headers']), 'Sensitive recorded header'
        assert 100 <= receipt['status'] <= 599, 'Invalid status'
        if 'parentFile' in receipt:
            assert Path(receipt['parentFile']).name == receipt['parentFile'], 'Invalid parent filename'
            assert (directory / receipt['parentFile']).is_file(), 'Missing original document'
            assert receipt.get('sourceKind'), 'Unattributed extraction'
    assert len(list(directory.glob('*.receipt.json'))) == len(bodies), 'Orphaned receipt'
    return len(bodies)


def self_test():
    data = b'{"source":"official"}'
    receipt = {'byteCount': len(data), 'file': 'body.json', 'headers': {}, 'retrievedAt': '2026-09-24T00:00:00+00:00', 'sha256': hashlib.sha256(data).hexdigest(), 'status': 200, 'url': 'https://api.govinfo.gov/collections'}
    with tempfile.TemporaryDirectory(prefix='govinfo-receipts-') as name:
        directory = Path(name)
        body = directory / 'body.json'
        metadata = directory / 'body.json.receipt.json'
        body.write_bytes(data)
        metadata.write_text(json.dumps(receipt))
        assert check(directory) == 1
        for field, invalid in [('byteCount', 0), ('sha256', 'changed'), ('file', 'another.json'), ('url', 'https://api.govinfo.gov/collections?api_key=secret'), ('headers', {'X-Api-Key': 'secret'}), ('retrievedAt', '2026-09-24T00:00:00'), ('parentFile', 'missing.xml')]:
            metadata.write_text(json.dumps({**receipt, field: invalid}))
            try:
                check(directory)
            except (AssertionError, FileNotFoundError):
                continue
            raise AssertionError('Missed planted receipt violation: ' + field)
    print('Receipt checker: clean input and 7 planted violations passed')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--self-test', action='store_true')
    arguments = parser.parse_args()
    if arguments.self_test:
        self_test()
    else:
        print(f'Verified {check(FIXTURES)} attributed source bodies')
