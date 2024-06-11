select  l.sid,s.serial#,s.username,s.terminal, 
        decode(l.type,'RW','RW - Row Wait Enqueue', 
                    'TM','TM - DML Enqueue', 
                    'TX','TX - Trans Enqueue', 
                    'UL','UL - User',l.type||'System') res, 
        substr(t.name,1,10) tab,u.name owner, 
        l.id1,l.id2, 
        decode(l.lmode,1,'No Lock', 
                2,'Row Share', 
                3,'Row Exclusive', 
                4,'Share', 
                5,'Shr Row Excl', 
                6,'Exclusive',null) lmode, 
        decode(l.request,1,'No Lock', 
                2,'Row Share', 
                3,'Row Excl', 
                4,'Share', 
                5,'Shr Row Excl', 
                6,'Exclusive',null) request 
from v$lock l, v$session s, 
sys.user$ u,sys.obj$ t 
where l.sid = s.sid 
and s.type != 'BACKGROUND' 
and t.obj# = l.id1 
and u.user# = t.owner# 
 
 alter system disconnect session '882, 25257' IMMEDIATE;
