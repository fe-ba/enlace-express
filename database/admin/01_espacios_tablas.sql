-- Espacios de tablas del modulo (capitulo 5, tabla de espacios de tablas).
-- Se ejecuta como SYSTEM en FREEPDB1. La imagen no define db_create_file_dest,
-- por eso se usa la ruta explicita de los archivos de la PDB.
WHENEVER SQLERROR EXIT FAILURE

CREATE TABLESPACE ts_enlace_datos
    DATAFILE '/opt/oracle/oradata/FREE/FREEPDB1/ts_enlace_datos01.dbf'
    SIZE 500M AUTOEXTEND ON NEXT 100M MAXSIZE 7G;

CREATE TABLESPACE ts_enlace_indices
    DATAFILE '/opt/oracle/oradata/FREE/FREEPDB1/ts_enlace_indices01.dbf'
    SIZE 300M AUTOEXTEND ON NEXT 100M MAXSIZE 4G;
