-- Preparacion de T08 (se ejecuta como el propietario, no es una de las 12
-- transacciones): lleva el envio C a su tercer intento. C ya tiene la novedad
-- del intento 1 (T07); aqui se arma un segundo despacho con el intento 2, se
-- registra su novedad y se arma un tercer despacho con el intento 3 PENDIENTE.
-- Todo con los disparadores activos.
WHENEVER SQLERROR EXIT FAILURE
SET DEFINE OFF
SET SERVEROUTPUT ON SIZE UNLIMITED

DECLARE
    TYPE t_guias IS TABLE OF envio.numero_guia%TYPE;
    v_g   t_guias;
    v_sol NUMBER;
    v_c   envio.numero_guia%TYPE;
    v_d   NUMBER;
    v_a   NUMBER;
    v_t   TIMESTAMP;

    FUNCTION instante(p_guia IN VARCHAR2) RETURN TIMESTAMP IS
        v_i TIMESTAMP;
    BEGIN
        SELECT GREATEST(LOCALTIMESTAMP, NVL(MAX(fecha_hora), LOCALTIMESTAMP) + INTERVAL '1' SECOND)
        INTO   v_i FROM evento_envio WHERE numero_guia = p_guia;
        RETURN v_i;
    END instante;
BEGIN
    SELECT MAX(id_solicitud) INTO v_sol FROM solicitud_recoleccion WHERE fecha_programada > DATE '2026-11-20';
    SELECT numero_guia BULK COLLECT INTO v_g FROM envio WHERE id_solicitud = v_sol ORDER BY numero_guia;
    v_c := v_g(3);

    -- intento 2: despacho del mensajero 6 con la motocicleta 1
    INSERT INTO despacho (id_centro, id_vehiculo, id_mensajero, fecha, tipo, hora_salida, estado)
    VALUES (1, 1, 6, TRUNC(SYSDATE), 'ENTREGA', LOCALTIMESTAMP, 'EN_RUTA') RETURNING id_despacho INTO v_d;
    INSERT INTO asignacion_despacho (numero_guia, id_despacho, numero_intento, orden_visita)
    VALUES (v_c, v_d, 2, 1) RETURNING id_asignacion INTO v_a;
    v_t := instante(v_c);
    INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion)
    VALUES (v_c, 5, 6, v_t, 'Sale en el despacho (intento 2)');          -- EN_RUTA
    INSERT INTO novedad (id_asignacion, tipo_novedad, descripcion)
    VALUES (v_a, 'DESTINATARIO_AUSENTE', 'Segunda visita sin respuesta');
    UPDATE asignacion_despacho SET resultado = 'NOVEDAD', hora_visita = LOCALTIMESTAMP WHERE id_asignacion = v_a;
    v_t := instante(v_c);
    INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion)
    VALUES (v_c, 7, 6, v_t, 'Novedad: destinatario ausente');             -- CON_NOVEDAD

    -- intento 3: despacho del mensajero 8 con la motocicleta 2
    INSERT INTO despacho (id_centro, id_vehiculo, id_mensajero, fecha, tipo, hora_salida, estado)
    VALUES (1, 2, 8, TRUNC(SYSDATE), 'ENTREGA', LOCALTIMESTAMP, 'EN_RUTA') RETURNING id_despacho INTO v_d;
    INSERT INTO asignacion_despacho (numero_guia, id_despacho, numero_intento, orden_visita)
    VALUES (v_c, v_d, 3, 1);
    v_t := instante(v_c);
    INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion)
    VALUES (v_c, 5, 8, v_t, 'Sale en el despacho (intento 3)');           -- EN_RUTA
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Preparacion de T08: envio ' || v_c || ' con 2 novedades y el intento 3 PENDIENTE');
END;
/
