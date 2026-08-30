import {hasSession} from './_lib/security.js';
import {recentLoginEvents} from './_lib/store.js';
export default async function handler(req,res){res.setHeader('Cache-Control','no-store');if(req.method!=='GET')return res.status(405).json({error:'Method not allowed'});if(!hasSession(req))return res.status(401).json({error:'Please sign in again.'});try{return res.status(200).json({events:await recentLoginEvents(30)})}catch(e){return res.status(503).json({error:e.message})}}
