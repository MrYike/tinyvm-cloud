import base64, hashlib, json, os
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path, PurePosixPath
from urllib.parse import parse_qs, urlparse

ROOT=Path(os.environ.get('CLOUDDRIVE_ROOT','/config/CloudDrive')).resolve()
TOKEN=os.environ.get('FILE_BRIDGE_TOKEN','')
MAX_BYTES=4*1024*1024

def target(name):
    clean=PurePosixPath('/'+str(name)).relative_to('/')
    path=(ROOT/clean).resolve()
    if path!=ROOT and ROOT not in path.parents: raise ValueError('Invalid path')
    return path

class Handler(BaseHTTPRequestHandler):
    def reply(self,status,data):
        body=json.dumps(data).encode(); self.send_response(status); self.send_header('Content-Type','application/json'); self.send_header('Content-Length',str(len(body))); self.end_headers(); self.wfile.write(body)
    def auth(self):
        if not TOKEN or self.headers.get('Authorization')!='Bearer '+TOKEN: self.reply(401,{'error':'Unauthorized'}); return False
        return True
    def do_GET(self):
        if not self.auth(): return
        query=parse_qs(urlparse(self.path).query)
        if query.get('action',[''])[0]=='download':
            try:
                path=target(query.get('path',[''])[0]); data=path.read_bytes(); self.reply(200,{'path':path.relative_to(ROOT).as_posix(),'content':base64.b64encode(data).decode()})
            except Exception as e: self.reply(404,{'error':str(e)})
            return
        ROOT.mkdir(parents=True,exist_ok=True); files=[]
        for path in ROOT.rglob('*'):
            if path.is_file():
                data=path.read_bytes(); files.append({'path':path.relative_to(ROOT).as_posix(),'size':len(data),'sha256':hashlib.sha256(data).hexdigest()})
        self.reply(200,{'files':files})
    def do_POST(self):
        if not self.auth(): return
        try:
            size=int(self.headers.get('Content-Length','0'))
            if size>MAX_BYTES*2: raise ValueError('File is too large')
            body=json.loads(self.rfile.read(size)); data=base64.b64decode(body['content'],validate=True)
            if len(data)>MAX_BYTES: raise ValueError('File is too large')
            path=target(body['path']); path.parent.mkdir(parents=True,exist_ok=True); path.write_bytes(data)
            self.reply(200,{'ok':True,'path':path.relative_to(ROOT).as_posix(),'sha256':hashlib.sha256(data).hexdigest()})
        except Exception as e: self.reply(400,{'error':str(e)})
    def log_message(self,*args): pass

ROOT.mkdir(parents=True,exist_ok=True)
ThreadingHTTPServer(('0.0.0.0',8765),Handler).serve_forever()
