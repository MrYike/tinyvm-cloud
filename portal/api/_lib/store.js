const base=()=>process.env.KV_REST_API_URL||process.env.UPSTASH_REDIS_REST_URL;const token=()=>process.env.KV_REST_API_TOKEN||process.env.UPSTASH_REDIS_REST_TOKEN;
async function command(parts){if(!base()||!token())throw new Error('The IP protection database is not configured');const r=await fetch(base(),{method:'POST',headers:{authorization:`Bearer ${token()}`,'content-type':'application/json'},body:JSON.stringify(parts)});if(!r.ok)throw new Error('The IP protection database is unavailable');return (await r.json()).result}
const key=ip=>`homework:access:${ip}`;export async function accessFor(ip){const raw=await command(['GET',key(ip)]);return raw?JSON.parse(raw):{attempts:0,blocked:false,trusted:false}}export async function saveAccess(ip,value){await command(['SET',key(ip),JSON.stringify(value)])}export async function clearAccess(ip){await command(['DEL',key(ip)])}

const LOG_KEY='homework:login-log';
export async function addLoginEvent(event){await command(['LPUSH',LOG_KEY,JSON.stringify(event)]);await command(['LTRIM',LOG_KEY,'0','99'])}
export async function recentLoginEvents(limit=30){const rows=await command(['LRANGE',LOG_KEY,'0',String(Math.max(0,Math.min(99,limit-1)))]);return (rows||[]).map(row=>{try{return JSON.parse(row)}catch{return null}}).filter(Boolean)}

const JOBS_KEY='homework:helper:jobs';
export async function nextHelperJob(){const raw=await command(['RPOP',JOBS_KEY]);return raw?JSON.parse(raw):null}
export async function saveHelperResult(id,value){await command(['SET',`homework:helper:result:${id}`,JSON.stringify(value),'EX','3600'])}

const HELPER_HEARTBEAT_KEY='homework:helper:heartbeat';
export async function saveHelperHeartbeat(value){await command(['SET',HELPER_HEARTBEAT_KEY,JSON.stringify(value),'EX','120'])}
export async function getHelperHeartbeat(){const raw=await command(['GET',HELPER_HEARTBEAT_KEY]);return raw?JSON.parse(raw):null}

const TUNNEL_KEY='homework:desktop:tunnel';
export async function saveTunnel(value){await command(['SET',TUNNEL_KEY,JSON.stringify(value),'EX','86400'])}
export async function getTunnel(){const raw=await command(['GET',TUNNEL_KEY]);return raw?JSON.parse(raw):null}
export async function saveRelayTicket(hash){await command(['SET',`homework:relay:ticket:${hash}`,'1','EX','3600'])}
export async function hasRelayTicket(hash){return Boolean(await command(['GET',`homework:relay:ticket:${hash}`]))}
