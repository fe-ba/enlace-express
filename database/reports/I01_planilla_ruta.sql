-- I01. Planilla de ruta (tabla de informes del capitulo 6)
-- Usuarios: U4, U2. Vista de origen: v_planilla_despacho.
-- Contenido: orden de visita, guia, destinatario, telefono, direccion, zona, fragil, alto valor y resultado.
-- Filtro y orden: un despacho; por orden de visita. Frecuencia: cada despacho.
-- Parametro &1: id del despacho (por defecto 15). Se ejecuta con svc_mensajero.
SET VERIFY OFF
SET TERMOUT OFF
COLUMN 1 NEW_VALUE 1 NOPRINT
SELECT '' "1" FROM dual WHERE ROWNUM = 0;
COLUMN p_despacho NEW_VALUE p_despacho NOPRINT
SELECT NVL('&1', '15') AS p_despacho FROM dual;
SET TERMOUT ON
SET LINESIZE 200 PAGESIZE 100 FEEDBACK ON
COLUMN orden_visita FORMAT 999 HEADING 'ORDEN'
COLUMN numero_guia FORMAT A16
COLUMN destinatario FORMAT A24
COLUMN telefono_destinatario FORMAT A12 HEADING 'TELEFONO'
COLUMN direccion_destino FORMAT A24
COLUMN zona FORMAT A11
COLUMN fragil FORMAT A6
COLUMN alto_valor FORMAT A10
COLUMN resultado FORMAT A10
PROMPT I01. Planilla de ruta del despacho &p_despacho

SELECT orden_visita, numero_guia, destinatario, telefono_destinatario, direccion_destino,
       zona, fragil, alto_valor, resultado
FROM   v_planilla_despacho
WHERE  id_despacho = &p_despacho
ORDER  BY orden_visita;
