SELECT 

segment_name, segment_type, tablespace_name, 

sum(ROUND(bytes/1024/1024/1024, 1)) AS gigabytes 

FROM 

dba_segments  

where 

lower(segment_name) like '%coef%'  -- название таблицы или индекса 

and owner = 'STAT2' 

group 

by segment_name, segment_type, tablespace_name 
