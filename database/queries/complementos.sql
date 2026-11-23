-- Consultas de apoyo para interpretar los resultados de C6, C7, C8 y C9 en la
-- seccion 6.3 del documento. No son consultas del modulo: muestran los datos que
-- explican por que cada resultado tiene las filas que tiene. Las ejecuta
-- database/queries/run-queries.sh al final, como propietario, y guarda la
-- salida en docs/evidence/05_consultas/complementos.txt.
SET VERIFY OFF
SET LINESIZE 200 PAGESIZE 100 FEEDBACK ON
COLUMN nombres FORMAT A12
COLUMN apellidos FORMAT A18
COLUMN origen FORMAT A12
COLUMN numero_guia FORMAT A16
COLUMN estado FORMAT A18
COLUMN placa FORMAT A10
COLUMN tipo FORMAT A14
COLUMN razon_social FORMAT A32

PROMPT
PROMPT A. Novedades por mensajero en noviembre de 2026 (C6 sin la condicion HAVING)
SELECT em.nombres, em.apellidos,
       COUNT(n.id_novedad) AS novedades
FROM   novedad n
JOIN   asignacion_despacho a ON a.id_asignacion = n.id_asignacion
JOIN   despacho d            ON d.id_despacho   = a.id_despacho
JOIN   empleado em           ON em.id_empleado  = d.id_mensajero
WHERE  d.fecha BETWEEN DATE '2026-11-01' AND DATE '2026-11-30'
GROUP  BY em.nombres, em.apellidos
ORDER  BY COUNT(n.id_novedad) DESC, em.nombres;

PROMPT
PROMPT B. Novedades y reclamaciones abiertas, con la guia (C7 las une y descarta las reclamaciones sin guia)
SELECT 'NOVEDAD' AS origen, a.numero_guia, n.estado
FROM   novedad n
JOIN   asignacion_despacho a ON a.id_asignacion = n.id_asignacion
WHERE  n.estado = 'ABIERTA'
UNION ALL
SELECT 'RECLAMACION', NVL(r.numero_guia, '(sin guia)'), r.estado
FROM   reclamacion r
WHERE  r.estado = 'ABIERTA'
ORDER  BY 2, 1;

PROMPT
PROMPT C. Modalidades distintas usadas por cada cliente (C8 pide las 3 que existen)
SELECT c.razon_social,
       COUNT(DISTINCT e.id_modalidad) AS modalidades
FROM   cliente c
JOIN   sede_cliente s          ON s.id_cliente   = c.id_cliente
JOIN   solicitud_recoleccion r ON r.id_sede      = s.id_sede
JOIN   envio e                 ON e.id_solicitud = r.id_solicitud
GROUP  BY c.razon_social
ORDER  BY COUNT(DISTINCT e.id_modalidad) DESC, c.razon_social;

PROMPT
PROMPT D. Vehiculos del tipo que conduce el mensajero 7, con su estado (C9 solo devuelve los DISPONIBLE)
SELECT v.id_vehiculo, v.placa, tv.nombre AS tipo, v.estado
FROM   mensajero m
JOIN   vehiculo v        ON v.id_tipo_vehiculo  = m.id_tipo_vehiculo
JOIN   tipo_vehiculo tv  ON tv.id_tipo_vehiculo = v.id_tipo_vehiculo
WHERE  m.id_empleado = 7
ORDER  BY v.id_vehiculo;
