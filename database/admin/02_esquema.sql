-- Esquema propietario. Requiere la variable de sustitucion pwd_propietario
-- (la define database/install.sh; nunca se escribe en el script).
WHENEVER SQLERROR EXIT FAILURE
SET VERIFY OFF

CREATE USER bd_enlace_express IDENTIFIED BY "&&pwd_propietario"
    DEFAULT TABLESPACE ts_enlace_datos
    TEMPORARY TABLESPACE temp
    QUOTA UNLIMITED ON ts_enlace_datos
    QUOTA UNLIMITED ON ts_enlace_indices;

GRANT CREATE SESSION, CREATE TABLE, CREATE VIEW, CREATE PROCEDURE,
      CREATE TRIGGER, CREATE SEQUENCE TO bd_enlace_express;
