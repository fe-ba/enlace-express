-- Una cuenta de servicio por rol (decision 12.1). Requiere las variables
-- pwd_svc_gerencia, pwd_svc_centro, pwd_svc_mesa, pwd_svc_mensajero y
-- pwd_svc_cliente (las define database/install.sh).
WHENEVER SQLERROR EXIT FAILURE
SET VERIFY OFF

CREATE USER svc_gerencia IDENTIFIED BY "&&pwd_svc_gerencia"
    DEFAULT TABLESPACE ts_enlace_datos TEMPORARY TABLESPACE temp;
CREATE USER svc_centro IDENTIFIED BY "&&pwd_svc_centro"
    DEFAULT TABLESPACE ts_enlace_datos TEMPORARY TABLESPACE temp;
CREATE USER svc_mesa IDENTIFIED BY "&&pwd_svc_mesa"
    DEFAULT TABLESPACE ts_enlace_datos TEMPORARY TABLESPACE temp;
CREATE USER svc_mensajero IDENTIFIED BY "&&pwd_svc_mensajero"
    DEFAULT TABLESPACE ts_enlace_datos TEMPORARY TABLESPACE temp;
CREATE USER svc_cliente IDENTIFIED BY "&&pwd_svc_cliente"
    DEFAULT TABLESPACE ts_enlace_datos TEMPORARY TABLESPACE temp;

GRANT CREATE SESSION TO svc_gerencia, svc_centro, svc_mesa, svc_mensajero, svc_cliente;

GRANT rol_gerencia TO svc_gerencia;
GRANT rol_centro TO svc_centro;
GRANT rol_mesa TO svc_mesa;
GRANT rol_mensajero TO svc_mensajero;
GRANT rol_cliente TO svc_cliente;

-- Roles por defecto (un unico rol por cuenta)
ALTER USER svc_gerencia DEFAULT ROLE rol_gerencia;
ALTER USER svc_centro DEFAULT ROLE rol_centro;
ALTER USER svc_mesa DEFAULT ROLE rol_mesa;
ALTER USER svc_mensajero DEFAULT ROLE rol_mensajero;
ALTER USER svc_cliente DEFAULT ROLE rol_cliente;
