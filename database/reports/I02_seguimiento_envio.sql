-- I02. Seguimiento del envio
-- Usuarios: U9, U3. Vista de origen: v_seguimiento_envio.
-- Contenido: fecha y hora, estado, observacion y responsable de cada evento.
-- Filtro y orden: una guia (U9: solo las de su empresa); por fecha. Frecuencia: cada consulta.
-- Parametros: &1 numero de guia (por defecto EE0000000000003); &2 id_cliente del portal
-- (por defecto 1): la cuenta del portal filtra siempre por su cliente. Se ejecuta con svc_cliente.
SET VERIFY OFF
SET TERMOUT OFF
COLUMN 1 NEW_VALUE 1 NOPRINT
COLUMN 2 NEW_VALUE 2 NOPRINT
SELECT '' "1", '' "2" FROM dual WHERE ROWNUM = 0;
COLUMN p_guia NEW_VALUE p_guia NOPRINT
COLUMN p_cliente NEW_VALUE p_cliente NOPRINT
SELECT NVL('&1', 'EE0000000000003') AS p_guia, NVL('&2', '1') AS p_cliente FROM dual;
SET TERMOUT ON
SET LINESIZE 200 PAGESIZE 100 FEEDBACK ON
COLUMN fecha_hora FORMAT A28
COLUMN estado FORMAT A12
COLUMN observacion FORMAT A50
COLUMN responsable FORMAT A24
PROMPT I02. Seguimiento de la guia &p_guia para el cliente &p_cliente

SELECT fecha_hora, estado, observacion, responsable
FROM   v_seguimiento_envio
WHERE  numero_guia = '&p_guia'
AND    id_cliente  = &p_cliente
ORDER  BY fecha_hora;
