-- Las cuentas de servicio distintas de svc_cliente no tienen acceso a la extension
-- E1: ni a sus tablas ni a sus paquetes. Corre con la cuenta con la que se conecte
-- (svc_gerencia, svc_centro, svc_mesa o svc_mensajero); lo orquesta test-e1.sh.
WHENEVER SQLERROR EXIT FAILURE
SET DEFINE OFF
SET LINESIZE 250
SET SERVEROUTPUT ON SIZE UNLIMITED FORMAT TRUNCATED
DECLARE
    v_cuenta VARCHAR2(30) := SYS_CONTEXT('USERENV', 'SESSION_USER');
    v_ok PLS_INTEGER := 0;
    v_falla PLS_INTEGER := 0;
    PROCEDURE rechazo(p_desc IN VARCHAR2, p_sql IN VARCHAR2) IS
        v_cod NUMBER := 0;
        v_bien BOOLEAN;
    BEGIN
        BEGIN EXECUTE IMMEDIATE p_sql; EXCEPTION WHEN OTHERS THEN v_cod := SQLCODE; END;
        v_bien := v_cod IN (-942, -1031, -41900, -6550);
        IF v_bien THEN v_ok := v_ok + 1; ELSE v_falla := v_falla + 1; END IF;
        DBMS_OUTPUT.PUT_LINE(CASE WHEN v_bien THEN 'OK   ' ELSE 'FALLA ' END || v_cuenta || ' ' || p_desc || ' se rechaza -> '
            || CASE WHEN v_cod = 0 THEN 'sin error' ELSE 'ORA' || TO_CHAR(v_cod, 'FM00000') END);
    END rechazo;
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- ' || v_cuenta || ' ---');
    rechazo('SELECT USUARIO_APLICACION', 'SELECT COUNT(*) FROM usuario_aplicacion');
    rechazo('SELECT CODIGO_ACTIVACION', 'SELECT COUNT(*) FROM codigo_activacion');
    rechazo('EXECUTE pkg_seguridad', 'DECLARE h VARCHAR2(100); r VARCHAR2(12); e VARCHAR2(10); i NUMBER; c NUMBER; BEGIN pkg_seguridad.datos_ingreso(''x'', h, r, e, i, c); END;');
    rechazo('EXECUTE pkg_codigos_activacion', 'DECLARE c VARCHAR2(20); BEGIN c := pkg_codigos_activacion.generar_para_empleado(''x''); END;');
    DBMS_OUTPUT.PUT_LINE(v_cuenta || ': ' || v_ok || ' OK, ' || v_falla || ' FALLA');
END;
/
