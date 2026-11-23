-- Extension E1: generacion de codigos de activacion. Solo la ejecuta el
-- administrador (el propietario); no se concede a ningun rol.
-- El codigo son 12 caracteres de un alfabeto de 32 (sin I, O, 0 ni 1), obtenidos
-- de DBMS_CRYPTO.RANDOMBYTES (aleatorio criptografico; el propietario recibe el
-- privilegio en database/admin/05_privilegios_extensiones.sql). Se muestra como
-- XXXX-XXXX-XXXX. En la base solo queda su SHA-256 en hexadecimal sobre el codigo
-- sin guiones, en mayusculas. Sin COMMIT: lo controla quien llama.
WHENEVER SQLERROR EXIT FAILURE

CREATE OR REPLACE PACKAGE pkg_codigos_activacion AS
    c_err_empleado CONSTANT PLS_INTEGER := -20110;
    c_err_cliente  CONSTANT PLS_INTEGER := -20111;

    -- Genera un codigo para un empleado ACTIVO; devuelve el codigo en claro (unica vez que existe).
    FUNCTION generar_para_empleado(p_documento IN VARCHAR2, p_horas_vigencia IN NUMBER DEFAULT 72) RETURN VARCHAR2;
    -- Genera un codigo para un cliente ACTIVO.
    FUNCTION generar_para_cliente(p_nit IN VARCHAR2, p_horas_vigencia IN NUMBER DEFAULT 72) RETURN VARCHAR2;
    -- SHA-256 en hexadecimal del codigo normalizado (sin guiones ni espacios, en mayusculas).
    FUNCTION hash_codigo(p_codigo IN VARCHAR2) RETURN VARCHAR2;
END pkg_codigos_activacion;
/

CREATE OR REPLACE PACKAGE BODY pkg_codigos_activacion AS
    c_alfabeto CONSTANT VARCHAR2(32) := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    c_largo    CONSTANT PLS_INTEGER := 12;

    FUNCTION normalizar(p_codigo IN VARCHAR2) RETURN VARCHAR2 IS
    BEGIN
        RETURN UPPER(REPLACE(REPLACE(TRIM(p_codigo), '-', ''), ' ', ''));
    END normalizar;

    FUNCTION hash_codigo(p_codigo IN VARCHAR2) RETURN VARCHAR2 IS
    BEGIN
        RETURN LOWER(RAWTOHEX(DBMS_CRYPTO.HASH(UTL_RAW.CAST_TO_RAW(normalizar(p_codigo)), DBMS_CRYPTO.HASH_SH256)));
    END hash_codigo;

    -- 12 caracteres: cada byte aleatorio se reduce modulo 32 (256 es multiplo de 32, sin sesgo)
    FUNCTION codigo_aleatorio RETURN VARCHAR2 IS
        v_bytes RAW(12) := DBMS_CRYPTO.RANDOMBYTES(c_largo);
        v_codigo VARCHAR2(14);
    BEGIN
        FOR i IN 1 .. c_largo LOOP
            v_codigo := v_codigo || SUBSTR(c_alfabeto, MOD(TO_NUMBER(RAWTOHEX(UTL_RAW.SUBSTR(v_bytes, i, 1)), 'XX'), 32) + 1, 1);
            IF MOD(i, 4) = 0 AND i < c_largo THEN
                v_codigo := v_codigo || '-';
            END IF;
        END LOOP;
        RETURN v_codigo;
    END codigo_aleatorio;

    PROCEDURE validar_vigencia(p_horas IN NUMBER) IS
    BEGIN
        IF p_horas IS NULL OR p_horas <= 0 OR p_horas > 24 * 90 THEN
            RAISE_APPLICATION_ERROR(-20112, 'E1: la vigencia del código debe estar entre 1 y 2160 horas');
        END IF;
    END validar_vigencia;

    FUNCTION generar_para_empleado(p_documento IN VARCHAR2, p_horas_vigencia IN NUMBER DEFAULT 72) RETURN VARCHAR2 IS
        v_id     empleado.id_empleado%TYPE;
        v_codigo VARCHAR2(14);
    BEGIN
        validar_vigencia(p_horas_vigencia);
        BEGIN
            SELECT id_empleado INTO v_id FROM empleado WHERE documento = p_documento AND estado = 'ACTIVO';
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(c_err_empleado, 'E1: no existe un empleado ACTIVO con el documento ' || p_documento);
        END;
        v_codigo := codigo_aleatorio;
        INSERT INTO codigo_activacion (codigo_hash, id_empleado, fecha_generacion, fecha_vencimiento)
        VALUES (hash_codigo(v_codigo), v_id, LOCALTIMESTAMP, LOCALTIMESTAMP + NUMTODSINTERVAL(p_horas_vigencia, 'HOUR'));
        RETURN v_codigo;
    END generar_para_empleado;

    FUNCTION generar_para_cliente(p_nit IN VARCHAR2, p_horas_vigencia IN NUMBER DEFAULT 72) RETURN VARCHAR2 IS
        v_id     cliente.id_cliente%TYPE;
        v_codigo VARCHAR2(14);
    BEGIN
        validar_vigencia(p_horas_vigencia);
        BEGIN
            SELECT id_cliente INTO v_id FROM cliente WHERE nit = p_nit AND estado = 'ACTIVO';
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(c_err_cliente, 'E1: no existe un cliente ACTIVO con el NIT ' || p_nit);
        END;
        v_codigo := codigo_aleatorio;
        INSERT INTO codigo_activacion (codigo_hash, id_cliente, fecha_generacion, fecha_vencimiento)
        VALUES (hash_codigo(v_codigo), v_id, LOCALTIMESTAMP, LOCALTIMESTAMP + NUMTODSINTERVAL(p_horas_vigencia, 'HOUR'));
        RETURN v_codigo;
    END generar_para_cliente;
END pkg_codigos_activacion;
/
