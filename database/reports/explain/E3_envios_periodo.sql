-- Consulta: C5, envios por zona y modalidad de una semana (14 a 19 de septiembre) y, al final, de un mes
-- Indice esperado: ENVIO_FECHA_REGISTRO_IX
-- Con la semana (unos 5.400 de 65.700 envios, 8 %) se espera el indice; con el mes
-- (unos 22.000, 33 %) el optimizador suele preferir recorrer la tabla completa,
-- porque leer un tercio de las filas por indice cuesta mas que un barrido.
SET LINESIZE 200 PAGESIZE 200 FEEDBACK OFF
EXPLAIN PLAN SET STATEMENT_ID = 'E3' FOR
SELECT z.nombre AS zona, m.nombre AS modalidad, COUNT(e.numero_guia) AS envios
FROM   envio e
JOIN   zona z      ON z.id_zona      = e.id_zona
JOIN   modalidad m ON m.id_modalidad = e.id_modalidad
WHERE  e.fecha_registro BETWEEN DATE '2026-09-14' AND DATE '2026-09-19'
GROUP  BY z.nombre, m.nombre
ORDER  BY z.nombre, m.nombre;
SELECT plan_table_output FROM TABLE(DBMS_XPLAN.DISPLAY(NULL, 'E3', 'TYPICAL'));
PROMPT
PROMPT El mismo informe para el mes de septiembre
EXPLAIN PLAN SET STATEMENT_ID = 'E3M' FOR
SELECT z.nombre AS zona, m.nombre AS modalidad, COUNT(e.numero_guia) AS envios
FROM   envio e
JOIN   zona z      ON z.id_zona      = e.id_zona
JOIN   modalidad m ON m.id_modalidad = e.id_modalidad
WHERE  e.fecha_registro BETWEEN DATE '2026-09-01' AND DATE '2026-09-30'
GROUP  BY z.nombre, m.nombre
ORDER  BY z.nombre, m.nombre;
SELECT plan_table_output FROM TABLE(DBMS_XPLAN.DISPLAY(NULL, 'E3M', 'TYPICAL'));
