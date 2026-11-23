-- RN12 (ciclo de vida) y RN05 (entrega con prueba) al insertar eventos.
-- Disparador compuesto (decision C3): la transicion se valida contra los
-- eventos de la misma tabla, y una insercion de varias filas de la misma
-- guia (EN_CENTRO y CLASIFICADO en un INSERT ... SELECT, con instantes
-- distintos, decision C5) solo es valida mirando el conjunto. Por fila se
-- guardan los eventos nuevos; despues de la sentencia se valida, para cada
-- guia afectada, toda su secuencia ordenada por fecha_hora (tabla de
-- transiciones del capitulo 5).
WHENEVER SQLERROR EXIT FAILURE

CREATE OR REPLACE TRIGGER trg_evento_transicion
FOR INSERT ON evento_envio
COMPOUND TRIGGER
    TYPE t_evento IS RECORD (
        numero_guia evento_envio.numero_guia%TYPE,
        id_estado   evento_envio.id_estado%TYPE
    );
    TYPE t_eventos IS TABLE OF t_evento INDEX BY PLS_INTEGER;
    TYPE t_guias IS TABLE OF PLS_INTEGER INDEX BY VARCHAR2(15);
    g_nuevos t_eventos;
    g_guias  t_guias;

    FUNCTION es_final(p_estado IN VARCHAR2) RETURN BOOLEAN IS
    BEGIN
        RETURN p_estado IN ('ENTREGADO', 'DEVUELTO', 'ANULADO');
    END es_final;

    -- Transiciones permitidas (p_anterior NULL = primer evento de la guia)
    FUNCTION permitida(p_anterior IN VARCHAR2, p_nuevo IN VARCHAR2) RETURN BOOLEAN IS
    BEGIN
        RETURN CASE
            WHEN p_anterior IS NULL          THEN p_nuevo = 'REGISTRADO'
            WHEN p_anterior = 'REGISTRADO'   THEN p_nuevo IN ('RECOLECTADO', 'ANULADO')
            WHEN p_anterior = 'RECOLECTADO'  THEN p_nuevo IN ('EN_CENTRO', 'ANULADO')
            WHEN p_anterior = 'EN_CENTRO'    THEN p_nuevo IN ('CLASIFICADO', 'ANULADO')
            WHEN p_anterior = 'CLASIFICADO'  THEN p_nuevo IN ('EN_RUTA', 'ANULADO')
            WHEN p_anterior = 'EN_RUTA'      THEN p_nuevo IN ('ENTREGADO', 'CON_NOVEDAD', 'DEVUELTO')
            WHEN p_anterior = 'CON_NOVEDAD'  THEN p_nuevo = 'EN_RUTA'
            ELSE FALSE
        END;
    END permitida;

    AFTER EACH ROW IS
    BEGIN
        g_nuevos(g_nuevos.COUNT + 1).numero_guia := :NEW.numero_guia;
        g_nuevos(g_nuevos.COUNT).id_estado := :NEW.id_estado;
        g_guias(:NEW.numero_guia) := 1;
    END AFTER EACH ROW;

    AFTER STATEMENT IS
        v_guia   VARCHAR2(15);
        v_nombre estado_envio.nombre%TYPE;
        v_existe NUMBER;
    BEGIN
        -- RN12: secuencia completa de cada guia afectada
        v_guia := g_guias.FIRST;
        WHILE v_guia IS NOT NULL LOOP
            FOR r IN (SELECT es.nombre AS estado,
                             LAG(es.nombre) OVER (ORDER BY ev.fecha_hora) AS anterior
                      FROM   evento_envio ev
                      JOIN   estado_envio es ON es.id_estado = ev.id_estado
                      WHERE  ev.numero_guia = v_guia
                      ORDER  BY ev.fecha_hora) LOOP
                IF NOT permitida(r.anterior, r.estado) THEN
                    IF r.anterior IS NULL THEN
                        pkg_errores.lanzar(pkg_errores.c_rn12,
                            'RN12: el primer evento de la guía ' || v_guia
                            || ' debe ser REGISTRADO, no ' || r.estado);
                    ELSIF es_final(r.anterior) THEN
                        pkg_errores.lanzar(pkg_errores.c_rn12,
                            'RN12: la guía ' || v_guia || ' ya está en un estado final ('
                            || r.anterior || ') y no admite el evento ' || r.estado);
                    ELSE
                        pkg_errores.lanzar(pkg_errores.c_rn12,
                            'RN12: transición no permitida de ' || r.anterior || ' a '
                            || r.estado || ' en la guía ' || v_guia);
                    END IF;
                END IF;
            END LOOP;
            v_guia := g_guias.NEXT(v_guia);
        END LOOP;

        -- RN05: ENTREGADO o DEVUELTO exigen una asignacion con ese resultado
        FOR i IN 1 .. g_nuevos.COUNT LOOP
            SELECT nombre INTO v_nombre FROM estado_envio WHERE id_estado = g_nuevos(i).id_estado;
            IF v_nombre IN ('ENTREGADO', 'DEVUELTO') THEN
                SELECT COUNT(*) INTO v_existe
                FROM   asignacion_despacho
                WHERE  numero_guia = g_nuevos(i).numero_guia AND resultado = v_nombre;
                IF v_existe = 0 THEN
                    pkg_errores.lanzar(pkg_errores.c_rn05,
                        'RN05: la guía ' || g_nuevos(i).numero_guia || ' no puede pasar a '
                        || v_nombre || ' sin una asignación con resultado ' || v_nombre
                        || ' y su prueba de entrega');
                END IF;
            END IF;
        END LOOP;
    END AFTER STATEMENT;
END trg_evento_transicion;
/
