-- Create table
create table SRC.SCHEMA_AUD
(
  n_audactid    NUMBER,
  c_audoper     VARCHAR2(256),
  c_objectowner VARCHAR2(256),
  c_objecttype  VARCHAR2(256),
  c_objectname  VARCHAR2(256),
  c_auduser     VARCHAR2(40) default user,
  d_auddate     DATE default sysdate,
  c_audhost     VARCHAR2(256) default sys_context('USERENV', 'HOST'),
  c_audosuser   VARCHAR2(256) default sys_context('USERENV', 'OS_USER'),
  c_ipaddress   VARCHAR2(256) default sys_context('USERENV', 'IP_ADDRESS'),
  c_ddl_text    CLOB
)
