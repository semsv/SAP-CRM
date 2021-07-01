select tablespace_name,sum(sizes), sum(occupied), sum(free),round(sum(persent)/count(*),2) from 
(SELECT 
t.tablespace_name , 
t.status, 
ROUND((MAX(d.bytes)/1024/1024) - (SUM(decode(f.bytes, NULL,0, f.bytes))/1024/1024),2) +ROUND(SUM(decode(f.bytes, NULL,0, f.bytes))/1024/1024,2) as sizes, 
ROUND((MAX(d.bytes)/1024/1024) - (SUM(decode(f.bytes, NULL,0, f.bytes))/1024/1024),2) as occupied, 
ROUND(SUM(decode(f.bytes, NULL,0, f.bytes))/1024/1024,2) as free, 
ROUND((ROUND((MAX(d.bytes)/1024/1024) - (SUM(decode(f.bytes, NULL,0, f.bytes))/1024/1024),2) / 
(ROUND((MAX(d.bytes)/1024/1024) - (SUM(decode(f.bytes, NULL,0, f.bytes))/1024/1024),2) + 
ROUND(SUM(decode(f.bytes, NULL,0, f.bytes))/1024/1024,2)) )*100,3) as persent, 
t.initial_extent , 
t.next_extent , 
t.min_extents , 
t.max_extents , 
t.pct_increase 
,SUBSTR(d.file_name,1,80) 
FROM DBA_FREE_SPACE f , DBA_DATA_FILES d , DBA_TABLESPACES t 
WHERE t.tablespace_name not in ('TEMP','UNDOTBS1') AND t.tablespace_name = d.tablespace_name AND f.tablespace_name(+) = d.tablespace_name 
AND f.file_id(+) = d.file_id 
GROUP BY t.tablespace_name , d.file_name , t.initial_extent , t.next_extent , t.min_extents , t.max_extents ,t.pct_increase , t.status ORDER BY 1,3 DESC) 
group by tablespace_name order by 1  
