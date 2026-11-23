-- RN10: vehiculo DISPONIBLE y mensajero ACTIVO.
-- RN11: el vehiculo es del tipo que conduce el mensajero.
WHENEVER SQLERROR EXIT FAILURE

CREATE OR REPLACE TRIGGER trg_despacho_vehiculo_mensajero
BEFORE INSERT OR UPDATE OF id_vehiculo, id_mensajero ON despacho
FOR EACH ROW
DECLARE
    v_estado_vehiculo   vehiculo.estado%TYPE;
    v_tipo_vehiculo     vehiculo.id_tipo_vehiculo%TYPE;
    v_estado_mensajero  empleado.estado%TYPE;
    v_tipo_mensajero    mensajero.id_tipo_vehiculo%TYPE;
BEGIN
    BEGIN
        SELECT estado, id_tipo_vehiculo INTO v_estado_vehiculo, v_tipo_vehiculo
        FROM   vehiculo WHERE id_vehiculo = :NEW.id_vehiculo;
        SELECT e.estado, m.id_tipo_vehiculo INTO v_estado_mensajero, v_tipo_mensajero
        FROM   mensajero m JOIN empleado e ON e.id_empleado = m.id_empleado
        WHERE  m.id_empleado = :NEW.id_mensajero;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN;  -- vehiculo o mensajero inexistente: lo rechaza la clave foranea
    END;

    IF v_estado_vehiculo <> 'DISPONIBLE' THEN
        pkg_errores.lanzar(pkg_errores.c_rn10,
            'RN10: el vehículo ' || :NEW.id_vehiculo || ' está ' || v_estado_vehiculo
            || '; debe estar DISPONIBLE');
    END IF;
    IF v_estado_mensajero <> 'ACTIVO' THEN
        pkg_errores.lanzar(pkg_errores.c_rn10,
            'RN10: el mensajero ' || :NEW.id_mensajero || ' está ' || v_estado_mensajero
            || '; debe estar ACTIVO');
    END IF;
    IF v_tipo_vehiculo <> v_tipo_mensajero THEN
        pkg_errores.lanzar(pkg_errores.c_rn11,
            'RN11: el vehículo ' || :NEW.id_vehiculo || ' no es del tipo que conduce el mensajero '
            || :NEW.id_mensajero);
    END IF;
END trg_despacho_vehiculo_mensajero;
/
