-- I07. Reclamaciones pendientes
-- Usuarios: U1, U3. Vista de origen: v_reclamaciones_pendientes.
-- Contenido: fecha de radicacion, cliente, guia, tipo y descripcion.
-- Filtro y orden: todas; de la mas antigua a la mas reciente. Frecuencia: diaria.
-- Sin parametros. Se ejecuta con svc_gerencia.
SET VERIFY OFF
SET LINESIZE 250 PAGESIZE 100 FEEDBACK ON
COLUMN fecha_radicacion FORMAT A28
COLUMN cliente FORMAT A30
COLUMN numero_guia FORMAT A16
COLUMN tipo FORMAT A12
COLUMN descripcion FORMAT A50
PROMPT I07. Reclamaciones pendientes

SELECT fecha_radicacion, cliente, numero_guia, tipo, descripcion
FROM   v_reclamaciones_pendientes
ORDER  BY fecha_radicacion, id_reclamacion;
