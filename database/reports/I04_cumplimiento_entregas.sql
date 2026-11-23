-- I04. Cumplimiento de entregas
-- Usuarios: U1. Vista de origen: v_cumplimiento_entregas.
-- Contenido: centro, zona, entregados, entregados a tiempo y porcentaje a tiempo.
-- Filtro y orden: un centro; de menor a mayor porcentaje. Frecuencia: semanal y mensual.
-- Parametro &1: id del centro (por defecto 1). Se ejecuta con svc_gerencia.
SET VERIFY OFF
SET TERMOUT OFF
COLUMN 1 NEW_VALUE 1 NOPRINT
SELECT '' "1" FROM dual WHERE ROWNUM = 0;
COLUMN p_centro NEW_VALUE p_centro NOPRINT
SELECT NVL('&1', '1') AS p_centro FROM dual;
SET TERMOUT ON
SET LINESIZE 200 PAGESIZE 100 FEEDBACK ON
COLUMN id_centro FORMAT 999 HEADING 'CENTRO'
COLUMN id_zona FORMAT 999 HEADING 'ID_ZONA'
COLUMN zona FORMAT A14
COLUMN entregados FORMAT 999,999
COLUMN entregados_a_tiempo FORMAT 999,999 HEADING 'A_TIEMPO'
COLUMN porcentaje_a_tiempo FORMAT 990.0 HEADING '% A TIEMPO'
PROMPT I04. Cumplimiento de entregas del centro &p_centro

SELECT id_centro, id_zona, zona, entregados, entregados_a_tiempo, porcentaje_a_tiempo
FROM   v_cumplimiento_entregas
WHERE  id_centro = &p_centro
ORDER  BY porcentaje_a_tiempo, id_zona;
