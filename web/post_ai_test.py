import requests
url='http://127.0.0.1:8000/ai/suggest'
payload={'title':'Test Ayakkabı','size':'1kg','imageBase64':'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR4nGNgYAAAAAMAASsJTYQAAAAASUVORK5CYII='}
resp=requests.post(url,json=payload,timeout=30)
print(resp.status_code)
print(resp.text)
