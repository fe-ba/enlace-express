-- I06. Novedades abiertas
-- Usuarios: U3. Vista de origen: v_novedades_abiertas.
-- Contenido: guia, intento, tipo y descripcion de la novedad, destinatario, cliente y telefonos.
-- Filtro y orden: todas; por hora de la visita. Frecuencia: diaria.
-- Sin parametros. Se ejecuta con svc_mesa.
SET VERIFY OFF
SET LINESIZE 250 PAGESIZE 100 FEEDBACK ON
COLUMN numero_guia FORMAT A16
COLUMN numero_intento FORMAT 99 HEADING 'INT'
COLUMN tipo_novedad FORMAT A20
COLUMN descripcion FORMAT A44
COLUMN destinatario FORMAT A20
COLUMN telefono_destinatario FORMAT A12 HEADING 'TEL_DEST'
COLUMN cliente FORMAT A30
COLUMN telefono_cliente FORMAT A12 HEADING 'TEL_CLIENTE'
PROMPT I06. Novedades abiertas

SELECT numero_guia, numero_intento, tipo_novedad, descripcion, destinatario, telefono_destinatario,
       cliente, telefono_cliente
FROM   v_novedades_abiertas
ORDER  BY hora_visita, numero_guia;
