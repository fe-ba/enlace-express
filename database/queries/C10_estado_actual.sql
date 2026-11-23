-- C10. Estado actual de cada envío
-- Usuarios: U1, U2, U3.
-- Operaciones del algebra relacional: agregación, renombre, reunión natural, selección y proyección.
-- Se ejecuta con la cuenta svc_gerencia (database/queries/run-queries.sh).
-- El SQL de abajo es identico al del documento (seccion 6.1); lo comprueba
-- database/tests/compare-queries.sh.
SET LINESIZE 200 PAGESIZE 100 FEEDBACK ON
COLUMN numero_guia FORMAT A16
COLUMN estado_actual FORMAT A14

SELECT ev.numero_guia, es.nombre AS estado_actual
FROM   evento_envio ev
JOIN   estado_envio es ON es.id_estado = ev.id_estado
WHERE  ev.fecha_hora = (SELECT MAX(x.fecha_hora)
                        FROM   evento_envio x
                        WHERE  x.numero_guia = ev.numero_guia)
ORDER  BY ev.numero_guia;
