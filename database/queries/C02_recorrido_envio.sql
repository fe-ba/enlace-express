-- C2. Recorrido de un envío
-- Usuarios: U3, U9.
-- Operaciones del algebra relacional: selección, reunión natural y proyección.
-- Se ejecuta con la cuenta svc_mesa (database/queries/run-queries.sh).
-- El SQL de abajo es identico al del documento (seccion 6.1); lo comprueba
-- database/tests/compare-queries.sh.
SET LINESIZE 200 PAGESIZE 100 FEEDBACK ON
COLUMN fecha_hora FORMAT A30
COLUMN estado FORMAT A12
COLUMN responsable FORMAT A12
COLUMN observacion FORMAT A50

SELECT ev.fecha_hora, es.nombre AS estado,
       em.nombres AS responsable, ev.observacion
FROM   evento_envio ev
JOIN   estado_envio es ON es.id_estado   = ev.id_estado
JOIN   empleado em     ON em.id_empleado = ev.id_empleado
WHERE  ev.numero_guia = 'EE0000000000003'
ORDER  BY ev.fecha_hora;
