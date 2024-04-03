CREATE OR REPLACE PACKAGE UBRR_CRM.UBRR_UPDATE_RTDM IS
  -- пакет предназначен для обновления информации в таблицах RTDM минуя RISKDWH 

/******************************************** HISTORY **********************************************\
       Дата          Автор            id          Описание
    ----------  ---------------   ----------  ------------------------------------------------------
    30.01.2023   Комилов А.А.     RRTDM-4237  Заполнение MAP_PRODUCT_OLD в RTDM типами ЕМН
    12.09.2020   Багаев М.С.       20-77311   Разработка пакета - Обновление таблиц по запросу      

\******************************************** HISTORY **********************************************/

-- обновление таблицы SAS_RTDM.PRODUCT_RTDM@RTDM
procedure update_product_rtdm;    

-- Старый метод для обновление таблицы SAS_RTDM.PRODUCT_RTDM@RTDM
procedure update_product_rtdm_old;

-- обновление таблицы SAS_RTDM.MAP_PRODUCT@RTDM
procedure update_map_product_rtdm;

-- обновление таблицы sas_rtdm.map_product_old@rtdm
procedure update_map_product_old_rtdm;        

end;
/
CREATE OR REPLACE PACKAGE BODY UBRR_CRM."UBRR_UPDATE_RTDM" IS
  -- пакет предназначен для обновления информации в таблицах RTDM минуя RISKDWH

/******************************************** HISTORY **********************************************\
       Дата          Автор            id          Описание
    ----------  ---------------   ----------  ------------------------------------------------------
    21.03.2024   Севастьянов С.В. RRTDM-6582  Ошибки при работе джоба UBRR_CRM.UPDATE_PRODUCT_RTDM_JOB на UVKL
    30.01.2023   Комилов А.А.     RRTDM-4237  Заполнение MAP_PRODUCT_OLD в RTDM типами ЕМН
    12.09.2020   Багаев М.С.       20-77311   Разработка пакета - Обновление таблиц по запросу

\******************************************** HISTORY **********************************************/


  -- логирование процесса
procedure logwrite (i_text varchar2) is
    pragma autonomous_transaction;
begin
    insert into UBRR_CRM.ubrr_update_rtdm_log (logtext) values (i_text);
    commit;
end logwrite;

  -- обновление таблицы SAS_RTDM.PRODUCT_RTDM@RTDM
procedure update_product_rtdm_old
  is
    v_rowcnt NUMBER;
    pragma autonomous_transaction;
begin  
  -->> ubrr 21.03.2024 Севастьянов С.В. RRTDM-6582
  if ubrr_vlv.code_block.is_block_enabled('UBRR_CRM.UBRR_UPDATE_RTDM RRTDM-6582') then
    MERGE INTO sas_rtdm.product_rtdm@rtdm D
    USING ( select
             x.TYPEDOG_ID          as ARM_TP_TYPE,        -- Номер продукта АРМ ТП
             x.TYPEDOG_NAME        as ARM_TP_TYPE_NAME,   -- Наименование типа продукта RTDM
             x.typedog_currency    as TYPEDOG_CURRENCY,   -- Валюта кредита (карточного счета)
             x.typedog_scred_m     as TYPEDOG_SCRED_M,    -- Срок кредита (месяц),
           --  x.typedog_proc_cred   as TYPEDOG_PROC_CRED,  -- Проценты по кредиту
             case when x3.percentvalue is null then x.typedog_prc_id else x3.percentvalue end as TYPEDOG_PROC_CRED, -- Проценты по кредиту
             x.typedog_limit_metod as TYPEDOG_LIMIT_METOD,-- Методика расчета лимита в АРМ МР
             x.typedog_min_sum     as TYPEDOG_MIN_SUM,    -- Минимальная сумма кредита
             x.typedog_max_sum     as TYPEDOG_MAX_SUM,    -- Максимальная сумма кредита
             case when x4.CONTRTYPE is not null then 1 else 0 end  RESTR -- Реструктурируемый (1) / не реструктурируемый (0)
             from ubrr_vdata.ubrr_scoring_typedog x
             left OUTER join
                     ( SELECT *       FROM ubrr_vdata.UBRR_SHM_VIEW_SCORING_GRPCON grp_ct
                      LEFT OUTER JOIN ubrr_vdata.UBRR_TAB_SCORING_GRP2AGGREG g2a ON g2a.id_grp = grp_ct.igrp_id
                      where id_aggreg = 5     -- Объединение 5 - реструктуризация;
                     ) x4
             on x.TYPEDOG_CTYPE_CRED = x4.CONTRTYPE
             left join  -- Проценты по кредиту
             (
              select x.id as typedog_prc_id,
                x2.percentvalue,
                row_number () over (partition by x1.ID order by x1.PRCDATE desc) nm
              from a4m.tPercentName@A4MBO x
                left join a4m.tPercentHistory@A4MBO x1 on x.id = x1.id
                                           and x.branch = x1.branch --<< 13.05.2020 Кокотов А.А. по примерам объдинения этих таблиц с базы TWR
                left join a4m.TPERCENTVALUE@A4MBO x2 on x1.code = x2.code
                 where x.category = 1 and x.dimension = 1
               ) x3 on x3.typedog_prc_id = x.typedog_prc_id and x3.nm=1
             ) S
     ON (D.arm_tp_type = s.arm_tp_type)
     WHEN NOT MATCHED THEN INSERT
             (D.ARM_TP_TYPE, D.ARM_TP_TYPE_NAME, D.TYPEDOG_CURRENCY, D.TYPEDOG_SCRED_M, D.TYPEDOG_PROC_CRED, D.TYPEDOG_LIMIT_METOD, D.TYPEDOG_MIN_SUM, D.TYPEDOG_MAX_SUM, D.RESTR)
      values (s.ARM_TP_TYPE, s.arm_tp_type_name, s.typedog_currency, s.typedog_scred_m, s.typedog_proc_cred, s.typedog_limit_metod, s.typedog_min_sum, s.typedog_max_sum, s.restr);
  else
    insert into SAS_RTDM.PRODUCT_RTDM@RTDM
      (ARM_TP_TYPE,ARM_TP_TYPE_NAME,TYPEDOG_CURRENCY,TYPEDOG_SCRED_M,TYPEDOG_PROC_CRED,TYPEDOG_LIMIT_METOD,TYPEDOG_MIN_SUM,TYPEDOG_MAX_SUM,RESTR)
      select  
        TYPEDOG_ID          as ARM_TP_TYPE,        -- Номер продукта АРМ ТП
        TYPEDOG_NAME        as ARM_TP_TYPE_NAME,   -- Наименование типа продукта RTDM
        TYPEDOG_CURRENCY    as TYPEDOG_CURRENCY,   -- Валюта кредита (карточного счета)
        TYPEDOG_SCRED_M     as TYPEDOG_SCRED_M,    -- Срок кредита (месяц)
        case when x3.percentvalue is null then a.typedog_prc_id else x3.percentvalue end as TYPEDOG_PROC_CRED, -- Проценты по кредиту
        TYPEDOG_LIMIT_METOD as TYPEDOG_LIMIT_METOD,-- Методика расчета лимита в АРМ МР
        TYPEDOG_MIN_SUM     as TYPEDOG_MIN_SUM,    -- Минимальная сумма кредита
        TYPEDOG_MAX_SUM     as TYPEDOG_MAX_SUM,    -- Максимальная сумма кредита
        case when x4.CONTRTYPE is not null then 1 else 0 end  RESTR -- Реструктурируемый (1) / не реструктурируемый (0) 
     from ubrr_vdata.ubrr_scoring_typedog a
     left OUTER join
       ( SELECT *       FROM ubrr_vdata.UBRR_SHM_VIEW_SCORING_GRPCON grp_ct
                        LEFT OUTER JOIN ubrr_vdata.UBRR_TAB_SCORING_GRP2AGGREG g2a ON g2a.id_grp = grp_ct.igrp_id
                        where id_aggreg = 5     -- Объединение 5 - реструктуризация;
       ) x4      
     on a.TYPEDOG_CTYPE_CRED = x4.CONTRTYPE
     left join  -- Проценты по кредиту
     (
      select x.id as typedog_prc_id, 
      x2.percentvalue, 
      row_number () over (partition by x1.ID order by x1.PRCDATE desc) nm
      from a4m.tPercentName@A4MBO x
      left join a4m.tPercentHistory@A4MBO x1 on x.id = x1.id
                                           and x.branch = x1.branch --<< 13.05.2020 Кокотов А.А. по примерам объдинения этих таблиц с базы TWR
      left join a4m.TPERCENTVALUE@A4MBO x2 on x1.code = x2.code
                where x.category = 1 and x.dimension = 1
     ) x3 on x3.typedog_prc_id = a.typedog_prc_id and x3.nm=1   
     where TYPEDOG_ID in -- выделим разницу
       (
       select TYPEDOG_ID  from ubrr_vdata.ubrr_scoring_typedog  
       minus
       select to_number(ARM_TP_TYPE) from SAS_RTDM.PRODUCT_RTDM@RTDM   
       ) ;      
  end if;
  --<< ubrr 21.03.2024 Севастьянов С.В. RRTDM-6582
  v_rowcnt:=SQL%ROWCOUNT;   
  commit;       
  logwrite ('update SAS_RTDM.PRODUCT_RTDM@RTDM: insert '||v_rowcnt||' rows' );
  
  MERGE INTO sas_rtdm.product_rtdm@rtdm D
  USING ( select 
           x.TYPEDOG_ID          as ARM_TP_TYPE,        -- Номер продукта АРМ ТП
           x.TYPEDOG_NAME        as ARM_TP_TYPE_NAME,   -- Наименование типа продукта RTDM
           x.typedog_currency    as TYPEDOG_CURRENCY,   -- Валюта кредита (карточного счета)
           x.typedog_scred_m     as TYPEDOG_SCRED_M,    -- Срок кредита (месяц),
         --  x.typedog_proc_cred   as TYPEDOG_PROC_CRED,  -- Проценты по кредиту
           case when x3.percentvalue is null then x.typedog_prc_id else x3.percentvalue end as TYPEDOG_PROC_CRED, -- Проценты по кредиту
           x.typedog_limit_metod as TYPEDOG_LIMIT_METOD,-- Методика расчета лимита в АРМ МР
           x.typedog_min_sum     as TYPEDOG_MIN_SUM,    -- Минимальная сумма кредита
           x.typedog_max_sum     as TYPEDOG_MAX_SUM,    -- Максимальная сумма кредита
           case when x4.CONTRTYPE is not null then 1 else 0 end  RESTR -- Реструктурируемый (1) / не реструктурируемый (0) 
           from ubrr_vdata.ubrr_scoring_typedog x 
           left OUTER join
                     ( SELECT *       FROM ubrr_vdata.UBRR_SHM_VIEW_SCORING_GRPCON grp_ct
                      LEFT OUTER JOIN ubrr_vdata.UBRR_TAB_SCORING_GRP2AGGREG g2a ON g2a.id_grp = grp_ct.igrp_id
                      where id_aggreg = 5     -- Объединение 5 - реструктуризация;
                     ) x4      
           on x.TYPEDOG_CTYPE_CRED = x4.CONTRTYPE
           left join  -- Проценты по кредиту
           (
            select x.id as typedog_prc_id, 
              x2.percentvalue, 
              row_number () over (partition by x1.ID order by x1.PRCDATE desc) nm
            from a4m.tPercentName@A4MBO x
              left join a4m.tPercentHistory@A4MBO x1 on x.id = x1.id
                                         and x.branch = x1.branch --<< 13.05.2020 Кокотов А.А. по примерам объдинения этих таблиц с базы TWR
              left join a4m.TPERCENTVALUE@A4MBO x2 on x1.code = x2.code
               where x.category = 1 and x.dimension = 1
             ) x3 on x3.typedog_prc_id = x.typedog_prc_id and x3.nm=1           
           ) S
   ON (D.arm_tp_type = s.arm_tp_type)
   WHEN MATCHED THEN UPDATE SET 
           D.ARM_TP_TYPE_NAME    = s.arm_tp_type_name,
           D.TYPEDOG_CURRENCY    = s.typedog_currency,
           D.TYPEDOG_SCRED_M     = s.typedog_scred_m,
           D.TYPEDOG_PROC_CRED   = s.typedog_proc_cred,
           D.TYPEDOG_LIMIT_METOD = s.typedog_limit_metod,
           D.TYPEDOG_MIN_SUM     = s.typedog_min_sum,
           D.TYPEDOG_MAX_SUM     = s.typedog_max_sum,
           D.RESTR               = s.restr;
  v_rowcnt:=SQL%ROWCOUNT;   
  commit;       
  logwrite ('update SAS_RTDM.PRODUCT_RTDM@RTDM: merge '||v_rowcnt||' rows' );
                     
end;

-- Новый метод обновление таблицы SAS_RTDM.PRODUCT_RTDM@RTDM
procedure update_product_rtdm
  is
    maxrowfetch constant NUMBER := 1000;
    v_rowcnt             NUMBER := 0;
    v_fetchcnt           NUMBER := 0;
    v_currcnt            NUMBER := 0;
    type tcurrow is record (
      ARM_TP_TYPE          ubrr_crm.Ubrr_Rtdm_Product.ARM_TP_TYPE%type,
      ARM_TP_TYPE_NAME     ubrr_crm.Ubrr_Rtdm_Product.ARM_TP_TYPE_NAME%type,
      TYPEDOG_CURRENCY     ubrr_crm.Ubrr_Rtdm_Product.TYPEDOG_CURRENCY%type,
      TYPEDOG_SCRED_M      ubrr_crm.Ubrr_Rtdm_Product.TYPEDOG_SCRED_M%type,
      TYPEDOG_PROC_CRED    ubrr_crm.Ubrr_Rtdm_Product.TYPEDOG_PROC_CRED%type,
      TYPEDOG_LIMIT_METOD  ubrr_crm.Ubrr_Rtdm_Product.TYPEDOG_LIMIT_METOD%type,
      TYPEDOG_MIN_SUM      ubrr_crm.Ubrr_Rtdm_Product.TYPEDOG_MIN_SUM%type,
      TYPEDOG_MAX_SUM      ubrr_crm.Ubrr_Rtdm_Product.TYPEDOG_MAX_SUM%type,
      RESTR                ubrr_crm.Ubrr_Rtdm_Product.RESTR%type
    );
    type ttabrows is table of tcurrow;
    vcurrow   ttabrows;
    vcurrow2  ttabrows;
    
    cursor cache_reset is
      select count(*)
        from ubrr_crm.ubrr_rtdm_product
       where 1=1;

    cursor cur_ins_cnt is
      select count(*)
        from ubrr_vdata.ubrr_scoring_typedog a
        left OUTER join
        ( SELECT *       FROM ubrr_vdata.UBRR_SHM_VIEW_SCORING_GRPCON grp_ct
                         LEFT OUTER JOIN ubrr_vdata.UBRR_TAB_SCORING_GRP2AGGREG g2a ON g2a.id_grp = grp_ct.igrp_id
                         where id_aggreg = 5     -- Объединение 5 - реструктуризация;
        ) x4      
          on a.TYPEDOG_CTYPE_CRED = x4.CONTRTYPE
     left join  -- Проценты по кредиту
       ( select x.id as typedog_prc_id, 
                x2.percentvalue, 
                row_number () over (partition by x1.ID order by x1.PRCDATE desc) nm
           from ubrr_crm.ubrr_a4m_tpercentname x
           left join ubrr_crm.ubrr_a4m_tpercenthistory x1 
                  on x.id = x1.id
                 and x.branch = x1.branch --<< 13.05.2020 Кокотов А.А. по примерам объдинения этих таблиц с базы TWR
           left join ubrr_crm.ubrr_a4m_tpercentvalue x2 
                  on x1.code = x2.code
               where x.category = 1 
                 and x.dimension = 1
       ) x3 on x3.typedog_prc_id = a.typedog_prc_id and x3.nm = 1
     where not exists(select 1 from ubrr_crm.Ubrr_Rtdm_Product b where b.ARM_TP_TYPE = a.TYPEDOG_ID);
    
    cursor cur1 is
      select
        TYPEDOG_ID          as ARM_TP_TYPE,        -- Номер продукта АРМ ТП
        TYPEDOG_NAME        as ARM_TP_TYPE_NAME,   -- Наименование типа продукта RTDM
        TYPEDOG_CURRENCY    as TYPEDOG_CURRENCY,   -- Валюта кредита (карточного счета)
        TYPEDOG_SCRED_M     as TYPEDOG_SCRED_M,    -- Срок кредита (месяц)
        case when x3.percentvalue is null then a.typedog_prc_id else x3.percentvalue end as TYPEDOG_PROC_CRED, -- Проценты по кредиту
        TYPEDOG_LIMIT_METOD as TYPEDOG_LIMIT_METOD,-- Методика расчета лимита в АРМ МР
        TYPEDOG_MIN_SUM     as TYPEDOG_MIN_SUM,    -- Минимальная сумма кредита
        TYPEDOG_MAX_SUM     as TYPEDOG_MAX_SUM,    -- Максимальная сумма кредита
        case when x4.CONTRTYPE is not null then 1 else 0 end  RESTR -- Реструктурируемый (1) / не реструктурируемый (0) 
     from ubrr_vdata.ubrr_scoring_typedog a
     left OUTER join
       ( SELECT *       FROM ubrr_vdata.UBRR_SHM_VIEW_SCORING_GRPCON grp_ct
                        LEFT OUTER JOIN ubrr_vdata.UBRR_TAB_SCORING_GRP2AGGREG g2a ON g2a.id_grp = grp_ct.igrp_id
                        where id_aggreg = 5     -- Объединение 5 - реструктуризация;
       ) x4      
     on a.TYPEDOG_CTYPE_CRED = x4.CONTRTYPE
     left join  -- Проценты по кредиту
       ( select x.id as typedog_prc_id, 
                x2.percentvalue, 
                row_number () over (partition by x1.ID order by x1.PRCDATE desc) nm
           from ubrr_crm.ubrr_a4m_tpercentname x
           left join ubrr_crm.ubrr_a4m_tpercenthistory x1 
                  on x.id = x1.id
                 and x.branch = x1.branch --<< 13.05.2020 Кокотов А.А. по примерам объдинения этих таблиц с базы TWR
           left join ubrr_crm.ubrr_a4m_tpercentvalue x2 
                  on x1.code = x2.code
               where x.category = 1 
                 and x.dimension = 1
       ) x3 on x3.typedog_prc_id = a.typedog_prc_id and x3.nm = 1
     where not exists(select 1 from ubrr_crm.Ubrr_Rtdm_Product b where b.ARM_TP_TYPE = a.TYPEDOG_ID);
          
   cursor cur2 is
      select S.*
        from ubrr_crm.Ubrr_Rtdm_Product D
        join ( select
           x.TYPEDOG_ID          as ARM_TP_TYPE,        -- Номер продукта АРМ ТП
           x.TYPEDOG_NAME        as ARM_TP_TYPE_NAME,   -- Наименование типа продукта RTDM
           x.typedog_currency    as TYPEDOG_CURRENCY,   -- Валюта кредита (карточного счета)
           x.typedog_scred_m     as TYPEDOG_SCRED_M,    -- Срок кредита (месяц),
         --  x.typedog_proc_cred   as TYPEDOG_PROC_CRED,  -- Проценты по кредиту
           case when x3.percentvalue is null then x.typedog_prc_id else x3.percentvalue end as TYPEDOG_PROC_CRED, -- Проценты по кредиту
           x.typedog_limit_metod as TYPEDOG_LIMIT_METOD,-- Методика расчета лимита в АРМ МР
           x.typedog_min_sum     as TYPEDOG_MIN_SUM,    -- Минимальная сумма кредита
           x.typedog_max_sum     as TYPEDOG_MAX_SUM,    -- Максимальная сумма кредита
           case when x4.CONTRTYPE is not null then 1 else 0 end  RESTR -- Реструктурируемый (1) / не реструктурируемый (0)
           from ubrr_vdata.ubrr_scoring_typedog x
           left OUTER join
                     ( SELECT *       FROM ubrr_vdata.UBRR_SHM_VIEW_SCORING_GRPCON grp_ct
                      LEFT OUTER JOIN ubrr_vdata.UBRR_TAB_SCORING_GRP2AGGREG g2a ON g2a.id_grp = grp_ct.igrp_id
                      where id_aggreg = 5     -- Объединение 5 - реструктуризация;
                     ) x4
           on x.TYPEDOG_CTYPE_CRED = x4.CONTRTYPE
           left join  -- Проценты по кредиту
           (
            select x.id as typedog_prc_id,
              x2.percentvalue,
              row_number () over (partition by x1.ID order by x1.PRCDATE desc) nm
            from ubrr_crm.ubrr_a4m_tpercentname x
              left join ubrr_crm.ubrr_a4m_tpercenthistory x1 on x.id = x1.id
                                         and x.branch = x1.branch --<< 13.05.2020 Кокотов А.А. по примерам объдинения этих таблиц с базы TWR
              left join ubrr_crm.ubrr_a4m_tpercentvalue x2 on x1.code = x2.code
               where x.category = 1 and x.dimension = 1
             ) x3 on x3.typedog_prc_id = x.typedog_prc_id and x3.nm=1
        ) S ON (D.arm_tp_type = s.arm_tp_type);
begin
  open cur_ins_cnt;
  fetch cur_ins_cnt into v_rowcnt;
  close cur_ins_cnt;
  if v_rowcnt > maxrowfetch then
    v_fetchcnt := maxrowfetch;
    v_currcnt  := v_rowcnt;
  else
    v_fetchcnt := v_rowcnt;
    v_currcnt  := v_rowcnt;
  end if;
  v_rowcnt := 0;
  loop
    open cur1;
    if v_fetchcnt = 0 then v_fetchcnt := 1; end if;
    fetch cur1 bulk collect into vcurrow limit v_fetchcnt;
    if cur1%notfound then
      close cur1;
      exit;
    end if;
    if cur1%isopen then close cur1; end if; -- закрываем курсор
    
    if vcurrow.count = 0 then exit; end if;
    dbms_output.put_line('fetch to insert row count: ' || vcurrow.count);
    
    for vindex in vcurrow.first..vcurrow.last
    loop
      begin
        insert into ubrr_crm.Ubrr_Rtdm_Product
          (ARM_TP_TYPE,  
           ARM_TP_TYPE_NAME,
           TYPEDOG_CURRENCY,
           TYPEDOG_SCRED_M,
           TYPEDOG_PROC_CRED,
           TYPEDOG_LIMIT_METOD,
           TYPEDOG_MIN_SUM,
           TYPEDOG_MAX_SUM,
           RESTR)
         values 
          (vcurrow(vindex).ARM_TP_TYPE, 
           vcurrow(vindex).ARM_TP_TYPE_NAME, 
           vcurrow(vindex).TYPEDOG_CURRENCY,
           vcurrow(vindex).TYPEDOG_SCRED_M,
           vcurrow(vindex).TYPEDOG_PROC_CRED,
           vcurrow(vindex).TYPEDOG_LIMIT_METOD,
           vcurrow(vindex).TYPEDOG_MIN_SUM,
           vcurrow(vindex).TYPEDOG_MAX_SUM,
           vcurrow(vindex).RESTR
        );
      exception
        when others then
          rollback;
          logwrite ('update SAS_RTDM.PRODUCT_RTDM@RTDM: insert ' || v_rowcnt || ' rows' );
          raise;
      end;
    end loop;
    commit;
    v_rowcnt := v_rowcnt + vcurrow.count;
    vcurrow.delete; -- освобождаем память
  end loop;
  
  commit;
  logwrite ('update SAS_RTDM.PRODUCT_RTDM@RTDM: insert ' || v_rowcnt || ' rows' );

  open cache_reset;
  fetch cache_reset into v_rowcnt;
  close cache_reset;
  if v_rowcnt > maxrowfetch then
    v_fetchcnt := maxrowfetch;
    v_currcnt  := v_rowcnt;
  else
    v_fetchcnt := v_rowcnt;
    v_currcnt  := v_rowcnt;
  end if;
  dbms_output.put_line('exists to update row count: ' || v_currcnt);
  v_rowcnt := 0;

  open cur2;
  loop
    v_currcnt := v_currcnt - v_fetchcnt;
    if v_currcnt < 0 then
      v_fetchcnt := v_currcnt + v_fetchcnt;
    end if;
    if v_fetchcnt = 0 then v_fetchcnt := 1; end if;
    fetch cur2 bulk collect into vcurrow2 limit v_fetchcnt;
    
    if cur2%notfound then
      close cur2;
      exit;
    end if;
  
    if vcurrow2.count = 0 then exit; end if;
    dbms_output.put_line('fetch to update row count: ' || vcurrow2.count);
  
    for vindex in vcurrow2.first..vcurrow2.last
    loop
      begin
        update ubrr_crm.Ubrr_Rtdm_Product S
           set S.ARM_TP_TYPE_NAME    = vcurrow2(vindex).ARM_TP_TYPE_NAME,
               S.TYPEDOG_CURRENCY    = vcurrow2(vindex).TYPEDOG_CURRENCY,
               S.TYPEDOG_SCRED_M     = vcurrow2(vindex).TYPEDOG_SCRED_M,
               S.TYPEDOG_PROC_CRED   = vcurrow2(vindex).TYPEDOG_PROC_CRED,
               S.TYPEDOG_LIMIT_METOD = vcurrow2(vindex).TYPEDOG_LIMIT_METOD,
               S.TYPEDOG_MIN_SUM     = vcurrow2(vindex).TYPEDOG_MIN_SUM,
               S.TYPEDOG_MAX_SUM     = vcurrow2(vindex).TYPEDOG_MAX_SUM,
               S.RESTR               = vcurrow2(vindex).RESTR
         where S.ARM_TP_TYPE         = vcurrow2(vindex).ARM_TP_TYPE;
      exception
        when others then
          rollback;
          if cur2%isopen then close cur2; end if;
          logwrite ('update SAS_RTDM.PRODUCT_RTDM@RTDM: update ' || v_rowcnt || ' rows' );
          raise;
      end;
    end loop;
    commit;
    v_rowcnt := v_rowcnt + vcurrow2.count;
    vcurrow2.delete; -- освобождаем память
    if v_currcnt <= 0 then exit; end if;
  end loop;
  if cur2%isopen then close cur2; end if;
  commit;
  logwrite ('update SAS_RTDM.PRODUCT_RTDM@RTDM: update ' || v_rowcnt || ' rows' );
  
exception
  when others then
    rollback;
    logwrite (     'update SAS_RTDM.PRODUCT_RTDM@RTDM error: '
                || ' ip:          ' || sys_context('USERENV', 'IP_ADDRESS')
                || ' user:        ' || sys_context('USERENV', 'SESSION_USER')
                || ' client_info: ' || sys_context('USERENV', 'CLIENT_INFO')
                || dbms_utility.format_error_backtrace
                || dbms_utility.format_error_stack
             );
    raise;
end;



  -- обновление таблицы UBRR_CRM.UBRR_RTDM_MAP_PRODUCT
procedure update_map_product_rtdm
  is
    v_rowcnt NUMBER;
    pragma autonomous_transaction;
begin
  insert into UBRR_CRM.UBRR_RTDM_MAP_PRODUCT
   (ARM_TP_TYPE,TWR_TYPE,CRM_TYPE)
   select
     ARM_TP_TYPE,
     TWR_TYPE,
     CRM_TYPE
   from ubrr_vdata.ubrr_ziv_product_link A
   where  not exists
   (  select B.ARM_TP_TYPE  from UBRR_CRM.UBRR_RTDM_MAP_PRODUCT B
   where  A.ARM_TP_TYPE = to_number(B.ARM_TP_TYPE)
     and  A.CRM_TYPE    = B.CRM_TYPE
   )  AND A.CRM_TYPE IS NOT NULL;
  v_rowcnt := SQL%ROWCOUNT;
  insert into UBRR_CRM.UBRR_RTDM_MAP_PRODUCT
   (ARM_TP_TYPE,TWR_TYPE,CRM_TYPE)
   select
     ARM_TP_TYPE,
     TWR_TYPE,
     CRM_TYPE
   from ubrr_vdata.ubrr_ziv_product_link A
   where  not exists
   (  select B.ARM_TP_TYPE  from UBRR_CRM.UBRR_RTDM_MAP_PRODUCT B
   where  A.ARM_TP_TYPE = to_number(B.ARM_TP_TYPE)
     and  B.CRM_TYPE    IS NULL
   ) AND A.CRM_TYPE IS NULL;
  v_rowcnt := v_rowcnt + SQL%ROWCOUNT;
  commit;
  logwrite ('update SAS_RTDM.MAP_PRODUCT@RTDM: insert '||v_rowcnt||' rows' );

  MERGE INTO UBRR_CRM.UBRR_RTDM_MAP_PRODUCT D
      USING(
            SELECT distinct
               ARM_TP_TYPE,
               CRM_TYPE ,
               MAX(TWR_TYPE) TWR_TYPE
            FROM ubrr_vdata.ubrr_ziv_product_link
            GROUP BY ARM_TP_TYPE, CRM_TYPE) S
            ON (D.ARM_TP_TYPE = s.ARM_TP_TYPE AND D.CRM_TYPE = s.CRM_TYPE)
             WHEN MATCHED THEN UPDATE SET D.twr_type = s.twr_type;
  v_rowcnt:=SQL%ROWCOUNT;
  MERGE INTO UBRR_CRM.UBRR_RTDM_MAP_PRODUCT D
      USING(
            SELECT distinct
               ARM_TP_TYPE,
               CRM_TYPE ,
               MAX(TWR_TYPE) TWR_TYPE
            FROM ubrr_vdata.ubrr_ziv_product_link
            GROUP BY ARM_TP_TYPE, CRM_TYPE) S
            ON (D.ARM_TP_TYPE = s.ARM_TP_TYPE AND S.CRM_TYPE IS NULL AND D.CRM_TYPE IS NULL)
             WHEN MATCHED THEN UPDATE SET D.twr_type = s.twr_type;
  v_rowcnt := v_rowcnt + SQL%ROWCOUNT;
  commit;
  logwrite ('update SAS_RTDM.MAP_PRODUCT@RTDM: merge '||v_rowcnt||' rows' );
end;

  -->> 30.01.2023 Комилов А.А. RRTDM-4237 Заполнение MAP_PRODUCT_OLD в RTDM типами ЕМН
  -- обновление таблицы sas_rtdm.map_product_old@rtdm
  procedure update_map_product_old_rtdm as
    v_rowcnt number;
  begin
    merge into ubrr_rtdm_map_product_old mo
    using (
          select arm_tp_type, crm_type, twr_type
          from ubrr_rtdm_map_product
          where crm_type in
            (select crm_product from ubrr_crm_product_emn)
          ) mp
    on (mo.arm_tp_type = mp.arm_tp_type
      and mo.crm_type = mp.crm_type
      and mo.twr_type = mp.twr_type)
    when not matched then
      insert (mo.arm_tp_type, mo.crm_type, mo.twr_type)
      values (mp.arm_tp_type, mp.crm_type, mp.twr_type);

  v_rowcnt:=sql%rowcount;
  commit;

  logwrite ('update SAS_RTDM.MAP_PRODUCT_OLD@RTDM: inserted '||v_rowcnt||' rows' );
  end;
  --<< 30.01.2023 Комилов А.А. RRTDM-4237 Заполнение MAP_PRODUCT_OLD в RTDM типами ЕМН

end;
/
