-- Consulta: v_novedades_abiertas (novedades con estado ABIERTA)
-- Indice esperado: NOVEDAD_ESTADO_IX
SET LINESIZE 200 PAGESIZE 200 FEEDBACK OFF
EXPLAIN PLAN SET STATEMENT_ID = 'E5' FOR
SELECT numero_guia, numero_intento, tipo_novedad, destinatario, cliente
FROM   v_novedades_abiertas
ORDER  BY hora_visita;
SELECT plan_table_output FROM TABLE(DBMS_XPLAN.DISPLAY(NULL, 'E5', 'TYPICAL'));
