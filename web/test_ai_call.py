import json, urllib.request, sys
url='https://pointed-bring-dried.ngrok-free.dev/ai/suggest'
data={'title':'Test ürün 8kg','imageUrl':'https://images.unsplash.com/photo-1601758174114-e711c0cbaa69?auto=format&fit=crop&q=80&w=600'}
req=urllib.request.Request(url,data=json.dumps(data).encode('utf-8'),headers={'Content-Type':'application/json'})
try:
    with urllib.request.urlopen(req, timeout=60) as resp:
        print('STATUS',resp.status)
        print(resp.read().decode('utf-8'))
except Exception as e:
    print('ERROR',e)
    sys.exit(1)
