-- Paquete de errores de negocio: un codigo por regla (-20000 menos el numero
-- de la regla, decision 12.1). Todo mensaje empieza con el codigo de la
-- regla ('RN07: ...'); la API lo convierte en Problem Details.
WHENEVER SQLERROR EXIT FAILURE

CREATE OR REPLACE PACKAGE pkg_errores AS
    c_rn02 CONSTANT PLS_INTEGER := -20002;
    c_rn05 CONSTANT PLS_INTEGER := -20005;
    c_rn06 CONSTANT PLS_INTEGER := -20006;
    c_rn07 CONSTANT PLS_INTEGER := -20007;
    c_rn08 CONSTANT PLS_INTEGER := -20008;
    c_rn10 CONSTANT PLS_INTEGER := -20010;
    c_rn11 CONSTANT PLS_INTEGER := -20011;
    c_rn12 CONSTANT PLS_INTEGER := -20012;
    c_rn15 CONSTANT PLS_INTEGER := -20015;

    -- Lanza el error con el codigo y el mensaje dados (RAISE_APPLICATION_ERROR).
    PROCEDURE lanzar(p_codigo IN PLS_INTEGER, p_mensaje IN VARCHAR2);
END pkg_errores;
/

CREATE OR REPLACE PACKAGE BODY pkg_errores AS
    PROCEDURE lanzar(p_codigo IN PLS_INTEGER, p_mensaje IN VARCHAR2) IS
    BEGIN
        RAISE_APPLICATION_ERROR(p_codigo, p_mensaje);
    END lanzar;
END pkg_errores;
/
