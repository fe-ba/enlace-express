-- Parametros para los informes con datos de volumen: despacho de entrega del
-- 15 de septiembre con mas asignaciones, guia con mas eventos y su cliente.
-- Salida: una linea "despacho|guia|cliente".
SET HEADING OFF PAGESIZE 0 FEEDBACK OFF VERIFY OFF TRIMSPOOL ON LINESIZE 200
SELECT d.id_despacho || '|' || g.numero_guia || '|' || s.id_cliente
FROM  (SELECT id_despacho FROM (SELECT a.id_despacho, COUNT(*) c
                                FROM asignacion_despacho a JOIN despacho d ON d.id_despacho = a.id_despacho
                                WHERE d.fecha = DATE '2026-09-15' AND d.tipo = 'ENTREGA'
                                GROUP BY a.id_despacho ORDER BY c DESC, a.id_despacho)
       FETCH FIRST 1 ROW ONLY) d,
      (SELECT numero_guia FROM (SELECT numero_guia, COUNT(*) c FROM evento_envio
                                WHERE numero_guia > 'EE0000000000029' GROUP BY numero_guia ORDER BY c DESC, numero_guia)
       FETCH FIRST 1 ROW ONLY) g,
      (SELECT DISTINCT id_cliente FROM v_seguimiento_envio WHERE numero_guia = (SELECT numero_guia FROM (SELECT numero_guia, COUNT(*) c FROM evento_envio
                                WHERE numero_guia > 'EE0000000000029' GROUP BY numero_guia ORDER BY c DESC, numero_guia) FETCH FIRST 1 ROW ONLY)) s;
