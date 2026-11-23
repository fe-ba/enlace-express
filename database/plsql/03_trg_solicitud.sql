-- RN15: solo se registran solicitudes de clientes activos.
WHENEVER SQLERROR EXIT FAILURE

CREATE OR REPLACE TRIGGER trg_solicitud_cliente_activo
BEFORE INSERT ON solicitud_recoleccion
FOR EACH ROW
DECLARE
    v_estado cliente.estado%TYPE;
BEGIN
    SELECT c.estado INTO v_estado
    FROM   sede_cliente s
    JOIN   cliente c ON c.id_cliente = s.id_cliente
    WHERE  s.id_sede = :NEW.id_sede;

    IF v_estado <> 'ACTIVO' THEN
        pkg_errores.lanzar(pkg_errores.c_rn15,
            'RN15: el cliente dueño de la sede ' || :NEW.id_sede || ' está ' || v_estado
            || '; solo se registran solicitudes de clientes activos');
    END IF;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        NULL;  -- sede inexistente: la clave foránea rechaza la fila
END trg_solicitud_cliente_activo;
/
