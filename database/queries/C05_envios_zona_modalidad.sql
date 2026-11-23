-- C5. Envíos por zona y modalidad
-- Usuarios: U1.
-- Operaciones del algebra relacional: selección, renombre, reunión natural y agregación.
-- Se ejecuta con la cuenta svc_gerencia (database/queries/run-queries.sh).
-- El SQL de abajo es identico al del documento (seccion 6.1); lo comprueba
-- database/tests/compare-queries.sh.
SET LINESIZE 200 PAGESIZE 100 FEEDBACK ON
COLUMN zona FORMAT A12
COLUMN modalidad FORMAT A14

SELECT z.nombre AS zona, m.nombre AS modalidad,
       COUNT(e.numero_guia) AS envios
FROM   envio e
JOIN   zona z      ON z.id_zona      = e.id_zona
JOIN   modalidad m ON m.id_modalidad = e.id_modalidad
WHERE  e.fecha_registro BETWEEN DATE '2026-11-01' AND DATE '2026-11-30'
GROUP  BY z.nombre, m.nombre
ORDER  BY z.nombre, m.nombre;
