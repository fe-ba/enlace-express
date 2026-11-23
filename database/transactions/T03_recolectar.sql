-- T03. Recolectar
-- Usuario: U4 (cuenta svc_mensajero). Reglas verificadas: RN12.
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
PROMPT ===== T03 | valido | recolectar la solicitud: ATENDIDA y evento RECOLECTADO de sus 3 envios
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
    v_estado VARCHAR2(12);
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
    SELECT (SELECT COUNT(*) FROM solicitud_recoleccion WHERE estado = 'ATENDIDA') + (SELECT COUNT(*) FROM evento_envio WHERE id_estado = 2) INTO v_antes FROM dual;
    SELECT (SELECT estado FROM solicitud_recoleccion WHERE id_solicitud = v_sol) || ' / ' || (SELECT LISTAGG(ev.id_estado, '>') WITHIN GROUP (ORDER BY ev.fecha_hora) FROM evento_envio ev WHERE ev.numero_guia = v_g(1)) INTO v_info_a FROM dual;
    -- inicio de la transaccion
    BEGIN
        SELECT estado INTO v_estado FROM solicitud_recoleccion WHERE id_solicitud = v_sol FOR UPDATE;
        UPDATE solicitud_recoleccion SET estado = 'ATENDIDA' WHERE id_solicitud = v_sol;
        FOR i IN 1 .. v_g.COUNT LOOP
            v_t := instante(v_g(i));
            INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion)
            VALUES (v_g(i), 2, 6, v_t, 'Recogido en la sede del cliente');  -- RECOLECTADO
        END LOOP;
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            v_cod := SQLCODE;
            v_msg := SUBSTR(SQLERRM, 1, 300);
            ROLLBACK;
    END;
    SELECT (SELECT COUNT(*) FROM solicitud_recoleccion WHERE estado = 'ATENDIDA') + (SELECT COUNT(*) FROM evento_envio WHERE id_estado = 2) INTO v_despues FROM dual;
    SELECT (SELECT estado FROM solicitud_recoleccion WHERE id_solicitud = v_sol) || ' / ' || (SELECT LISTAGG(ev.id_estado, '>') WITHIN GROUP (ORDER BY ev.fecha_hora) FROM evento_envio ev WHERE ev.numero_guia = v_g(1)) INTO v_info_d FROM dual;
    DBMS_OUTPUT.PUT_LINE('  Antes:   ' || v_info_a);
    DBMS_OUTPUT.PUT_LINE('  Despues: ' || v_info_d);
    IF v_cod <> 0 THEN
        DBMS_OUTPUT.PUT_LINE('  Error:   ' || v_msg);
    END IF;
    v_ok := v_cod = 0 AND v_despues - v_antes = 4;
    DBMS_OUTPUT.PUT_LINE('RESULTADO|T03|valido|recolectar la solicitud: ATENDIDA y evento RECOLECTADO de sus 3 envios|' || 'COMMIT; medida +4' || '|' || CASE WHEN v_cod = 0 THEN 'COMMIT; medida ' || TO_CHAR(v_despues - v_antes, 'FMS99') ELSE 'ORA' || TO_CHAR(v_cod, 'FM00000') END || '|' || CASE WHEN v_ok THEN 'OK' ELSE 'FALLA' END);
END;
/

PROMPT
PROMPT ===== T03 | rechazado | recolectar un envio que ya fue entregado (solicitud 11 vuelve a ATENDIDA y se deshace)
DECLARE
    v_antes   NUMBER;
    v_despues NUMBER;
    v_cod     NUMBER := 0;
    v_msg     VARCHAR2(400);
    v_info_a  VARCHAR2(400);
    v_info_d  VARCHAR2(400);
    v_ok      BOOLEAN;
    v_t       TIMESTAMP;
    v_estado VARCHAR2(12);
    -- C5: instante estrictamente posterior al ultimo evento de la guia (y a la hora actual)
    FUNCTION instante(p_guia IN VARCHAR2) RETURN TIMESTAMP IS
        v_i TIMESTAMP;
    BEGIN
        SELECT GREATEST(LOCALTIMESTAMP, NVL(MAX(fecha_hora), LOCALTIMESTAMP) + INTERVAL '1' SECOND)
        INTO   v_i FROM evento_envio WHERE numero_guia = p_guia;
        RETURN v_i;
    END instante;
BEGIN
    SELECT (SELECT COUNT(*) FROM solicitud_recoleccion WHERE estado = 'ATENDIDA') + (SELECT COUNT(*) FROM evento_envio WHERE id_estado = 2) INTO v_antes FROM dual;
    SELECT (SELECT estado FROM solicitud_recoleccion WHERE id_solicitud = 11) INTO v_info_a FROM dual;
    -- inicio de la transaccion
    BEGIN
        SELECT estado INTO v_estado FROM solicitud_recoleccion WHERE id_solicitud = 11 FOR UPDATE;
        UPDATE solicitud_recoleccion SET estado = 'ATENDIDA' WHERE id_solicitud = 11;
        v_t := instante('EE0000000000020');
        INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion)
        VALUES ('EE0000000000020', 2, 6, v_t, 'Intento invalido');  -- RECOLECTADO
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            v_cod := SQLCODE;
            v_msg := SUBSTR(SQLERRM, 1, 300);
            ROLLBACK;
    END;
    SELECT (SELECT COUNT(*) FROM solicitud_recoleccion WHERE estado = 'ATENDIDA') + (SELECT COUNT(*) FROM evento_envio WHERE id_estado = 2) INTO v_despues FROM dual;
    SELECT (SELECT estado FROM solicitud_recoleccion WHERE id_solicitud = 11) INTO v_info_d FROM dual;
    DBMS_OUTPUT.PUT_LINE('  Antes:   ' || v_info_a);
    DBMS_OUTPUT.PUT_LINE('  Despues: ' || v_info_d);
    IF v_cod <> 0 THEN
        DBMS_OUTPUT.PUT_LINE('  Error:   ' || v_msg);
    END IF;
    v_ok := v_cod IN (-20012) AND v_despues = v_antes AND INSTR(v_msg, 'RN12') > 0;
    DBMS_OUTPUT.PUT_LINE('RESULTADO|T03|rechazado|recolectar un envio que ya fue entregado (solicitud 11 vuelve a ATENDIDA y se deshace)|' || 'ORA-20012 (RN12); ROLLBACK, medida sin cambio' || '|' || CASE WHEN v_cod = 0 THEN 'sin error' ELSE 'ORA' || TO_CHAR(v_cod, 'FM00000') END || '; medida ' || v_antes || ' -> ' || v_despues || '|' || CASE WHEN v_ok THEN 'OK' ELSE 'FALLA' END);
END;
/
