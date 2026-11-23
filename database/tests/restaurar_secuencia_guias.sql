-- Deja seq_numero_guia en (ultima guia EE + 13 digitos) + 1. Las pruebas que
-- llaman a pr_registrar_envio y hacen ROLLBACK consumen valores de la
-- secuencia, que no se revierte; este script la restaura.
-- Uso: database/run.sh propietario tests/restaurar_secuencia_guias.sql
WHENEVER SQLERROR EXIT FAILURE

DECLARE
    v_ultima NUMBER;
BEGIN
    SELECT NVL(MAX(TO_NUMBER(SUBSTR(numero_guia, 3))), 0)
    INTO   v_ultima
    FROM   envio
    WHERE  REGEXP_LIKE(numero_guia, '^EE[0-9]{13}$');
    EXECUTE IMMEDIATE 'ALTER SEQUENCE seq_numero_guia RESTART START WITH ' || (v_ultima + 1);
END;
/
