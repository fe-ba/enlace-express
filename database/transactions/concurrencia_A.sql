-- Sesion A de la prueba de concurrencia (C4): bloquea la fila del envio con
-- SELECT ... FOR UPDATE, no confirma durante unos segundos y luego deshace.
-- Son dos bloques para que SQL*Plus muestre el primer mensaje al instante
-- (DBMS_OUTPUT solo se vacia al terminar cada bloque); la transaccion sigue
-- abierta entre ambos.
WHENEVER SQLERROR EXIT FAILURE
SET LINESIZE 300
SET SERVEROUTPUT ON SIZE UNLIMITED
DECLARE
    v_guia envio.numero_guia%TYPE;
BEGIN
    SELECT numero_guia INTO v_guia FROM envio WHERE numero_guia = 'EE0000000000028' FOR UPDATE;
    DBMS_OUTPUT.PUT_LINE(TO_CHAR(SYSTIMESTAMP, 'HH24:MI:SS.FF3') || '  A: bloqueo obtenido sobre ' || v_guia || ' (sin COMMIT)');
END;
/
BEGIN
    DBMS_SESSION.SLEEP(6);
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE(TO_CHAR(SYSTIMESTAMP, 'HH24:MI:SS.FF3') || '  A: ROLLBACK, bloqueo liberado');
END;
/
