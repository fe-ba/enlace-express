-- Consulta: estado actual de una guia con v_estado_actual_envio (subconsulta MAX(fecha_hora), C10)
-- Indice esperado: EVENTO_GUIA_FECHA_UX
SET LINESIZE 200 PAGESIZE 200 FEEDBACK OFF
EXPLAIN PLAN SET STATEMENT_ID = 'E2' FOR
SELECT numero_guia, estado_actual, fecha_hora_estado
FROM   v_estado_actual_envio
WHERE  numero_guia = 'EE0000000030000';
SELECT plan_table_output FROM TABLE(DBMS_XPLAN.DISPLAY(NULL, 'E2', 'TYPICAL'));
