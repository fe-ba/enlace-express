-- C1. Datos de un envío
-- Usuarios: U3.
-- Operaciones del algebra relacional: selección y proyección.
-- Se ejecuta con la cuenta svc_mesa (database/queries/run-queries.sh).
-- El SQL de abajo es identico al del documento (seccion 6.1); lo comprueba
-- database/tests/compare-queries.sh.
SET LINESIZE 200 PAGESIZE 100 FEEDBACK ON
COLUMN numero_guia FORMAT A16
COLUMN fragil FORMAT A5
COLUMN alto_valor FORMAT A10
COLUMN peso_real FORMAT 999.99

SELECT numero_guia, fecha_registro, fecha_compromiso,
       peso_real, fragil, alto_valor
FROM   envio
WHERE  numero_guia = 'EE0000000000003';
