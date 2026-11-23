-- Procedimiento de registro del envio (capitulo 5, tabla de disparadores y
-- procedimiento). En una sola llamada: busca o crea el destinatario (RN04),
-- genera la guia, inserta el envio y su evento REGISTRADO (RN12, RN13) y
-- devuelve la guia. No hace COMMIT: la transaccion la controla quien llama.
-- Si p_fecha_compromiso es NULL se calcula con pkg_calendario: el plazo de la
-- modalidad cuenta el dia del registro como dia 1, en dias habiles de lunes a
-- sabado (MISMO_DIA = 1, DIA_SIGUIENTE = 2, ESTANDAR = 3). No bloquea filas ni usa SELECT FOR UPDATE.
WHENEVER SQLERROR EXIT FAILURE

CREATE SEQUENCE seq_numero_guia START WITH 1 INCREMENT BY 1 MAXVALUE 9999999999999 NOCYCLE;

CREATE OR REPLACE PROCEDURE pr_registrar_envio (
    p_id_solicitud      IN  envio.id_solicitud%TYPE,
    p_tipo_documento    IN  destinatario.tipo_documento%TYPE,
    p_numero_documento  IN  destinatario.numero_documento%TYPE,
    p_nombre            IN  destinatario.nombre%TYPE,
    p_telefono          IN  destinatario.telefono%TYPE,
    p_correo            IN  destinatario.correo%TYPE,
    p_id_zona           IN  envio.id_zona%TYPE,
    p_id_modalidad      IN  envio.id_modalidad%TYPE,
    p_direccion_destino IN  envio.direccion_destino%TYPE,
    p_peso_declarado    IN  envio.peso_declarado%TYPE,
    p_contenido         IN  envio.contenido%TYPE,
    p_valor_declarado   IN  envio.valor_declarado%TYPE,
    p_fragil            IN  envio.fragil%TYPE,
    p_alto_valor        IN  envio.alto_valor%TYPE,
    p_fecha_compromiso  IN  envio.fecha_compromiso%TYPE,
    p_id_empleado       IN  evento_envio.id_empleado%TYPE,
    p_numero_guia       OUT envio.numero_guia%TYPE
) IS
    v_id_destinatario destinatario.id_destinatario%TYPE;
    v_id_estado       estado_envio.id_estado%TYPE;
    v_registro        DATE := TRUNC(SYSDATE);
    v_compromiso      DATE := p_fecha_compromiso;
    v_plazo           modalidad.plazo_dias_habiles%TYPE;
    v_fragil          envio.fragil%TYPE := NVL(p_fragil, 'N');
    v_alto_valor      envio.alto_valor%TYPE := NVL(p_alto_valor, 'N');

    PROCEDURE exigir(p_presente IN BOOLEAN, p_dato IN VARCHAR2) IS
    BEGIN
        IF NOT p_presente THEN
            pkg_errores.lanzar(pkg_errores.c_rn02,
                'RN02: el envio exige ' || p_dato || ' (dato obligatorio ausente)');
        END IF;
    END exigir;
BEGIN
    -- RN02: datos obligatorios
    exigir(p_id_solicitud IS NOT NULL, 'la solicitud de recoleccion');
    exigir(p_tipo_documento IS NOT NULL AND p_numero_documento IS NOT NULL
           AND p_nombre IS NOT NULL AND p_telefono IS NOT NULL, 'el destinatario completo (tipo y numero de documento, nombre y telefono)');
    exigir(p_direccion_destino IS NOT NULL, 'la direccion de destino');
    exigir(p_id_zona IS NOT NULL, 'la zona');
    exigir(p_id_modalidad IS NOT NULL, 'la modalidad');
    exigir(p_peso_declarado IS NOT NULL, 'el peso');
    exigir(p_contenido IS NOT NULL, 'el contenido');
    exigir(p_valor_declarado IS NOT NULL, 'el valor declarado');
    exigir(p_id_empleado IS NOT NULL, 'el empleado responsable del evento');

    -- RN02: fecha de compromiso (dias habiles de lunes a sabado)
    IF v_compromiso IS NULL THEN
        BEGIN
            SELECT plazo_dias_habiles INTO v_plazo
            FROM   modalidad WHERE id_modalidad = p_id_modalidad;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                pkg_errores.lanzar(pkg_errores.c_rn02,
                    'RN02: la modalidad ' || p_id_modalidad || ' no existe');
        END;
        v_compromiso := pkg_calendario.fecha_compromiso(v_registro, v_plazo);
    END IF;

    -- RN04: el destinatario existe una sola vez; si ya esta, se reutiliza sin tocar sus datos
    BEGIN
        SELECT id_destinatario INTO v_id_destinatario
        FROM   destinatario
        WHERE  tipo_documento = p_tipo_documento AND numero_documento = p_numero_documento;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            BEGIN
                INSERT INTO destinatario (tipo_documento, numero_documento, nombre, telefono, correo)
                VALUES (p_tipo_documento, p_numero_documento, p_nombre, p_telefono, p_correo)
                RETURNING id_destinatario INTO v_id_destinatario;
            EXCEPTION
                WHEN DUP_VAL_ON_INDEX THEN
                    -- otra sesion lo creo entre la consulta y el insert
                    SELECT id_destinatario INTO v_id_destinatario
                    FROM   destinatario
                    WHERE  tipo_documento = p_tipo_documento AND numero_documento = p_numero_documento;
            END;
    END;

    -- RN01: guia unica generada por la secuencia
    p_numero_guia := 'EE' || LPAD(TO_CHAR(seq_numero_guia.NEXTVAL), 13, '0');

    INSERT INTO envio (numero_guia, id_solicitud, id_destinatario, id_zona, id_modalidad,
                       fecha_registro, direccion_destino, peso_declarado, contenido,
                       valor_declarado, fragil, alto_valor, fecha_compromiso)
    VALUES (p_numero_guia, p_id_solicitud, v_id_destinatario, p_id_zona, p_id_modalidad,
            v_registro, p_direccion_destino, p_peso_declarado, p_contenido,
            p_valor_declarado, v_fragil, v_alto_valor, v_compromiso);

    -- RN12 y RN13: toda guia nace con el evento REGISTRADO y su responsable
    SELECT id_estado INTO v_id_estado FROM estado_envio WHERE nombre = 'REGISTRADO';
    INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion)
    VALUES (p_numero_guia, v_id_estado, p_id_empleado, LOCALTIMESTAMP, 'Envio registrado');
END pr_registrar_envio;
/
