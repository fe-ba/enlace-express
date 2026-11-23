-- C4. Envíos clasificados sin asignar
-- Usuarios: U2.
-- Operaciones del algebra relacional: selección, reunión natural, proyección y diferencia.
-- Se ejecuta con la cuenta svc_centro (database/queries/run-queries.sh).
-- El SQL de abajo es identico al del documento (seccion 6.1); lo comprueba
-- database/tests/compare-queries.sh.
SET LINESIZE 200 PAGESIZE 100 FEEDBACK ON
COLUMN numero_guia FORMAT A16

SELECT ev.numero_guia
FROM   evento_envio ev
JOIN   estado_envio es ON es.id_estado = ev.id_estado
WHERE  es.nombre = 'CLASIFICADO'
AND    ev.numero_guia NOT IN (SELECT numero_guia
                              FROM   asignacion_despacho);
