select *
from   (SELECT dhst.sql_id,
               SQL_TEXT,
               X.CPU_TIME / 1000000 CPU_Time_inSec,
               X.Num_Execs,
               round(((X.CPU_TIME / 1000000) / X.Num_Execs), 3) CPUPEREXEC,
               X.num_rows
        FROM   DBA_HIST_SQLTEXT DHST,
               (SELECT DHSS.SQL_ID SQL_ID,
                       SUM(DHSS.CPU_TIME_DELTA) CPU_TIME,
                       sum(executions_delta) as Num_Execs,
                       sum(ROWS_PROCESSED_delta) as num_rows
                FROM   DBA_HIST_SQLSTAT DHSS
                WHERE  DHSS.SNAP_ID IN
                       (SELECT SNAP_ID
                        FROM   DBA_HIST_SNAPSHOT)
                GROUP  BY DHSS.SQL_ID) X
        WHERE  X.SQL_ID = DHST.SQL_ID
        and    X.Num_Execs != 0
        ORDER  BY X.CPU_TIME DESC) y
where  rownum <= 50
--where upper(SQL_TEXT) like '%RTDM_CRM_PROD_OFFERS%' 
--order by y.cpuperexec desc
order  by Y.CPU_Time_inSec desc;
