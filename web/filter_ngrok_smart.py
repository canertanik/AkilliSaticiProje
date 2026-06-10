import urllib.request, json
try:
    with urllib.request.urlopen('http://127.0.0.1:4040/api/requests/http?limit=200', timeout=10) as r:
        data=json.load(r)
        hits=[entry for entry in data.get('requests', []) if entry.get('request', {}).get('uri')=='/api/products/admin/smart']
        print(json.dumps(hits, indent=2, ensure_ascii=False))
except Exception as e:
    print('ERR',e)
