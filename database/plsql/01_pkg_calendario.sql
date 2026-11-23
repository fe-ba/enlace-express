-- Calendario de plazos del servicio. El plazo de la modalidad cuenta el dia
-- del registro como dia 1; los dias habiles son de lunes a sabado. Si el
-- registro cae en domingo, el dia 1 es el lunes siguiente.
-- Es una funcion de apoyo del procedimiento de registro; no es un
-- procedimiento del modulo.
WHENEVER SQLERROR EXIT FAILURE

CREATE OR REPLACE PACKAGE pkg_calendario AS
    -- Fecha de compromiso = fecha de registro avanzada (plazo - 1) dias habiles.
    FUNCTION fecha_compromiso(p_registro IN DATE, p_plazo_dias_habiles IN NUMBER) RETURN DATE;
END pkg_calendario;
/

CREATE OR REPLACE PACKAGE BODY pkg_calendario AS
    -- IW empieza en lunes: diferencia 6 = domingo (no habil)
    FUNCTION es_domingo(p_fecha IN DATE) RETURN BOOLEAN IS
    BEGIN
        RETURN p_fecha - TRUNC(p_fecha, 'IW') = 6;
    END es_domingo;

    FUNCTION fecha_compromiso(p_registro IN DATE, p_plazo_dias_habiles IN NUMBER) RETURN DATE IS
        v_fecha     DATE := TRUNC(p_registro);
        v_pendiente NUMBER := p_plazo_dias_habiles - 1;
    BEGIN
        IF es_domingo(v_fecha) THEN
            v_fecha := v_fecha + 1;
        END IF;
        WHILE v_pendiente > 0 LOOP
            v_fecha := v_fecha + 1;
            IF NOT es_domingo(v_fecha) THEN
                v_pendiente := v_pendiente - 1;
            END IF;
        END LOOP;
        RETURN v_fecha;
    END fecha_compromiso;
END pkg_calendario;
/
