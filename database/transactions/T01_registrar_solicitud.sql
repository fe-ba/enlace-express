-- T01. Registrar solicitud de recoleccion
-- Usuario: U3 (cuenta svc_mesa). Reglas verificadas: RN15.
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
PROMPT ===== T01 | valido | solicitud de recoleccion de un cliente ACTIVO
DECLARE
    v_antes   NUMBER;
    v_despues NUMBER;
    v_cod     NUMBER := 0;
    v_msg     VARCHAR2(400);
    v_info_a  VARCHAR2(400);
    v_info_d  VARCHAR2(400);
    v_ok      BOOLEAN;
    v_t       TIMESTAMP;
    v_sol NUMBER;
    -- C5: instante estrictamente posterior al ultimo evento de la guia (y a la hora actual)
    FUNCTION instante(p_guia IN VARCHAR2) RETURN TIMESTAMP IS
        v_i TIMESTAMP;
    BEGIN
        SELECT GREATEST(LOCALTIMESTAMP, NVL(MAX(fecha_hora), LOCALTIMESTAMP) + INTERVAL '1' SECOND)
        INTO   v_i FROM evento_envio WHERE numero_guia = p_guia;
        RETURN v_i;
    END instante;
BEGIN
    SELECT (SELECT COUNT(*) FROM solicitud_recoleccion) INTO v_antes FROM dual;
    SELECT TO_CHAR((SELECT COUNT(*) FROM solicitud_recoleccion)) INTO v_info_a FROM dual;
    -- inicio de la transaccion
    BEGIN
        SELECT id_sede INTO v_sol FROM sede_cliente WHERE id_sede = 1 FOR UPDATE;
        INSERT INTO solicitud_recoleccion (id_sede, fecha_solicitud, fecha_programada, franja_horaria, estado)
        VALUES (1, TRUNC(SYSDATE), TRUNC(SYSDATE) + 2, 'MANANA', 'PROGRAMADA');
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            v_cod := SQLCODE;
            v_msg := SUBSTR(SQLERRM, 1, 300);
            ROLLBACK;
    END;
    SELECT (SELECT COUNT(*) FROM solicitud_recoleccion) INTO v_despues FROM dual;
    SELECT TO_CHAR((SELECT COUNT(*) FROM solicitud_recoleccion)) INTO v_info_d FROM dual;
    DBMS_OUTPUT.PUT_LINE('  Antes:   ' || v_info_a);
    DBMS_OUTPUT.PUT_LINE('  Despues: ' || v_info_d);
    IF v_cod <> 0 THEN
        DBMS_OUTPUT.PUT_LINE('  Error:   ' || v_msg);
    END IF;
    v_ok := v_cod = 0 AND v_despues - v_antes = 1;
    DBMS_OUTPUT.PUT_LINE('RESULTADO|T01|valido|solicitud de recoleccion de un cliente ACTIVO|' || 'COMMIT; medida +1' || '|' || CASE WHEN v_cod = 0 THEN 'COMMIT; medida ' || TO_CHAR(v_despues - v_antes, 'FMS99') ELSE 'ORA' || TO_CHAR(v_cod, 'FM00000') END || '|' || CASE WHEN v_ok THEN 'OK' ELSE 'FALLA' END);
END;
/

PROMPT
PROMPT ===== T01 | rechazado | segunda solicitud de un cliente INACTIVO tras una valida
DECLARE
    v_antes   NUMBER;
    v_despues NUMBER;
    v_cod     NUMBER := 0;
    v_msg     VARCHAR2(400);
    v_info_a  VARCHAR2(400);
    v_info_d  VARCHAR2(400);
    v_ok      BOOLEAN;
    v_t       TIMESTAMP;
    v_sol NUMBER;
    -- C5: instante estrictamente posterior al ultimo evento de la guia (y a la hora actual)
    FUNCTION instante(p_guia IN VARCHAR2) RETURN TIMESTAMP IS
        v_i TIMESTAMP;
    BEGIN
        SELECT GREATEST(LOCALTIMESTAMP, NVL(MAX(fecha_hora), LOCALTIMESTAMP) + INTERVAL '1' SECOND)
        INTO   v_i FROM evento_envio WHERE numero_guia = p_guia;
        RETURN v_i;
    END instante;
BEGIN
    SELECT (SELECT COUNT(*) FROM solicitud_recoleccion) INTO v_antes FROM dual;
    SELECT TO_CHAR((SELECT COUNT(*) FROM solicitud_recoleccion)) INTO v_info_a FROM dual;
    -- inicio de la transaccion
    BEGIN
        SELECT id_sede INTO v_sol FROM sede_cliente WHERE id_sede = 1 FOR UPDATE;
        INSERT INTO solicitud_recoleccion (id_sede, fecha_solicitud, fecha_programada, franja_horaria, estado)
        VALUES (1, TRUNC(SYSDATE), TRUNC(SYSDATE) + 2, 'TARDE', 'PROGRAMADA');
        INSERT INTO solicitud_recoleccion (id_sede, fecha_solicitud, fecha_programada, franja_horaria, estado)
        VALUES (7, TRUNC(SYSDATE), TRUNC(SYSDATE) + 2, 'MANANA', 'PROGRAMADA');  -- sede del cliente 4 (INACTIVO)
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            v_cod := SQLCODE;
            v_msg := SUBSTR(SQLERRM, 1, 300);
            ROLLBACK;
    END;
    SELECT (SELECT COUNT(*) FROM solicitud_recoleccion) INTO v_despues FROM dual;
    SELECT TO_CHAR((SELECT COUNT(*) FROM solicitud_recoleccion)) INTO v_info_d FROM dual;
    DBMS_OUTPUT.PUT_LINE('  Antes:   ' || v_info_a);
    DBMS_OUTPUT.PUT_LINE('  Despues: ' || v_info_d);
    IF v_cod <> 0 THEN
        DBMS_OUTPUT.PUT_LINE('  Error:   ' || v_msg);
    END IF;
    v_ok := v_cod IN (-20015) AND v_despues = v_antes AND INSTR(v_msg, 'RN15') > 0;
    DBMS_OUTPUT.PUT_LINE('RESULTADO|T01|rechazado|segunda solicitud de un cliente INACTIVO tras una valida|' || 'ORA-20015 (RN15); ROLLBACK, medida sin cambio' || '|' || CASE WHEN v_cod = 0 THEN 'sin error' ELSE 'ORA' || TO_CHAR(v_cod, 'FM00000') END || '; medida ' || v_antes || ' -> ' || v_despues || '|' || CASE WHEN v_ok THEN 'OK' ELSE 'FALLA' END);
END;
/
