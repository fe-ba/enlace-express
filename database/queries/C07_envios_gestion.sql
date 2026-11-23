-- C7. Envíos que requieren gestión
-- Usuarios: U3.
-- Operaciones del algebra relacional: selección, reunión natural, proyección y unión.
-- Se ejecuta con la cuenta svc_mesa (database/queries/run-queries.sh).
-- El SQL de abajo es identico al del documento (seccion 6.1); lo comprueba
-- database/tests/compare-queries.sh.
SET LINESIZE 200 PAGESIZE 100 FEEDBACK ON
COLUMN numero_guia FORMAT A16

SELECT a.numero_guia
FROM   novedad n
JOIN   asignacion_despacho a ON a.id_asignacion = n.id_asignacion
WHERE  n.estado = 'ABIERTA'
UNION
SELECT numero_guia
FROM   reclamacion
WHERE  estado = 'ABIERTA'
AND    numero_guia IS NOT NULL;
