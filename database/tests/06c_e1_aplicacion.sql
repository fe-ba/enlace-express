-- Prueba de E1 como la hace la aplicacion: con la cuenta svc_cliente (rol_cliente)
-- y CURRENT_SCHEMA = BD_ENLACE_EXPRESS. Parametro &1: el codigo generado por 06b.
-- Hace COMMIT del registro, como la aplicacion; 06d limpia lo creado.
-- Uso: lo orquesta database/tests/test-e1.sh
WHENEVER SQLERROR EXIT FAILURE
SET DEFINE ON
SET VERIFY OFF
SET LINESIZE 250
SET SERVEROUTPUT ON SIZE UNLIMITED FORMAT TRUNCATED
DEFINE codigo_app = "&1"

DECLARE
    c_hash CONSTANT VARCHAR2(60) := '$2a$10$' || RPAD('y', 53, 'y');
    v_ok PLS_INTEGER := 0;
    v_falla PLS_INTEGER := 0;
    v_id NUMBER;
    v_hash VARCHAR2(100); v_rol VARCHAR2(12); v_estado VARCHAR2(10); v_emp NUMBER; v_cli NUMBER;
    v_cod NUMBER; v_msg VARCHAR2(300);

    PROCEDURE chk(p_desc IN VARCHAR2, p_cond IN BOOLEAN) IS
    BEGIN
        IF p_cond THEN v_ok := v_ok + 1; ELSE v_falla := v_falla + 1; END IF;
        DBMS_OUTPUT.PUT_LINE(CASE WHEN p_cond THEN 'OK   ' ELSE 'FALLA ' END || 'svc_cliente ' || p_desc);
    END chk;

    -- sentencia dinamica que debe ser rechazada por falta de privilegios
    PROCEDURE rechazo(p_desc IN VARCHAR2, p_sql IN VARCHAR2) IS
    BEGIN
        v_cod := 0;
        BEGIN EXECUTE IMMEDIATE p_sql; EXCEPTION WHEN OTHERS THEN v_cod := SQLCODE; v_msg := SQLERRM; END;
        chk(p_desc || ' se rechaza -> ' || CASE WHEN v_cod = 0 THEN 'sin error' ELSE 'ORA' || TO_CHAR(v_cod, 'FM00000') END,
            v_cod IN (-942, -1031, -41900, -6550));
    END rechazo;
BEGIN
    v_id := pkg_seguridad.registrar_empleado('E1-APP-9301', '&codigo_app', 'e1_app_mensajero', c_hash);
    COMMIT;
    chk('registra al mensajero con su codigo por pkg_seguridad (id_usuario ' || v_id || ')', v_id IS NOT NULL);
    pkg_seguridad.datos_ingreso('e1_app_mensajero', v_hash, v_rol, v_estado, v_emp, v_cli);
    chk('datos_ingreso devuelve hash, rol MENSAJERO, estado ACTIVO y empleado 9301',
        v_hash = c_hash AND v_rol = 'MENSAJERO' AND v_estado = 'ACTIVO' AND v_emp = 9301 AND v_cli IS NULL);
    pkg_seguridad.registrar_ingreso('e1_app_mensajero');
    COMMIT;
    chk('registrar_ingreso confirma sin error', TRUE);
    pkg_seguridad.datos_ingreso('nadie_registrado', v_hash, v_rol, v_estado, v_emp, v_cli);
    chk('datos_ingreso de un usuario inexistente devuelve nulos', v_hash IS NULL AND v_rol IS NULL AND v_estado IS NULL);
    BEGIN
        v_id := pkg_seguridad.registrar_empleado('E1-APP-9301', '&codigo_app', 'e1_app_otro', c_hash);
        chk('reutilizar el codigo', FALSE);
    EXCEPTION WHEN OTHERS THEN
        chk('reutilizar el codigo -> ORA' || TO_CHAR(SQLCODE, 'FM00000'), SQLCODE = -20101);
    END;

    rechazo('SELECT USUARIO_APLICACION', 'SELECT COUNT(*) FROM usuario_aplicacion');
    rechazo('SELECT CODIGO_ACTIVACION', 'SELECT COUNT(*) FROM codigo_activacion');
    rechazo('INSERT USUARIO_APLICACION', 'INSERT INTO usuario_aplicacion (nombre_usuario, hash_contrasena, rol, id_empleado) VALUES (''x'', ''y'', ''GERENCIA'', 1)');
    rechazo('DELETE USUARIO_APLICACION', 'DELETE FROM usuario_aplicacion');
    rechazo('EXECUTE pkg_codigos_activacion', 'DECLARE c VARCHAR2(20); BEGIN c := pkg_codigos_activacion.generar_para_empleado(''E1-APP-9301''); END;');
    DBMS_OUTPUT.PUT_LINE('svc_cliente: ' || v_ok || ' OK, ' || v_falla || ' FALLA');
END;
/
