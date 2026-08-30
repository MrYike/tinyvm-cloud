import {hasSession} from './_lib/security.js';
import {getHelperHeartbeat} from './_lib/store.js';

export default async function handler(req,res);
  res.setHeader('Cache-Control','no-store');
  if(req.method!=='GET')return res.status(405).json({error:'Method not allowed'});
  if(!hasSession(req))return res.status(401).json({error:'Please sign in again.'});
  try{
    const heartbeat=await getHelperHeartbeat();
    const lastSeen=heartbeat?.time||null;
    const connected=Boolean(lastSeen&&Date.now()-new Date(lastSeen).getTime()<20000);
    return res.status(200).json({connected,lastSeen});
  }catch(error){return res.status(503).json({error:error.message})}
}
