-- Conteo de la base con los datos de volumen: filas por tabla, proporciones
-- respecto al supuesto del capitulo 5, estados finales y tamano de los segmentos.
-- Se ejecuta como BD_ENLACE_EXPRESS: database/run.sh propietario tests/05_conteo_volumen.sql
WHENEVER SQLERROR EXIT FAILURE
SET LINESIZE 120 PAGESIZE 100 FEEDBACK OFF
COLUMN tabla FORMAT A28
COLUMN filas FORMAT 9,999,999
COLUMN estado_actual FORMAT A16
COLUMN envios FORMAT 9,999,999
COLUMN concepto FORMAT A52
COLUMN valor FORMAT A14
COLUMN espacio FORMAT A22
COLUMN tipo FORMAT A8
COLUMN mb FORMAT 99,990.0

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
PROMPT Proporciones por envio de agosto a octubre (supuesto del capitulo 5 entre parentesis)
SELECT 'Eventos por envio (6,2)' AS concepto,
       TO_CHAR((SELECT COUNT(*) FROM evento_envio ev JOIN envio e ON e.numero_guia = ev.numero_guia WHERE e.fecha_registro < DATE '2026-11-01')
             / (SELECT COUNT(*) FROM envio WHERE fecha_registro < DATE '2026-11-01'), 'FM990.00') AS valor FROM dual
UNION ALL
SELECT 'Asignaciones por envio (1,12)',
       TO_CHAR((SELECT COUNT(*) FROM asignacion_despacho a JOIN envio e ON e.numero_guia = a.numero_guia WHERE e.fecha_registro < DATE '2026-11-01')
             / (SELECT COUNT(*) FROM envio WHERE fecha_registro < DATE '2026-11-01'), 'FM990.00') FROM dual
UNION ALL
SELECT 'Novedades por envio (0,12)',
       TO_CHAR((SELECT COUNT(*) FROM novedad n JOIN asignacion_despacho a ON a.id_asignacion = n.id_asignacion
                  JOIN envio e ON e.numero_guia = a.numero_guia WHERE e.fecha_registro < DATE '2026-11-01')
             / (SELECT COUNT(*) FROM envio WHERE fecha_registro < DATE '2026-11-01'), 'FM990.00') FROM dual
UNION ALL
SELECT 'Pruebas de entrega por envio (1)',
       TO_CHAR((SELECT COUNT(*) FROM prueba_entrega p JOIN asignacion_despacho a ON a.id_asignacion = p.id_asignacion
                  JOIN envio e ON e.numero_guia = a.numero_guia WHERE e.fecha_registro < DATE '2026-11-01')
             / (SELECT COUNT(*) FROM envio WHERE fecha_registro < DATE '2026-11-01'), 'FM990.00') FROM dual
UNION ALL
SELECT 'Envios por solicitud (6)',
       TO_CHAR((SELECT COUNT(*) FROM envio WHERE fecha_registro < DATE '2026-11-01')
             / (SELECT COUNT(DISTINCT id_solicitud) FROM envio WHERE fecha_registro < DATE '2026-11-01'), 'FM990.00') FROM dual
UNION ALL
SELECT 'Destinatarios nuevos por envio (0,60)',
       TO_CHAR((SELECT COUNT(DISTINCT id_destinatario) FROM envio WHERE fecha_registro < DATE '2026-11-01')
             / (SELECT COUNT(*) FROM envio WHERE fecha_registro < DATE '2026-11-01'), 'FM990.00') FROM dual
UNION ALL
SELECT 'Despachos por dia habil (50)',
       TO_CHAR((SELECT COUNT(*) FROM despacho WHERE fecha < DATE '2026-11-01') / 73, 'FM990.0') FROM dual;

PROMPT
PROMPT Envios por estado actual (v_estado_actual_envio)
SELECT estado_actual, COUNT(*) AS envios
FROM   v_estado_actual_envio
GROUP  BY estado_actual
ORDER  BY MIN(CASE estado_actual WHEN 'REGISTRADO' THEN 1 WHEN 'RECOLECTADO' THEN 2 WHEN 'EN_CENTRO' THEN 3
                  WHEN 'CLASIFICADO' THEN 4 WHEN 'EN_RUTA' THEN 5 WHEN 'ENTREGADO' THEN 6
                  WHEN 'CON_NOVEDAD' THEN 7 WHEN 'DEVUELTO' THEN 8 ELSE 9 END);

PROMPT
PROMPT Tamano de los segmentos por espacio de tablas (USER_SEGMENTS)
SELECT tablespace_name AS espacio, segment_type AS tipo, ROUND(SUM(bytes) / 1048576, 1) AS mb
FROM   user_segments
GROUP  BY tablespace_name, segment_type
ORDER  BY tablespace_name, segment_type;

PROMPT
PROMPT Tablas mas grandes (MB, datos)
SELECT segment_name AS tabla, ROUND(SUM(bytes) / 1048576, 1) AS mb
FROM   user_segments
WHERE  segment_type = 'TABLE'
GROUP  BY segment_name
HAVING SUM(bytes) / 1048576 >= 1
ORDER  BY SUM(bytes) DESC;
