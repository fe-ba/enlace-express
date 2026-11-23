-- Sesion B de la prueba de concurrencia (C4): intenta bloquear la misma fila con
-- NOWAIT. Mientras A la tenga bloqueada recibe ORA-00054; reintenta cada segundo
-- hasta conseguir el bloqueo cuando A termina.
WHENEVER SQLERROR EXIT FAILURE
SET LINESIZE 300
SET SERVEROUTPUT ON SIZE UNLIMITED
DECLARE
    v_guia   envio.numero_guia%TYPE;
    v_intento PLS_INTEGER := 0;
    v_ocupado EXCEPTION;
    PRAGMA EXCEPTION_INIT(v_ocupado, -54);
BEGIN
    LOOP
        v_intento := v_intento + 1;
        BEGIN
            SELECT numero_guia INTO v_guia FROM envio WHERE numero_guia = 'EE0000000000028' FOR UPDATE NOWAIT;
            DBMS_OUTPUT.PUT_LINE(TO_CHAR(SYSTIMESTAMP, 'HH24:MI:SS.FF3') || '  B: intento ' || v_intento
                || ' consigue el bloqueo sobre ' || v_guia);
            EXIT;
        EXCEPTION
            WHEN v_ocupado THEN
                DBMS_OUTPUT.PUT_LINE(TO_CHAR(SYSTIMESTAMP, 'HH24:MI:SS.FF3') || '  B: intento ' || v_intento
                    || ' rechazado: ORA-00054 recurso ocupado (la fila esta bloqueada por A)');
                IF v_intento >= 30 THEN
                    RAISE_APPLICATION_ERROR(-20999, 'B no consiguio el bloqueo en 30 intentos');
                END IF;
                DBMS_SESSION.SLEEP(1);
        END;
    END LOOP;
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE(TO_CHAR(SYSTIMESTAMP, 'HH24:MI:SS.FF3') || '  B: ROLLBACK (la prueba no modifica datos)');
END;
/
