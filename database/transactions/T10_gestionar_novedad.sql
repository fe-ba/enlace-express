-- T10. Gestionar una novedad
-- Usuario: U3 (cuenta svc_mesa). Reglas verificadas: (ninguna regla de negocio; CHECK de accion).
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
PROMPT ===== T10 | valido | gestionar la novedad del envio C: accion, solucion y estado CERRADA
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
    v_n NUMBER;
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
    SELECT n.id_novedad INTO v_n FROM novedad n JOIN asignacion_despacho a ON a.id_asignacion = n.id_asignacion WHERE a.numero_guia = v_g(3) AND a.numero_intento = 1;
    SELECT (SELECT COUNT(*) FROM novedad WHERE estado = 'ABIERTA') INTO v_antes FROM dual;
    SELECT (SELECT estado || '/' || NVL(accion, '-') FROM novedad WHERE id_novedad = v_n) INTO v_info_a FROM dual;
    -- inicio de la transaccion
    BEGIN
        SELECT id_novedad INTO v_x FROM novedad WHERE id_novedad = v_n FOR UPDATE;
        UPDATE novedad SET accion = 'REINTENTO', solucion = 'Se reprogramo la entrega con el destinatario', estado = 'CERRADA'
         WHERE id_novedad = v_n;
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            v_cod := SQLCODE;
            v_msg := SUBSTR(SQLERRM, 1, 300);
            ROLLBACK;
    END;
    SELECT (SELECT COUNT(*) FROM novedad WHERE estado = 'ABIERTA') INTO v_despues FROM dual;
    SELECT (SELECT estado || '/' || NVL(accion, '-') FROM novedad WHERE id_novedad = v_n) INTO v_info_d FROM dual;
    DBMS_OUTPUT.PUT_LINE('  Antes:   ' || v_info_a);
    DBMS_OUTPUT.PUT_LINE('  Despues: ' || v_info_d);
    IF v_cod <> 0 THEN
        DBMS_OUTPUT.PUT_LINE('  Error:   ' || v_msg);
    END IF;
    v_ok := v_cod = 0 AND v_despues - v_antes = -1;
    DBMS_OUTPUT.PUT_LINE('RESULTADO|T10|valido|gestionar la novedad del envio C: accion, solucion y estado CERRADA|' || 'COMMIT; medida -1' || '|' || CASE WHEN v_cod = 0 THEN 'COMMIT; medida ' || TO_CHAR(v_despues - v_antes, 'FMS99') ELSE 'ORA' || TO_CHAR(v_cod, 'FM00000') END || '|' || CASE WHEN v_ok THEN 'OK' ELSE 'FALLA' END);
END;
/

PROMPT
PROMPT ===== T10 | rechazado | accion no permitida tras actualizar la solucion
DECLARE
    v_antes   NUMBER;
    v_despues NUMBER;
    v_cod     NUMBER := 0;
    v_msg     VARCHAR2(400);
    v_info_a  VARCHAR2(400);
    v_info_d  VARCHAR2(400);
    v_ok      BOOLEAN;
    v_t       TIMESTAMP;
    v_n NUMBER := 6;
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
    SELECT (SELECT COUNT(*) FROM novedad WHERE estado = 'ABIERTA') + (SELECT COUNT(*) FROM novedad WHERE solucion IS NOT NULL) INTO v_antes FROM dual;
    SELECT (SELECT estado || '/' || NVL(solucion, '-') FROM novedad WHERE id_novedad = v_n) INTO v_info_a FROM dual;
    -- inicio de la transaccion
    BEGIN
        SELECT id_novedad INTO v_x FROM novedad WHERE id_novedad = v_n FOR UPDATE;
        UPDATE novedad SET solucion = 'Intento de solucion' WHERE id_novedad = v_n;
        UPDATE novedad SET accion = 'CANCELAR', estado = 'CERRADA' WHERE id_novedad = v_n;
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            v_cod := SQLCODE;
            v_msg := SUBSTR(SQLERRM, 1, 300);
            ROLLBACK;
    END;
    SELECT (SELECT COUNT(*) FROM novedad WHERE estado = 'ABIERTA') + (SELECT COUNT(*) FROM novedad WHERE solucion IS NOT NULL) INTO v_despues FROM dual;
    SELECT (SELECT estado || '/' || NVL(solucion, '-') FROM novedad WHERE id_novedad = v_n) INTO v_info_d FROM dual;
    DBMS_OUTPUT.PUT_LINE('  Antes:   ' || v_info_a);
    DBMS_OUTPUT.PUT_LINE('  Despues: ' || v_info_d);
    IF v_cod <> 0 THEN
        DBMS_OUTPUT.PUT_LINE('  Error:   ' || v_msg);
    END IF;
    v_ok := v_cod IN (-2290) AND v_despues = v_antes;
    DBMS_OUTPUT.PUT_LINE('RESULTADO|T10|rechazado|accion no permitida tras actualizar la solucion|' || 'ORA-02290 (CHECK NOVEDAD_ACCION_CK); ROLLBACK, medida sin cambio' || '|' || CASE WHEN v_cod = 0 THEN 'sin error' ELSE 'ORA' || TO_CHAR(v_cod, 'FM00000') END || '; medida ' || v_antes || ' -> ' || v_despues || '|' || CASE WHEN v_ok THEN 'OK' ELSE 'FALLA' END);
END;
/
