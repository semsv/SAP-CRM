  begin
  for c in (select 'alter '|| rtrim (object_type, ' BODY') ||' ' || t.owner || '.' || t.object_name ||' compile' txt
              from dba_objects t
             where status = 'INVALID'
              and object_type != 'SYNONYM') loop
    begin          
      execute immediate (c.txt);
    exception 
      when others then 
        dbms_output.put_line (c.txt);
    end;
  end loop;
 
  for c in (select t.*
              from dba_objects t
             where status = 'INVALID') loop
    begin          
      dbms_utility.validate (c.object_id);
    exception 
      when others then 
        dbms_output.put_line (c.owner || '.' || c.object_name);
    end;
  end loop;
end;
