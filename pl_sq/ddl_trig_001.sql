CREATE OR REPLACE TRIGGER UBRR_SRC.tr_database_src_aud
 AFTER
  DDL
 ON DATABASE
begin
  ubrr_src_aud_tools.Write_Aud;
exception
    when others then
        null;
end;
