-- Conteo de filas por tabla y de envios por estado actual (datos cargados).
-- Se ejecuta como BD_ENLACE_EXPRESS: database/run.sh propietario tests/04_conteo_datos.sql
WHENEVER SQLERROR EXIT FAILURE
SET LINESIZE 100 PAGESIZE 100 FEEDBACK OFF
COLUMN tabla FORMAT A28
COLUMN filas FORMAT 999999
COLUMN estado_actual FORMAT A20
COLUMN envios FORMAT 999999

PROMPT Filas por tabla
SELECT tabla, filas FROM (
    SELECT 'ASIGNACION_DESPACHO' AS tabla, COUNT(*) AS filas FROM asignacion_despacho
    UNION ALL
    SELECT 'CENTRO_DISTRIBUCION' AS tabla, COUNT(*) AS filas FROM centro_distribucion
    UNION ALL
    SELECT 'CLIENTE' AS tabla, COUNT(*) AS filas FROM cliente
    UNION ALL
    SELECT 'DESPACHO' AS tabla, COUNT(*) AS filas FROM despacho
    UNION ALL
    SELECT 'DESTINATARIO' AS tabla, COUNT(*) AS filas FROM destinatario
    UNION ALL
    SELECT 'EMPLEADO' AS tabla, COUNT(*) AS filas FROM empleado
    UNION ALL
    SELECT 'ENVIO' AS tabla, COUNT(*) AS filas FROM envio
    UNION ALL
    SELECT 'ESTADO_ENVIO' AS tabla, COUNT(*) AS filas FROM estado_envio
    UNION ALL
    SELECT 'EVENTO_ENVIO' AS tabla, COUNT(*) AS filas FROM evento_envio
    UNION ALL
    SELECT 'MENSAJERO' AS tabla, COUNT(*) AS filas FROM mensajero
    UNION ALL
    SELECT 'MODALIDAD' AS tabla, COUNT(*) AS filas FROM modalidad
    UNION ALL
    SELECT 'NOVEDAD' AS tabla, COUNT(*) AS filas FROM novedad
    UNION ALL
    SELECT 'PRUEBA_ENTREGA' AS tabla, COUNT(*) AS filas FROM prueba_entrega
    UNION ALL
    SELECT 'RECLAMACION' AS tabla, COUNT(*) AS filas FROM reclamacion
    UNION ALL
    SELECT 'SEDE_CLIENTE' AS tabla, COUNT(*) AS filas FROM sede_cliente
    UNION ALL
    SELECT 'SOLICITUD_RECOLECCION' AS tabla, COUNT(*) AS filas FROM solicitud_recoleccion
    UNION ALL
    SELECT 'TIPO_VEHICULO' AS tabla, COUNT(*) AS filas FROM tipo_vehiculo
    UNION ALL
    SELECT 'VEHICULO' AS tabla, COUNT(*) AS filas FROM vehiculo
    UNION ALL
    SELECT 'ZONA' AS tabla, COUNT(*) AS filas FROM zona
) ORDER BY tabla;

PROMPT
PROMPT Envios por estado actual (v_estado_actual_envio)
SELECT estado_actual, COUNT(*) AS envios
FROM   v_estado_actual_envio
GROUP  BY estado_actual
ORDER  BY MIN(CASE estado_actual WHEN 'REGISTRADO' THEN 1 WHEN 'RECOLECTADO' THEN 2 WHEN 'EN_CENTRO' THEN 3
                  WHEN 'CLASIFICADO' THEN 4 WHEN 'EN_RUTA' THEN 5 WHEN 'ENTREGADO' THEN 6
                  WHEN 'CON_NOVEDAD' THEN 7 WHEN 'DEVUELTO' THEN 8 ELSE 9 END);

PROMPT
PROMPT Total de envios
SELECT COUNT(*) AS envios FROM envio;
