create or replace procedure ubrr_xxi5.ubrr_clc_loader_run_job is
  V_IS_RUN              ubrr_data.ubrr_clc_loader_run.Is_Run%type;
  V_ON_DELETE           ubrr_data.ubrr_clc_loader_run.On_Delete%type;
  V_PROC_NAME           ubrr_data.ubrr_clc_loader_run.Procedure_Name%type;
  V_TYPE_PROC           ubrr_data.ubrr_clc_loader_run.TYPE_PROCEDURE%type;
  V_PARAM_CNT           ubrr_data.ubrr_clc_loader_run.PARAM_COUNT%type;
  V_PARAM_VAL1          ubrr_data.ubrr_clc_loader_run.PARAM_VAL1%type;
  V_PARAM_VAL2          ubrr_data.ubrr_clc_loader_run.PARAM_VAL2%type;
  V_PARAM_VAL3          ubrr_data.ubrr_clc_loader_run.PARAM_VAL3%type;
  V_PARAM_VAL4          ubrr_data.ubrr_clc_loader_run.PARAM_VAL4%type;
  V_PARAM_VAL5          ubrr_data.ubrr_clc_loader_run.PARAM_VAL5%type;
  V_PARAM_MASK1         ubrr_data.ubrr_clc_loader_run.PARAM_MASK1%type;
  V_PARAM_MASK2         ubrr_data.ubrr_clc_loader_run.PARAM_MASK2%type;
  V_PARAM_MASK3         ubrr_data.ubrr_clc_loader_run.PARAM_MASK3%type;
  V_PARAM_MASK4         ubrr_data.ubrr_clc_loader_run.PARAM_MASK4%type;
  V_PARAM_MASK5         ubrr_data.ubrr_clc_loader_run.PARAM_MASK5%type;
  V_PARAM_TO_FMT1       ubrr_data.ubrr_clc_loader_run.PARAM_TO_FMT1%type;
  V_PARAM_TO_FMT2       ubrr_data.ubrr_clc_loader_run.PARAM_TO_FMT2%type;
  V_PARAM_TO_FMT3       ubrr_data.ubrr_clc_loader_run.PARAM_TO_FMT3%type;
  V_PARAM_TO_FMT4       ubrr_data.ubrr_clc_loader_run.PARAM_TO_FMT4%type;
  V_PARAM_TO_FMT5       ubrr_data.ubrr_clc_loader_run.PARAM_TO_FMT5%type;
  V_IMMDT               varchar2(2000);
  VTXTERR               ubrr_data.ubrr_clc_loader_run.Txterr%type;
  nrowid                rowid       := null;
  user_sqlrowcount      pls_integer := 0;
  vcnt                  number      := 0;
begin
-- �������� ������� ������������� ����� ���� stopped, � ���� ����� ������ �� ��������� (��������� ��� �������) ������� ���� ��������
-- ��� ��������� ���� is_stop � ���� �� 1 �� ��� ���������� ���� ���������� ����� ���� ������ ���� stopped � 1
delete from ubrr_data.ubrr_clc_loader_run r where r.stopped = 1 and r.is_stop = 1;
commit;

  for rec in (select ID_WORK, PROCEDURE_NAME, WAIT_ID_WORK
                from ubrr_data.ubrr_clc_loader_run r
               where r.IS_RUN               = 0 and
                     trunc(r.START_DATE_RUN) = trunc(sysdate) -- ���� �� ��������� ������ ������� ������ ����������� �������
               order by r.ID_WORK asc  -- ��������� �� ����������� �� ������
             )
  loop
    begin
      -- ������ �� �������� ������� ����� � ��� �� ������������
      select count(*)
        into vcnt
        from ubrr_data.ubrr_clc_loader_run r
        where r.Procedure_Name = rec.Procedure_Name
          and r.Is_Run         = 1;
      --
      if vcnt = 0 and rec.WAIT_ID_WORK is not null then
        -- �������� ��� �� ����������� ��������� ������ (�� ��������� ������ ������ ���� ������ �� ������� ������)
        select count(*)
          into vcnt
          from ubrr_data.ubrr_clc_loader_run r
          where r.Is_Run         = 1
            and r.Id_Work        = rec.WAIT_ID_WORK;
      end if;

      if vcnt = 0 then
      -- ����������� ������ � ��������� �������
      begin
        select r.IS_RUN,
               r.rowid,
               nvl(ON_DELETE, 0) ON_DELETE,
               PROCEDURE_NAME,
               TYPE_PROCEDURE,
               PARAM_COUNT,
               PARAM_VAL1, PARAM_VAL2, PARAM_VAL3, PARAM_VAL4, PARAM_VAL5,
               PARAM_MASK1, PARAM_MASK2, PARAM_MASK3, PARAM_MASK4, PARAM_MASK5,
               PARAM_TO_FMT1, PARAM_TO_FMT2, PARAM_TO_FMT3, PARAM_TO_FMT4, PARAM_TO_FMT5
          into V_IS_RUN,
               nrowid,
               V_ON_DELETE,
               V_PROC_NAME,
               V_TYPE_PROC,
               V_PARAM_CNT,
               V_PARAM_VAL1, V_PARAM_VAL2, V_PARAM_VAL3, V_PARAM_VAL4, V_PARAM_VAL5,
               V_PARAM_MASK1, V_PARAM_MASK2, V_PARAM_MASK3, V_PARAM_MASK4, V_PARAM_MASK5,
               V_PARAM_TO_FMT1, V_PARAM_TO_FMT2, V_PARAM_TO_FMT3, V_PARAM_TO_FMT4, V_PARAM_TO_FMT5
          from ubrr_data.ubrr_clc_loader_run r
         where r.ID_WORK               = rec.Id_Work    -- �� ������
           and trunc(r.START_DATE_RUN) = trunc(sysdate) -- ������ ���� ��������� �������
           and r.Is_Run                = 0              -- ��� �� ��������
           and rownum                  = 1              -- �� ����� ����� ������
          for update nowait;
      exception
        when others then
          rollback;
          V_IS_RUN := 1;
          nrowid   := null;
      end;
      else
        V_IS_RUN := 1;
        nrowid   := null;
      end if;
      if V_IS_RUN = 0 then
        -- ���� ������ �� ��������, ��������� ������ ������
        update ubrr_data.ubrr_clc_loader_run r set r.Is_Run = 1, r.RUN_DATE = sysdate where r.rowid = nrowid;
        commit;
        -- ������ ������
        if V_TYPE_PROC = 0 then
          if V_PARAM_CNT = 0 then
            -- ������ ������� �� ������
            execute immediate 'declare '||
                              '  user_sqlrowcount  pls_integer := 0; ' ||
                              'begin ' ||
                              '  user_sqlrowcount :=' || V_PROC_NAME || ';' || ' ' ||
                              '  :1               := user_sqlrowcount;' ||
                              'end;'
                    using out user_sqlrowcount;
          elsif V_PARAM_CNT = 1 then
            -- ������ ������� �� ������
            execute immediate 'declare '||
                              '  user_sqlrowcount  pls_integer := 0; ' ||
                              'begin ' ||
                              '  user_sqlrowcount :=' || V_PROC_NAME || '(:2);' || ' ' ||
                              '  :1               := user_sqlrowcount;' ||
                              'end;'
                    using in out user_sqlrowcount, V_PARAM_VAL1;
          elsif V_PARAM_CNT = 2 then
            -- ������ ������� �� ������
            execute immediate 'declare '||
                              '  user_sqlrowcount  pls_integer := 0; ' ||
                              'begin ' ||
                              '  user_sqlrowcount :=' || V_PROC_NAME || '(:2, :3);' || ' ' ||
                              '  :1               := user_sqlrowcount;' ||
                              'end;'
                    using in out user_sqlrowcount, V_PARAM_VAL1, V_PARAM_VAL2;
          elsif V_PARAM_CNT = 3 then
            -- ������ ������� �� ������
            execute immediate 'declare '||
                              '  user_sqlrowcount  pls_integer := 0; ' ||
                              'begin ' ||
                              '  user_sqlrowcount :=' || V_PROC_NAME || '(:2, :3, :4);' || ' ' ||
                              '  :1               := user_sqlrowcount;' ||
                              'end;'
                    using in out user_sqlrowcount, V_PARAM_VAL1, V_PARAM_VAL2, V_PARAM_VAL3;
         elsif V_PARAM_CNT = 4 then
            -- ������ ������� �� ������
            execute immediate 'declare '||
                              '  user_sqlrowcount  pls_integer := 0; ' ||
                              'begin ' ||
                              '  user_sqlrowcount :=' || V_PROC_NAME || '(:2, :3, :4, :5);' || ' ' ||
                              '  :1               := user_sqlrowcount;' ||
                              'end;'
                    using in out user_sqlrowcount, V_PARAM_VAL1, V_PARAM_VAL2, V_PARAM_VAL3, V_PARAM_VAL4;
          elsif V_PARAM_CNT = 5 then
            -- ������ ������� �� ������
            execute immediate 'declare '||
                              '  user_sqlrowcount  pls_integer := 0; ' ||
                              'begin ' ||
                              '  user_sqlrowcount :=' || V_PROC_NAME || '(:2, :3, :4, :5, :6);' || ' ' ||
                              '  :1               := user_sqlrowcount;' ||
                              'end;'
                    using in out user_sqlrowcount, V_PARAM_VAL1, V_PARAM_VAL2, V_PARAM_VAL3, V_PARAM_VAL4, V_PARAM_VAL5;
          end if;
        else
          if V_PARAM_CNT = 0 then
            -- ������ ��������� �� ������
            execute immediate 'call ' || V_PROC_NAME || '(' || '' || ')';
          elsif V_PARAM_CNT = 1 then
            -- ������ ��������� �� ������
            if V_PARAM_MASK1 is null then
              execute immediate 'begin ' || V_PROC_NAME || '(' || ':1' || '); end;'
                      using in out V_PARAM_VAL1;
            else
              V_IMMDT        := 'begin ' || V_PROC_NAME || '(' || nvl(V_PARAM_TO_FMT1, 'TO_DATE') || '(' || ':1, :2)' || '); end;';
              execute immediate V_IMMDT using in out V_PARAM_VAL1, V_PARAM_MASK1;
            end if;
          elsif V_PARAM_CNT = 2 then
            -- ������ ��������� �� ������
            execute immediate 'begin ' || V_PROC_NAME || '(' || ':1, :2' || '); end;'
                    using in out V_PARAM_VAL1, V_PARAM_VAL2;
          elsif V_PARAM_CNT = 3 then
            -- ������ ��������� �� ������
            execute immediate 'begin ' || V_PROC_NAME || '(' || ':1, :2, :3' || '); end;'
                    using in out V_PARAM_VAL1, V_PARAM_VAL2, V_PARAM_VAL3;
          elsif V_PARAM_CNT = 4 then
            -- ������ ��������� �� ������
            execute immediate 'begin ' || V_PROC_NAME || '(' || ':1, :2, :3, :4' || '); end;'
                    using in out V_PARAM_VAL1, V_PARAM_VAL2, V_PARAM_VAL3, V_PARAM_VAL4;
          elsif V_PARAM_CNT = 5 then
            -- ������ ��������� �� ������
            execute immediate 'begin ' || V_PROC_NAME || '(' || ':1, :2, :3, :4, :5' || '); end;'
                    using in out V_PARAM_VAL1, V_PARAM_VAL2, V_PARAM_VAL3, V_PARAM_VAL4, V_PARAM_VAL5;
          end if;
        end if;
        -- ���������� ��� ������ ��� ��������� � ������ ����������
        update ubrr_data.ubrr_clc_loader_run r          -- ������� "������������ �������"
          set r.Is_Run         = 0,                     -- ���������
              r.Status         = 0,                     -- �����
              r.Txterr         = null,                  -- ������ ���
              r.START_DATE_RUN = r.START_DATE_RUN + 1,  -- ���� ������ ������
              r.FINAL_DATE     = sysdate,               -- ��������� ���� � ����� ����� ����������
              r.return_value   = user_sqlrowcount,      -- ��������� ������������ � ��������
              r.PARAM_VAL1     = V_PARAM_VAL1,          -- ���������� �������� ���������� 1
              r.PARAM_VAL2     = V_PARAM_VAL2,          -- ���������� �������� ���������� 2
              r.PARAM_VAL3     = V_PARAM_VAL3,          -- ���������� �������� ���������� 3
              r.PARAM_VAL4     = V_PARAM_VAL4,          -- ���������� �������� ���������� 4
              r.PARAM_VAL5     = V_PARAM_VAL5           -- ���������� �������� ���������� 5
          where r.rowid = nrowid;
        -- ���� ����� ������� ������ ����� ���������� �� ������� ����� ������ ���������
        if V_ON_DELETE = 1 then
          delete ubrr_data.ubrr_clc_loader_run r where r.rowid = nrowid;
        else 
        -- ����� ������ ���������
          update ubrr_data.ubrr_clc_loader_run r set r.Status = r.Status where r.rowid = nrowid;
        -- ���� ������ ����� ��� ���������� ������ � ��� ������� � ������ ����� ������ �� ��������� �� "������������ �������" 
        end if;
        nrowid := null;
        commit;
        -- ������� �� ��������� ����� ����� ����� ���������� �� ID ������, ����� ������ ����� ��������� ������
        exit;
      else -- ���� ������ �� ��������
        commit;
      end if;
    exception
      when others then
        VTXTERR := substr(sqlerrm, 1, 255);
        if nrowid is not null then
          update ubrr_data.ubrr_clc_loader_run r
              set r.Txterr = VTXTERR,
                  r.Status = 1,
                  r.Is_Run = 0
              where r.rowid = nrowid;
          -- ���� ����� ������� ������ �� ������� ����� ������ ���������
          if V_ON_DELETE = 1 then
            delete ubrr_data.ubrr_clc_loader_run r where r.rowid = nrowid;
          else 
          -- ����� ������ ���������
            update ubrr_data.ubrr_clc_loader_run r set r.Status = r.Status where r.rowid = nrowid;
          -- ���� ������ ����� ��� ���������� ������ � ��� ������� � ������ ����� ������ �� ��������� �� "������������ �������"   
          end if;
          nrowid := null;
          commit;
        end if;
    end;
  end loop;
  -- �������� ������� ������������� ����� ���� stopped, � ���� ����� ������ �� ��������� (��������� ��� ������� ������� ���� ��������)
  -- ��� ��������� ���� is_stop � ���� �� 1 �� ��� ���������� ���� ���������� ����� ���� ������ ���� stopped � 1
  delete from ubrr_data.ubrr_clc_loader_run r where r.stopped = 1 and r.is_stop = 1;
  -- ������ ������ �� �����
  delete from ubrr_data.ubrr_clc_loader_run_log l where trunc(l.CHANGE_DATE) < sysdate-90 and l.FINAL_DATE is null;
  commit;
end;
/
