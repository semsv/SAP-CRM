select t.table_name table_name,
       t.table_size table_size_KB,
       i.index_name index_name,
       i.index_size index_size_KB
  from (select segment_name table_name, 
               ceil(sum(bytes) / #cc66cc;">1024) table_size
          from dba_segments
         where owner = 'ИМЯ_СХЕМЫ'
           and segment_type = 'TABLE'
           and segment_name = 'ИМЯ_ТАБЛИЦЫ'
         group by segment_name) t
  left join dba_indexes ti
    on ti.table_name = t.table_name
  left join (select segment_name index_name,
                    ceil(sum(bytes) / #cc66cc;">1024) index_size
               from dba_segments
              where owner = 'ИМЯ_СХЕМЫ'
                and segment_type = 'INDEX'
              group by segment_name) i
    on i.index_name = ti.index_name
 order by i.index_size desc;
