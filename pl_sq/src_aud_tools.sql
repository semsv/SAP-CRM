CREATE OR REPLACE PACKAGE UBRR_SRC.ubrr_src_aud_tools
IS

procedure Write_Aud;

END; -- Package spec
/
CREATE OR REPLACE PACKAGE BODY UBRR_SRC.ubrr_src_aud_tools
IS


  TYPE ntt_varchar2 IS TABLE OF VARCHAR2(1028);

----------------------------------
--Процедура удаления из текста DDLки строки с паролем
procedure Clear_Passwd_From_DDL(pStr in out nocopy clob)
is

  cvStr varchar2(32000);

  type t_StrList is table of varchar2(32000)
    index by binary_integer;

  vWordsList t_StrList;

  cvOneWord varchar2(512);
  bvExist_IDENT  boolean;
  bvExist_BY     boolean;
  bvExist_Quotes boolean;

  ivPos number;
  ivPos_Space number;
  ivPos_NewLine number;

  cvPasswd varchar2(4000);
  cvPasswd_Null varchar2(4000);

begin

  bvExist_IDENT  :=false;
  bvExist_BY     :=false;
  bvExist_Quotes :=false;
  cvPasswd:=null;

  cvStr:=substr(pStr,1,32000);
  vWordsList.delete;
  cvPasswd:=null;

  --разбираем строку на слова
  loop
    --позиция следующего пробела
    ivPos_Space:=nvl(instr(cvStr,' '),0);
    if ivPos_Space=0 then
      ivPos_Space:=nvl(length(cvStr),0);
    end if;

    --позиция следующей новой сроки
    ivPos_NewLine:=nvl(instr(cvStr,chr(10)),0);
    if ivPos_NewLine=0 then
      ivPos_NewLine:=ivPos_Space;
    end if;

    --меньшую из позиций считаем границей слова
    ivPos:=least(ivPos_NewLine,ivPos_Space);

    if ivPos>0 then
      vWordsList(vWordsList.count+1):=substr(cvStr,1,ivPos);
      cvStr:=substr(cvStr,ivPos+1);
    end if;

    exit when cvStr is null;

  end loop;

  --ищем вставку "IDENTIFIED BY"
  for ii in nvl(vWordsList.first,1)..nvl(vWordsList.last,0) loop

    cvOneWord:=vWordsList(ii);

    --убираем лишние символы
    cvOneWord:=trim(chr(10) from cvOneWord);
    cvOneWord:=upper(trim(cvOneWord));

    --ищем нужное слово
    if    not bvExist_IDENT then
       bvExist_IDENT:= nvl(cvOneWord,'***')='IDENTIFIED' ;
    elsif not bvExist_BY then
       if cvOneWord is not null then
         bvExist_BY := cvOneWord='BY';
         bvExist_IDENT:=bvExist_BY;
         bvExist_Quotes:=false;
         cvPasswd_Null:='<ENTER_PASSWORD_HERE>';
       end if;
    else

      if cvOneWord is not null then
        -- разбор пароля
        if not bvExist_Quotes then
          bvExist_Quotes:=nvl(substr(cvOneWord,1,1),'***')='"';
        end if;

        if bvExist_Quotes then
          bvExist_Quotes:=not nvl(substr(cvOneWord,-1,1),'***')='"';
        end if;

        if not bvExist_Quotes then
          bvExist_BY:=false;
          bvExist_IDENT:=false;
        end if;

      end if;

      cvPasswd:=cvPasswd||vWordsList(ii);

    end if;

  end loop;

  cvPasswd:=trim(chr(10) from cvPasswd);
  cvPasswd:=trim(cvPasswd);

  if cvPasswd is not null then
    pStr:=replace(pStr, cvPasswd,cvPasswd_Null);
    cvPasswd_Null:=null;
  end if;

exception
  when OTHERS then
    null;
end;



   FUNCTION string_to_table (
            string_in    IN VARCHAR2,
            delimiter_in IN VARCHAR2 DEFAULT ','
            ) RETURN ntt_varchar2 IS

      v_wkg_str VARCHAR2(32767) := string_in || delimiter_in;
      v_pos     PLS_INTEGER;
      nt_return ntt_varchar2 := ntt_varchar2();

   BEGIN

      LOOP
         v_pos := INSTR(v_wkg_str,delimiter_in);
         EXIT WHEN NVL(v_pos,0) = 0;
         nt_return.EXTEND;
         nt_return(nt_return.LAST) := TRIM(SUBSTR(v_wkg_str,1,v_pos-1));
         v_wkg_str := SUBSTR(v_wkg_str,v_pos+1);
      END LOOP;

      RETURN nt_return;

   END string_to_table;


   FUNCTION parse (
            depth_in IN PLS_INTEGER DEFAULT 2
            ) RETURN VARCHAR2 IS

      v_call_stack   VARCHAR2(4096);
      nt_stack_lines ntt_varchar2;
      c_recsep       CONSTANT VARCHAR2(1) := CHR(10);
      c_headlines    CONSTANT PLS_INTEGER := 3;

   BEGIN

      /* Get the call stack, removing the trailing newline... */
      v_call_stack := RTRIM(DBMS_UTILITY.FORMAT_CALL_STACK, c_recsep);

      /* Turn the call stack into a collection of lines... */
      nt_stack_lines := string_to_table(v_call_stack, c_recsep);

      /* Return the depth required (ignoring the header lines)... */
      RETURN nt_stack_lines(depth_in + c_headlines);

   EXCEPTION
      WHEN SUBSCRIPT_BEYOND_COUNT THEN
         RETURN NULL;
   END parse;

-----------------------------
--Запись аудита
procedure Write_Aud
is
  n_actid  number;

  sql_text ora_name_list_t;
  ivRowNum number ;
  cvClobText clob;
  cvOwner varchar2(30) := null;
  cvParsedOwner varchar2(1028);
  cvStr varchar2(1024);

  cvTempText varchar2(4000);
  cvTempOper schema_aud.c_audoper%type;
  cvTempPos number;
  cvTempOldName schema_aud.c_objectname%type;
  cvTempNewName schema_aud.c_objectname%type := null;
begin

  --игнорируем удаление данных из таблиц, анализ объектов и объекты, созданные из САПа (кроме удаления и грантов)
  if ora_sysevent='TRUNCATE'
     or user is null
     or (
           (
             sys_context('userenv', 'host') in (lower(sys_context('userenv','db_name')), 'SAPEE\EED')
             and user in ('SAPSR3', 'SAPE7D', 'SAPE7P', 'SAPEED', 'SAPEEP')
             and ora_sysevent not in ('DROP', 'GRANT', 'REVOKE')
           )
             or ora_sysevent = 'ANALYZE'
        )
  then
    return;
  end if;

  ivRowNum := ora_sql_txt(sql_text);

  cvClobText := null;
  for i in 1 .. nvl(ivRowNum, 0) loop
    cvClobText:=cvClobText||sql_text(i);
  end loop;

  cvOwner := ora_dict_obj_owner;

  -- для дблинков
  if ora_dict_obj_type = 'DATABASE LINK' then
      if cvOwner is null then
          cvStr := substr(cvClobText,1,1024);
          if instr(upper(cvStr), ' PUBLIC ') > 0 then
              cvOwner := 'PUBLIC';
          else
              cvParsedOwner := nullif(parse(4),'');
              if cvParsedOwner is not null then
                  cvOwner := substr(cvParsedOwner,
                                    instr(cvParsedOwner, ' ', -1) + 1,
                                    instr(cvParsedOwner, '.', -1) - instr(cvParsedOwner, ' ', -1) - 1);
              else
                  cvOwner := ora_login_user;
              end if;
          end if;
      end if;
  end if;

  if ora_dict_obj_type in ('USER','DATABASE LINK','ROLE') then
    Clear_Passwd_From_DDL(cvClobText);
  end if;

  select s_schema_aud.NEXTVAL into n_actid from dual;

  insert into schema_aud(n_audactid, c_audoper, c_objectowner, c_objecttype, c_objectname, c_ddl_text)
      values (n_actid, ora_sysevent, cvOwner, ora_dict_obj_type, ora_dict_obj_name, cvClobText);

  -- дополнительная обработка операции переименования объекта
  if    ora_sysevent = 'ALTER' and ora_dict_obj_type in ('TABLE', 'INDEX')
     or ora_sysevent = 'RENAME' and ora_dict_obj_type in ('TABLE', 'VIEW', 'SEQUENCE', 'SYNONYM')
  then
      cvTempOldName := ora_dict_obj_name;
      cvTempText := lower(trim(regexp_replace(replace(replace(replace(dbms_lob.substr(cvClobText, 4000, 1), chr(10), ' '), chr(13), ' '), chr(0), ' '), '( ){2,}', ' ')));
      if ora_sysevent = 'ALTER' then
          cvTempOper := ' rename to ';
          cvTempPos := instr(cvTempText, cvTempOper);
          if cvTempPos > 0 then
              cvTempNewName :=  substr(cvTempText, cvTempPos + length(cvTempOper));
          end if;
      elsif ora_sysevent = 'RENAME' then
          if cvTempOldName <> upper(cvTempOldName) then
              cvTempOldName := '"'||cvTempOldName||'"';
          else
              cvTempOldName := lower(cvTempOldName);
          end if;
          cvTempOper := 'rename '||cvTempOldName||' to ';
          cvTempPos := instr(cvTempText, cvTempOper);
          if cvTempPos > 0 then
              cvTempNewName :=  substr(cvTempText, cvTempPos + length(cvTempOper));
          end if;
      end if;

      -- если подстрока rename найдена в clob-е, то добавим записи в аудит
      if cvTempNewName is not null then
          if substr(cvTempNewName, 1, 1) = '"' and substr(cvTempNewName, -1, 1) = '"' then
              cvTempNewName := replace(cvTempNewName, '"', '');
          else
              cvTempNewName := upper(cvTempNewName);
          end if;

          -- drop для старого объекта
          select s_schema_aud.NEXTVAL into n_actid from dual;

          insert into schema_aud(n_audactid, c_audoper, c_objectowner, c_objecttype, c_objectname, c_ddl_text)
                         values (n_actid, 'DROP', cvOwner, ora_dict_obj_type, ora_dict_obj_name, to_clob('DROP '||ora_dict_obj_type||' '||cvTempOldName));

          -- create для нового объекта
          select s_schema_aud.NEXTVAL into n_actid from dual;

          insert into schema_aud(n_audactid, c_audoper, c_objectowner, c_objecttype, c_objectname, c_ddl_text)
                         values (n_actid, 'CREATE', cvOwner, ora_dict_obj_type, cvTempNewName, cvClobText);

      end if;
  end if;

exception
    when others then
        null;
end;


END;
/
