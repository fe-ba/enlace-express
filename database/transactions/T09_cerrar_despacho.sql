-- T09. Cerrar el despacho
-- Usuario: U2 (cuenta svc_centro). Reglas verificadas: (ninguna regla de negocio; CHECK de horas).
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
PROMPT ===== T09 | valido | cerrar el despacho del envio A (todos sus envios con resultado)
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
    v_x VARCHAR2(10);
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
    SELECT id_despacho INTO v_d FROM asignacion_despacho WHERE numero_guia = v_g(1) AND numero_intento = 1;
    SELECT (SELECT COUNT(*) FROM despacho WHERE estado = 'CERRADO') INTO v_antes FROM dual;
    SELECT (SELECT estado FROM despacho WHERE id_despacho = v_d) INTO v_info_a FROM dual;
    -- inicio de la transaccion
    BEGIN
        SELECT estado INTO v_x FROM despacho WHERE id_despacho = v_d FOR UPDATE;
        UPDATE despacho SET hora_cierre = LOCALTIMESTAMP, estado = 'CERRADO' WHERE id_despacho = v_d;
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            v_cod := SQLCODE;
            v_msg := SUBSTR(SQLERRM, 1, 300);
            ROLLBACK;
    END;
    SELECT (SELECT COUNT(*) FROM despacho WHERE estado = 'CERRADO') INTO v_despues FROM dual;
    SELECT (SELECT estado FROM despacho WHERE id_despacho = v_d) INTO v_info_d FROM dual;
    DBMS_OUTPUT.PUT_LINE('  Antes:   ' || v_info_a);
    DBMS_OUTPUT.PUT_LINE('  Despues: ' || v_info_d);
    IF v_cod <> 0 THEN
        DBMS_OUTPUT.PUT_LINE('  Error:   ' || v_msg);
    END IF;
    v_ok := v_cod = 0 AND v_despues - v_antes = 1;
    DBMS_OUTPUT.PUT_LINE('RESULTADO|T09|valido|cerrar el despacho del envio A (todos sus envios con resultado)|' || 'COMMIT; medida +1' || '|' || CASE WHEN v_cod = 0 THEN 'COMMIT; medida ' || TO_CHAR(v_despues - v_antes, 'FMS99') ELSE 'ORA' || TO_CHAR(v_cod, 'FM00000') END || '|' || CASE WHEN v_ok THEN 'OK' ELSE 'FALLA' END);
END;
/

PROMPT
PROMPT ===== T09 | rechazado | hora de cierre anterior a la de salida (el estado CERRADO ya se habia actualizado)
DECLARE
    v_antes   NUMBER;
    v_despues NUMBER;
    v_cod     NUMBER := 0;
    v_msg     VARCHAR2(400);
    v_info_a  VARCHAR2(400);
    v_info_d  VARCHAR2(400);
    v_ok      BOOLEAN;
    v_t       TIMESTAMP;
    v_d NUMBER := 15;
    v_x VARCHAR2(10);
    -- C5: instante estrictamente posterior al ultimo evento de la guia (y a la hora actual)
    FUNCTION instante(p_guia IN VARCHAR2) RETURN TIMESTAMP IS
        v_i TIMESTAMP;
    BEGIN
        SELECT GREATEST(LOCALTIMESTAMP, NVL(MAX(fecha_hora), LOCALTIMESTAMP) + INTERVAL '1' SECOND)
        INTO   v_i FROM evento_envio WHERE numero_guia = p_guia;
        RETURN v_i;
    END instante;
BEGIN
    SELECT (SELECT COUNT(*) FROM despacho WHERE estado = 'CERRADO') INTO v_antes FROM dual;
    SELECT (SELECT estado FROM despacho WHERE id_despacho = v_d) INTO v_info_a FROM dual;
    -- inicio de la transaccion
    BEGIN
        SELECT estado INTO v_x FROM despacho WHERE id_despacho = v_d FOR UPDATE;
        UPDATE despacho SET estado = 'CERRADO' WHERE id_despacho = v_d;
        UPDATE despacho SET hora_cierre = hora_salida - INTERVAL '1' HOUR WHERE id_despacho = v_d;
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            v_cod := SQLCODE;
            v_msg := SUBSTR(SQLERRM, 1, 300);
            ROLLBACK;
    END;
    SELECT (SELECT COUNT(*) FROM despacho WHERE estado = 'CERRADO') INTO v_despues FROM dual;
    SELECT (SELECT estado FROM despacho WHERE id_despacho = v_d) INTO v_info_d FROM dual;
    DBMS_OUTPUT.PUT_LINE('  Antes:   ' || v_info_a);
    DBMS_OUTPUT.PUT_LINE('  Despues: ' || v_info_d);
    IF v_cod <> 0 THEN
        DBMS_OUTPUT.PUT_LINE('  Error:   ' || v_msg);
    END IF;
    v_ok := v_cod IN (-2290) AND v_despues = v_antes;
    DBMS_OUTPUT.PUT_LINE('RESULTADO|T09|rechazado|hora de cierre anterior a la de salida (el estado CERRADO ya se habia actualizado)|' || 'ORA-02290 (CHECK DESPACHO_HORAS_CK); ROLLBACK, medida sin cambio' || '|' || CASE WHEN v_cod = 0 THEN 'sin error' ELSE 'ORA' || TO_CHAR(v_cod, 'FM00000') END || '; medida ' || v_antes || ' -> ' || v_despues || '|' || CASE WHEN v_ok THEN 'OK' ELSE 'FALLA' END);
END;
/
