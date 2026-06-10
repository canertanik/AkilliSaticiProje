import urllib.request, json, sys
try:
    with urllib.request.urlopen('http://127.0.0.1:4040/api/tunnels', timeout=5) as r:
        data=json.load(r)
        for t in data.get('tunnels',[]):
            addr = t.get('config',{}).get('addr','')
            pub = t.get('public_url','')
            if '5200' in addr or '5200' in pub or 'localhost:5200' in addr:
                print(pub)
                sys.exit(0)
        # fallback: print all tunnels
        for t in data.get('tunnels',[]):
            print(t.get('public_url'))
except Exception as e:
    print('ERR',e)
