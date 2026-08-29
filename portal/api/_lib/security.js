import crypto from 'node:crypto';
export function getIp(req){return String(req.headers['x-forwarded-for']||req.socket?.remoteAddress||'unknown').split(',')[0].trim()}
function secret(){if(!process.env.SESSION_SECRET)throw new Error('SESSION_SECRET is not configured');return process.env.SESSION_SECRET}
function signature(value){return crypto.createHmac('sha256',secret()).update(value).digest('base64url')}
export function makeSession(ip){const payload=Buffer.from(JSON.stringify({ip,exp:Date.now()+12*60*60*1000})).toString('base64url');return `${payload}.${signature(payload)}`}
export function hasSession(req){const raw=(req.headers.cookie||'').split(';').map(v=>v.trim()).find(v=>v.startsWith('homework_session='))?.slice(17);if(!raw)return false;const [payload,sig]=raw.split('.');if(!payload||!sig)return false;const expected=signature(payload);if(sig.length!==expected.length||!crypto.timingSafeEqual(Buffer.from(sig),Buffer.from(expected)))return false;try{const data=JSON.parse(Buffer.from(payload,'base64url'));return data.exp>Date.now()&&data.ip===getIp(req)}catch{return false}}
export function sessionCookie(value){return `homework_session=${value}; Path=/; HttpOnly; Secure; SameSite=Strict; Max-Age=43200`}
export function safeEqual(a,b){const x=Buffer.from(String(a||'')),y=Buffer.from(String(b||''));return x.length===y.length&&crypto.timingSafeEqual(x,y)}
