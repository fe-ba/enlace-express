-- T11. Registrar y responder una reclamacion
-- Usuario: U3 (cuenta svc_mesa). Reglas verificadas: RN14.
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
PROMPT ===== T11 | valido | radicar la reclamacion del envio A y responderla a las 3 horas
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
    v_r NUMBER;
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
    SELECT (SELECT COUNT(*) FROM reclamacion) + (SELECT COUNT(*) FROM reclamacion WHERE estado = 'RESPONDIDA') INTO v_antes FROM dual;
    SELECT (SELECT COUNT(*) FROM reclamacion) || ' reclamaciones, ' || (SELECT COUNT(*) FROM reclamacion WHERE estado = 'RESPONDIDA') || ' respondidas' INTO v_info_a FROM dual;
    -- inicio de la transaccion
    BEGIN
        INSERT INTO reclamacion (id_cliente, numero_guia, fecha_radicacion, tipo, descripcion)
        VALUES (1, v_g(1), LOCALTIMESTAMP - INTERVAL '3' HOUR, 'ENTREGA', 'El paquete llego sin la caja original')
        RETURNING id_reclamacion INTO v_r;
        UPDATE reclamacion
           SET respuesta = 'Se ofrecieron disculpas y se registro el caso', fecha_respuesta = LOCALTIMESTAMP, estado = 'RESPONDIDA'
         WHERE id_reclamacion = v_r;
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            v_cod := SQLCODE;
            v_msg := SUBSTR(SQLERRM, 1, 300);
            ROLLBACK;
    END;
    SELECT (SELECT COUNT(*) FROM reclamacion) + (SELECT COUNT(*) FROM reclamacion WHERE estado = 'RESPONDIDA') INTO v_despues FROM dual;
    SELECT (SELECT COUNT(*) FROM reclamacion) || ' reclamaciones, ' || (SELECT COUNT(*) FROM reclamacion WHERE estado = 'RESPONDIDA') || ' respondidas' INTO v_info_d FROM dual;
    DBMS_OUTPUT.PUT_LINE('  Antes:   ' || v_info_a);
    DBMS_OUTPUT.PUT_LINE('  Despues: ' || v_info_d);
    IF v_cod <> 0 THEN
        DBMS_OUTPUT.PUT_LINE('  Error:   ' || v_msg);
    END IF;
    v_ok := v_cod = 0 AND v_despues - v_antes = 2;
    DBMS_OUTPUT.PUT_LINE('RESULTADO|T11|valido|radicar la reclamacion del envio A y responderla a las 3 horas|' || 'COMMIT; medida +2' || '|' || CASE WHEN v_cod = 0 THEN 'COMMIT; medida ' || TO_CHAR(v_despues - v_antes, 'FMS99') ELSE 'ORA' || TO_CHAR(v_cod, 'FM00000') END || '|' || CASE WHEN v_ok THEN 'OK' ELSE 'FALLA' END);
END;
/

PROMPT
PROMPT ===== T11 | rechazado | respuesta con fecha anterior a la radicacion
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
    v_r NUMBER;
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
    SELECT (SELECT COUNT(*) FROM reclamacion) + (SELECT COUNT(*) FROM reclamacion WHERE estado = 'RESPONDIDA') INTO v_antes FROM dual;
    SELECT (SELECT COUNT(*) FROM reclamacion) || ' reclamaciones, ' || (SELECT COUNT(*) FROM reclamacion WHERE estado = 'RESPONDIDA') || ' respondidas' INTO v_info_a FROM dual;
    -- inicio de la transaccion
    BEGIN
        INSERT INTO reclamacion (id_cliente, numero_guia, fecha_radicacion, tipo, descripcion)
        VALUES (1, v_g(1), LOCALTIMESTAMP, 'OTRO', 'Reclamacion de prueba')
        RETURNING id_reclamacion INTO v_r;
        UPDATE reclamacion
           SET respuesta = 'Respuesta con fecha invalida', fecha_respuesta = LOCALTIMESTAMP - INTERVAL '1' HOUR, estado = 'RESPONDIDA'
         WHERE id_reclamacion = v_r;
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            v_cod := SQLCODE;
            v_msg := SUBSTR(SQLERRM, 1, 300);
            ROLLBACK;
    END;
    SELECT (SELECT COUNT(*) FROM reclamacion) + (SELECT COUNT(*) FROM reclamacion WHERE estado = 'RESPONDIDA') INTO v_despues FROM dual;
    SELECT (SELECT COUNT(*) FROM reclamacion) || ' reclamaciones, ' || (SELECT COUNT(*) FROM reclamacion WHERE estado = 'RESPONDIDA') || ' respondidas' INTO v_info_d FROM dual;
    DBMS_OUTPUT.PUT_LINE('  Antes:   ' || v_info_a);
    DBMS_OUTPUT.PUT_LINE('  Despues: ' || v_info_d);
    IF v_cod <> 0 THEN
        DBMS_OUTPUT.PUT_LINE('  Error:   ' || v_msg);
    END IF;
    v_ok := v_cod IN (-2290) AND v_despues = v_antes;
    DBMS_OUTPUT.PUT_LINE('RESULTADO|T11|rechazado|respuesta con fecha anterior a la radicacion|' || 'ORA-02290 (RN14, CHECK RECLAMACION_RESP_CK); ROLLBACK, medida sin cambio' || '|' || CASE WHEN v_cod = 0 THEN 'sin error' ELSE 'ORA' || TO_CHAR(v_cod, 'FM00000') END || '; medida ' || v_antes || ' -> ' || v_despues || '|' || CASE WHEN v_ok THEN 'OK' ELSE 'FALLA' END);
END;
/
