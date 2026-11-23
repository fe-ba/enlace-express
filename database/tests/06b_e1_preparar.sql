-- Preparacion de la prueba de E1 desde la aplicacion (como el propietario): crea un
-- mensajero de prueba (empleado 9301), le genera un codigo y lo confirma. Imprime
-- "CODIGO|<codigo>" para que test-e1.sh se lo pase a 06c. 06d lo limpia.
WHENEVER SQLERROR EXIT FAILURE
SET DEFINE OFF
SET SERVEROUTPUT ON SIZE UNLIMITED
DECLARE
    v_codigo VARCHAR2(20);
BEGIN
    INSERT INTO empleado (id_empleado, id_centro, documento, nombres, apellidos, cargo, telefono, fecha_ingreso, estado)
    VALUES (9301, 1, 'E1-APP-9301', 'Prueba', 'Aplicacion E1', 'Mensajero', '3000000000', DATE '2026-01-05', 'ACTIVO');
    INSERT INTO mensajero (id_empleado, id_zona, id_tipo_vehiculo) VALUES (9301, 1, 1);
    v_codigo := pkg_codigos_activacion.generar_para_empleado('E1-APP-9301', 24);
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('CODIGO|' || v_codigo);
END;
/
