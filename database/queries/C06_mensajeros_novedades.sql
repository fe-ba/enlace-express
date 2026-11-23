-- C6. Mensajeros con varias novedades
-- Usuarios: U1.
-- Operaciones del algebra relacional: selección, reunión natural, reunión theta y agregación.
-- Se ejecuta con la cuenta svc_gerencia (database/queries/run-queries.sh).
-- El SQL de abajo es identico al del documento (seccion 6.1); lo comprueba
-- database/tests/compare-queries.sh.
SET LINESIZE 200 PAGESIZE 100 FEEDBACK ON
COLUMN nombres FORMAT A12
COLUMN apellidos FORMAT A18

SELECT em.nombres, em.apellidos,
       COUNT(n.id_novedad) AS novedades
FROM   novedad n
JOIN   asignacion_despacho a ON a.id_asignacion = n.id_asignacion
JOIN   despacho d            ON d.id_despacho   = a.id_despacho
JOIN   empleado em           ON em.id_empleado  = d.id_mensajero
WHERE  d.fecha BETWEEN DATE '2026-11-01' AND DATE '2026-11-30'
GROUP  BY em.nombres, em.apellidos
HAVING COUNT(n.id_novedad) >= 2;
