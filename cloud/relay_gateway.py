import asyncio
from aiohttp import ClientSession, WSMsgType, web

UPSTREAM='http://127.0.0.1:3000'
HOP={'connection','keep-alive','proxy-authenticate','proxy-authorization','te','trailers','transfer-encoding','upgrade','content-length','x-frame-options','content-security-policy'}

async def valid(token):
    if len(token)!=64:return False
    try:
        async with ClientSession() as client:
            async with client.get('https://homework-study-work-app.vercel.app/api/tunnel-validate',params={'token':token},timeout=10) as response:return response.status==200
    except Exception:return False

async def relay_ws(request):
    if not await valid(request.query.get('token','')):raise web.HTTPForbidden(text='Protected by Homework')
    client=ClientSession(); browser=web.WebSocketResponse(heartbeat=20,compress=False);await browser.prepare(request)
    upstream=await client.ws_connect(UPSTREAM+request.path_qs,heartbeat=20,max_msg_size=0)
    async def pump(source,target):
        async for msg in source:
            if msg.type==WSMsgType.TEXT:await target.send_str(msg.data)
            elif msg.type==WSMsgType.BINARY:await target.send_bytes(msg.data)
            elif msg.type in (WSMsgType.CLOSE,WSMsgType.CLOSED,WSMsgType.ERROR):break
    try:await asyncio.gather(pump(browser,upstream),pump(upstream,browser))
    finally:await upstream.close();await client.close()
    return browser

async def relay_http(request):
    headers={k:v for k,v in request.headers.items() if k.lower() not in HOP and k.lower()!='host'}
    async with ClientSession() as client:
        async with client.request(request.method,UPSTREAM+request.rel_url.path_qs,headers=headers,data=await request.read(),allow_redirects=False) as response:
            body=await response.read();out={k:v for k,v in response.headers.items() if k.lower() not in HOP};return web.Response(status=response.status,body=body,headers=out)

async def handler(request):
    if request.headers.get('Upgrade','').lower()=='websocket':return await relay_ws(request)
    return await relay_http(request)

app=web.Application(client_max_size=16*1024*1024);app.router.add_route('*','/{path:.*}',handler);web.run_app(app,host='0.0.0.0',port=3100,access_log=None)
