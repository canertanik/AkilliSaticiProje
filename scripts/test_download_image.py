from urllib.request import Request, urlopen
url='https://upload.wikimedia.org/wikipedia/commons/4/47/PNG_transparency_demonstration_1.png'
req = Request(url, headers={'User-Agent':'Mozilla/5.0'})
try:
    with urlopen(req, timeout=20) as r:
        data = r.read()
        print('OK', len(data), 'bytes')
        print('Content-Type:', r.headers.get('Content-Type'))
except Exception as e:
    print('ERR', e)
