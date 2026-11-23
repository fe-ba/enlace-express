-- RN05, RN07 y RN08 al cambiar el resultado de una asignacion.
-- Disparador de fila simple: solo lee PRUEBA_ENTREGA y NOVEDAD, no su propia
-- tabla, asi que no hay tabla en mutacion.
WHENEVER SQLERROR EXIT FAILURE

CREATE OR REPLACE TRIGGER trg_asignacion_resultado
BEFORE UPDATE OF resultado ON asignacion_despacho
FOR EACH ROW
DECLARE
    v_existe NUMBER;
BEGIN
    IF :NEW.resultado = :OLD.resultado OR :NEW.resultado = 'PENDIENTE' THEN
        RETURN;
    END IF;

    -- RN07: el tercer intento solo termina en DEVUELTO, y DEVUELTO solo en el tercero
    IF :NEW.resultado = 'DEVUELTO' AND :NEW.numero_intento <> 3 THEN
        pkg_errores.lanzar(pkg_errores.c_rn07,
            'RN07: DEVUELTO solo es posible en el intento 3 (esta asignación es el intento '
            || :NEW.numero_intento || ')');
    ELSIF :NEW.resultado IN ('ENTREGADO', 'NOVEDAD') AND :NEW.numero_intento = 3 THEN
        pkg_errores.lanzar(pkg_errores.c_rn07,
            'RN07: el intento 3 solo puede terminar en DEVUELTO, no en ' || :NEW.resultado);
    END IF;

    -- RN05: ENTREGADO y DEVUELTO exigen la prueba de entrega del intento
    IF :NEW.resultado IN ('ENTREGADO', 'DEVUELTO') THEN
        SELECT COUNT(*) INTO v_existe
        FROM   prueba_entrega WHERE id_asignacion = :NEW.id_asignacion;
        IF v_existe = 0 THEN
            pkg_errores.lanzar(pkg_errores.c_rn05,
                'RN05: la asignación ' || :NEW.id_asignacion || ' no puede quedar '
                || :NEW.resultado || ' sin prueba de entrega');
        END IF;
    END IF;

    -- RN08: NOVEDAD exige la novedad registrada del intento
    IF :NEW.resultado = 'NOVEDAD' THEN
        SELECT COUNT(*) INTO v_existe
        FROM   novedad WHERE id_asignacion = :NEW.id_asignacion;
        IF v_existe = 0 THEN
            pkg_errores.lanzar(pkg_errores.c_rn08,
                'RN08: la asignación ' || :NEW.id_asignacion
                || ' no puede quedar en NOVEDAD sin la novedad registrada');
        END IF;
    END IF;
END trg_asignacion_resultado;
/
