select t.table_name table_name,
       t.table_size table_size_MB,
       i.index_name index_name,
       i.index_size index_size_MB
  from (select segment_name table_name, 
               round(sum(bytes) / 1024 / 1024) table_size
          from dba_segments
         where owner = 'ИМЯ_СХЕМЫ'
           and segment_type = 'TABLE'
           and segment_name = 'ИМЯ_ТАБЛИЦЫ'
         group by segment_name) t
  left join dba_indexes ti
    on ti.table_name = t.table_name
  left join (select segment_name index_name,
                    round(sum(bytes) / 1024 / 1024) index_size
               from dba_segments
              where owner = 'ИМЯ_СХЕМЫ'
                and segment_type = 'INDEX'
              group by segment_name) i
    on i.index_name = ti.index_name
 order by i.index_size desc;
