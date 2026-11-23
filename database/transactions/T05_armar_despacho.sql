-- T05. Armar el despacho de entrega
-- Usuario: U2 (cuenta svc_centro). Reglas verificadas: RN07, RN09 a RN12.
-- Cada caso es una transaccion: SELECT ... FOR UPDATE de la fila cuyo estado
-- cambia (decision C4), las operaciones en el orden de la tabla de
-- transacciones del capitulo 6 y un unico COMMIT al final; ante cualquier error
-- se hace ROLLBACK. Los casos rechazados comprueban ademas que no quedo nada
-- (la "medida" es la misma antes y despues). Los eventos del mismo envio usan
-- instantes distintos (C5): el siguiente al ultimo evento de la guia.
-- Se ejecuta en cadena (T01 a T12) sobre la base recien instalada:
--   database/transactions/run-transactions.sh
WHENEVER SQLERROR EXIT FAILURE
SET DEFINE OFF
SET LINESIZE 600
SET SERVEROUTPUT ON SIZE UNLIMITED FORMAT TRUNCATED
PROMPT
PROMPT ===== T05 | valido | armar el despacho de entrega con los 3 envios clasificados
DECLARE
    v_antes   NUMBER;
    v_despues NUMBER;
    v_cod     NUMBER := 0;
    v_msg     VARCHAR2(400);
    v_info_a  VARCHAR2(400);
    v_info_d  VARCHAR2(400);
    v_ok      BOOLEAN;
    v_t       TIMESTAMP;
    TYPE t_guias IS TABLE OF envio.numero_guia%TYPE;
    v_g t_guias;
    v_sol NUMBER;
    v_d NUMBER;
    v_x NUMBER;
    -- C5: instante estrictamente posterior al ultimo evento de la guia (y a la hora actual)
    FUNCTION instante(p_guia IN VARCHAR2) RETURN TIMESTAMP IS
        v_i TIMESTAMP;
    BEGIN
        SELECT GREATEST(LOCALTIMESTAMP, NVL(MAX(fecha_hora), LOCALTIMESTAMP) + INTERVAL '1' SECOND)
        INTO   v_i FROM evento_envio WHERE numero_guia = p_guia;
        RETURN v_i;
    END instante;
BEGIN
    SELECT MAX(id_solicitud) INTO v_sol FROM solicitud_recoleccion WHERE fecha_programada > DATE '2026-11-20';
    SELECT numero_guia BULK COLLECT INTO v_g FROM envio WHERE id_solicitud = v_sol ORDER BY numero_guia;
    SELECT (SELECT COUNT(*) FROM despacho) + (SELECT COUNT(*) FROM asignacion_despacho) + (SELECT COUNT(*) FROM evento_envio WHERE id_estado = 5) INTO v_antes FROM dual;
    SELECT (SELECT LISTAGG(es.nombre, ' > ') WITHIN GROUP (ORDER BY ev.fecha_hora) FROM evento_envio ev JOIN estado_envio es ON es.id_estado = ev.id_estado WHERE ev.numero_guia = v_g(1)) INTO v_info_a FROM dual;
    -- inicio de la transaccion
    BEGIN
        FOR i IN 1 .. v_g.COUNT LOOP
            SELECT 1 INTO v_x FROM envio WHERE numero_guia = v_g(i) FOR UPDATE;
        END LOOP;
        INSERT INTO despacho (id_centro, id_vehiculo, id_mensajero, fecha, tipo, hora_salida, estado)
        VALUES (1, 1, 7, TRUNC(SYSDATE), 'ENTREGA', LOCALTIMESTAMP, 'EN_RUTA')
        RETURNING id_despacho INTO v_d;
        FOR i IN 1 .. v_g.COUNT LOOP
            INSERT INTO asignacion_despacho (numero_guia, id_despacho, numero_intento, orden_visita)
            VALUES (v_g(i), v_d, 1, i);
            v_t := instante(v_g(i));
            INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion)
            VALUES (v_g(i), 5, 7, v_t, 'Sale en el despacho de entrega');  -- EN_RUTA
        END LOOP;
        DBMS_OUTPUT.PUT_LINE('  despacho creado: ' || v_d);
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            v_cod := SQLCODE;
            v_msg := SUBSTR(SQLERRM, 1, 300);
            ROLLBACK;
    END;
    SELECT (SELECT COUNT(*) FROM despacho) + (SELECT COUNT(*) FROM asignacion_despacho) + (SELECT COUNT(*) FROM evento_envio WHERE id_estado = 5) INTO v_despues FROM dual;
    SELECT (SELECT LISTAGG(es.nombre, ' > ') WITHIN GROUP (ORDER BY ev.fecha_hora) FROM evento_envio ev JOIN estado_envio es ON es.id_estado = ev.id_estado WHERE ev.numero_guia = v_g(1)) INTO v_info_d FROM dual;
    DBMS_OUTPUT.PUT_LINE('  Antes:   ' || v_info_a);
    DBMS_OUTPUT.PUT_LINE('  Despues: ' || v_info_d);
    IF v_cod <> 0 THEN
        DBMS_OUTPUT.PUT_LINE('  Error:   ' || v_msg);
    END IF;
    v_ok := v_cod = 0 AND v_despues - v_antes = 7;
    DBMS_OUTPUT.PUT_LINE('RESULTADO|T05|valido|armar el despacho de entrega con los 3 envios clasificados|' || 'COMMIT; medida +7' || '|' || CASE WHEN v_cod = 0 THEN 'COMMIT; medida ' || TO_CHAR(v_despues - v_antes, 'FMS99') ELSE 'ORA' || TO_CHAR(v_cod, 'FM00000') END || '|' || CASE WHEN v_ok THEN 'OK' ELSE 'FALLA' END);
END;
/

PROMPT
PROMPT ===== T05 | rechazado | vehiculo EN_MANTENIMIENTO
DECLARE
    v_antes   NUMBER;
    v_despues NUMBER;
    v_cod     NUMBER := 0;
    v_msg     VARCHAR2(400);
    v_info_a  VARCHAR2(400);
    v_info_d  VARCHAR2(400);
    v_ok      BOOLEAN;
    v_t       TIMESTAMP;
    TYPE t_guias IS TABLE OF envio.numero_guia%TYPE;
    v_g t_guias;
    v_sol NUMBER;
    v_d NUMBER;
    v_x NUMBER;
    -- C5: instante estrictamente posterior al ultimo evento de la guia (y a la hora actual)
    FUNCTION instante(p_guia IN VARCHAR2) RETURN TIMESTAMP IS
        v_i TIMESTAMP;
    BEGIN
        SELECT GREATEST(LOCALTIMESTAMP, NVL(MAX(fecha_hora), LOCALTIMESTAMP) + INTERVAL '1' SECOND)
        INTO   v_i FROM evento_envio WHERE numero_guia = p_guia;
        RETURN v_i;
    END instante;
BEGIN
    SELECT 1 INTO v_x FROM dual;
    SELECT (SELECT COUNT(*) FROM despacho) + (SELECT COUNT(*) FROM asignacion_despacho) + (SELECT COUNT(*) FROM evento_envio WHERE id_estado = 5) INTO v_antes FROM dual;
    SELECT (SELECT LISTAGG(es.nombre, ' > ') WITHIN GROUP (ORDER BY ev.fecha_hora) FROM evento_envio ev JOIN estado_envio es ON es.id_estado = ev.id_estado WHERE ev.numero_guia = 'EE0000000000025') INTO v_info_a FROM dual;
    -- inicio de la transaccion
    BEGIN
        SELECT 1 INTO v_x FROM envio WHERE numero_guia = 'EE0000000000025' FOR UPDATE;
        INSERT INTO despacho (id_centro, id_vehiculo, id_mensajero, fecha, tipo, hora_salida, estado)
        VALUES (1, 3, 7, TRUNC(SYSDATE), 'ENTREGA', LOCALTIMESTAMP, 'EN_RUTA')
        RETURNING id_despacho INTO v_d;
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            v_cod := SQLCODE;
            v_msg := SUBSTR(SQLERRM, 1, 300);
            ROLLBACK;
    END;
    SELECT (SELECT COUNT(*) FROM despacho) + (SELECT COUNT(*) FROM asignacion_despacho) + (SELECT COUNT(*) FROM evento_envio WHERE id_estado = 5) INTO v_despues FROM dual;
    SELECT (SELECT LISTAGG(es.nombre, ' > ') WITHIN GROUP (ORDER BY ev.fecha_hora) FROM evento_envio ev JOIN estado_envio es ON es.id_estado = ev.id_estado WHERE ev.numero_guia = 'EE0000000000025') INTO v_info_d FROM dual;
    DBMS_OUTPUT.PUT_LINE('  Antes:   ' || v_info_a);
    DBMS_OUTPUT.PUT_LINE('  Despues: ' || v_info_d);
    IF v_cod <> 0 THEN
        DBMS_OUTPUT.PUT_LINE('  Error:   ' || v_msg);
    END IF;
    v_ok := v_cod IN (-20010) AND v_despues = v_antes AND INSTR(v_msg, 'RN10') > 0;
    DBMS_OUTPUT.PUT_LINE('RESULTADO|T05|rechazado|vehiculo EN_MANTENIMIENTO|' || 'ORA-20010 (RN10); ROLLBACK, medida sin cambio' || '|' || CASE WHEN v_cod = 0 THEN 'sin error' ELSE 'ORA' || TO_CHAR(v_cod, 'FM00000') END || '; medida ' || v_antes || ' -> ' || v_despues || '|' || CASE WHEN v_ok THEN 'OK' ELSE 'FALLA' END);
END;
/

PROMPT
PROMPT ===== T05 | rechazado | mensajero RETIRADO
DECLARE
    v_antes   NUMBER;
    v_despues NUMBER;
    v_cod     NUMBER := 0;
    v_msg     VARCHAR2(400);
    v_info_a  VARCHAR2(400);
    v_info_d  VARCHAR2(400);
    v_ok      BOOLEAN;
    v_t       TIMESTAMP;
    v_d NUMBER;
    v_x NUMBER;
    -- C5: instante estrictamente posterior al ultimo evento de la guia (y a la hora actual)
    FUNCTION instante(p_guia IN VARCHAR2) RETURN TIMESTAMP IS
        v_i TIMESTAMP;
    BEGIN
        SELECT GREATEST(LOCALTIMESTAMP, NVL(MAX(fecha_hora), LOCALTIMESTAMP) + INTERVAL '1' SECOND)
        INTO   v_i FROM evento_envio WHERE numero_guia = p_guia;
        RETURN v_i;
    END instante;
BEGIN
    SELECT (SELECT COUNT(*) FROM despacho) + (SELECT COUNT(*) FROM asignacion_despacho) + (SELECT COUNT(*) FROM evento_envio WHERE id_estado = 5) INTO v_antes FROM dual;
    SELECT (SELECT LISTAGG(es.nombre, ' > ') WITHIN GROUP (ORDER BY ev.fecha_hora) FROM evento_envio ev JOIN estado_envio es ON es.id_estado = ev.id_estado WHERE ev.numero_guia = 'EE0000000000025') INTO v_info_a FROM dual;
    -- inicio de la transaccion
    BEGIN
        SELECT 1 INTO v_x FROM envio WHERE numero_guia = 'EE0000000000025' FOR UPDATE;
        INSERT INTO despacho (id_centro, id_vehiculo, id_mensajero, fecha, tipo, hora_salida, estado)
        VALUES (1, 1, 12, TRUNC(SYSDATE), 'ENTREGA', LOCALTIMESTAMP, 'EN_RUTA')
        RETURNING id_despacho INTO v_d;
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            v_cod := SQLCODE;
            v_msg := SUBSTR(SQLERRM, 1, 300);
            ROLLBACK;
    END;
    SELECT (SELECT COUNT(*) FROM despacho) + (SELECT COUNT(*) FROM asignacion_despacho) + (SELECT COUNT(*) FROM evento_envio WHERE id_estado = 5) INTO v_despues FROM dual;
    SELECT (SELECT LISTAGG(es.nombre, ' > ') WITHIN GROUP (ORDER BY ev.fecha_hora) FROM evento_envio ev JOIN estado_envio es ON es.id_estado = ev.id_estado WHERE ev.numero_guia = 'EE0000000000025') INTO v_info_d FROM dual;
    DBMS_OUTPUT.PUT_LINE('  Antes:   ' || v_info_a);
    DBMS_OUTPUT.PUT_LINE('  Despues: ' || v_info_d);
    IF v_cod <> 0 THEN
        DBMS_OUTPUT.PUT_LINE('  Error:   ' || v_msg);
    END IF;
    v_ok := v_cod IN (-20010) AND v_despues = v_antes AND INSTR(v_msg, 'RN10') > 0;
    DBMS_OUTPUT.PUT_LINE('RESULTADO|T05|rechazado|mensajero RETIRADO|' || 'ORA-20010 (RN10); ROLLBACK, medida sin cambio' || '|' || CASE WHEN v_cod = 0 THEN 'sin error' ELSE 'ORA' || TO_CHAR(v_cod, 'FM00000') END || '; medida ' || v_antes || ' -> ' || v_despues || '|' || CASE WHEN v_ok THEN 'OK' ELSE 'FALLA' END);
END;
/

PROMPT
PROMPT ===== T05 | rechazado | vehiculo de otro tipo que el del mensajero (furgoneta con motociclista)
DECLARE
    v_antes   NUMBER;
    v_despues NUMBER;
    v_cod     NUMBER := 0;
    v_msg     VARCHAR2(400);
    v_info_a  VARCHAR2(400);
    v_info_d  VARCHAR2(400);
    v_ok      BOOLEAN;
    v_t       TIMESTAMP;
    v_d NUMBER;
    v_x NUMBER;
    -- C5: instante estrictamente posterior al ultimo evento de la guia (y a la hora actual)
    FUNCTION instante(p_guia IN VARCHAR2) RETURN TIMESTAMP IS
        v_i TIMESTAMP;
    BEGIN
        SELECT GREATEST(LOCALTIMESTAMP, NVL(MAX(fecha_hora), LOCALTIMESTAMP) + INTERVAL '1' SECOND)
        INTO   v_i FROM evento_envio WHERE numero_guia = p_guia;
        RETURN v_i;
    END instante;
BEGIN
    SELECT (SELECT COUNT(*) FROM despacho) + (SELECT COUNT(*) FROM asignacion_despacho) + (SELECT COUNT(*) FROM evento_envio WHERE id_estado = 5) INTO v_antes FROM dual;
    SELECT (SELECT LISTAGG(es.nombre, ' > ') WITHIN GROUP (ORDER BY ev.fecha_hora) FROM evento_envio ev JOIN estado_envio es ON es.id_estado = ev.id_estado WHERE ev.numero_guia = 'EE0000000000025') INTO v_info_a FROM dual;
    -- inicio de la transaccion
    BEGIN
        SELECT 1 INTO v_x FROM envio WHERE numero_guia = 'EE0000000000025' FOR UPDATE;
        INSERT INTO despacho (id_centro, id_vehiculo, id_mensajero, fecha, tipo, hora_salida, estado)
        VALUES (1, 6, 7, TRUNC(SYSDATE), 'ENTREGA', LOCALTIMESTAMP, 'EN_RUTA')
        RETURNING id_despacho INTO v_d;
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            v_cod := SQLCODE;
            v_msg := SUBSTR(SQLERRM, 1, 300);
            ROLLBACK;
    END;
    SELECT (SELECT COUNT(*) FROM despacho) + (SELECT COUNT(*) FROM asignacion_despacho) + (SELECT COUNT(*) FROM evento_envio WHERE id_estado = 5) INTO v_despues FROM dual;
    SELECT (SELECT LISTAGG(es.nombre, ' > ') WITHIN GROUP (ORDER BY ev.fecha_hora) FROM evento_envio ev JOIN estado_envio es ON es.id_estado = ev.id_estado WHERE ev.numero_guia = 'EE0000000000025') INTO v_info_d FROM dual;
    DBMS_OUTPUT.PUT_LINE('  Antes:   ' || v_info_a);
    DBMS_OUTPUT.PUT_LINE('  Despues: ' || v_info_d);
    IF v_cod <> 0 THEN
        DBMS_OUTPUT.PUT_LINE('  Error:   ' || v_msg);
    END IF;
    v_ok := v_cod IN (-20011) AND v_despues = v_antes AND INSTR(v_msg, 'RN11') > 0;
    DBMS_OUTPUT.PUT_LINE('RESULTADO|T05|rechazado|vehiculo de otro tipo que el del mensajero (furgoneta con motociclista)|' || 'ORA-20011 (RN11); ROLLBACK, medida sin cambio' || '|' || CASE WHEN v_cod = 0 THEN 'sin error' ELSE 'ORA' || TO_CHAR(v_cod, 'FM00000') END || '; medida ' || v_antes || ' -> ' || v_despues || '|' || CASE WHEN v_ok THEN 'OK' ELSE 'FALLA' END);
END;
/

PROMPT
PROMPT ===== T05 | rechazado | intento 2 de un envio cuyo intento 1 sigue PENDIENTE, tras armar el despacho
DECLARE
    v_antes   NUMBER;
    v_despues NUMBER;
    v_cod     NUMBER := 0;
    v_msg     VARCHAR2(400);
    v_info_a  VARCHAR2(400);
    v_info_d  VARCHAR2(400);
    v_ok      BOOLEAN;
    v_t       TIMESTAMP;
    v_d NUMBER;
    v_x NUMBER;
    -- C5: instante estrictamente posterior al ultimo evento de la guia (y a la hora actual)
    FUNCTION instante(p_guia IN VARCHAR2) RETURN TIMESTAMP IS
        v_i TIMESTAMP;
    BEGIN
        SELECT GREATEST(LOCALTIMESTAMP, NVL(MAX(fecha_hora), LOCALTIMESTAMP) + INTERVAL '1' SECOND)
        INTO   v_i FROM evento_envio WHERE numero_guia = p_guia;
        RETURN v_i;
    END instante;
BEGIN
    SELECT (SELECT COUNT(*) FROM despacho) + (SELECT COUNT(*) FROM asignacion_despacho) + (SELECT COUNT(*) FROM evento_envio WHERE id_estado = 5) INTO v_antes FROM dual;
    SELECT (SELECT LISTAGG(es.nombre, ' > ') WITHIN GROUP (ORDER BY ev.fecha_hora) FROM evento_envio ev JOIN estado_envio es ON es.id_estado = ev.id_estado WHERE ev.numero_guia = 'EE0000000000025') INTO v_info_a FROM dual;
    -- inicio de la transaccion
    BEGIN
        SELECT 1 INTO v_x FROM envio WHERE numero_guia = 'EE0000000000025' FOR UPDATE;
        SELECT 1 INTO v_x FROM envio WHERE numero_guia = 'EE0000000000023' FOR UPDATE;
        INSERT INTO despacho (id_centro, id_vehiculo, id_mensajero, fecha, tipo, hora_salida, estado)
        VALUES (1, 1, 7, TRUNC(SYSDATE), 'ENTREGA', LOCALTIMESTAMP, 'EN_RUTA')
        RETURNING id_despacho INTO v_d;
        INSERT INTO asignacion_despacho (numero_guia, id_despacho, numero_intento, orden_visita)
        VALUES ('EE0000000000025', v_d, 1, 1);
        v_t := instante('EE0000000000025');
        INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion)
        VALUES ('EE0000000000025', 5, 7, v_t, 'Sale en el despacho');  -- EN_RUTA
        INSERT INTO asignacion_despacho (numero_guia, id_despacho, numero_intento, orden_visita)
        VALUES ('EE0000000000023', v_d, 2, 2);  -- ya esta en el despacho 15, abierto
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            v_cod := SQLCODE;
            v_msg := SUBSTR(SQLERRM, 1, 300);
            ROLLBACK;
    END;
    SELECT (SELECT COUNT(*) FROM despacho) + (SELECT COUNT(*) FROM asignacion_despacho) + (SELECT COUNT(*) FROM evento_envio WHERE id_estado = 5) INTO v_despues FROM dual;
    SELECT (SELECT LISTAGG(es.nombre, ' > ') WITHIN GROUP (ORDER BY ev.fecha_hora) FROM evento_envio ev JOIN estado_envio es ON es.id_estado = ev.id_estado WHERE ev.numero_guia = 'EE0000000000025') INTO v_info_d FROM dual;
    DBMS_OUTPUT.PUT_LINE('  Antes:   ' || v_info_a);
    DBMS_OUTPUT.PUT_LINE('  Despues: ' || v_info_d);
    IF v_cod <> 0 THEN
        DBMS_OUTPUT.PUT_LINE('  Error:   ' || v_msg);
    END IF;
    v_ok := v_cod IN (-20007) AND v_despues = v_antes AND INSTR(v_msg, 'RN07') > 0;
    DBMS_OUTPUT.PUT_LINE('RESULTADO|T05|rechazado|intento 2 de un envio cuyo intento 1 sigue PENDIENTE, tras armar el despacho|' || 'ORA-20007 (RN07); ROLLBACK, medida sin cambio' || '|' || CASE WHEN v_cod = 0 THEN 'sin error' ELSE 'ORA' || TO_CHAR(v_cod, 'FM00000') END || '; medida ' || v_antes || ' -> ' || v_despues || '|' || CASE WHEN v_ok THEN 'OK' ELSE 'FALLA' END);
END;
/

PROMPT
PROMPT ===== T05 | rechazado | EN_RUTA sobre un envio REGISTRADO (no clasificado), tras crear despacho y asignacion
DECLARE
    v_antes   NUMBER;
    v_despues NUMBER;
    v_cod     NUMBER := 0;
    v_msg     VARCHAR2(400);
    v_info_a  VARCHAR2(400);
    v_info_d  VARCHAR2(400);
    v_ok      BOOLEAN;
    v_t       TIMESTAMP;
    v_d NUMBER;
    v_x NUMBER;
    -- C5: instante estrictamente posterior al ultimo evento de la guia (y a la hora actual)
    FUNCTION instante(p_guia IN VARCHAR2) RETURN TIMESTAMP IS
        v_i TIMESTAMP;
    BEGIN
        SELECT GREATEST(LOCALTIMESTAMP, NVL(MAX(fecha_hora), LOCALTIMESTAMP) + INTERVAL '1' SECOND)
        INTO   v_i FROM evento_envio WHERE numero_guia = p_guia;
        RETURN v_i;
    END instante;
BEGIN
    SELECT (SELECT COUNT(*) FROM despacho) + (SELECT COUNT(*) FROM asignacion_despacho) + (SELECT COUNT(*) FROM evento_envio WHERE id_estado = 5) INTO v_antes FROM dual;
    SELECT (SELECT LISTAGG(es.nombre, ' > ') WITHIN GROUP (ORDER BY ev.fecha_hora) FROM evento_envio ev JOIN estado_envio es ON es.id_estado = ev.id_estado WHERE ev.numero_guia = 'EE0000000000029') INTO v_info_a FROM dual;
    -- inicio de la transaccion
    BEGIN
        SELECT 1 INTO v_x FROM envio WHERE numero_guia = 'EE0000000000029' FOR UPDATE;
        INSERT INTO despacho (id_centro, id_vehiculo, id_mensajero, fecha, tipo, hora_salida, estado)
        VALUES (1, 1, 7, TRUNC(SYSDATE), 'ENTREGA', LOCALTIMESTAMP, 'EN_RUTA')
        RETURNING id_despacho INTO v_d;
        INSERT INTO asignacion_despacho (numero_guia, id_despacho, numero_intento, orden_visita)
        VALUES ('EE0000000000029', v_d, 1, 1);
        v_t := instante('EE0000000000029');
        INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion)
        VALUES ('EE0000000000029', 5, 7, v_t, 'Salida indebida');  -- EN_RUTA
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            v_cod := SQLCODE;
            v_msg := SUBSTR(SQLERRM, 1, 300);
            ROLLBACK;
    END;
    SELECT (SELECT COUNT(*) FROM despacho) + (SELECT COUNT(*) FROM asignacion_despacho) + (SELECT COUNT(*) FROM evento_envio WHERE id_estado = 5) INTO v_despues FROM dual;
    SELECT (SELECT LISTAGG(es.nombre, ' > ') WITHIN GROUP (ORDER BY ev.fecha_hora) FROM evento_envio ev JOIN estado_envio es ON es.id_estado = ev.id_estado WHERE ev.numero_guia = 'EE0000000000029') INTO v_info_d FROM dual;
    DBMS_OUTPUT.PUT_LINE('  Antes:   ' || v_info_a);
    DBMS_OUTPUT.PUT_LINE('  Despues: ' || v_info_d);
    IF v_cod <> 0 THEN
        DBMS_OUTPUT.PUT_LINE('  Error:   ' || v_msg);
    END IF;
    v_ok := v_cod IN (-20012) AND v_despues = v_antes AND INSTR(v_msg, 'RN12') > 0;
    DBMS_OUTPUT.PUT_LINE('RESULTADO|T05|rechazado|EN_RUTA sobre un envio REGISTRADO (no clasificado), tras crear despacho y asignacion|' || 'ORA-20012 (RN12); ROLLBACK, medida sin cambio' || '|' || CASE WHEN v_cod = 0 THEN 'sin error' ELSE 'ORA' || TO_CHAR(v_cod, 'FM00000') END || '; medida ' || v_antes || ' -> ' || v_despues || '|' || CASE WHEN v_ok THEN 'OK' ELSE 'FALLA' END);
END;
/
