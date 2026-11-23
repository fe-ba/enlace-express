-- Extension E1: acceso de usuarios para la aplicacion (derechos del definidor:
-- se ejecuta con los privilegios del propietario, asi que quien lo llama no
-- necesita acceso a las tablas USUARIO_APLICACION y CODIGO_ACTIVACION).
-- Errores en el rango -20100 a -20199, con mensajes que empiezan con "E1:".
-- El mensaje de registro no revela si fallo el documento o el codigo.
-- Ningun COMMIT: la transaccion la controla la aplicacion.
WHENEVER SQLERROR EXIT FAILURE

CREATE OR REPLACE PACKAGE pkg_seguridad AS
    c_err_registro   CONSTANT PLS_INTEGER := -20101;  -- documento o codigo no validos (mensaje unico)
    c_err_usuario    CONSTANT PLS_INTEGER := -20102;  -- el nombre de usuario ya existe
    c_err_cargo      CONSTANT PLS_INTEGER := -20103;  -- el cargo no tiene acceso a la aplicacion
    c_err_hash       CONSTANT PLS_INTEGER := -20104;  -- hash de contrasena ausente o invalido
    c_err_cuenta     CONSTANT PLS_INTEGER := -20105;  -- el empleado ya tiene cuenta

    -- Registra la cuenta de un empleado ACTIVO con su codigo; el rol sale de su cargo. Devuelve el id_usuario.
    FUNCTION registrar_empleado(p_documento IN VARCHAR2, p_codigo IN VARCHAR2,
                                p_nombre_usuario IN VARCHAR2, p_hash IN VARCHAR2) RETURN NUMBER;
    -- Registra una cuenta de cliente (rol CLIENTE) de una empresa ACTIVA con su NIT y su codigo.
    FUNCTION registrar_cliente(p_nit IN VARCHAR2, p_codigo IN VARCHAR2,
                               p_nombre_usuario IN VARCHAR2, p_hash IN VARCHAR2) RETURN NUMBER;
    -- Datos para el inicio de sesion; si el usuario no existe devuelve todo nulo, sin error.
    PROCEDURE datos_ingreso(p_nombre_usuario IN VARCHAR2, p_hash OUT VARCHAR2, p_rol OUT VARCHAR2,
                            p_estado OUT VARCHAR2, p_id_empleado OUT NUMBER, p_id_cliente OUT NUMBER);
    -- Anota el instante del ultimo inicio de sesion correcto.
    PROCEDURE registrar_ingreso(p_nombre_usuario IN VARCHAR2);
END pkg_seguridad;
/

CREATE OR REPLACE PACKAGE BODY pkg_seguridad AS
    c_msg_registro CONSTANT VARCHAR2(100) := 'E1: los datos de registro o el código no son válidos';

    PROCEDURE error_registro IS
    BEGIN
        RAISE_APPLICATION_ERROR(c_err_registro, c_msg_registro);
    END error_registro;

    PROCEDURE validar_usuario_y_hash(p_nombre_usuario IN VARCHAR2, p_hash IN VARCHAR2) IS
    BEGIN
        IF p_nombre_usuario IS NULL OR LENGTH(TRIM(p_nombre_usuario)) < 3 THEN
            RAISE_APPLICATION_ERROR(c_err_usuario, 'E1: el nombre de usuario debe tener al menos 3 caracteres');
        END IF;
        IF p_hash IS NULL OR LENGTH(p_hash) < 20 THEN
            RAISE_APPLICATION_ERROR(c_err_hash, 'E1: el hash de la contraseña no es válido');
        END IF;
    END validar_usuario_y_hash;

    -- Inserta la cuenta y devuelve su id. Traduce las violaciones de unicidad a mensajes claros.
    FUNCTION insertar_usuario(p_nombre_usuario IN VARCHAR2, p_hash IN VARCHAR2, p_rol IN VARCHAR2,
                              p_id_empleado IN NUMBER, p_id_cliente IN NUMBER) RETURN NUMBER IS
        v_id usuario_aplicacion.id_usuario%TYPE;
    BEGIN
        INSERT INTO usuario_aplicacion (nombre_usuario, hash_contrasena, rol, id_empleado, id_cliente)
        VALUES (p_nombre_usuario, p_hash, p_rol, p_id_empleado, p_id_cliente)
        RETURNING id_usuario INTO v_id;
        RETURN v_id;
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            IF INSTR(SQLERRM, 'USUARIO_EMPLEADO_UK') > 0 THEN
                RAISE_APPLICATION_ERROR(c_err_cuenta, 'E1: el empleado ya tiene una cuenta');
            END IF;
            RAISE_APPLICATION_ERROR(c_err_usuario, 'E1: el nombre de usuario ya existe');
    END insertar_usuario;

    -- Bloquea (C4) el codigo de ese destino y comprueba que sirva; cualquier fallo da el mismo mensaje.
    FUNCTION tomar_codigo(p_codigo IN VARCHAR2, p_id_empleado IN NUMBER, p_id_cliente IN NUMBER) RETURN NUMBER IS
        v_id     codigo_activacion.id_codigo%TYPE;
        v_uso    codigo_activacion.fecha_uso%TYPE;
        v_vence  codigo_activacion.fecha_vencimiento%TYPE;
    BEGIN
        SELECT id_codigo, fecha_uso, fecha_vencimiento INTO v_id, v_uso, v_vence
        FROM   codigo_activacion
        WHERE  codigo_hash = pkg_codigos_activacion.hash_codigo(p_codigo)
        AND    (id_empleado = p_id_empleado OR id_cliente = p_id_cliente)
        FOR UPDATE;
        IF v_uso IS NOT NULL OR v_vence <= LOCALTIMESTAMP THEN
            error_registro;
        END IF;
        RETURN v_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            error_registro;
    END tomar_codigo;

    PROCEDURE marcar_usado(p_id_codigo IN NUMBER, p_id_usuario IN NUMBER) IS
    BEGIN
        UPDATE codigo_activacion SET fecha_uso = LOCALTIMESTAMP, id_usuario = p_id_usuario
        WHERE  id_codigo = p_id_codigo;
    END marcar_usado;

    FUNCTION registrar_empleado(p_documento IN VARCHAR2, p_codigo IN VARCHAR2,
                                p_nombre_usuario IN VARCHAR2, p_hash IN VARCHAR2) RETURN NUMBER IS
        v_id_empleado empleado.id_empleado%TYPE;
        v_cargo       empleado.cargo%TYPE;
        v_rol         usuario_aplicacion.rol%TYPE;
        v_id_codigo   codigo_activacion.id_codigo%TYPE;
        v_id_usuario  usuario_aplicacion.id_usuario%TYPE;
        v_existe      NUMBER;
    BEGIN
        IF p_documento IS NULL OR p_codigo IS NULL THEN
            error_registro;
        END IF;
        BEGIN
            SELECT id_empleado, cargo INTO v_id_empleado, v_cargo
            FROM   empleado WHERE documento = p_documento AND estado = 'ACTIVO';
        EXCEPTION
            WHEN NO_DATA_FOUND THEN error_registro;
        END;
        v_id_codigo := tomar_codigo(p_codigo, v_id_empleado, NULL);
        validar_usuario_y_hash(p_nombre_usuario, p_hash);

        -- el rol no se elige: sale del cargo (y, para el mensajero, de que exista en MENSAJERO)
        v_rol := CASE v_cargo
                     WHEN 'Gerente' THEN 'GERENCIA'
                     WHEN 'Auxiliar de centro' THEN 'CENTRO'
                     WHEN 'Agente de mesa de servicio' THEN 'MESA'
                     WHEN 'Mensajero' THEN 'MENSAJERO'
                 END;
        IF v_rol = 'MENSAJERO' THEN
            SELECT COUNT(*) INTO v_existe FROM mensajero WHERE id_empleado = v_id_empleado;
            IF v_existe = 0 THEN v_rol := NULL; END IF;
        END IF;
        IF v_rol IS NULL THEN
            RAISE_APPLICATION_ERROR(c_err_cargo, 'E1: el cargo del empleado no tiene acceso a la aplicación');
        END IF;

        v_id_usuario := insertar_usuario(p_nombre_usuario, p_hash, v_rol, v_id_empleado, NULL);
        marcar_usado(v_id_codigo, v_id_usuario);
        RETURN v_id_usuario;
    END registrar_empleado;

    FUNCTION registrar_cliente(p_nit IN VARCHAR2, p_codigo IN VARCHAR2,
                               p_nombre_usuario IN VARCHAR2, p_hash IN VARCHAR2) RETURN NUMBER IS
        v_id_cliente cliente.id_cliente%TYPE;
        v_id_codigo  codigo_activacion.id_codigo%TYPE;
        v_id_usuario usuario_aplicacion.id_usuario%TYPE;
    BEGIN
        IF p_nit IS NULL OR p_codigo IS NULL THEN
            error_registro;
        END IF;
        BEGIN
            SELECT id_cliente INTO v_id_cliente FROM cliente WHERE nit = p_nit AND estado = 'ACTIVO';
        EXCEPTION
            WHEN NO_DATA_FOUND THEN error_registro;
        END;
        v_id_codigo := tomar_codigo(p_codigo, NULL, v_id_cliente);
        validar_usuario_y_hash(p_nombre_usuario, p_hash);
        v_id_usuario := insertar_usuario(p_nombre_usuario, p_hash, 'CLIENTE', NULL, v_id_cliente);
        marcar_usado(v_id_codigo, v_id_usuario);
        RETURN v_id_usuario;
    END registrar_cliente;

    PROCEDURE datos_ingreso(p_nombre_usuario IN VARCHAR2, p_hash OUT VARCHAR2, p_rol OUT VARCHAR2,
                            p_estado OUT VARCHAR2, p_id_empleado OUT NUMBER, p_id_cliente OUT NUMBER) IS
    BEGIN
        -- un usuario cuyo empleado esta RETIRADO o cuyo cliente esta INACTIVO sale INACTIVO
        -- aunque su fila diga ACTIVO (desactivacion inmediata)
        SELECT u.hash_contrasena, u.rol,
               CASE WHEN u.estado <> 'ACTIVO' OR e.estado <> 'ACTIVO' OR c.estado <> 'ACTIVO'
                    THEN 'INACTIVO' ELSE 'ACTIVO' END,
               u.id_empleado, u.id_cliente
        INTO   p_hash, p_rol, p_estado, p_id_empleado, p_id_cliente
        FROM   usuario_aplicacion u
        LEFT   JOIN empleado e ON e.id_empleado = u.id_empleado
        LEFT   JOIN cliente c  ON c.id_cliente = u.id_cliente
        WHERE  u.nombre_usuario = p_nombre_usuario;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            p_hash := NULL; p_rol := NULL; p_estado := NULL; p_id_empleado := NULL; p_id_cliente := NULL;
    END datos_ingreso;

    PROCEDURE registrar_ingreso(p_nombre_usuario IN VARCHAR2) IS
    BEGIN
        UPDATE usuario_aplicacion SET ultimo_ingreso = LOCALTIMESTAMP WHERE nombre_usuario = p_nombre_usuario;
    END registrar_ingreso;
END pkg_seguridad;
/
