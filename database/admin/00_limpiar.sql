-- Deja la base como si el proyecto nunca se hubiera instalado.
-- Se ejecuta como SYSTEM en FREEPDB1. No falla si algun objeto no existe.
WHENEVER SQLERROR EXIT FAILURE

DECLARE
    PROCEDURE ejecutar(p_sql VARCHAR2, p_ignorar NUMBER) IS
        v_intento PLS_INTEGER := 0;
    BEGIN
        LOOP
            v_intento := v_intento + 1;
            BEGIN
                EXECUTE IMMEDIATE p_sql;
                DBMS_OUTPUT.PUT_LINE('OK: ' || p_sql);
                EXIT;
            EXCEPTION
                WHEN OTHERS THEN
                    IF SQLCODE = p_ignorar THEN
                        EXIT;
                    ELSIF SQLCODE = -1940 AND v_intento < 20 THEN
                        DBMS_SESSION.SLEEP(0.5);   -- una sesion cerrada tarda un instante en desaparecer
                    ELSE
                        RAISE;
                    END IF;
            END;
        END LOOP;
    END;
BEGIN
    -- Cierra las sesiones abiertas de las cuentas del proyecto (una aplicacion o una prueba
    -- con su pool conectado impediria borrar el usuario: ORA-01940).
    FOR s IN (SELECT sid, serial# FROM v$session
              WHERE  username IN ('BD_ENLACE_EXPRESS', 'SVC_GERENCIA', 'SVC_CENTRO', 'SVC_MESA', 'SVC_MENSAJERO', 'SVC_CLIENTE')) LOOP
        BEGIN
            EXECUTE IMMEDIATE 'ALTER SYSTEM KILL SESSION ''' || s.sid || ',' || s.serial# || ''' IMMEDIATE';
        EXCEPTION
            WHEN OTHERS THEN
                NULL;  -- la sesion ya termino
        END;
    END LOOP;
    -- ORA-01918: el usuario no existe; ORA-01919: el rol no existe;
    -- ORA-00959: el espacio de tablas no existe
    ejecutar('DROP USER svc_gerencia CASCADE', -1918);
    ejecutar('DROP USER svc_centro CASCADE', -1918);
    ejecutar('DROP USER svc_mesa CASCADE', -1918);
    ejecutar('DROP USER svc_mensajero CASCADE', -1918);
    ejecutar('DROP USER svc_cliente CASCADE', -1918);
    ejecutar('DROP USER bd_enlace_express CASCADE', -1918);
    ejecutar('DROP ROLE rol_gerencia', -1919);
    ejecutar('DROP ROLE rol_centro', -1919);
    ejecutar('DROP ROLE rol_mesa', -1919);
    ejecutar('DROP ROLE rol_mensajero', -1919);
    ejecutar('DROP ROLE rol_cliente', -1919);
    ejecutar('DROP TABLESPACE ts_enlace_datos INCLUDING CONTENTS AND DATAFILES', -959);
    ejecutar('DROP TABLESPACE ts_enlace_indices INCLUDING CONTENTS AND DATAFILES', -959);
END;
/
