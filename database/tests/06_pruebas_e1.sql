-- Pruebas de la extension E1 (usuarios y codigos de activacion): logica de
-- pkg_codigos_activacion y pkg_seguridad, ejecutada como el propietario sobre
-- empleados y clientes propios de la prueba (claves 9201 en adelante). Termina
-- con ROLLBACK. La parte que corre como svc_cliente (lo que hace la aplicacion)
-- esta en 06c_e1_aplicacion.sql; todo se orquesta con test-e1.sh.
-- Uso: database/run.sh propietario tests/06_pruebas_e1.sql
WHENEVER SQLERROR EXIT FAILURE
SET DEFINE OFF
SET LINESIZE 250
SET SERVEROUTPUT ON SIZE UNLIMITED FORMAT TRUNCATED

DECLARE
    c_hash CONSTANT VARCHAR2(60) := '$2a$10$' || RPAD('x', 53, 'x');
    v_ok     PLS_INTEGER := 0;
    v_falla  PLS_INTEGER := 0;
    v_codigo VARCHAR2(20);
    v_id     NUMBER;
    g_cod    NUMBER;          -- SQLCODE del ultimo intento (0 si paso)
    g_msg    VARCHAR2(400);
    g_id     NUMBER;
    v_c1 VARCHAR2(20); v_c2 VARCHAR2(20); v_c3 VARCHAR2(20); v_c4 VARCHAR2(20);
    v_m1 VARCHAR2(400); v_m2 VARCHAR2(400); v_m3 VARCHAR2(400); v_m4 VARCHAR2(400);
    v_rol VARCHAR2(12); v_hash VARCHAR2(100); v_estado VARCHAR2(10); v_emp NUMBER; v_cli NUMBER; v_n NUMBER;
    v_t TIMESTAMP;

    PROCEDURE chk(p_desc IN VARCHAR2, p_cond IN BOOLEAN) IS
    BEGIN
        IF p_cond THEN v_ok := v_ok + 1; ELSE v_falla := v_falla + 1; END IF;
        DBMS_OUTPUT.PUT_LINE(CASE WHEN p_cond THEN 'OK   ' ELSE 'FALLA ' END || p_desc);
    END chk;

    PROCEDURE cod(p_desc IN VARCHAR2, p_esperado IN NUMBER) IS
    BEGIN
        chk(p_desc || ' -> ' || CASE WHEN g_cod = 0 THEN 'sin error' ELSE 'ORA' || TO_CHAR(g_cod, 'FM00000') END
            || CASE WHEN g_cod <> p_esperado THEN ' (esperado ' || p_esperado || ': ' || SUBSTR(g_msg, 1, 100) || ')' END,
            g_cod = p_esperado);
    END cod;

    PROCEDURE gen_emp(p_doc IN VARCHAR2, p_horas IN NUMBER DEFAULT 72) IS
    BEGIN
        g_cod := 0; g_msg := NULL; v_codigo := NULL;
        v_codigo := pkg_codigos_activacion.generar_para_empleado(p_doc, p_horas);
    EXCEPTION WHEN OTHERS THEN g_cod := SQLCODE; g_msg := SQLERRM;
    END gen_emp;

    PROCEDURE gen_cli(p_nit IN VARCHAR2) IS
    BEGIN
        g_cod := 0; g_msg := NULL; v_codigo := NULL;
        v_codigo := pkg_codigos_activacion.generar_para_cliente(p_nit);
    EXCEPTION WHEN OTHERS THEN g_cod := SQLCODE; g_msg := SQLERRM;
    END gen_cli;

    PROCEDURE r_emp(p_doc IN VARCHAR2, p_codigo IN VARCHAR2, p_usuario IN VARCHAR2, p_hash IN VARCHAR2 DEFAULT NULL) IS
    BEGIN
        g_cod := 0; g_msg := NULL; g_id := NULL;
        g_id := pkg_seguridad.registrar_empleado(p_doc, p_codigo, p_usuario, NVL(p_hash, c_hash));
    EXCEPTION WHEN OTHERS THEN g_cod := SQLCODE; g_msg := SQLERRM;
    END r_emp;

    PROCEDURE r_cli(p_nit IN VARCHAR2, p_codigo IN VARCHAR2, p_usuario IN VARCHAR2) IS
    BEGIN
        g_cod := 0; g_msg := NULL; g_id := NULL;
        g_id := pkg_seguridad.registrar_cliente(p_nit, p_codigo, p_usuario, c_hash);
    EXCEPTION WHEN OTHERS THEN g_cod := SQLCODE; g_msg := SQLERRM;
    END r_cli;

    PROCEDURE empleado(p_id IN NUMBER, p_cargo IN VARCHAR2, p_estado IN VARCHAR2 DEFAULT 'ACTIVO', p_mensajero IN BOOLEAN DEFAULT FALSE) IS
    BEGIN
        INSERT INTO empleado (id_empleado, id_centro, documento, nombres, apellidos, cargo, telefono, fecha_ingreso, estado)
        VALUES (p_id, 1, 'E1-' || p_id, 'Prueba', 'E1 ' || p_id, p_cargo, '3000000000', DATE '2026-01-05', p_estado);
        IF p_mensajero THEN
            INSERT INTO mensajero (id_empleado, id_zona, id_tipo_vehiculo) VALUES (p_id, 1, 1);
        END IF;
    END empleado;

    FUNCTION rol_de(p_id IN NUMBER) RETURN VARCHAR2 IS
        v VARCHAR2(12);
    BEGIN
        SELECT rol INTO v FROM usuario_aplicacion WHERE id_usuario = p_id;
        RETURN v;
    END rol_de;
BEGIN
    -- datos propios de la prueba
    empleado(9201, 'Mensajero', 'ACTIVO', TRUE);
    empleado(9202, 'Mensajero', 'ACTIVO', TRUE);
    empleado(9203, 'Gerente');
    empleado(9204, 'Auxiliar de centro');
    empleado(9205, 'Agente de mesa de servicio');
    empleado(9206, 'Contador');
    empleado(9207, 'Mensajero');                       -- cargo Mensajero pero sin fila en MENSAJERO
    empleado(9208, 'Mensajero', 'RETIRADO', TRUE);
    INSERT INTO cliente (id_cliente, nit, razon_social, tipo_cliente, telefono, correo, fecha_vinculacion, estado)
        VALUES (9201, '990000001', 'Cliente E1 activo', 'OFICINA', '3001', 'a@example.com', DATE '2026-01-10', 'ACTIVO');
    INSERT INTO cliente (id_cliente, nit, razon_social, tipo_cliente, telefono, correo, fecha_vinculacion, estado)
        VALUES (9202, '990000002', 'Cliente E1 inactivo', 'OFICINA', '3002', 'b@example.com', DATE '2026-01-10', 'INACTIVO');
    INSERT INTO cliente (id_cliente, nit, razon_social, tipo_cliente, telefono, correo, fecha_vinculacion, estado)
        VALUES (9203, '990000003', 'Cliente E1 otro', 'DROGUERIA', '3003', 'c@example.com', DATE '2026-01-10', 'ACTIVO');

    DBMS_OUTPUT.PUT_LINE('--- Generacion de codigos ---');
    gen_emp('E1-9201');
    cod('generar codigo para un mensajero activo', 0);
    v_c1 := v_codigo;
    chk('el codigo tiene el formato XXXX-XXXX-XXXX sin I, O, 0 ni 1 (' || v_c1 || ')',
        REGEXP_LIKE(v_c1, '^[A-HJ-NP-Z2-9]{4}-[A-HJ-NP-Z2-9]{4}-[A-HJ-NP-Z2-9]{4}$'));
    SELECT COUNT(*) INTO v_n FROM codigo_activacion WHERE codigo_hash = REPLACE(v_c1, '-', '') OR codigo_hash = v_c1;
    chk('la base no guarda el codigo en claro', v_n = 0);
    SELECT COUNT(*) INTO v_n FROM codigo_activacion WHERE LENGTH(codigo_hash) = 64 AND codigo_hash = LOWER(codigo_hash) AND codigo_hash = pkg_codigos_activacion.hash_codigo(v_c1);
    chk('el hash guardado es SHA-256 en hexadecimal (64 caracteres)', v_n = 1);
    gen_emp('E1-9208');
    cod('empleado RETIRADO: no se le genera codigo', -20110);
    gen_emp('NO-EXISTE');
    cod('documento inexistente: no se genera codigo', -20110);
    gen_cli('990000002');
    cod('cliente INACTIVO: no se genera codigo', -20111);
    gen_cli('000');
    cod('cliente inexistente: no se genera codigo', -20111);
    gen_emp('E1-9201', 0);
    cod('vigencia de 0 horas', -20112);

    DBMS_OUTPUT.PUT_LINE('--- Registro de empleados ---');
    r_emp('E1-9201', v_c1, 'e1_mensajero');
    cod('registrar al mensajero con su codigo', 0);
    v_id := g_id;
    chk('el rol se deriva del cargo Mensajero -> MENSAJERO', rol_de(v_id) = 'MENSAJERO');
    SELECT COUNT(*) INTO v_n FROM codigo_activacion WHERE fecha_uso IS NOT NULL AND id_usuario = v_id;
    chk('el codigo queda usado (fecha_uso e id_usuario)', v_n = 1);
    r_emp('E1-9201', v_c1, 'e1_mensajero_bis'); v_m1 := g_msg;
    cod('reutilizar el codigo', -20101);

    gen_emp('E1-9202'); v_c2 := v_codigo;
    UPDATE codigo_activacion SET fecha_generacion = LOCALTIMESTAMP - INTERVAL '2' HOUR, fecha_vencimiento = LOCALTIMESTAMP - INTERVAL '1' HOUR
     WHERE codigo_hash = pkg_codigos_activacion.hash_codigo(v_c2);
    r_emp('E1-9202', v_c2, 'e1_mensajero2'); v_m2 := g_msg;
    cod('codigo vencido', -20101);

    gen_emp('E1-9202'); v_c3 := v_codigo;
    r_emp('E1-9203', v_c3, 'e1_gerente_malo'); v_m3 := g_msg;
    cod('codigo de otro empleado', -20101);

    r_emp('NO-EXISTE', v_c3, 'e1_fantasma'); v_m4 := g_msg;
    cod('documento inexistente', -20101);
    chk('el mismo mensaje para codigo usado, vencido, ajeno y documento inexistente',
        v_m1 = v_m2 AND v_m2 = v_m3 AND v_m3 = v_m4 AND v_m1 LIKE '%E1: los datos de registro o el código no son válidos%');
    r_emp('E1-9208', v_c3, 'e1_retirado'); 
    cod('empleado RETIRADO no se registra (mismo mensaje)', -20101);

    r_emp('E1-9202', v_c3, 'e1_mensajero');
    cod('nombre de usuario repetido', -20102);
    r_emp('E1-9202', v_c3, 'e1_mensajero2', 'corto');
    cod('hash de contrasena invalido', -20104);
    r_emp('E1-9202', LOWER(REPLACE(v_c3, '-', '')), 'e1_mensajero2');
    cod('el mismo codigo escrito en minusculas y sin guiones sirve', 0);
    chk('segundo mensajero tambien MENSAJERO', rol_de(g_id) = 'MENSAJERO');

    gen_emp('E1-9201'); v_c4 := v_codigo;
    r_emp('E1-9201', v_c4, 'e1_otra_cuenta');
    cod('una segunda cuenta para el mismo empleado', -20105);

    DBMS_OUTPUT.PUT_LINE('--- Rol derivado del cargo ---');
    gen_emp('E1-9203'); r_emp('E1-9203', v_codigo, 'e1_gerente');
    cod('cargo Gerente', 0); chk('Gerente -> GERENCIA', rol_de(g_id) = 'GERENCIA');
    gen_emp('E1-9204'); r_emp('E1-9204', v_codigo, 'e1_auxiliar');
    cod('cargo Auxiliar de centro', 0); chk('Auxiliar de centro -> CENTRO', rol_de(g_id) = 'CENTRO');
    gen_emp('E1-9205'); r_emp('E1-9205', v_codigo, 'e1_agente');
    cod('cargo Agente de mesa de servicio', 0); chk('Agente de mesa de servicio -> MESA', rol_de(g_id) = 'MESA');
    gen_emp('E1-9206'); r_emp('E1-9206', v_codigo, 'e1_contador');
    cod('cargo sin acceso a la aplicacion (Contador)', -20103);
    gen_emp('E1-9207'); r_emp('E1-9207', v_codigo, 'e1_sin_fila');
    cod('cargo Mensajero sin fila en MENSAJERO', -20103);

    DBMS_OUTPUT.PUT_LINE('--- Registro de clientes ---');
    gen_cli('990000001'); v_c1 := v_codigo;
    cod('generar codigo para un cliente ACTIVO', 0);
    r_cli('990000001', v_c1, 'e1_cliente');
    cod('registrar al cliente con su NIT y su codigo', 0);
    v_id := g_id;
    chk('rol CLIENTE vinculado a la empresa', rol_de(v_id) = 'CLIENTE');
    SELECT id_cliente, id_empleado INTO v_cli, v_emp FROM usuario_aplicacion WHERE id_usuario = v_id;
    chk('la cuenta del cliente tiene id_cliente y no id_empleado', v_cli = 9201 AND v_emp IS NULL);
    gen_cli('990000001'); r_cli('990000001', v_codigo, 'e1_cliente2');
    cod('una empresa puede tener varias cuentas (otro codigo)', 0);
    gen_cli('990000003'); r_cli('990000001', v_codigo, 'e1_cliente3');
    cod('codigo de otra empresa', -20101);
    gen_emp('E1-9205'); r_cli('990000001', v_codigo, 'e1_cliente4');
    cod('codigo de un empleado usado como cliente', -20101);
    r_cli('990000002', v_c1, 'e1_cliente5');
    cod('NIT de cliente INACTIVO', -20101);

    DBMS_OUTPUT.PUT_LINE('--- Inicio de sesion ---');
    pkg_seguridad.datos_ingreso('e1_mensajero', v_hash, v_rol, v_estado, v_emp, v_cli);
    chk('datos_ingreso de un usuario existente: hash, rol, estado y empleado',
        v_hash = c_hash AND v_rol = 'MENSAJERO' AND v_estado = 'ACTIVO' AND v_emp = 9201 AND v_cli IS NULL);
    pkg_seguridad.datos_ingreso('e1_cliente', v_hash, v_rol, v_estado, v_emp, v_cli);
    chk('datos_ingreso de un cliente: rol CLIENTE e id_cliente', v_rol = 'CLIENTE' AND v_cli = 9201 AND v_emp IS NULL);
    pkg_seguridad.datos_ingreso('no_existe', v_hash, v_rol, v_estado, v_emp, v_cli);
    chk('datos_ingreso de un usuario inexistente devuelve nulos y no lanza error',
        v_hash IS NULL AND v_rol IS NULL AND v_estado IS NULL AND v_emp IS NULL AND v_cli IS NULL);
    UPDATE empleado SET estado = 'RETIRADO' WHERE id_empleado = 9201;
    pkg_seguridad.datos_ingreso('e1_mensajero', v_hash, v_rol, v_estado, v_emp, v_cli);
    SELECT estado INTO v_hash FROM usuario_aplicacion WHERE nombre_usuario = 'e1_mensajero';
    chk('empleado RETIRADO: la cuenta sale INACTIVA aunque su fila diga ACTIVO', v_estado = 'INACTIVO' AND v_hash = 'ACTIVO');
    UPDATE cliente SET estado = 'INACTIVO' WHERE id_cliente = 9201;
    pkg_seguridad.datos_ingreso('e1_cliente', v_hash, v_rol, v_estado, v_emp, v_cli);
    chk('cliente INACTIVO: la cuenta sale INACTIVA', v_estado = 'INACTIVO');
    UPDATE usuario_aplicacion SET estado = 'INACTIVO' WHERE nombre_usuario = 'e1_gerente';
    pkg_seguridad.datos_ingreso('e1_gerente', v_hash, v_rol, v_estado, v_emp, v_cli);
    chk('cuenta INACTIVA por su propio estado', v_estado = 'INACTIVO');
    pkg_seguridad.registrar_ingreso('e1_auxiliar');
    SELECT COUNT(*) INTO v_n FROM usuario_aplicacion WHERE nombre_usuario = 'e1_auxiliar' AND ultimo_ingreso IS NOT NULL;
    chk('registrar_ingreso anota ultimo_ingreso', v_n = 1);

    DBMS_OUTPUT.PUT_LINE('--- Restricciones de la tabla ---');
    BEGIN
        INSERT INTO usuario_aplicacion (nombre_usuario, hash_contrasena, rol, id_empleado, id_cliente)
        VALUES ('e1_mal', c_hash, 'CLIENTE', 9203, NULL);
        chk('CHECK de vinculo: rol CLIENTE con empleado', FALSE);
    EXCEPTION WHEN OTHERS THEN chk('CHECK de vinculo: rol CLIENTE con empleado -> ORA' || TO_CHAR(SQLCODE, 'FM00000'), SQLCODE = -2290);
    END;
    BEGIN
        INSERT INTO codigo_activacion (codigo_hash, id_empleado, id_cliente, fecha_generacion, fecha_vencimiento)
        VALUES (RPAD('a', 64, 'a'), 9203, 9201, LOCALTIMESTAMP, LOCALTIMESTAMP + INTERVAL '1' HOUR);
        chk('CHECK de destino: codigo para empleado y cliente a la vez', FALSE);
    EXCEPTION WHEN OTHERS THEN chk('CHECK de destino: codigo para empleado y cliente a la vez -> ORA' || TO_CHAR(SQLCODE, 'FM00000'), SQLCODE = -2290);
    END;

    DBMS_OUTPUT.PUT_LINE('--- Total ---');
    DBMS_OUTPUT.PUT_LINE('E1 (propietario): ' || v_ok || ' OK, ' || v_falla || ' FALLA');
END;
/
ROLLBACK;
