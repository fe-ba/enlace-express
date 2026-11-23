-- C8. Clientes que usan todas las modalidades
-- Usuarios: U1.
-- Operaciones del algebra relacional: proyección, reunión natural y división.
-- Se ejecuta con la cuenta svc_gerencia (database/queries/run-queries.sh).
-- El SQL de abajo es identico al del documento (seccion 6.1); lo comprueba
-- database/tests/compare-queries.sh.
SET LINESIZE 200 PAGESIZE 100 FEEDBACK ON
COLUMN razon_social FORMAT A40

SELECT c.razon_social
FROM   cliente c
JOIN   sede_cliente s          ON s.id_cliente   = c.id_cliente
JOIN   solicitud_recoleccion r ON r.id_sede      = s.id_sede
JOIN   envio e                 ON e.id_solicitud = r.id_solicitud
GROUP  BY c.razon_social
HAVING COUNT(DISTINCT e.id_modalidad) = (SELECT COUNT(*)
                                         FROM   modalidad);
