-- T02. Registrar envio (procedimiento pr_registrar_envio)
-- Usuario: U3 (cuenta svc_mesa). Reglas verificadas: RN01 a RN04, RN12.
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
PROMPT ===== T02 | valido | registro del envio A (destinatario nuevo)
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
    v_guia VARCHAR2(15);
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
    SELECT (SELECT COUNT(*) FROM envio) + (SELECT COUNT(*) FROM evento_envio) + (SELECT COUNT(*) FROM destinatario) INTO v_antes FROM dual;
    SELECT 'envios=' || (SELECT COUNT(*) FROM envio) || ', eventos=' || (SELECT COUNT(*) FROM evento_envio) || ', destinatarios=' || (SELECT COUNT(*) FROM destinatario) INTO v_info_a FROM dual;
    -- inicio de la transaccion
    BEGIN
        SELECT id_solicitud INTO v_sol FROM solicitud_recoleccion WHERE id_solicitud = v_sol FOR UPDATE;
        pr_registrar_envio(v_sol, 'CC', 'TX-1001', 'Andrea Prueba', '3001001001', NULL, 1, 3, 'Carrera 10 # 20-30',
                           1.5, 'Libros', 120000, 'N', 'N', NULL, 4, v_guia);
        DBMS_OUTPUT.PUT_LINE('  guia registrada: ' || v_guia);
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            v_cod := SQLCODE;
            v_msg := SUBSTR(SQLERRM, 1, 300);
            ROLLBACK;
    END;
    SELECT (SELECT COUNT(*) FROM envio) + (SELECT COUNT(*) FROM evento_envio) + (SELECT COUNT(*) FROM destinatario) INTO v_despues FROM dual;
    SELECT 'envios=' || (SELECT COUNT(*) FROM envio) || ', eventos=' || (SELECT COUNT(*) FROM evento_envio) || ', destinatarios=' || (SELECT COUNT(*) FROM destinatario) INTO v_info_d FROM dual;
    DBMS_OUTPUT.PUT_LINE('  Antes:   ' || v_info_a);
    DBMS_OUTPUT.PUT_LINE('  Despues: ' || v_info_d);
    IF v_cod <> 0 THEN
        DBMS_OUTPUT.PUT_LINE('  Error:   ' || v_msg);
    END IF;
    v_ok := v_cod = 0 AND v_despues - v_antes = 3;
    DBMS_OUTPUT.PUT_LINE('RESULTADO|T02|valido|registro del envio A (destinatario nuevo)|' || 'COMMIT; medida +3' || '|' || CASE WHEN v_cod = 0 THEN 'COMMIT; medida ' || TO_CHAR(v_despues - v_antes, 'FMS99') ELSE 'ORA' || TO_CHAR(v_cod, 'FM00000') END || '|' || CASE WHEN v_ok THEN 'OK' ELSE 'FALLA' END);
END;
/

PROMPT
PROMPT ===== T02 | valido | registro del envio B, fragil (destinatario nuevo)
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
    v_guia VARCHAR2(15);
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
    SELECT (SELECT COUNT(*) FROM envio) + (SELECT COUNT(*) FROM evento_envio) + (SELECT COUNT(*) FROM destinatario) INTO v_antes FROM dual;
    SELECT 'envios=' || (SELECT COUNT(*) FROM envio) || ', eventos=' || (SELECT COUNT(*) FROM evento_envio) || ', destinatarios=' || (SELECT COUNT(*) FROM destinatario) INTO v_info_a FROM dual;
    -- inicio de la transaccion
    BEGIN
        SELECT id_solicitud INTO v_sol FROM solicitud_recoleccion WHERE id_solicitud = v_sol FOR UPDATE;
        pr_registrar_envio(v_sol, 'CC', 'TX-1002', 'Bruno Prueba', '3001001002', NULL, 1, 2, 'Carrera 10 # 20-30',
                           1.5, 'Equipo de laboratorio', 300000, 'S', 'N', NULL, 4, v_guia);
        DBMS_OUTPUT.PUT_LINE('  guia registrada: ' || v_guia);
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            v_cod := SQLCODE;
            v_msg := SUBSTR(SQLERRM, 1, 300);
            ROLLBACK;
    END;
    SELECT (SELECT COUNT(*) FROM envio) + (SELECT COUNT(*) FROM evento_envio) + (SELECT COUNT(*) FROM destinatario) INTO v_despues FROM dual;
    SELECT 'envios=' || (SELECT COUNT(*) FROM envio) || ', eventos=' || (SELECT COUNT(*) FROM evento_envio) || ', destinatarios=' || (SELECT COUNT(*) FROM destinatario) INTO v_info_d FROM dual;
    DBMS_OUTPUT.PUT_LINE('  Antes:   ' || v_info_a);
    DBMS_OUTPUT.PUT_LINE('  Despues: ' || v_info_d);
    IF v_cod <> 0 THEN
        DBMS_OUTPUT.PUT_LINE('  Error:   ' || v_msg);
    END IF;
    v_ok := v_cod = 0 AND v_despues - v_antes = 3;
    DBMS_OUTPUT.PUT_LINE('RESULTADO|T02|valido|registro del envio B, fragil (destinatario nuevo)|' || 'COMMIT; medida +3' || '|' || CASE WHEN v_cod = 0 THEN 'COMMIT; medida ' || TO_CHAR(v_despues - v_antes, 'FMS99') ELSE 'ORA' || TO_CHAR(v_cod, 'FM00000') END || '|' || CASE WHEN v_ok THEN 'OK' ELSE 'FALLA' END);
END;
/

PROMPT
PROMPT ===== T02 | valido | registro del envio C (destinatario reutilizado, RN04)
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
    v_guia VARCHAR2(15);
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
    SELECT (SELECT COUNT(*) FROM envio) + (SELECT COUNT(*) FROM evento_envio) + (SELECT COUNT(*) FROM destinatario) INTO v_antes FROM dual;
    SELECT 'envios=' || (SELECT COUNT(*) FROM envio) || ', eventos=' || (SELECT COUNT(*) FROM evento_envio) || ', destinatarios=' || (SELECT COUNT(*) FROM destinatario) INTO v_info_a FROM dual;
    -- inicio de la transaccion
    BEGIN
        SELECT id_solicitud INTO v_sol FROM solicitud_recoleccion WHERE id_solicitud = v_sol FOR UPDATE;
        pr_registrar_envio(v_sol, 'CC', 'TX-1001', 'Andrea Prueba', '3001001001', NULL, 1, 3, 'Carrera 10 # 20-30',
                           1.5, 'Papeleria', 80000, 'N', 'N', NULL, 4, v_guia);
        DBMS_OUTPUT.PUT_LINE('  guia registrada: ' || v_guia);
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            v_cod := SQLCODE;
            v_msg := SUBSTR(SQLERRM, 1, 300);
            ROLLBACK;
    END;
    SELECT (SELECT COUNT(*) FROM envio) + (SELECT COUNT(*) FROM evento_envio) + (SELECT COUNT(*) FROM destinatario) INTO v_despues FROM dual;
    SELECT 'envios=' || (SELECT COUNT(*) FROM envio) || ', eventos=' || (SELECT COUNT(*) FROM evento_envio) || ', destinatarios=' || (SELECT COUNT(*) FROM destinatario) INTO v_info_d FROM dual;
    DBMS_OUTPUT.PUT_LINE('  Antes:   ' || v_info_a);
    DBMS_OUTPUT.PUT_LINE('  Despues: ' || v_info_d);
    IF v_cod <> 0 THEN
        DBMS_OUTPUT.PUT_LINE('  Error:   ' || v_msg);
    END IF;
    v_ok := v_cod = 0 AND v_despues - v_antes = 2;
    DBMS_OUTPUT.PUT_LINE('RESULTADO|T02|valido|registro del envio C (destinatario reutilizado, RN04)|' || 'COMMIT; medida +2' || '|' || CASE WHEN v_cod = 0 THEN 'COMMIT; medida ' || TO_CHAR(v_despues - v_antes, 'FMS99') ELSE 'ORA' || TO_CHAR(v_cod, 'FM00000') END || '|' || CASE WHEN v_ok THEN 'OK' ELSE 'FALLA' END);
END;
/

PROMPT
PROMPT ===== T02 | rechazado | fecha de compromiso anterior a la de registro tras crear el destinatario
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
    v_guia VARCHAR2(15);
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
    SELECT (SELECT COUNT(*) FROM envio) + (SELECT COUNT(*) FROM evento_envio) + (SELECT COUNT(*) FROM destinatario) INTO v_antes FROM dual;
    SELECT TO_CHAR((SELECT COUNT(*) FROM envio) + (SELECT COUNT(*) FROM evento_envio) + (SELECT COUNT(*) FROM destinatario)) INTO v_info_a FROM dual;
    -- inicio de la transaccion
    BEGIN
        SELECT id_solicitud INTO v_sol FROM solicitud_recoleccion WHERE id_solicitud = v_sol FOR UPDATE;
        pr_registrar_envio(v_sol, 'CC', 'TX-1009', 'Destinatario nuevo', '3001001009', NULL, 1, 3, 'Calle 1 # 2-3',
                           1.5, 'Libros', 50000, 'N', 'N', TRUNC(SYSDATE) - 1, 4, v_guia);
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            v_cod := SQLCODE;
            v_msg := SUBSTR(SQLERRM, 1, 300);
            ROLLBACK;
    END;
    SELECT (SELECT COUNT(*) FROM envio) + (SELECT COUNT(*) FROM evento_envio) + (SELECT COUNT(*) FROM destinatario) INTO v_despues FROM dual;
    SELECT TO_CHAR((SELECT COUNT(*) FROM envio) + (SELECT COUNT(*) FROM evento_envio) + (SELECT COUNT(*) FROM destinatario)) INTO v_info_d FROM dual;
    DBMS_OUTPUT.PUT_LINE('  Antes:   ' || v_info_a);
    DBMS_OUTPUT.PUT_LINE('  Despues: ' || v_info_d);
    IF v_cod <> 0 THEN
        DBMS_OUTPUT.PUT_LINE('  Error:   ' || v_msg);
    END IF;
    v_ok := v_cod IN (-2290) AND v_despues = v_antes;
    DBMS_OUTPUT.PUT_LINE('RESULTADO|T02|rechazado|fecha de compromiso anterior a la de registro tras crear el destinatario|' || 'ORA-02290 (RN03, CHECK ENVIO_COMPROMISO_CK); ROLLBACK, medida sin cambio' || '|' || CASE WHEN v_cod = 0 THEN 'sin error' ELSE 'ORA' || TO_CHAR(v_cod, 'FM00000') END || '; medida ' || v_antes || ' -> ' || v_despues || '|' || CASE WHEN v_ok THEN 'OK' ELSE 'FALLA' END);
END;
/

PROMPT
PROMPT ===== T02 | rechazado | registro sin peso (dato obligatorio)
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
    v_guia VARCHAR2(15);
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
    SELECT (SELECT COUNT(*) FROM envio) + (SELECT COUNT(*) FROM evento_envio) + (SELECT COUNT(*) FROM destinatario) INTO v_antes FROM dual;
    SELECT TO_CHAR((SELECT COUNT(*) FROM envio) + (SELECT COUNT(*) FROM evento_envio) + (SELECT COUNT(*) FROM destinatario)) INTO v_info_a FROM dual;
    -- inicio de la transaccion
    BEGIN
        SELECT id_solicitud INTO v_sol FROM solicitud_recoleccion WHERE id_solicitud = v_sol FOR UPDATE;
        pr_registrar_envio(v_sol, 'CC', 'TX-1010', 'Destinatario nuevo', '3001001010', NULL, 1, 3, 'Calle 1 # 2-3',
                           NULL, 'Libros', 50000, 'N', 'N', NULL, 4, v_guia);
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            v_cod := SQLCODE;
            v_msg := SUBSTR(SQLERRM, 1, 300);
            ROLLBACK;
    END;
    SELECT (SELECT COUNT(*) FROM envio) + (SELECT COUNT(*) FROM evento_envio) + (SELECT COUNT(*) FROM destinatario) INTO v_despues FROM dual;
    SELECT TO_CHAR((SELECT COUNT(*) FROM envio) + (SELECT COUNT(*) FROM evento_envio) + (SELECT COUNT(*) FROM destinatario)) INTO v_info_d FROM dual;
    DBMS_OUTPUT.PUT_LINE('  Antes:   ' || v_info_a);
    DBMS_OUTPUT.PUT_LINE('  Despues: ' || v_info_d);
    IF v_cod <> 0 THEN
        DBMS_OUTPUT.PUT_LINE('  Error:   ' || v_msg);
    END IF;
    v_ok := v_cod IN (-20002) AND v_despues = v_antes AND INSTR(v_msg, 'RN02') > 0;
    DBMS_OUTPUT.PUT_LINE('RESULTADO|T02|rechazado|registro sin peso (dato obligatorio)|' || 'ORA-20002 (RN02); ROLLBACK, medida sin cambio' || '|' || CASE WHEN v_cod = 0 THEN 'sin error' ELSE 'ORA' || TO_CHAR(v_cod, 'FM00000') END || '; medida ' || v_antes || ' -> ' || v_despues || '|' || CASE WHEN v_ok THEN 'OK' ELSE 'FALLA' END);
END;
/
