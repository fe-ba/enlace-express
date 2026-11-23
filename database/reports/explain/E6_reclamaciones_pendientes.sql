-- Consulta: v_reclamaciones_pendientes (reclamaciones con estado ABIERTA)
-- Indice esperado: RECLAMACION_ESTADO_IX
SET LINESIZE 200 PAGESIZE 200 FEEDBACK OFF
EXPLAIN PLAN SET STATEMENT_ID = 'E6' FOR
SELECT id_reclamacion, fecha_radicacion, cliente, numero_guia, tipo
FROM   v_reclamaciones_pendientes
ORDER  BY fecha_radicacion;
SELECT plan_table_output FROM TABLE(DBMS_XPLAN.DISPLAY(NULL, 'E6', 'TYPICAL'));
