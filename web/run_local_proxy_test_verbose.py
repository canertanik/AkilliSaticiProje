import json, urllib.request, sys
url='http://localhost:5200/api/ai/suggest'
payload=json.load(open('temp_ai_payload.json','r',encoding='utf-8'))
data=json.dumps(payload).encode('utf-8')
req=urllib.request.Request(url,data=data,method='POST')
req.add_header('Content-Type','application/json')
try:
    with urllib.request.urlopen(req,timeout=30) as r:
        print('STATUS',r.status)
        print('HEADERS',dict(r.getheaders()))
        body=r.read()
        print('BODYLEN',len(body))
        print(body.decode('utf-8',errors='replace'))
except urllib.error.HTTPError as e:
    print('HTTPERR',e.code)
    try:
        print(e.read().decode('utf-8',errors='replace'))
    except Exception as ex:
        print('READERR',ex)
except Exception as e:
    print('ERR',e)
    sys.exit(1)
