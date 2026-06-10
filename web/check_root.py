import urllib.request
url='https://pointed-bring-dried.ngrok-free.dev/'
try:
    with urllib.request.urlopen(url, timeout=20) as resp:
        print('STATUS',resp.status)
        print(resp.read(1000).decode('utf-8','ignore'))
except Exception as e:
    print('ERROR',e)
