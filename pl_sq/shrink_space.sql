create or replace procedure ubrr_clc_process_shrink_space is
begin
  for rec in
  (
    select SEGMENT_NAME, MAX(BYTES)
      from user_segments
     where SEGMENT_TYPE = 'TABLE'
  group by SEGMENT_NAME
  )
  loop
      begin
        execute immediate 'alter table ' || rec.SEGMENT_NAME || ' enable row movement';
        execute immediate 'alter table ' || rec.SEGMENT_NAME || ' shrink space';
      exception
        when others then
          dbms_output.put_line(rec.SEGMENT_NAME || ' : ' || substr(sqlerrm, 1, 255));
      end;
  end loop;
end;
