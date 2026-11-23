-- Consulta: C2, recorrido de una guia (evento_envio + estado_envio + empleado)
-- Indice esperado: EVENTO_GUIA_FECHA_UX (unico sobre numero_guia, fecha_hora)
SET LINESIZE 200 PAGESIZE 200 FEEDBACK OFF
EXPLAIN PLAN SET STATEMENT_ID = 'E1' FOR
SELECT ev.fecha_hora, es.nombre AS estado, em.nombres AS responsable, ev.observacion
FROM   evento_envio ev
JOIN   estado_envio es ON es.id_estado   = ev.id_estado
JOIN   empleado em     ON em.id_empleado = ev.id_empleado
WHERE  ev.numero_guia = 'EE0000000030000'
ORDER  BY ev.fecha_hora;
SELECT plan_table_output FROM TABLE(DBMS_XPLAN.DISPLAY(NULL, 'E1', 'TYPICAL'));
