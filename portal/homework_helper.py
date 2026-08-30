"""Homework CloudDrive helper — run this file directly in Thonny."""
import base64, hashlib, http.cookiejar, json, pathlib, shutil, subprocess, sys, time, urllib.error, urllib.parse, urllib.request

PORTAL_URL = "https://homework-study-work-app.vercel.app"
PASSWORD = "123456"
LOCAL_FOLDER = pathlib.Path.home() / "HomeworkCloudDrive"
MAX_BYTES = 4 * 1024 * 1024
MODEL_FOLDER = pathlib.Path.home() / "HomeworkLocalAI" / "models"
MODEL = MODEL_FOLDER / "qwen2.5-3b-instruct-q4_k_m.gguf"
MODEL_URL = "https://huggingface.co/Qwen/Qwen2.5-3B-Instruct-GGUF/resolve/main/qwen2.5-3b-instruct-q4_k_m.gguf?download=true"
cookies = http.cookiejar.CookieJar()
opener = urllib.request.build_opener(urllib.request.HTTPCookieProcessor(cookies))

def request(path, payload=None, allow_non_json=False):
    data = None if payload is None else json.dumps(payload).encode()
    req = urllib.request.Request(PORTAL_URL + path, data=data, headers={"Content-Type":"application/json"})
    with opener.open(req, timeout=1800) as response:
        body = response.read()
        if response.status == 204 or not body.strip(): return None
        try: return json.loads(body.decode())
        except (UnicodeDecodeError, json.JSONDecodeError):
            if allow_non_json and 200 <= response.status < 300: return None
            raise RuntimeError("Homework returned an unreadable response for " + path)

def run_local_chat(payload):
    try: from llama_cpp import Llama
    except ImportError:
        print("Preparing the portable AI library inside Thonny Python...")
        args=[sys.executable,"-m","pip","install","llama-cpp-python"]
        if sys.platform=="darwin": args += ["--extra-index-url","https://abetlen.github.io/llama-cpp-python/whl/metal"]
        else: args += ["--extra-index-url","https://abetlen.github.io/llama-cpp-python/whl/cpu"]
        subprocess.check_call(args); from llama_cpp import Llama
    MODEL_FOLDER.mkdir(parents=True,exist_ok=True)
    if not MODEL.exists() or MODEL.stat().st_size<1_000_000_000:
        print("Downloading the portable local AI model once (about 2 GB)...")
        partial=MODEL.with_suffix(".partial")
        curl=shutil.which("curl")
        if curl: subprocess.check_call([curl,"-fL","--retry","5","--continue-at","-","--output",str(partial),MODEL_URL])
        else:
            with urllib.request.urlopen(MODEL_URL,timeout=60) as source,open(partial,"wb") as output: shutil.copyfileobj(source,output,1024*1024)
        partial.replace(MODEL)
    model=Llama(model_path=str(MODEL),n_ctx=4096,n_gpu_layers=-1,verbose=False)
    answer=model.create_chat_completion(messages=payload.get("messages",[]),max_tokens=2048,temperature=.7)
    return {"message":answer["choices"][0]["message"]["content"] or "No response."}

def sync_files():
    remote = {item["path"]: item for item in request("/api/files").get("files", [])}
    local = {name:(path, hashlib.sha256(path.read_bytes()).hexdigest()) for path,name in relative_files()}
    for name,item in remote.items():
        if name not in local or local[name][1] != item.get("sha256"):
            result = request("/api/files?action=download&path=" + urllib.parse.quote(name))
            destination = LOCAL_FOLDER / name
            destination.parent.mkdir(parents=True, exist_ok=True)
            destination.write_bytes(base64.b64decode(result["content"]))
            print("Downloaded", name)
    for name,(path,digest) in local.items():
        if name not in remote or remote[name].get("sha256") != digest:
            content = path.read_bytes()
            if len(content) > MAX_BYTES:
                print("Skipped (over 4 MB):", name); continue
            request("/api/files", {"path":name,"content":base64.b64encode(content).decode()})
            print("Uploaded", name)

def helper_loop():
    print("Helper connected. Files now sync automatically while Thonny stays open.")
    next_sync = 0
    while True:
        try:
            now = time.time()
            if now >= next_sync:
                sync_files()
                next_sync = now + 15
            request("/api/helper", {"heartbeat": True}, allow_non_json=True)
            packet=request("/api/helper", allow_non_json=True)
            if not packet: time.sleep(2); continue
            job=packet["job"]
            try:
                result=run_local_chat(job.get("payload",{})) if job.get("type")=="chat" else {"error":"Unsupported local job type"}
                request("/api/helper",{"id":job["id"],"result":result},allow_non_json=True)
            except Exception as error: request("/api/helper",{"id":job["id"],"error":str(error)},allow_non_json=True)
        except Exception as error:
            print("Waiting for Homework:",error); time.sleep(5)

def relative_files():
    for path in LOCAL_FOLDER.rglob("*"):
        if path.is_file():
            yield path, path.relative_to(LOCAL_FOLDER).as_posix()

def main():
    LOCAL_FOLDER.mkdir(parents=True, exist_ok=True)
    print("Starting Homework Manager...")
    request("/api/login", {"password": PASSWORD})
    helper_loop()

if __name__ == "__main__":
    try: main()
    except urllib.error.HTTPError as error: print("CloudDrive error:", error.read().decode(errors="replace"))
    except Exception as error: print("CloudDrive error:", error)
