-- C3. Planilla de un despacho
-- Usuarios: U2, U4.
-- Operaciones del algebra relacional: renombre, selección, reunión natural y proyección.
-- Se ejecuta con la cuenta svc_centro (database/queries/run-queries.sh).
-- El SQL de abajo es identico al del documento (seccion 6.1); lo comprueba
-- database/tests/compare-queries.sh.
SET LINESIZE 200 PAGESIZE 100 FEEDBACK ON
COLUMN numero_guia FORMAT A16
COLUMN destinatario FORMAT A26
COLUMN direccion_destino FORMAT A20
COLUMN zona FORMAT A11
COLUMN resultado FORMAT A10

SELECT a.orden_visita, a.numero_guia, d.nombre AS destinatario,
       e.direccion_destino, z.nombre AS zona, a.resultado
FROM   asignacion_despacho a
JOIN   envio e        ON e.numero_guia     = a.numero_guia
JOIN   destinatario d ON d.id_destinatario = e.id_destinatario
JOIN   zona z         ON z.id_zona         = e.id_zona
WHERE  a.id_despacho = 15
ORDER  BY a.orden_visita;
