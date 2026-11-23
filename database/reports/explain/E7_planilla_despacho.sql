-- Consulta: C3, planilla del despacho 15 (reunion por clave foranea ASIGNACION_DESPACHO.ID_DESPACHO)
-- Indice esperado: ASIGNACION_DESPACHO_FK_IX
SET LINESIZE 200 PAGESIZE 200 FEEDBACK OFF
EXPLAIN PLAN SET STATEMENT_ID = 'E7' FOR
SELECT a.orden_visita, a.numero_guia, d.nombre AS destinatario,
       e.direccion_destino, z.nombre AS zona, a.resultado
FROM   asignacion_despacho a
JOIN   envio e        ON e.numero_guia     = a.numero_guia
JOIN   destinatario d ON d.id_destinatario = e.id_destinatario
JOIN   zona z         ON z.id_zona         = e.id_zona
WHERE  a.id_despacho = 15
ORDER  BY a.orden_visita;
SELECT plan_table_output FROM TABLE(DBMS_XPLAN.DISPLAY(NULL, 'E7', 'TYPICAL'));
