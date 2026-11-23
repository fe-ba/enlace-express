-- I03. Envios por estado
-- Usuarios: U1, U2. Vista de origen: v_estado_actual_envio.
-- Contenido: estado actual y numero de envios.
-- Filtro y orden: por centro o zona; agrupado por estado. Frecuencia: diaria.
-- Parametros: &1 id del centro (por defecto 1); &2 id de la zona (0 = todas, por defecto).
-- Se ejecuta con svc_gerencia.
SET VERIFY OFF
SET TERMOUT OFF
COLUMN 1 NEW_VALUE 1 NOPRINT
COLUMN 2 NEW_VALUE 2 NOPRINT
SELECT '' "1", '' "2" FROM dual WHERE ROWNUM = 0;
COLUMN p_centro NEW_VALUE p_centro NOPRINT
COLUMN p_zona NEW_VALUE p_zona NOPRINT
SELECT NVL('&1', '1') AS p_centro, NVL('&2', '0') AS p_zona FROM dual;
SET TERMOUT ON
SET LINESIZE 200 PAGESIZE 100 FEEDBACK ON
COLUMN estado_actual FORMAT A14
COLUMN envios FORMAT 999,999
PROMPT I03. Envios por estado del centro &p_centro (zona &p_zona; 0 = todas)

SELECT estado_actual, COUNT(*) AS envios
FROM   v_estado_actual_envio
WHERE  id_centro = &p_centro
AND    (&p_zona = 0 OR id_zona = &p_zona)
GROUP  BY estado_actual
ORDER  BY MIN(CASE estado_actual WHEN 'REGISTRADO' THEN 1 WHEN 'RECOLECTADO' THEN 2 WHEN 'EN_CENTRO' THEN 3
                  WHEN 'CLASIFICADO' THEN 4 WHEN 'EN_RUTA' THEN 5 WHEN 'ENTREGADO' THEN 6
                  WHEN 'CON_NOVEDAD' THEN 7 WHEN 'DEVUELTO' THEN 8 ELSE 9 END);
