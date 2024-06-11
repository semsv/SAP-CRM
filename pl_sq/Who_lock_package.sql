select distinct 'alter system disconnect session ''' || sid || ',' || serial# || ''' immediate;'
from v$session, x$kgllk
where saddr = kgllkuse and kglnaobj = upper ('package_name'); 
