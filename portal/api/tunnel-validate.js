import crypto from 'node:crypto';
import {hasRelayTicket} from './_lib/store.js';
export default async function handler(req,res){res.setHeader('Cache-Control','no-store');if(req.method!=='GET')return res.status(405).json({valid:false});const token=String(req.query?.token||'');if(!/^[a-f0-9]{64}$/.test(token))return res.status(403).json({valid:false});try{const hash=crypto.createHash('sha256').update(token).digest('hex');return (await hasRelayTicket(hash))?res.status(200).json({valid:true}):res.status(403).json({valid:false})}catch{return res.status(503).json({valid:false})}}
