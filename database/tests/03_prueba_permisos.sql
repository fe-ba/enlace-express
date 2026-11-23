-- Prueba de permisos de las 5 cuentas de servicio (decision 12.1). Corre
-- como la cuenta con la que se conecta (SESSION_USER) y ejecuta sus casos:
--   database/run.sh svc_cliente tests/03_prueba_permisos.sql
-- o las cinco con database/tests/test-grants.sh. Necesita los datos
-- de seed. Termina con ROLLBACK. Un "rechazo" acepta ORA-00942 (la tabla
-- no es visible para la cuenta), ORA-01031 o ORA-41900 (privilegio insuficiente:
-- 23c da este ultimo cuando la cuenta ve la tabla pero no tiene ese privilegio).
WHENEVER SQLERROR EXIT FAILURE
SET DEFINE OFF
SET LINESIZE 250
SET SERVEROUTPUT ON SIZE UNLIMITED FORMAT TRUNCATED

DECLARE
    c_ninguno CONSTANT NUMBER := 0;
    c_rechazo CONSTANT NUMBER := -1;   -- 942, 1031 o 41900
    v_cuenta  VARCHAR2(30) := SYS_CONTEXT('USERENV', 'SESSION_USER');
    v_ok      PLS_INTEGER := 0;
    v_falla   PLS_INTEGER := 0;

    PROCEDURE caso(p_desc IN VARCHAR2, p_esperado IN NUMBER, p_sql IN VARCHAR2) IS
        v_cod  NUMBER := 0;
        v_msg  VARCHAR2(200);
        v_bien BOOLEAN;
    BEGIN
        BEGIN
            EXECUTE IMMEDIATE p_sql;
        EXCEPTION
            WHEN OTHERS THEN
                v_cod := SQLCODE;
                v_msg := SUBSTR(SQLERRM, 1, 120);
        END;
        IF p_esperado = c_rechazo THEN
            v_bien := v_cod IN (-942, -1031, -41900);
        ELSE
            v_bien := v_cod = p_esperado;
        END IF;
        IF v_bien THEN v_ok := v_ok + 1; ELSE v_falla := v_falla + 1; END IF;
        DBMS_OUTPUT.PUT_LINE(CASE WHEN v_bien THEN 'OK   ' ELSE 'FALLA ' END
            || v_cuenta || ' ' || p_desc || ' -> '
            || CASE WHEN v_cod = 0 THEN 'sin error' ELSE 'ORA' || TO_CHAR(v_cod, 'FM00000') END
            || CASE WHEN NOT v_bien THEN ': ' || v_msg END);
    END caso;

    PROCEDURE consulta(p_objeto IN VARCHAR2) IS
    BEGIN
        caso('SELECT ' || p_objeto || ' pasa', c_ninguno, 'SELECT COUNT(*) FROM ' || p_objeto);
    END consulta;

    PROCEDURE rechazo(p_desc IN VARCHAR2, p_sql IN VARCHAR2) IS
    BEGIN
        caso(p_desc || ' se rechaza', c_rechazo, p_sql);
    END rechazo;
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- ' || v_cuenta || ' ---');
    IF v_cuenta = 'SVC_CLIENTE' THEN
        consulta('v_seguimiento_envio');
        consulta('v_rastreo_publico');
        rechazo('SELECT envio', 'SELECT COUNT(*) FROM envio');
        rechazo('SELECT zona', 'SELECT COUNT(*) FROM zona');
        rechazo('SELECT v_estado_actual_envio', 'SELECT COUNT(*) FROM v_estado_actual_envio');
        rechazo('UPDATE envio', 'UPDATE envio SET fragil = ''N'' WHERE numero_guia = ''EE0000000000001''');
        rechazo('DELETE envio (RN16)', 'DELETE FROM envio WHERE numero_guia = ''EE0000000000001''');

    ELSIF v_cuenta = 'SVC_MESA' THEN
        consulta('v_seguimiento_envio');
        consulta('v_novedades_abiertas');
        consulta('v_reclamaciones_pendientes');
        consulta('v_estado_actual_envio');
        caso('EXECUTE pr_registrar_envio pasa', c_ninguno,
             q'~DECLARE v VARCHAR2(15); s NUMBER; BEGIN SELECT MIN(id_solicitud) INTO s FROM solicitud_recoleccion; pr_registrar_envio(s, 'CC', 'PERM-001', 'Destinatario de prueba', '3000000000', NULL, 1, 3, 'Calle 1 # 2-3', 1, 'Libros', 1000, NULL, NULL, NULL, 4, v); END;~');
        caso('UPDATE novedad pasa', c_ninguno, 'UPDATE novedad SET solucion = solucion WHERE id_novedad = 1');
        rechazo('DELETE envio (RN16)', 'DELETE FROM envio WHERE numero_guia = ''EE0000000000001''');
        rechazo('INSERT despacho', 'INSERT INTO despacho (id_despacho, id_centro, id_vehiculo, id_mensajero, fecha, tipo) VALUES (9901, 1, 2, 7, TRUNC(SYSDATE), ''ENTREGA'')');
        rechazo('SELECT v_cumplimiento_entregas', 'SELECT COUNT(*) FROM v_cumplimiento_entregas');

    ELSIF v_cuenta = 'SVC_CENTRO' THEN
        consulta('v_planilla_despacho');
        consulta('v_envios_por_despachar');
        consulta('v_estado_actual_envio');
        caso('INSERT despacho valido pasa', c_ninguno,
             'INSERT INTO despacho (id_despacho, id_centro, id_vehiculo, id_mensajero, fecha, tipo) VALUES (9901, 1, 2, 7, TRUNC(SYSDATE), ''ENTREGA'')');
        caso('SELECT ... FOR UPDATE sobre envio pasa', c_ninguno,
             'SELECT numero_guia FROM envio WHERE numero_guia = ''EE0000000000028'' FOR UPDATE');
        rechazo('DELETE despacho (RN16)', 'DELETE FROM despacho WHERE id_despacho = 9901');
        rechazo('INSERT reclamacion', 'INSERT INTO reclamacion (id_cliente, fecha_radicacion, tipo, descripcion) VALUES (1, LOCALTIMESTAMP, ''OTRO'', ''x'')');
        rechazo('SELECT v_seguimiento_envio', 'SELECT COUNT(*) FROM v_seguimiento_envio');

    ELSIF v_cuenta = 'SVC_MENSAJERO' THEN
        consulta('v_planilla_despacho');
        consulta('despacho');
        caso('UPDATE asignacion_despacho pasa', c_ninguno,
             'UPDATE asignacion_despacho SET orden_visita = orden_visita WHERE id_asignacion = 1');
        rechazo('INSERT reclamacion', 'INSERT INTO reclamacion (id_cliente, fecha_radicacion, tipo, descripcion) VALUES (1, LOCALTIMESTAMP, ''OTRO'', ''x'')');
        rechazo('DELETE novedad (RN16)', 'DELETE FROM novedad WHERE id_novedad = 1');
        rechazo('SELECT cliente', 'SELECT COUNT(*) FROM cliente');
        rechazo('SELECT destinatario (la planilla se lee por la vista)', 'SELECT COUNT(*) FROM destinatario');

    ELSIF v_cuenta = 'SVC_GERENCIA' THEN
        consulta('v_seguimiento_envio');
        consulta('v_estado_actual_envio');
        consulta('v_planilla_despacho');
        consulta('v_envios_por_despachar');
        consulta('v_novedades_abiertas');
        consulta('v_reclamaciones_pendientes');
        consulta('v_cumplimiento_entregas');
        consulta('envio');
        rechazo('INSERT zona', 'INSERT INTO zona (id_zona, id_centro, nombre, localidades) VALUES (9999, 1, ''X'', ''Y'')');
        rechazo('INSERT envio', 'INSERT INTO envio (numero_guia) VALUES (''X'')');
        rechazo('UPDATE cliente', 'UPDATE cliente SET estado = estado WHERE id_cliente = 1');
        rechazo('DELETE envio (RN16)', 'DELETE FROM envio WHERE numero_guia = ''EE0000000000001''');
    ELSE
        DBMS_OUTPUT.PUT_LINE('FALLA cuenta no prevista: ' || v_cuenta);
        v_falla := v_falla + 1;
    END IF;
    DBMS_OUTPUT.PUT_LINE(v_cuenta || ': ' || v_ok || ' OK, ' || v_falla || ' FALLA');
END;
/

ROLLBACK;
