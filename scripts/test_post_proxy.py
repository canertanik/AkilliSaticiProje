import urllib.request, json, urllib.error
url='http://localhost:5200/api/ai/suggest'
payload={'title':'Test proxy sonrası','imageUrl':'https://upload.wikimedia.org/wikipedia/commons/4/47/PNG_transparency_demonstration_1.png'}
req = urllib.request.Request(url, data=json.dumps(payload).encode('utf-8'), method='POST')
req.add_header('Content-Type','application/json')
try:
    with urllib.request.urlopen(req, timeout=60) as r:
        print('STATUS', r.status)
        body = r.read()
        print('BODYLEN', len(body))
        print(body.decode('utf-8', errors='replace'))
except urllib.error.HTTPError as e:
    print('HTTPERR', e.code)
    print(e.read().decode('utf-8', errors='replace'))
except Exception as e:
    print('ERR', e)
