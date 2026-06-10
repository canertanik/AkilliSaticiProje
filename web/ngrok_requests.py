import urllib.request, json
try:
    with urllib.request.urlopen('http://127.0.0.1:4040/api/requests/http?limit=50', timeout=5) as r:
        data=json.load(r)
        print(json.dumps(data, indent=2))
except Exception as e:
    print('ERR',e)
