-- T04. Recibir y clasificar
-- Usuario: U2 (cuenta svc_centro). Reglas verificadas: RN03, RN12.
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
PROMPT ===== T04 | valido | recibir y clasificar los 3 envios: EN_CENTRO, CLASIFICADO, peso real y flete
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
    v_peso NUMBER;
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
    SELECT (SELECT COUNT(*) FROM evento_envio WHERE id_estado IN (3, 4)) INTO v_antes FROM dual;
    SELECT (SELECT LISTAGG(es.nombre, ' > ') WITHIN GROUP (ORDER BY ev.fecha_hora) FROM evento_envio ev JOIN estado_envio es ON es.id_estado = ev.id_estado WHERE ev.numero_guia = v_g(1)) INTO v_info_a FROM dual;
    -- inicio de la transaccion
    BEGIN
        FOR i IN 1 .. v_g.COUNT LOOP
            SELECT peso_declarado INTO v_peso FROM envio WHERE numero_guia = v_g(i) FOR UPDATE;
            v_t := instante(v_g(i));
            INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion)
            VALUES (v_g(i), 3, 2, v_t, 'Recibido y pesado en el centro');  -- EN_CENTRO
            v_t := instante(v_g(i));
            INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion)
            VALUES (v_g(i), 4, 2, v_t, 'Clasificado por zona');  -- CLASIFICADO
            UPDATE envio SET peso_real = v_peso + 0.1, valor_flete = 4500 + 1800 * v_peso
             WHERE numero_guia = v_g(i);
        END LOOP;
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            v_cod := SQLCODE;
            v_msg := SUBSTR(SQLERRM, 1, 300);
            ROLLBACK;
    END;
    SELECT (SELECT COUNT(*) FROM evento_envio WHERE id_estado IN (3, 4)) INTO v_despues FROM dual;
    SELECT (SELECT LISTAGG(es.nombre, ' > ') WITHIN GROUP (ORDER BY ev.fecha_hora) FROM evento_envio ev JOIN estado_envio es ON es.id_estado = ev.id_estado WHERE ev.numero_guia = v_g(1)) INTO v_info_d FROM dual;
    DBMS_OUTPUT.PUT_LINE('  Antes:   ' || v_info_a);
    DBMS_OUTPUT.PUT_LINE('  Despues: ' || v_info_d);
    IF v_cod <> 0 THEN
        DBMS_OUTPUT.PUT_LINE('  Error:   ' || v_msg);
    END IF;
    v_ok := v_cod = 0 AND v_despues - v_antes = 6;
    DBMS_OUTPUT.PUT_LINE('RESULTADO|T04|valido|recibir y clasificar los 3 envios: EN_CENTRO, CLASIFICADO, peso real y flete|' || 'COMMIT; medida +6' || '|' || CASE WHEN v_cod = 0 THEN 'COMMIT; medida ' || TO_CHAR(v_despues - v_antes, 'FMS99') ELSE 'ORA' || TO_CHAR(v_cod, 'FM00000') END || '|' || CASE WHEN v_ok THEN 'OK' ELSE 'FALLA' END);
END;
/

PROMPT
PROMPT ===== T04 | rechazado | peso real negativo tras registrar EN_CENTRO y CLASIFICADO
DECLARE
    v_antes   NUMBER;
    v_despues NUMBER;
    v_cod     NUMBER := 0;
    v_msg     VARCHAR2(400);
    v_info_a  VARCHAR2(400);
    v_info_d  VARCHAR2(400);
    v_ok      BOOLEAN;
    v_t       TIMESTAMP;
    v_peso NUMBER;
    v_guia VARCHAR2(15) := 'EE0000000000028';
    -- C5: instante estrictamente posterior al ultimo evento de la guia (y a la hora actual)
    FUNCTION instante(p_guia IN VARCHAR2) RETURN TIMESTAMP IS
        v_i TIMESTAMP;
    BEGIN
        SELECT GREATEST(LOCALTIMESTAMP, NVL(MAX(fecha_hora), LOCALTIMESTAMP) + INTERVAL '1' SECOND)
        INTO   v_i FROM evento_envio WHERE numero_guia = p_guia;
        RETURN v_i;
    END instante;
BEGIN
    SELECT (SELECT COUNT(*) FROM evento_envio WHERE id_estado IN (3, 4)) INTO v_antes FROM dual;
    SELECT (SELECT LISTAGG(es.nombre, ' > ') WITHIN GROUP (ORDER BY ev.fecha_hora) FROM evento_envio ev JOIN estado_envio es ON es.id_estado = ev.id_estado WHERE ev.numero_guia = 'EE0000000000028') INTO v_info_a FROM dual;
    -- inicio de la transaccion
    BEGIN
        SELECT peso_declarado INTO v_peso FROM envio WHERE numero_guia = v_guia FOR UPDATE;
        v_t := instante(v_guia);
        INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion)
        VALUES (v_guia, 3, 2, v_t, 'Recibido en el centro');  -- EN_CENTRO
        v_t := instante(v_guia);
        INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion)
        VALUES (v_guia, 4, 2, v_t, 'Clasificado');  -- CLASIFICADO
        UPDATE envio SET peso_real = -1 WHERE numero_guia = v_guia;
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            v_cod := SQLCODE;
            v_msg := SUBSTR(SQLERRM, 1, 300);
            ROLLBACK;
    END;
    SELECT (SELECT COUNT(*) FROM evento_envio WHERE id_estado IN (3, 4)) INTO v_despues FROM dual;
    SELECT (SELECT LISTAGG(es.nombre, ' > ') WITHIN GROUP (ORDER BY ev.fecha_hora) FROM evento_envio ev JOIN estado_envio es ON es.id_estado = ev.id_estado WHERE ev.numero_guia = 'EE0000000000028') INTO v_info_d FROM dual;
    DBMS_OUTPUT.PUT_LINE('  Antes:   ' || v_info_a);
    DBMS_OUTPUT.PUT_LINE('  Despues: ' || v_info_d);
    IF v_cod <> 0 THEN
        DBMS_OUTPUT.PUT_LINE('  Error:   ' || v_msg);
    END IF;
    v_ok := v_cod IN (-2290) AND v_despues = v_antes;
    DBMS_OUTPUT.PUT_LINE('RESULTADO|T04|rechazado|peso real negativo tras registrar EN_CENTRO y CLASIFICADO|' || 'ORA-02290 (RN03, CHECK ENVIO_PESOS_CK); ROLLBACK, medida sin cambio' || '|' || CASE WHEN v_cod = 0 THEN 'sin error' ELSE 'ORA' || TO_CHAR(v_cod, 'FM00000') END || '; medida ' || v_antes || ' -> ' || v_despues || '|' || CASE WHEN v_ok THEN 'OK' ELSE 'FALLA' END);
END;
/

PROMPT
PROMPT ===== T04 | rechazado | EN_CENTRO sobre un envio aun REGISTRADO
DECLARE
    v_antes   NUMBER;
    v_despues NUMBER;
    v_cod     NUMBER := 0;
    v_msg     VARCHAR2(400);
    v_info_a  VARCHAR2(400);
    v_info_d  VARCHAR2(400);
    v_ok      BOOLEAN;
    v_t       TIMESTAMP;
    v_peso NUMBER;
    v_guia VARCHAR2(15) := 'EE0000000000029';
    -- C5: instante estrictamente posterior al ultimo evento de la guia (y a la hora actual)
    FUNCTION instante(p_guia IN VARCHAR2) RETURN TIMESTAMP IS
        v_i TIMESTAMP;
    BEGIN
        SELECT GREATEST(LOCALTIMESTAMP, NVL(MAX(fecha_hora), LOCALTIMESTAMP) + INTERVAL '1' SECOND)
        INTO   v_i FROM evento_envio WHERE numero_guia = p_guia;
        RETURN v_i;
    END instante;
BEGIN
    SELECT (SELECT COUNT(*) FROM evento_envio WHERE id_estado IN (3, 4)) INTO v_antes FROM dual;
    SELECT (SELECT LISTAGG(es.nombre, ' > ') WITHIN GROUP (ORDER BY ev.fecha_hora) FROM evento_envio ev JOIN estado_envio es ON es.id_estado = ev.id_estado WHERE ev.numero_guia = 'EE0000000000029') INTO v_info_a FROM dual;
    -- inicio de la transaccion
    BEGIN
        SELECT peso_declarado INTO v_peso FROM envio WHERE numero_guia = v_guia FOR UPDATE;
        v_t := instante(v_guia);
        INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion)
        VALUES (v_guia, 3, 2, v_t, 'Recibido sin haber sido recolectado');  -- EN_CENTRO
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            v_cod := SQLCODE;
            v_msg := SUBSTR(SQLERRM, 1, 300);
            ROLLBACK;
    END;
    SELECT (SELECT COUNT(*) FROM evento_envio WHERE id_estado IN (3, 4)) INTO v_despues FROM dual;
    SELECT (SELECT LISTAGG(es.nombre, ' > ') WITHIN GROUP (ORDER BY ev.fecha_hora) FROM evento_envio ev JOIN estado_envio es ON es.id_estado = ev.id_estado WHERE ev.numero_guia = 'EE0000000000029') INTO v_info_d FROM dual;
    DBMS_OUTPUT.PUT_LINE('  Antes:   ' || v_info_a);
    DBMS_OUTPUT.PUT_LINE('  Despues: ' || v_info_d);
    IF v_cod <> 0 THEN
        DBMS_OUTPUT.PUT_LINE('  Error:   ' || v_msg);
    END IF;
    v_ok := v_cod IN (-20012) AND v_despues = v_antes AND INSTR(v_msg, 'RN12') > 0;
    DBMS_OUTPUT.PUT_LINE('RESULTADO|T04|rechazado|EN_CENTRO sobre un envio aun REGISTRADO|' || 'ORA-20012 (RN12); ROLLBACK, medida sin cambio' || '|' || CASE WHEN v_cod = 0 THEN 'sin error' ELSE 'ORA' || TO_CHAR(v_cod, 'FM00000') END || '; medida ' || v_antes || ' -> ' || v_despues || '|' || CASE WHEN v_ok THEN 'OK' ELSE 'FALLA' END);
END;
/
