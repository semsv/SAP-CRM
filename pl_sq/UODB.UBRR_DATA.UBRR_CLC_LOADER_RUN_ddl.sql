------------------------------
-- Extracted from: https://svn.lan.ubrr.ru/svn/DB/trunk/UODB/UBRR_DATA.UBRR_CLC_LOADER_RUN_ddl.sql
------------------------------
CREATE TABLE "UBRR_DATA"."UBRR_CLC_LOADER_RUN" 
   (	"ID_WORK" NUMBER DEFAULT 0, 
	"IS_RUN" NUMBER(1,0) DEFAULT 0, 
	"RUN_DATE" DATE, 
	"STATUS" NUMBER, 
	"TXTERR" VARCHAR2(255), 
	"FINAL_DATE" DATE, 
	"START_DATE_RUN" DATE DEFAULT sysdate, 
	"ON_DELETE" NUMBER(1,0) DEFAULT 0, 
	"PROCEDURE_NAME" VARCHAR2(255), 
	"RETURN_VALUE" NUMBER DEFAULT 0, 
	"TYPE_PROCEDURE" NUMBER(1,0) DEFAULT 0, 
	"PARAM_COUNT" NUMBER DEFAULT 0, 
	"PARAM_VAL1" VARCHAR2(255) DEFAULT 0, 
	"PARAM_VAL2" VARCHAR2(255) DEFAULT 0, 
	"PARAM_VAL3" VARCHAR2(255) DEFAULT 0, 
	"PARAM_VAL4" VARCHAR2(255) DEFAULT 0, 
	"PARAM_VAL5" VARCHAR2(255) DEFAULT 0, 
	"WAIT_ID_WORK" NUMBER, 
	"IS_STOP" NUMBER(1,0) DEFAULT 0, 
	"STOPPED" NUMBER(1,0) DEFAULT 0, 
	"PARAM_MASK1" VARCHAR2(255) DEFAULT 'dd.mm.yyyy', 
	"PARAM_MASK2" VARCHAR2(255), 
	"PARAM_MASK3" VARCHAR2(255), 
	"PARAM_MASK4" VARCHAR2(255), 
	"PARAM_MASK5" VARCHAR2(255), 
	"PARAM_TO_FMT1" VARCHAR2(255) DEFAULT 'TO_DATE', 
	"PARAM_TO_FMT2" VARCHAR2(255), 
	"PARAM_TO_FMT3" VARCHAR2(255), 
	"PARAM_TO_FMT4" VARCHAR2(255), 
	"PARAM_TO_FMT5" VARCHAR2(255), 
	 CONSTRAINT "UBRR_CLCLDR_R_PKEY" PRIMARY KEY ("ID_WORK", "PROCEDURE_NAME", "START_DATE_RUN")
  USING INDEX PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  STORAGE(INITIAL 81920 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "USERS"  ENABLE, 
	 CONSTRAINT "CK_CLC_LOAD_RUN_ISR" CHECK (IS_RUN IN (0, 1) 
and TYPE_PROCEDURE in (0, 1) 
and ON_DELETE in (0, 1)
and STATUS in (0, 1)
and PARAM_COUNT in (0, 1, 2, 3, 4, 5)
and is_stop in (0, 1)
and stopped in (0, 1)) ENABLE
   ) SEGMENT CREATION IMMEDIATE 
  PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 
 NOCOMPRESS LOGGING
  STORAGE(INITIAL 81920 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "USERS" 
/
COMMENT ON COLUMN "UBRR_DATA"."UBRR_CLC_LOADER_RUN"."ID_WORK" IS '»дентификатор задачи'
/
COMMENT ON COLUMN "UBRR_DATA"."UBRR_CLC_LOADER_RUN"."IS_RUN" IS 'ѕризнак что уже запущена (0 - не запущена, 1 - запущена)'
/
COMMENT ON COLUMN "UBRR_DATA"."UBRR_CLC_LOADER_RUN"."RUN_DATE" IS 'ƒата и врем€ запуска задачи    (в это поле пишет только JOB)'
/
COMMENT ON COLUMN "UBRR_DATA"."UBRR_CLC_LOADER_RUN"."STATUS" IS '—татус последнего запуска (0 - успех, 1 - ошибка) (в это поле пишет только JOB)'
/
COMMENT ON COLUMN "UBRR_DATA"."UBRR_CLC_LOADER_RUN"."TXTERR" IS '“екст ошибки (в это поле пишет только JOB)'
/
COMMENT ON COLUMN "UBRR_DATA"."UBRR_CLC_LOADER_RUN"."FINAL_DATE" IS 'ƒата и врем€ завершени€ задачи (в это поле пишет только JOB)'
/
COMMENT ON COLUMN "UBRR_DATA"."UBRR_CLC_LOADER_RUN"."START_DATE_RUN" IS 'ƒата планируемого запуска'
/
COMMENT ON COLUMN "UBRR_DATA"."UBRR_CLC_LOADER_RUN"."ON_DELETE" IS 'ѕризнак что запись нужно удалить после выполнени€ (0 - не удал€ть, 1 - удалить)'
/
COMMENT ON COLUMN "UBRR_DATA"."UBRR_CLC_LOADER_RUN"."PROCEDURE_NAME" IS '»м€ запускаемой процедуры в Ѕƒ'
/
COMMENT ON COLUMN "UBRR_DATA"."UBRR_CLC_LOADER_RUN"."RETURN_VALUE" IS '¬озвращенное значение'
/
COMMENT ON COLUMN "UBRR_DATA"."UBRR_CLC_LOADER_RUN"."TYPE_PROCEDURE" IS '0 - функци€, 1 - процедура'
/
COMMENT ON COLUMN "UBRR_DATA"."UBRR_CLC_LOADER_RUN"."PARAM_COUNT" IS ' ол-во входных параметров {0, 1, 2, 3, 4, 5}'
/
COMMENT ON COLUMN "UBRR_DATA"."UBRR_CLC_LOADER_RUN"."PARAM_VAL1" IS '«начение параметра 1'
/
COMMENT ON COLUMN "UBRR_DATA"."UBRR_CLC_LOADER_RUN"."PARAM_VAL2" IS '«начение параметра 2'
/
COMMENT ON COLUMN "UBRR_DATA"."UBRR_CLC_LOADER_RUN"."PARAM_VAL3" IS '«начение параметра 3'
/
COMMENT ON COLUMN "UBRR_DATA"."UBRR_CLC_LOADER_RUN"."PARAM_VAL4" IS '«начение параметра 4'
/
COMMENT ON COLUMN "UBRR_DATA"."UBRR_CLC_LOADER_RUN"."PARAM_VAL5" IS '«начение параметра 5'
/
COMMENT ON COLUMN "UBRR_DATA"."UBRR_CLC_LOADER_RUN"."WAIT_ID_WORK" IS '»дентификатор задачи, выполнени€ которой необх дождатьс€ если она запущена'
/
COMMENT ON COLUMN "UBRR_DATA"."UBRR_CLC_LOADER_RUN"."IS_STOP" IS '«адача будет остановлена (0 - нет, 1 - да) если запущенна€ задача умеет провер€ть этот признак она прервет свое выполнение после взведени€ данного флажка'
/
COMMENT ON COLUMN "UBRR_DATA"."UBRR_CLC_LOADER_RUN"."STOPPED" IS '«адача остановлена (0 - нет, 1 - да) записи в которых данный флажок взведен в "1" буду сразу удал€тьс€, первым job-ом который найдет такую запись'
/
COMMENT ON COLUMN "UBRR_DATA"."UBRR_CLC_LOADER_RUN"."PARAM_MASK1" IS 'маска дл€ параметр 1 дл€ €вного преобразовани€ типов'
/
COMMENT ON COLUMN "UBRR_DATA"."UBRR_CLC_LOADER_RUN"."PARAM_MASK2" IS 'маска дл€ параметр 2 дл€ €вного преобразовани€ типов'
/
COMMENT ON COLUMN "UBRR_DATA"."UBRR_CLC_LOADER_RUN"."PARAM_MASK3" IS 'маска дл€ параметр 3 дл€ €вного преобразовани€ типов'
/
COMMENT ON COLUMN "UBRR_DATA"."UBRR_CLC_LOADER_RUN"."PARAM_MASK4" IS 'маска дл€ параметр 4 дл€ €вного преобразовани€ типов'
/
COMMENT ON COLUMN "UBRR_DATA"."UBRR_CLC_LOADER_RUN"."PARAM_MASK5" IS 'маска дл€ параметр 5 дл€ €вного преобразовани€ типов'
/
COMMENT ON COLUMN "UBRR_DATA"."UBRR_CLC_LOADER_RUN"."PARAM_TO_FMT1" IS 'формат €вного приведени€ типов дл€ параметра 1'
/
COMMENT ON COLUMN "UBRR_DATA"."UBRR_CLC_LOADER_RUN"."PARAM_TO_FMT2" IS 'формат €вного приведени€ типов дл€ параметра 2'
/
COMMENT ON COLUMN "UBRR_DATA"."UBRR_CLC_LOADER_RUN"."PARAM_TO_FMT3" IS 'формат €вного приведени€ типов дл€ параметра 3'
/
COMMENT ON COLUMN "UBRR_DATA"."UBRR_CLC_LOADER_RUN"."PARAM_TO_FMT4" IS 'формат €вного приведени€ типов дл€ параметра 4'
/
COMMENT ON COLUMN "UBRR_DATA"."UBRR_CLC_LOADER_RUN"."PARAM_TO_FMT5" IS 'формат €вного приведени€ типов дл€ параметра 5'
/
CREATE UNIQUE INDEX "UBRR_DATA"."UBRR_CLCLDR_R_PKEY" ON "UBRR_DATA"."UBRR_CLC_LOADER_RUN" ("ID_WORK", "PROCEDURE_NAME", "START_DATE_RUN") 
  PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  STORAGE(INITIAL 81920 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "USERS" 
/
GRANT DELETE ON "UBRR_DATA"."UBRR_CLC_LOADER_RUN" TO "T_SAP_BWREP"
/
GRANT INSERT ON "UBRR_DATA"."UBRR_CLC_LOADER_RUN" TO "T_SAP_BWREP"
/
GRANT SELECT ON "UBRR_DATA"."UBRR_CLC_LOADER_RUN" TO "T_SAP_BWREP"
/
GRANT UPDATE ON "UBRR_DATA"."UBRR_CLC_LOADER_RUN" TO "T_SAP_BWREP"
/
CREATE OR REPLACE TRIGGER "UBRR_DATA"."UBRR_CLC_LOADER_LOGTRG" 
  after delete
  on UBRR_DATA.UBRR_CLC_LOADER_RUN 
  for each row
declare
  -- local variables here
begin
  insert into ubrr_data.ubrr_clc_loader_run_log l
         (Id_Work, 
          Is_Run, 
          Run_Date, 
          Final_Date, 
          Start_Date_Run, 
          Status, 
          Txterr, 
          User_Name, 
          Change_Date, 
          Operate,
          l.Procedure_Name,
          l.Param_Count,
          l.Param_Val1,
          l.Param_Val2,
          l.Param_Val3,
          l.Param_Val4,
          l.Param_Val5,
          l.Wait_Id_Work,
          l.Is_Stop,
          l.Stopped,
          l.Return_Value,
          l.On_Delete)
  values (nvl(:old.Id_Work,        :new.Id_Work), 
          nvl(:old.Is_Run,         :new.Is_Run),
          nvl(:old.Run_Date,       :new.run_date),
          nvl(:old.Final_Date,     :new.Final_Date), 
          nvl(:old.Start_Date_Run, :new.Start_Date_Run),
          nvl(:old.Status,         :new.status),
          nvl(:old.Txterr,         :new.txterr),
          user, 
          sysdate, 
          'DEL_ROW',          
          nvl(:old.Procedure_Name   ,        :new.Procedure_Name),
          nvl(:old.Param_Count      ,        :new.Param_Count),
          nvl(:old.Param_Val1       ,        :new.Param_Val1),
          nvl(:old.Param_Val2       ,        :new.Param_Val2),
          nvl(:old.Param_Val3       ,        :new.Param_Val3),
          nvl(:old.Param_Val4       ,        :new.Param_Val4),
          nvl(:old.Param_Val5       ,        :new.Param_Val5),
          nvl(:old.Wait_Id_Work     ,        :new.Wait_Id_Work),
          nvl(:old.Is_Stop          ,        :new.Is_Stop),
          nvl(:old.Stopped          ,        :new.Stopped),
          nvl(:old.Return_Value     ,        :new.Return_Value),
          nvl(:old.On_Delete        ,        :new.On_Delete));
end UBRR_CLC_LOADER_LOGTRG;
/
CREATE OR REPLACE TRIGGER "UBRR_DATA"."UBRR_CLC_LOADER_LOGTRGU" 
  after insert or update
  on UBRR_DATA.UBRR_CLC_LOADER_RUN 
  for each row
declare
  -- local variables here
begin
    insert into ubrr_data.ubrr_clc_loader_run_log l
         (Id_Work, 
          Is_Run, 
          Run_Date, 
          Final_Date, 
          Start_Date_Run, 
          Status, 
          Txterr, 
          User_Name, 
          Change_Date, 
          Operate,
          l.Procedure_Name,
          l.Param_Count,
          l.Param_Val1,
          l.Param_Val2,
          l.Param_Val3,
          l.Param_Val4,
          l.Param_Val5,
          l.Wait_Id_Work,
          l.Is_Stop,
          l.Stopped,
          l.Return_Value,
          l.On_Delete)
  values (nvl(:old.Id_Work,        :new.Id_Work), 
          nvl(:old.Is_Run,         :new.Is_Run),
          nvl(:old.Run_Date,       :new.run_date),
          nvl(:old.Final_Date,     :new.Final_Date), 
          nvl(:old.Start_Date_Run, :new.Start_Date_Run),
          nvl(:old.Status,         :new.status),
          nvl(:old.Txterr,         :new.txterr),
          user, 
          sysdate, 
          'INS_ROW/UPD_ROW',          
          nvl(:old.Procedure_Name   ,        :new.Procedure_Name),
          nvl(:old.Param_Count      ,        :new.Param_Count),
          nvl(:old.Param_Val1       ,        :new.Param_Val1),
          nvl(:old.Param_Val2       ,        :new.Param_Val2),
          nvl(:old.Param_Val3       ,        :new.Param_Val3),
          nvl(:old.Param_Val4       ,        :new.Param_Val4),
          nvl(:old.Param_Val5       ,        :new.Param_Val5),
          nvl(:old.Wait_Id_Work     ,        :new.Wait_Id_Work),
          nvl(:old.Is_Stop          ,        :new.Is_Stop),
          nvl(:old.Stopped          ,        :new.Stopped),
          nvl(:old.Return_Value     ,        :new.Return_Value),
          nvl(:old.On_Delete        ,        :new.On_Delete));
end UBRR_CLC_LOADER_LOGTRGU;
/
------------------------------
-- Extracted at 2017.04.10 14:38:02 by IT(A) v.1.5.40 (alpha)
------------------------------
