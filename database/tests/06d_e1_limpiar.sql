-- Limpieza de la prueba de E1 desde la aplicacion (como el propietario): borra la
-- cuenta, los codigos y el mensajero de prueba (empleado 9301). Es un script de
-- pruebas del administrador; los roles de la aplicacion no pueden borrar (RN16).
WHENEVER SQLERROR EXIT FAILURE
DELETE FROM codigo_activacion WHERE id_empleado = 9301;
DELETE FROM usuario_aplicacion WHERE id_empleado = 9301;
DELETE FROM mensajero WHERE id_empleado = 9301;
DELETE FROM empleado WHERE id_empleado = 9301;
COMMIT;
