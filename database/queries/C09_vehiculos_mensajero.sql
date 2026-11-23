-- C9. Vehículos disponibles para un mensajero
-- Usuarios: U2.
-- Operaciones del algebra relacional: selección, reunión natural y proyección.
-- Se ejecuta con la cuenta svc_centro (database/queries/run-queries.sh).
-- El SQL de abajo es identico al del documento (seccion 6.1); lo comprueba
-- database/tests/compare-queries.sh.
SET LINESIZE 200 PAGESIZE 100 FEEDBACK ON
COLUMN placa FORMAT A10
COLUMN marca FORMAT A12
COLUMN modelo FORMAT A16

SELECT v.id_vehiculo, v.placa, v.marca, v.modelo
FROM   mensajero m
JOIN   vehiculo v ON v.id_tipo_vehiculo = m.id_tipo_vehiculo
WHERE  m.id_empleado = 7
AND    v.estado = 'DISPONIBLE';
