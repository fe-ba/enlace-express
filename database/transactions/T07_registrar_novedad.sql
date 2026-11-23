-- T07. Registrar una novedad
-- Usuario: U4 (cuenta svc_mensajero). Reglas verificadas: RN07, RN08, RN12.
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
PROMPT ===== T07 | valido | novedad del envio C: DESTINATARIO_AUSENTE, resultado NOVEDAD y evento
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
    WHERE  a.numero_guia = v_g(3) AND a.numero_intento = 1;
    SELECT (SELECT COUNT(*) FROM novedad) + (SELECT COUNT(*) FROM asignacion_despacho WHERE resultado = 'NOVEDAD') + (SELECT COUNT(*) FROM evento_envio WHERE id_estado = 7) INTO v_antes FROM dual;
    SELECT (SELECT resultado FROM asignacion_despacho WHERE id_asignacion = v_a) || ' / ' || (SELECT LISTAGG(ev.id_estado, '>') WITHIN GROUP (ORDER BY ev.fecha_hora) FROM evento_envio ev WHERE ev.numero_guia = v_g(3)) INTO v_info_a FROM dual;
    -- inicio de la transaccion
    BEGIN
        SELECT id_asignacion INTO v_x FROM asignacion_despacho WHERE id_asignacion = v_a FOR UPDATE;
        INSERT INTO novedad (id_asignacion, tipo_novedad, descripcion)
        VALUES (v_a, 'DESTINATARIO_AUSENTE', 'Nadie atendio en la direccion');
        UPDATE asignacion_despacho SET resultado = 'NOVEDAD', hora_visita = LOCALTIMESTAMP WHERE id_asignacion = v_a;
        v_t := instante(v_g(3));
        INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion)
        VALUES (v_g(3), 7, v_mens, v_t, 'Novedad: destinatario ausente');  -- CON_NOVEDAD
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            v_cod := SQLCODE;
            v_msg := SUBSTR(SQLERRM, 1, 300);
            ROLLBACK;
    END;
    SELECT (SELECT COUNT(*) FROM novedad) + (SELECT COUNT(*) FROM asignacion_despacho WHERE resultado = 'NOVEDAD') + (SELECT COUNT(*) FROM evento_envio WHERE id_estado = 7) INTO v_despues FROM dual;
    SELECT (SELECT resultado FROM asignacion_despacho WHERE id_asignacion = v_a) || ' / ' || (SELECT LISTAGG(ev.id_estado, '>') WITHIN GROUP (ORDER BY ev.fecha_hora) FROM evento_envio ev WHERE ev.numero_guia = v_g(3)) INTO v_info_d FROM dual;
    DBMS_OUTPUT.PUT_LINE('  Antes:   ' || v_info_a);
    DBMS_OUTPUT.PUT_LINE('  Despues: ' || v_info_d);
    IF v_cod <> 0 THEN
        DBMS_OUTPUT.PUT_LINE('  Error:   ' || v_msg);
    END IF;
    v_ok := v_cod = 0 AND v_despues - v_antes = 3;
    DBMS_OUTPUT.PUT_LINE('RESULTADO|T07|valido|novedad del envio C: DESTINATARIO_AUSENTE, resultado NOVEDAD y evento|' || 'COMMIT; medida +3' || '|' || CASE WHEN v_cod = 0 THEN 'COMMIT; medida ' || TO_CHAR(v_despues - v_antes, 'FMS99') ELSE 'ORA' || TO_CHAR(v_cod, 'FM00000') END || '|' || CASE WHEN v_ok THEN 'OK' ELSE 'FALLA' END);
END;
/

PROMPT
PROMPT ===== T07 | rechazado | segunda novedad para el mismo intento
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
    WHERE  a.numero_guia = v_g(3) AND a.numero_intento = 1;
    SELECT (SELECT COUNT(*) FROM novedad) + (SELECT COUNT(*) FROM asignacion_despacho WHERE resultado = 'NOVEDAD') + (SELECT COUNT(*) FROM evento_envio WHERE id_estado = 7) + (SELECT COUNT(*) FROM asignacion_despacho WHERE hora_visita IS NOT NULL) INTO v_antes FROM dual;
    SELECT (SELECT resultado FROM asignacion_despacho WHERE id_asignacion = v_a) || ' / ' || (SELECT LISTAGG(ev.id_estado, '>') WITHIN GROUP (ORDER BY ev.fecha_hora) FROM evento_envio ev WHERE ev.numero_guia = v_g(3)) INTO v_info_a FROM dual;
    -- inicio de la transaccion
    BEGIN
        SELECT id_asignacion INTO v_x FROM asignacion_despacho WHERE id_asignacion = v_a FOR UPDATE;
        UPDATE asignacion_despacho SET hora_visita = LOCALTIMESTAMP WHERE id_asignacion = v_a;
        INSERT INTO novedad (id_asignacion, tipo_novedad, descripcion)
        VALUES (v_a, 'OTRA', 'Novedad repetida');
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            v_cod := SQLCODE;
            v_msg := SUBSTR(SQLERRM, 1, 300);
            ROLLBACK;
    END;
    SELECT (SELECT COUNT(*) FROM novedad) + (SELECT COUNT(*) FROM asignacion_despacho WHERE resultado = 'NOVEDAD') + (SELECT COUNT(*) FROM evento_envio WHERE id_estado = 7) + (SELECT COUNT(*) FROM asignacion_despacho WHERE hora_visita IS NOT NULL) INTO v_despues FROM dual;
    SELECT (SELECT resultado FROM asignacion_despacho WHERE id_asignacion = v_a) || ' / ' || (SELECT LISTAGG(ev.id_estado, '>') WITHIN GROUP (ORDER BY ev.fecha_hora) FROM evento_envio ev WHERE ev.numero_guia = v_g(3)) INTO v_info_d FROM dual;
    DBMS_OUTPUT.PUT_LINE('  Antes:   ' || v_info_a);
    DBMS_OUTPUT.PUT_LINE('  Despues: ' || v_info_d);
    IF v_cod <> 0 THEN
        DBMS_OUTPUT.PUT_LINE('  Error:   ' || v_msg);
    END IF;
    v_ok := v_cod IN (-1) AND v_despues = v_antes;
    DBMS_OUTPUT.PUT_LINE('RESULTADO|T07|rechazado|segunda novedad para el mismo intento|' || 'ORA-00001 (RN08, UNIQUE NOVEDAD_ASIGNACION_UK); ROLLBACK, medida sin cambio' || '|' || CASE WHEN v_cod = 0 THEN 'sin error' ELSE 'ORA' || TO_CHAR(v_cod, 'FM00000') END || '; medida ' || v_antes || ' -> ' || v_despues || '|' || CASE WHEN v_ok THEN 'OK' ELSE 'FALLA' END);
END;
/

PROMPT
PROMPT ===== T07 | rechazado | resultado NOVEDAD sin la novedad registrada
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
    WHERE  a.numero_guia = 'EE0000000000024' AND a.numero_intento = 1;
    SELECT (SELECT COUNT(*) FROM novedad) + (SELECT COUNT(*) FROM asignacion_despacho WHERE resultado = 'NOVEDAD') + (SELECT COUNT(*) FROM evento_envio WHERE id_estado = 7) + (SELECT COUNT(*) FROM asignacion_despacho WHERE hora_visita IS NOT NULL) INTO v_antes FROM dual;
    SELECT (SELECT resultado FROM asignacion_despacho WHERE id_asignacion = v_a) || ' / ' || (SELECT LISTAGG(ev.id_estado, '>') WITHIN GROUP (ORDER BY ev.fecha_hora) FROM evento_envio ev WHERE ev.numero_guia = 'EE0000000000024') INTO v_info_a FROM dual;
    -- inicio de la transaccion
    BEGIN
        SELECT id_asignacion INTO v_x FROM asignacion_despacho WHERE id_asignacion = v_a FOR UPDATE;
        UPDATE asignacion_despacho SET hora_visita = LOCALTIMESTAMP WHERE id_asignacion = v_a;
        UPDATE asignacion_despacho SET resultado = 'NOVEDAD' WHERE id_asignacion = v_a;
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            v_cod := SQLCODE;
            v_msg := SUBSTR(SQLERRM, 1, 300);
            ROLLBACK;
    END;
    SELECT (SELECT COUNT(*) FROM novedad) + (SELECT COUNT(*) FROM asignacion_despacho WHERE resultado = 'NOVEDAD') + (SELECT COUNT(*) FROM evento_envio WHERE id_estado = 7) + (SELECT COUNT(*) FROM asignacion_despacho WHERE hora_visita IS NOT NULL) INTO v_despues FROM dual;
    SELECT (SELECT resultado FROM asignacion_despacho WHERE id_asignacion = v_a) || ' / ' || (SELECT LISTAGG(ev.id_estado, '>') WITHIN GROUP (ORDER BY ev.fecha_hora) FROM evento_envio ev WHERE ev.numero_guia = 'EE0000000000024') INTO v_info_d FROM dual;
    DBMS_OUTPUT.PUT_LINE('  Antes:   ' || v_info_a);
    DBMS_OUTPUT.PUT_LINE('  Despues: ' || v_info_d);
    IF v_cod <> 0 THEN
        DBMS_OUTPUT.PUT_LINE('  Error:   ' || v_msg);
    END IF;
    v_ok := v_cod IN (-20008) AND v_despues = v_antes AND INSTR(v_msg, 'RN08') > 0;
    DBMS_OUTPUT.PUT_LINE('RESULTADO|T07|rechazado|resultado NOVEDAD sin la novedad registrada|' || 'ORA-20008 (RN08); ROLLBACK, medida sin cambio' || '|' || CASE WHEN v_cod = 0 THEN 'sin error' ELSE 'ORA' || TO_CHAR(v_cod, 'FM00000') END || '; medida ' || v_antes || ' -> ' || v_despues || '|' || CASE WHEN v_ok THEN 'OK' ELSE 'FALLA' END);
END;
/

PROMPT
PROMPT ===== T07 | rechazado | evento CON_NOVEDAD sobre un envio ya ENTREGADO (novedad y resultado ya registrados)
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
    WHERE  a.numero_guia = 'EE0000000000020' AND a.numero_intento = 1;
    SELECT (SELECT COUNT(*) FROM novedad) + (SELECT COUNT(*) FROM asignacion_despacho WHERE resultado = 'NOVEDAD') + (SELECT COUNT(*) FROM evento_envio WHERE id_estado = 7) INTO v_antes FROM dual;
    SELECT (SELECT resultado FROM asignacion_despacho WHERE id_asignacion = v_a) || ' / ' || (SELECT LISTAGG(ev.id_estado, '>') WITHIN GROUP (ORDER BY ev.fecha_hora) FROM evento_envio ev WHERE ev.numero_guia = 'EE0000000000020') INTO v_info_a FROM dual;
    -- inicio de la transaccion
    BEGIN
        SELECT id_asignacion INTO v_x FROM asignacion_despacho WHERE id_asignacion = v_a FOR UPDATE;
        INSERT INTO novedad (id_asignacion, tipo_novedad, descripcion)
        VALUES (v_a, 'OTRA', 'Novedad sobre un envio ya entregado');
        UPDATE asignacion_despacho SET resultado = 'NOVEDAD' WHERE id_asignacion = v_a;
        v_t := instante('EE0000000000020');
        INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion)
        VALUES ('EE0000000000020', 7, v_mens, v_t, 'Novedad tardia');  -- CON_NOVEDAD
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            v_cod := SQLCODE;
            v_msg := SUBSTR(SQLERRM, 1, 300);
            ROLLBACK;
    END;
    SELECT (SELECT COUNT(*) FROM novedad) + (SELECT COUNT(*) FROM asignacion_despacho WHERE resultado = 'NOVEDAD') + (SELECT COUNT(*) FROM evento_envio WHERE id_estado = 7) INTO v_despues FROM dual;
    SELECT (SELECT resultado FROM asignacion_despacho WHERE id_asignacion = v_a) || ' / ' || (SELECT LISTAGG(ev.id_estado, '>') WITHIN GROUP (ORDER BY ev.fecha_hora) FROM evento_envio ev WHERE ev.numero_guia = 'EE0000000000020') INTO v_info_d FROM dual;
    DBMS_OUTPUT.PUT_LINE('  Antes:   ' || v_info_a);
    DBMS_OUTPUT.PUT_LINE('  Despues: ' || v_info_d);
    IF v_cod <> 0 THEN
        DBMS_OUTPUT.PUT_LINE('  Error:   ' || v_msg);
    END IF;
    v_ok := v_cod IN (-20012) AND v_despues = v_antes AND INSTR(v_msg, 'RN12') > 0;
    DBMS_OUTPUT.PUT_LINE('RESULTADO|T07|rechazado|evento CON_NOVEDAD sobre un envio ya ENTREGADO (novedad y resultado ya registrados)|' || 'ORA-20012 (RN12); ROLLBACK, medida sin cambio' || '|' || CASE WHEN v_cod = 0 THEN 'sin error' ELSE 'ORA' || TO_CHAR(v_cod, 'FM00000') END || '; medida ' || v_antes || ' -> ' || v_despues || '|' || CASE WHEN v_ok THEN 'OK' ELSE 'FALLA' END);
END;
/
