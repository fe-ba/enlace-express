-- Consulta: despachos de un dia (planilla del dia: 15 de septiembre)
-- Indice esperado: DESPACHO_FECHA_IX
SET LINESIZE 200 PAGESIZE 200 FEEDBACK OFF
EXPLAIN PLAN SET STATEMENT_ID = 'E4' FOR
SELECT id_despacho, id_mensajero, id_vehiculo, tipo, estado
FROM   despacho
WHERE  fecha = DATE '2026-09-15';
SELECT plan_table_output FROM TABLE(DBMS_XPLAN.DISPLAY(NULL, 'E4', 'TYPICAL'));
