-- RN07 al insertar una asignacion. Disparador compuesto (decision C3): la
-- comprobacion de los intentos anteriores consulta la misma tabla, algo que
-- un disparador de fila no puede hacer (ORA-04091). Por fila se valida el
-- despacho y se guardan los intentos nuevos; despues de la sentencia se
-- comparan con los intentos anteriores, tambien con INSERT ... SELECT.
WHENEVER SQLERROR EXIT FAILURE

CREATE OR REPLACE TRIGGER trg_asignacion_intento
FOR INSERT ON asignacion_despacho
COMPOUND TRIGGER
    TYPE t_intento IS RECORD (
        numero_guia    asignacion_despacho.numero_guia%TYPE,
        numero_intento asignacion_despacho.numero_intento%TYPE
    );
    TYPE t_intentos IS TABLE OF t_intento INDEX BY PLS_INTEGER;
    g_nuevos t_intentos;

    BEFORE EACH ROW IS
        v_tipo   despacho.tipo%TYPE;
        v_estado despacho.estado%TYPE;
    BEGIN
        BEGIN
            SELECT tipo, estado INTO v_tipo, v_estado
            FROM   despacho WHERE id_despacho = :NEW.id_despacho;
            IF v_tipo <> 'ENTREGA' THEN
                pkg_errores.lanzar(pkg_errores.c_rn07,
                    'RN07: el despacho ' || :NEW.id_despacho || ' es de ' || v_tipo
                    || '; solo se asignan envios a despachos de ENTREGA');
            END IF;
            IF v_estado = 'CERRADO' THEN
                pkg_errores.lanzar(pkg_errores.c_rn07,
                    'RN07: el despacho ' || :NEW.id_despacho || ' está CERRADO y no admite asignaciones');
            END IF;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                NULL;  -- despacho inexistente: lo rechaza la clave foranea
        END;

        -- una asignacion nace PENDIENTE: el resultado se fija luego, con su prueba o novedad
        IF :NEW.resultado IN ('ENTREGADO', 'DEVUELTO') THEN
            pkg_errores.lanzar(pkg_errores.c_rn05,
                'RN05: una asignación nueva no puede nacer ' || :NEW.resultado
                || ' sin prueba de entrega');
        ELSIF :NEW.resultado = 'NOVEDAD' THEN
            pkg_errores.lanzar(pkg_errores.c_rn08,
                'RN08: una asignación nueva no puede nacer con resultado NOVEDAD sin novedad registrada');
        END IF;

        g_nuevos(g_nuevos.COUNT + 1).numero_guia := :NEW.numero_guia;
        g_nuevos(g_nuevos.COUNT).numero_intento := :NEW.numero_intento;
    END BEFORE EACH ROW;

    AFTER STATEMENT IS
        v_previos NUMBER;
        v_novedad NUMBER;
    BEGIN
        FOR i IN 1 .. g_nuevos.COUNT LOOP
            IF g_nuevos(i).numero_intento > 1 THEN
                SELECT COUNT(*), COUNT(CASE WHEN resultado = 'NOVEDAD' THEN 1 END)
                INTO   v_previos, v_novedad
                FROM   asignacion_despacho
                WHERE  numero_guia = g_nuevos(i).numero_guia
                AND    numero_intento < g_nuevos(i).numero_intento;

                IF v_previos <> g_nuevos(i).numero_intento - 1
                   OR v_novedad <> v_previos THEN
                    pkg_errores.lanzar(pkg_errores.c_rn07,
                        'RN07: el intento ' || g_nuevos(i).numero_intento || ' de la guía '
                        || g_nuevos(i).numero_guia || ' solo se crea si los '
                        || (g_nuevos(i).numero_intento - 1) || ' anteriores terminaron en NOVEDAD');
                END IF;
            END IF;
        END LOOP;
    END AFTER STATEMENT;
END trg_asignacion_intento;
/
