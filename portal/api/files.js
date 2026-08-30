import crypto from 'node:crypto';
import {hasSession} from './_lib/security.js';
import {saveRelayTicket} from './_lib/store.js';

async function relay(){
  const response=await fetch('https://raw.githubusercontent.com/MrYike/tinyvm-cloud/main/runtime/tunnel.json',{cache:'no-store'});
  if(!response.ok)throw new Error('CloudDrive relay is starting.');
  const record=await response.json(),url=new URL(record.url);
  if(url.protocol!=='https:'||!url.hostname.endsWith('.trycloudflare.com'))throw new Error('CloudDrive relay is invalid.');
  return url.origin;
}

export default async function handler(req,res){
  if(!hasSession(req))return res.status(401).json({error:'Please sign in again.'});
  try{
    const token=crypto.randomBytes(32).toString('hex');
    await saveRelayTicket(crypto.createHash('sha256').update(token).digest('hex'));
    const url=new URL('/cloud-files',await relay());
    for(const [key,value] of Object.entries(req.query||{}))url.searchParams.set(key,String(value));
    url.searchParams.set('token',token);
    const upstream=await fetch(url,{method:req.method,headers:{'content-type':'application/json'},body:req.method==='GET'?undefined:JSON.stringify(req.body||{})});
    const data=await upstream.arrayBuffer();res.status(upstream.status);res.setHeader('content-type',upstream.headers.get('content-type')||'application/json');return res.send(Buffer.from(data));
  }catch(error){return res.status(502).json({error:error.message})}
}
