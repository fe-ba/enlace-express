-- RN06: si el envio es fragil o de alto valor, quien recibe es el destinatario
-- (el documento de la prueba coincide con el del destinatario).
WHENEVER SQLERROR EXIT FAILURE

CREATE OR REPLACE TRIGGER trg_prueba_documento
BEFORE INSERT ON prueba_entrega
FOR EACH ROW
DECLARE
    v_fragil     envio.fragil%TYPE;
    v_alto_valor envio.alto_valor%TYPE;
    v_documento  destinatario.numero_documento%TYPE;
BEGIN
    SELECT e.fragil, e.alto_valor, d.numero_documento
    INTO   v_fragil, v_alto_valor, v_documento
    FROM   asignacion_despacho a
    JOIN   envio e        ON e.numero_guia = a.numero_guia
    JOIN   destinatario d ON d.id_destinatario = e.id_destinatario
    WHERE  a.id_asignacion = :NEW.id_asignacion;

    IF (v_fragil = 'S' OR v_alto_valor = 'S') AND :NEW.documento_receptor <> v_documento THEN
        pkg_errores.lanzar(pkg_errores.c_rn06,
            'RN06: el envío es frágil o de alto valor y solo se entrega al destinatario; '
            || 'el documento de quien recibe no coincide con el del destinatario');
    END IF;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        NULL;  -- asignacion inexistente: la clave foranea rechaza la fila
END trg_prueba_documento;
/
