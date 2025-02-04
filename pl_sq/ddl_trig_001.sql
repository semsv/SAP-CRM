CREATE OR REPLACE TRIGGER SRC.tr_database_src_aud
 AFTER
  DDL
 ON DATABASE
begin
  src_aud_tools.Write_Aud;
exception
    when others then
        null;
end;
