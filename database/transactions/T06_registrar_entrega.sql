-- T06. Registrar una entrega
-- Usuario: U4 (cuenta svc_mensajero). Reglas verificadas: RN05, RN06, RN08, RN12.
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
PROMPT ===== T06 | valido | entrega del envio A: prueba, resultado ENTREGADO y evento
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
    v_a NUMBER;
    v_mens NUMBER;
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
    SELECT a.id_asignacion, d.id_mensajero INTO v_a, v_mens
    FROM   asignacion_despacho a JOIN despacho d ON d.id_despacho = a.id_despacho
    WHERE  a.numero_guia = v_g(1) AND a.numero_intento = 1;
    SELECT (SELECT COUNT(*) FROM prueba_entrega) + (SELECT COUNT(*) FROM asignacion_despacho WHERE resultado = 'ENTREGADO') + (SELECT COUNT(*) FROM evento_envio WHERE id_estado = 6) INTO v_antes FROM dual;
    SELECT (SELECT resultado FROM asignacion_despacho WHERE id_asignacion = v_a) || ' / ' || (SELECT LISTAGG(ev.id_estado, '>') WITHIN GROUP (ORDER BY ev.fecha_hora) FROM evento_envio ev WHERE ev.numero_guia = v_g(1)) INTO v_info_a FROM dual;
    -- inicio de la transaccion
    BEGIN
        SELECT id_asignacion INTO v_x FROM asignacion_despacho WHERE id_asignacion = v_a FOR UPDATE;
        INSERT INTO prueba_entrega (id_asignacion, fecha_hora, nombre_receptor, documento_receptor, tipo_prueba)
        VALUES (v_a, LOCALTIMESTAMP, 'Recepcion del edificio', 'TX-REC-1', 'DOCUMENTO');
        UPDATE asignacion_despacho SET resultado = 'ENTREGADO', hora_visita = LOCALTIMESTAMP WHERE id_asignacion = v_a;
        v_t := instante(v_g(1));
        INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion)
        VALUES (v_g(1), 6, v_mens, v_t, 'Entregado a la recepcion');  -- ENTREGADO
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            v_cod := SQLCODE;
            v_msg := SUBSTR(SQLERRM, 1, 300);
            ROLLBACK;
    END;
    SELECT (SELECT COUNT(*) FROM prueba_entrega) + (SELECT COUNT(*) FROM asignacion_despacho WHERE resultado = 'ENTREGADO') + (SELECT COUNT(*) FROM evento_envio WHERE id_estado = 6) INTO v_despues FROM dual;
    SELECT (SELECT resultado FROM asignacion_despacho WHERE id_asignacion = v_a) || ' / ' || (SELECT LISTAGG(ev.id_estado, '>') WITHIN GROUP (ORDER BY ev.fecha_hora) FROM evento_envio ev WHERE ev.numero_guia = v_g(1)) INTO v_info_d FROM dual;
    DBMS_OUTPUT.PUT_LINE('  Antes:   ' || v_info_a);
    DBMS_OUTPUT.PUT_LINE('  Despues: ' || v_info_d);
    IF v_cod <> 0 THEN
        DBMS_OUTPUT.PUT_LINE('  Error:   ' || v_msg);
    END IF;
    v_ok := v_cod = 0 AND v_despues - v_antes = 3;
    DBMS_OUTPUT.PUT_LINE('RESULTADO|T06|valido|entrega del envio A: prueba, resultado ENTREGADO y evento|' || 'COMMIT; medida +3' || '|' || CASE WHEN v_cod = 0 THEN 'COMMIT; medida ' || TO_CHAR(v_despues - v_antes, 'FMS99') ELSE 'ORA' || TO_CHAR(v_cod, 'FM00000') END || '|' || CASE WHEN v_ok THEN 'OK' ELSE 'FALLA' END);
END;
/

PROMPT
PROMPT ===== T06 | rechazado | envio B fragil con documento distinto al del destinatario
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
    v_a NUMBER;
    v_mens NUMBER;
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
    SELECT a.id_asignacion, d.id_mensajero INTO v_a, v_mens
    FROM   asignacion_despacho a JOIN despacho d ON d.id_despacho = a.id_despacho
    WHERE  a.numero_guia = v_g(2) AND a.numero_intento = 1;
    SELECT (SELECT COUNT(*) FROM prueba_entrega) + (SELECT COUNT(*) FROM asignacion_despacho WHERE resultado = 'ENTREGADO') + (SELECT COUNT(*) FROM evento_envio WHERE id_estado = 6) + (SELECT COUNT(*) FROM asignacion_despacho WHERE hora_visita IS NOT NULL) INTO v_antes FROM dual;
    SELECT (SELECT resultado FROM asignacion_despacho WHERE id_asignacion = v_a) || ' / ' || (SELECT LISTAGG(ev.id_estado, '>') WITHIN GROUP (ORDER BY ev.fecha_hora) FROM evento_envio ev WHERE ev.numero_guia = v_g(2)) INTO v_info_a FROM dual;
    -- inicio de la transaccion
    BEGIN
        SELECT id_asignacion INTO v_x FROM asignacion_despacho WHERE id_asignacion = v_a FOR UPDATE;
        UPDATE asignacion_despacho SET hora_visita = LOCALTIMESTAMP WHERE id_asignacion = v_a;
        INSERT INTO prueba_entrega (id_asignacion, fecha_hora, nombre_receptor, documento_receptor, tipo_prueba)
        VALUES (v_a, LOCALTIMESTAMP, 'Vecino', 'TX-OTRO-9', 'DOCUMENTO');
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            v_cod := SQLCODE;
            v_msg := SUBSTR(SQLERRM, 1, 300);
            ROLLBACK;
    END;
    SELECT (SELECT COUNT(*) FROM prueba_entrega) + (SELECT COUNT(*) FROM asignacion_despacho WHERE resultado = 'ENTREGADO') + (SELECT COUNT(*) FROM evento_envio WHERE id_estado = 6) + (SELECT COUNT(*) FROM asignacion_despacho WHERE hora_visita IS NOT NULL) INTO v_despues FROM dual;
    SELECT (SELECT resultado FROM asignacion_despacho WHERE id_asignacion = v_a) || ' / ' || (SELECT LISTAGG(ev.id_estado, '>') WITHIN GROUP (ORDER BY ev.fecha_hora) FROM evento_envio ev WHERE ev.numero_guia = v_g(2)) INTO v_info_d FROM dual;
    DBMS_OUTPUT.PUT_LINE('  Antes:   ' || v_info_a);
    DBMS_OUTPUT.PUT_LINE('  Despues: ' || v_info_d);
    IF v_cod <> 0 THEN
        DBMS_OUTPUT.PUT_LINE('  Error:   ' || v_msg);
    END IF;
    v_ok := v_cod IN (-20006) AND v_despues = v_antes AND INSTR(v_msg, 'RN06') > 0;
    DBMS_OUTPUT.PUT_LINE('RESULTADO|T06|rechazado|envio B fragil con documento distinto al del destinatario|' || 'ORA-20006 (RN06); ROLLBACK, medida sin cambio' || '|' || CASE WHEN v_cod = 0 THEN 'sin error' ELSE 'ORA' || TO_CHAR(v_cod, 'FM00000') END || '; medida ' || v_antes || ' -> ' || v_despues || '|' || CASE WHEN v_ok THEN 'OK' ELSE 'FALLA' END);
END;
/

PROMPT
PROMPT ===== T06 | valido | entrega del envio B fragil al propio destinatario
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
    v_a NUMBER;
    v_mens NUMBER;
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
    SELECT a.id_asignacion, d.id_mensajero INTO v_a, v_mens
    FROM   asignacion_despacho a JOIN despacho d ON d.id_despacho = a.id_despacho
    WHERE  a.numero_guia = v_g(2) AND a.numero_intento = 1;
    SELECT (SELECT COUNT(*) FROM prueba_entrega) + (SELECT COUNT(*) FROM asignacion_despacho WHERE resultado = 'ENTREGADO') + (SELECT COUNT(*) FROM evento_envio WHERE id_estado = 6) INTO v_antes FROM dual;
    SELECT (SELECT resultado FROM asignacion_despacho WHERE id_asignacion = v_a) || ' / ' || (SELECT LISTAGG(ev.id_estado, '>') WITHIN GROUP (ORDER BY ev.fecha_hora) FROM evento_envio ev WHERE ev.numero_guia = v_g(2)) INTO v_info_a FROM dual;
    -- inicio de la transaccion
    BEGIN
        SELECT id_asignacion INTO v_x FROM asignacion_despacho WHERE id_asignacion = v_a FOR UPDATE;
        INSERT INTO prueba_entrega (id_asignacion, fecha_hora, nombre_receptor, documento_receptor, tipo_prueba)
        VALUES (v_a, LOCALTIMESTAMP, 'Bruno Prueba', 'TX-1002', 'FIRMA');
        UPDATE asignacion_despacho SET resultado = 'ENTREGADO', hora_visita = LOCALTIMESTAMP WHERE id_asignacion = v_a;
        v_t := instante(v_g(2));
        INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion)
        VALUES (v_g(2), 6, v_mens, v_t, 'Entregado al destinatario');  -- ENTREGADO
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            v_cod := SQLCODE;
            v_msg := SUBSTR(SQLERRM, 1, 300);
            ROLLBACK;
    END;
    SELECT (SELECT COUNT(*) FROM prueba_entrega) + (SELECT COUNT(*) FROM asignacion_despacho WHERE resultado = 'ENTREGADO') + (SELECT COUNT(*) FROM evento_envio WHERE id_estado = 6) INTO v_despues FROM dual;
    SELECT (SELECT resultado FROM asignacion_despacho WHERE id_asignacion = v_a) || ' / ' || (SELECT LISTAGG(ev.id_estado, '>') WITHIN GROUP (ORDER BY ev.fecha_hora) FROM evento_envio ev WHERE ev.numero_guia = v_g(2)) INTO v_info_d FROM dual;
    DBMS_OUTPUT.PUT_LINE('  Antes:   ' || v_info_a);
    DBMS_OUTPUT.PUT_LINE('  Despues: ' || v_info_d);
    IF v_cod <> 0 THEN
        DBMS_OUTPUT.PUT_LINE('  Error:   ' || v_msg);
    END IF;
    v_ok := v_cod = 0 AND v_despues - v_antes = 3;
    DBMS_OUTPUT.PUT_LINE('RESULTADO|T06|valido|entrega del envio B fragil al propio destinatario|' || 'COMMIT; medida +3' || '|' || CASE WHEN v_cod = 0 THEN 'COMMIT; medida ' || TO_CHAR(v_despues - v_antes, 'FMS99') ELSE 'ORA' || TO_CHAR(v_cod, 'FM00000') END || '|' || CASE WHEN v_ok THEN 'OK' ELSE 'FALLA' END);
END;
/

PROMPT
PROMPT ===== T06 | rechazado | segunda prueba de entrega para el mismo intento
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
    v_a NUMBER;
    v_mens NUMBER;
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
    SELECT a.id_asignacion, d.id_mensajero INTO v_a, v_mens
    FROM   asignacion_despacho a JOIN despacho d ON d.id_despacho = a.id_despacho
    WHERE  a.numero_guia = v_g(1) AND a.numero_intento = 1;
    SELECT (SELECT COUNT(*) FROM prueba_entrega) + (SELECT COUNT(*) FROM asignacion_despacho WHERE resultado = 'ENTREGADO') + (SELECT COUNT(*) FROM evento_envio WHERE id_estado = 6) + (SELECT COUNT(*) FROM asignacion_despacho WHERE hora_visita IS NOT NULL) INTO v_antes FROM dual;
    SELECT (SELECT resultado FROM asignacion_despacho WHERE id_asignacion = v_a) || ' / ' || (SELECT LISTAGG(ev.id_estado, '>') WITHIN GROUP (ORDER BY ev.fecha_hora) FROM evento_envio ev WHERE ev.numero_guia = v_g(1)) INTO v_info_a FROM dual;
    -- inicio de la transaccion
    BEGIN
        SELECT id_asignacion INTO v_x FROM asignacion_despacho WHERE id_asignacion = v_a FOR UPDATE;
        UPDATE asignacion_despacho SET hora_visita = LOCALTIMESTAMP WHERE id_asignacion = v_a;
        INSERT INTO prueba_entrega (id_asignacion, fecha_hora, nombre_receptor, documento_receptor, tipo_prueba)
        VALUES (v_a, LOCALTIMESTAMP, 'Otro receptor', 'TX-REC-2', 'DOCUMENTO');
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            v_cod := SQLCODE;
            v_msg := SUBSTR(SQLERRM, 1, 300);
            ROLLBACK;
    END;
    SELECT (SELECT COUNT(*) FROM prueba_entrega) + (SELECT COUNT(*) FROM asignacion_despacho WHERE resultado = 'ENTREGADO') + (SELECT COUNT(*) FROM evento_envio WHERE id_estado = 6) + (SELECT COUNT(*) FROM asignacion_despacho WHERE hora_visita IS NOT NULL) INTO v_despues FROM dual;
    SELECT (SELECT resultado FROM asignacion_despacho WHERE id_asignacion = v_a) || ' / ' || (SELECT LISTAGG(ev.id_estado, '>') WITHIN GROUP (ORDER BY ev.fecha_hora) FROM evento_envio ev WHERE ev.numero_guia = v_g(1)) INTO v_info_d FROM dual;
    DBMS_OUTPUT.PUT_LINE('  Antes:   ' || v_info_a);
    DBMS_OUTPUT.PUT_LINE('  Despues: ' || v_info_d);
    IF v_cod <> 0 THEN
        DBMS_OUTPUT.PUT_LINE('  Error:   ' || v_msg);
    END IF;
    v_ok := v_cod IN (-1) AND v_despues = v_antes;
    DBMS_OUTPUT.PUT_LINE('RESULTADO|T06|rechazado|segunda prueba de entrega para el mismo intento|' || 'ORA-00001 (RN08, UNIQUE PRUEBA_ASIGNACION_UK); ROLLBACK, medida sin cambio' || '|' || CASE WHEN v_cod = 0 THEN 'sin error' ELSE 'ORA' || TO_CHAR(v_cod, 'FM00000') END || '; medida ' || v_antes || ' -> ' || v_despues || '|' || CASE WHEN v_ok THEN 'OK' ELSE 'FALLA' END);
END;
/

PROMPT
PROMPT ===== T06 | rechazado | ENTREGADO sin prueba de entrega
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
    v_a NUMBER;
    v_mens NUMBER;
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
    SELECT a.id_asignacion, d.id_mensajero INTO v_a, v_mens
    FROM   asignacion_despacho a JOIN despacho d ON d.id_despacho = a.id_despacho
    WHERE  a.numero_guia = 'EE0000000000023' AND a.numero_intento = 1;
    SELECT (SELECT COUNT(*) FROM prueba_entrega) + (SELECT COUNT(*) FROM asignacion_despacho WHERE resultado = 'ENTREGADO') + (SELECT COUNT(*) FROM evento_envio WHERE id_estado = 6) + (SELECT COUNT(*) FROM asignacion_despacho WHERE hora_visita IS NOT NULL) INTO v_antes FROM dual;
    SELECT (SELECT resultado FROM asignacion_despacho WHERE id_asignacion = v_a) || ' / ' || (SELECT LISTAGG(ev.id_estado, '>') WITHIN GROUP (ORDER BY ev.fecha_hora) FROM evento_envio ev WHERE ev.numero_guia = 'EE0000000000023') INTO v_info_a FROM dual;
    -- inicio de la transaccion
    BEGIN
        SELECT id_asignacion INTO v_x FROM asignacion_despacho WHERE id_asignacion = v_a FOR UPDATE;
        UPDATE asignacion_despacho SET hora_visita = LOCALTIMESTAMP WHERE id_asignacion = v_a;
        UPDATE asignacion_despacho SET resultado = 'ENTREGADO' WHERE id_asignacion = v_a;
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            v_cod := SQLCODE;
            v_msg := SUBSTR(SQLERRM, 1, 300);
            ROLLBACK;
    END;
    SELECT (SELECT COUNT(*) FROM prueba_entrega) + (SELECT COUNT(*) FROM asignacion_despacho WHERE resultado = 'ENTREGADO') + (SELECT COUNT(*) FROM evento_envio WHERE id_estado = 6) + (SELECT COUNT(*) FROM asignacion_despacho WHERE hora_visita IS NOT NULL) INTO v_despues FROM dual;
    SELECT (SELECT resultado FROM asignacion_despacho WHERE id_asignacion = v_a) || ' / ' || (SELECT LISTAGG(ev.id_estado, '>') WITHIN GROUP (ORDER BY ev.fecha_hora) FROM evento_envio ev WHERE ev.numero_guia = 'EE0000000000023') INTO v_info_d FROM dual;
    DBMS_OUTPUT.PUT_LINE('  Antes:   ' || v_info_a);
    DBMS_OUTPUT.PUT_LINE('  Despues: ' || v_info_d);
    IF v_cod <> 0 THEN
        DBMS_OUTPUT.PUT_LINE('  Error:   ' || v_msg);
    END IF;
    v_ok := v_cod IN (-20005) AND v_despues = v_antes AND INSTR(v_msg, 'RN05') > 0;
    DBMS_OUTPUT.PUT_LINE('RESULTADO|T06|rechazado|ENTREGADO sin prueba de entrega|' || 'ORA-20005 (RN05); ROLLBACK, medida sin cambio' || '|' || CASE WHEN v_cod = 0 THEN 'sin error' ELSE 'ORA' || TO_CHAR(v_cod, 'FM00000') END || '; medida ' || v_antes || ' -> ' || v_despues || '|' || CASE WHEN v_ok THEN 'OK' ELSE 'FALLA' END);
END;
/

PROMPT
PROMPT ===== T06 | rechazado | evento ENTREGADO sobre un envio CON_NOVEDAD (prueba y resultado ya registrados)
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
    v_a NUMBER;
    v_mens NUMBER;
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
    SELECT a.id_asignacion, d.id_mensajero INTO v_a, v_mens
    FROM   asignacion_despacho a JOIN despacho d ON d.id_despacho = a.id_despacho
    WHERE  a.numero_guia = 'EE0000000000022' AND a.numero_intento = 1;
    SELECT (SELECT COUNT(*) FROM prueba_entrega) + (SELECT COUNT(*) FROM asignacion_despacho WHERE resultado = 'ENTREGADO') + (SELECT COUNT(*) FROM evento_envio WHERE id_estado = 6) INTO v_antes FROM dual;
    SELECT (SELECT resultado FROM asignacion_despacho WHERE id_asignacion = v_a) || ' / ' || (SELECT LISTAGG(ev.id_estado, '>') WITHIN GROUP (ORDER BY ev.fecha_hora) FROM evento_envio ev WHERE ev.numero_guia = 'EE0000000000022') INTO v_info_a FROM dual;
    -- inicio de la transaccion
    BEGIN
        SELECT id_asignacion INTO v_x FROM asignacion_despacho WHERE id_asignacion = v_a FOR UPDATE;
        INSERT INTO prueba_entrega (id_asignacion, fecha_hora, nombre_receptor, documento_receptor, tipo_prueba)
        VALUES (v_a, LOCALTIMESTAMP, 'Recepcion', 'TX-REC-3', 'DOCUMENTO');
        UPDATE asignacion_despacho SET resultado = 'ENTREGADO' WHERE id_asignacion = v_a;
        v_t := instante('EE0000000000022');
        INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion)
        VALUES ('EE0000000000022', 6, v_mens, v_t, 'Entrega tras novedad sin reintento');  -- ENTREGADO
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            v_cod := SQLCODE;
            v_msg := SUBSTR(SQLERRM, 1, 300);
            ROLLBACK;
    END;
    SELECT (SELECT COUNT(*) FROM prueba_entrega) + (SELECT COUNT(*) FROM asignacion_despacho WHERE resultado = 'ENTREGADO') + (SELECT COUNT(*) FROM evento_envio WHERE id_estado = 6) INTO v_despues FROM dual;
    SELECT (SELECT resultado FROM asignacion_despacho WHERE id_asignacion = v_a) || ' / ' || (SELECT LISTAGG(ev.id_estado, '>') WITHIN GROUP (ORDER BY ev.fecha_hora) FROM evento_envio ev WHERE ev.numero_guia = 'EE0000000000022') INTO v_info_d FROM dual;
    DBMS_OUTPUT.PUT_LINE('  Antes:   ' || v_info_a);
    DBMS_OUTPUT.PUT_LINE('  Despues: ' || v_info_d);
    IF v_cod <> 0 THEN
        DBMS_OUTPUT.PUT_LINE('  Error:   ' || v_msg);
    END IF;
    v_ok := v_cod IN (-20012) AND v_despues = v_antes AND INSTR(v_msg, 'RN12') > 0;
    DBMS_OUTPUT.PUT_LINE('RESULTADO|T06|rechazado|evento ENTREGADO sobre un envio CON_NOVEDAD (prueba y resultado ya registrados)|' || 'ORA-20012 (RN12); ROLLBACK, medida sin cambio' || '|' || CASE WHEN v_cod = 0 THEN 'sin error' ELSE 'ORA' || TO_CHAR(v_cod, 'FM00000') END || '; medida ' || v_antes || ' -> ' || v_despues || '|' || CASE WHEN v_ok THEN 'OK' ELSE 'FALLA' END);
END;
/
