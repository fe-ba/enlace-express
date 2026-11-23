-- Extension E2: vista del rastreo publico (decision D2). Muestra de cada evento solo la
-- fecha, el estado y la zona de destino del envio: sin observacion ni responsable (pueden
-- traer nombres), sin destinatario, direccion ni telefono. La consulta con la guia sin
-- sesion usa la cuenta svc_cliente, que no puede leer ENVIO ni ZONA; por eso la zona se
-- expone aqui y no se modifica v_seguimiento_envio (una de las 7 vistas del modulo).
-- Se ejecuta como BD_ENLACE_EXPRESS, despues de las tablas del modulo.
WHENEVER SQLERROR EXIT FAILURE

CREATE OR REPLACE VIEW v_rastreo_publico (numero_guia, id_evento, fecha_hora, estado, zona) AS
SELECT ev.numero_guia,
       ev.id_evento,
       ev.fecha_hora,
       es.nombre,
       z.nombre
FROM   evento_envio ev
JOIN   estado_envio es ON es.id_estado = ev.id_estado
JOIN   envio e         ON e.numero_guia = ev.numero_guia
JOIN   zona z          ON z.id_zona = e.id_zona
WITH READ ONLY;

COMMENT ON TABLE v_rastreo_publico IS
'Extensión E2: recorrido público de un envío (fecha, estado y zona de cada evento), sin datos personales.';

GRANT SELECT ON v_rastreo_publico TO rol_cliente;
