-- Comprobacion de cifras contra el documento (decisiones C1 y C2).
-- Se ejecuta como SYSTEM: usa las vistas DBA_* limitadas al esquema
-- BD_ENLACE_EXPRESS y a la lista explicita de las 19 tablas del modulo
-- (las tablas de extensiones no cuentan). Los roles solo son visibles
-- desde un usuario administrador.
WHENEVER SQLERROR EXIT FAILURE
SET PAGESIZE 100 LINESIZE 120 FEEDBACK OFF TRIMSPOOL ON
COLUMN cifra FORMAT A52
COLUMN esperado FORMAT 999999
COLUMN obtenido FORMAT 999999
COLUMN resultado FORMAT A9

WITH tablas AS (
    SELECT column_value AS nombre FROM TABLE(SYS.ODCIVARCHAR2LIST(
        'ASIGNACION_DESPACHO','CENTRO_DISTRIBUCION','CLIENTE','DESPACHO','DESTINATARIO',
        'EMPLEADO','ENVIO','ESTADO_ENVIO','EVENTO_ENVIO','MENSAJERO','MODALIDAD','NOVEDAD',
        'PRUEBA_ENTREGA','RECLAMACION','SEDE_CLIENTE','SOLICITUD_RECOLECCION','TIPO_VEHICULO',
        'VEHICULO','ZONA'))
),
vistas AS (
    SELECT column_value AS nombre FROM TABLE(SYS.ODCIVARCHAR2LIST(
        'V_SEGUIMIENTO_ENVIO','V_ESTADO_ACTUAL_ENVIO','V_PLANILLA_DESPACHO',
        'V_ENVIOS_POR_DESPACHAR','V_NOVEDADES_ABIERTAS','V_RECLAMACIONES_PENDIENTES',
        'V_CUMPLIMIENTO_ENTREGAS'))
),
roles AS (
    SELECT column_value AS nombre FROM TABLE(SYS.ODCIVARCHAR2LIST(
        'ROL_GERENCIA','ROL_CENTRO','ROL_MESA','ROL_MENSAJERO','ROL_CLIENTE'))
),
cols AS (
    SELECT c.* FROM dba_tab_columns c JOIN tablas t ON t.nombre = c.table_name
    WHERE c.owner = 'BD_ENLACE_EXPRESS'
),
cons AS (
    SELECT c.* FROM dba_constraints c JOIN tablas t ON t.nombre = c.table_name
    WHERE c.owner = 'BD_ENLACE_EXPRESS'
),
cifras AS (
    SELECT 1 AS orden, 'Tablas' AS cifra, 19 AS esperado,
           (SELECT COUNT(*) FROM dba_tables d JOIN tablas t ON t.nombre = d.table_name
             WHERE d.owner = 'BD_ENLACE_EXPRESS') AS obtenido FROM dual
    UNION ALL SELECT 2, 'Columnas', 130, (SELECT COUNT(*) FROM cols) FROM dual
    UNION ALL SELECT 3, 'Columnas NOT NULL', 110,
           (SELECT COUNT(*) FROM cols WHERE nullable = 'N') FROM dual
    UNION ALL SELECT 4, 'Claves primarias', 19,
           (SELECT COUNT(*) FROM cons WHERE constraint_type = 'P') FROM dual
    UNION ALL SELECT 5, 'Restricciones UNIQUE', 13,
           (SELECT COUNT(*) FROM cons WHERE constraint_type = 'U') FROM dual
    UNION ALL SELECT 6, 'Claves foraneas', 27,
           (SELECT COUNT(*) FROM cons WHERE constraint_type = 'R') FROM dual
    UNION ALL SELECT 7, 'Restricciones CHECK (sin NOT NULL)', 33,
           (SELECT COUNT(*) FROM cons WHERE constraint_type = 'C'
               AND NOT REGEXP_LIKE(search_condition_vc, '^"[A-Z0-9_$#]+" IS NOT NULL$')) FROM dual
    UNION ALL SELECT 8, 'Columnas con DEFAULT (sin identidad)', 12,
           (SELECT COUNT(*) FROM cols WHERE data_default IS NOT NULL
               AND identity_column = 'NO') FROM dual
    UNION ALL SELECT 9, 'Indices', 59,
           (SELECT COUNT(*) FROM dba_indexes i JOIN tablas t ON t.nombre = i.table_name
             WHERE i.owner = 'BD_ENLACE_EXPRESS') FROM dual
    UNION ALL SELECT 10, 'Vistas', 7,
           (SELECT COUNT(*) FROM dba_views v JOIN vistas s ON s.nombre = v.view_name
             WHERE v.owner = 'BD_ENLACE_EXPRESS') FROM dual
    UNION ALL SELECT 11, 'Disparadores', 6,
           (SELECT COUNT(*) FROM dba_triggers g JOIN tablas t ON t.nombre = g.table_name
             WHERE g.owner = 'BD_ENLACE_EXPRESS') FROM dual
    UNION ALL SELECT 12, 'Procedimientos', 1,
           (SELECT COUNT(*) FROM dba_objects
             WHERE owner = 'BD_ENLACE_EXPRESS' AND object_type = 'PROCEDURE') FROM dual
    UNION ALL SELECT 13, 'Roles', 5,
           (SELECT COUNT(*) FROM dba_roles r JOIN roles s ON s.nombre = r.role) FROM dual
    UNION ALL SELECT 14, 'Espacios de tablas', 2,
           (SELECT COUNT(*) FROM dba_tablespaces
             WHERE tablespace_name IN ('TS_ENLACE_DATOS','TS_ENLACE_INDICES')) FROM dual
    -- Comprobaciones de apoyo
    UNION ALL SELECT 20, 'Apoyo: columnas de identidad', 14,
           (SELECT COUNT(*) FROM dba_tab_identity_cols i JOIN tablas t ON t.nombre = i.table_name
             WHERE i.owner = 'BD_ENLACE_EXPRESS') FROM dual
    UNION ALL SELECT 21, 'Apoyo: tablas en TS_ENLACE_DATOS', 19,
           (SELECT COUNT(*) FROM dba_tables d JOIN tablas t ON t.nombre = d.table_name
             WHERE d.owner = 'BD_ENLACE_EXPRESS' AND d.tablespace_name = 'TS_ENLACE_DATOS') FROM dual
    UNION ALL SELECT 22, 'Apoyo: indices en TS_ENLACE_INDICES', 59,
           (SELECT COUNT(*) FROM dba_indexes i JOIN tablas t ON t.nombre = i.table_name
             WHERE i.owner = 'BD_ENLACE_EXPRESS' AND i.tablespace_name = 'TS_ENLACE_INDICES') FROM dual
    UNION ALL SELECT 23, 'Apoyo: columnas VARCHAR2/CHAR en caracteres',
           (SELECT COUNT(*) FROM cols WHERE data_type IN ('VARCHAR2','CHAR')),
           (SELECT COUNT(*) FROM cols WHERE data_type IN ('VARCHAR2','CHAR') AND char_used = 'C') FROM dual
    UNION ALL SELECT 24, 'Apoyo: comentarios de tabla', 19,
           (SELECT COUNT(*) FROM dba_tab_comments m JOIN tablas t ON t.nombre = m.table_name
             WHERE m.owner = 'BD_ENLACE_EXPRESS' AND m.table_type = 'TABLE'
               AND m.comments IS NOT NULL) FROM dual
    UNION ALL SELECT 25, 'Apoyo: comentarios de columna', 130,
           (SELECT COUNT(*) FROM dba_col_comments m JOIN tablas t ON t.nombre = m.table_name
             WHERE m.owner = 'BD_ENLACE_EXPRESS' AND m.comments IS NOT NULL) FROM dual
    UNION ALL SELECT 26, 'Apoyo: privilegios DELETE de los roles (RN16)', 0,
           (SELECT COUNT(*) FROM dba_tab_privs p JOIN roles r ON r.nombre = p.grantee
             WHERE p.privilege = 'DELETE') FROM dual
    -- Extension E1 (database/extensions): fuera de las 19 tablas del modulo
    UNION ALL SELECT 30, 'Extension E1: tablas', 2,
           (SELECT COUNT(*) FROM dba_tables WHERE owner = 'BD_ENLACE_EXPRESS'
               AND table_name IN ('USUARIO_APLICACION', 'CODIGO_ACTIVACION')) FROM dual
    UNION ALL SELECT 31, 'Extension E1: privilegios concedidos a roles', 0,
           (SELECT COUNT(*) FROM dba_tab_privs p JOIN roles r ON r.nombre = p.grantee
             WHERE p.owner = 'BD_ENLACE_EXPRESS' AND p.table_name IN ('USUARIO_APLICACION', 'CODIGO_ACTIVACION', 'PKG_CODIGOS_ACTIVACION')) FROM dual
    -- Extension E2 (database/extensions): la vista del rastreo publico no es una de las 7 del modulo
    UNION ALL SELECT 32, 'Extension E2: vistas', 1,
           (SELECT COUNT(*) FROM dba_views WHERE owner = 'BD_ENLACE_EXPRESS' AND view_name = 'V_RASTREO_PUBLICO') FROM dual
)
SELECT cifra, esperado, obtenido,
       CASE WHEN esperado = obtenido THEN 'OK' ELSE 'FALLA' END AS resultado
FROM cifras
ORDER BY orden;
