-- I05. Envios por despachar
-- Usuarios: U2. Vista de origen: v_envios_por_despachar.
-- Contenido: guia, zona, modalidad, fecha de compromiso, peso, fragil y alto valor.
-- Filtro y orden: un centro; por fecha de compromiso. Frecuencia: antes de cada salida.
-- Parametro &1: id del centro (por defecto 1). Se ejecuta con svc_centro.
SET VERIFY OFF
SET TERMOUT OFF
COLUMN 1 NEW_VALUE 1 NOPRINT
SELECT '' "1" FROM dual WHERE ROWNUM = 0;
COLUMN p_centro NEW_VALUE p_centro NOPRINT
SELECT NVL('&1', '1') AS p_centro FROM dual;
SET TERMOUT ON
SET LINESIZE 200 PAGESIZE 100 FEEDBACK ON
COLUMN numero_guia FORMAT A16
COLUMN zona FORMAT A11
COLUMN modalidad FORMAT A14
COLUMN peso_kg FORMAT 990.00 HEADING 'PESO_KG'
COLUMN fragil FORMAT A6
COLUMN alto_valor FORMAT A10
PROMPT I05. Envios por despachar del centro &p_centro

SELECT numero_guia, zona, modalidad, fecha_compromiso, peso_kg, fragil, alto_valor
FROM   v_envios_por_despachar
WHERE  id_centro = &p_centro
ORDER  BY fecha_compromiso, numero_guia;
