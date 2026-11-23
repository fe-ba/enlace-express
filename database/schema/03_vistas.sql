-- Las 7 vistas de usuario del modulo (capitulo 4, tabla de vistas).
-- Se ejecuta como BD_ENLACE_EXPRESS, despues de las tablas y los indices.
-- Todas son de solo lectura. Las restricciones de visibilidad por usuario
-- (por ejemplo el filtro por id_cliente del portal, o el rastreo publico que
-- solo muestra estados, fechas y zona) las aplica la aplicacion.
WHENEVER SQLERROR EXIT FAILURE

-- 1. Recorrido completo de un envio: una fila por evento.
CREATE OR REPLACE VIEW v_seguimiento_envio (
    numero_guia, id_cliente, id_evento, fecha_hora, estado, observacion, responsable
) AS
SELECT ev.numero_guia,
       sc.id_cliente,
       ev.id_evento,
       ev.fecha_hora,
       es.nombre,
       ev.observacion,
       em.nombres || ' ' || em.apellidos
FROM   envio e
JOIN   solicitud_recoleccion sr ON sr.id_solicitud = e.id_solicitud
JOIN   sede_cliente sc          ON sc.id_sede = sr.id_sede
JOIN   evento_envio ev          ON ev.numero_guia = e.numero_guia
JOIN   estado_envio es          ON es.id_estado = ev.id_estado
JOIN   empleado em              ON em.id_empleado = ev.id_empleado
WITH READ ONLY;

COMMENT ON TABLE v_seguimiento_envio IS
'Recorrido completo de un envío por número de guía. El cliente (U9) la consulta filtrada por su id_cliente.';

-- 2. Estado actual de cada envio: el de su evento con la mayor fecha_hora (C10).
CREATE OR REPLACE VIEW v_estado_actual_envio (
    numero_guia, fecha_registro, fecha_compromiso, id_cliente, razon_social,
    id_zona, zona, id_centro, id_modalidad, modalidad,
    estado_actual, es_final, fecha_hora_estado
) AS
SELECT e.numero_guia,
       e.fecha_registro,
       e.fecha_compromiso,
       c.id_cliente,
       c.razon_social,
       z.id_zona,
       z.nombre,
       z.id_centro,
       m.id_modalidad,
       m.nombre,
       es.nombre,
       es.es_final,
       ev.fecha_hora
FROM   envio e
JOIN   solicitud_recoleccion sr ON sr.id_solicitud = e.id_solicitud
JOIN   sede_cliente sc          ON sc.id_sede = sr.id_sede
JOIN   cliente c                ON c.id_cliente = sc.id_cliente
JOIN   zona z                   ON z.id_zona = e.id_zona
JOIN   modalidad m              ON m.id_modalidad = e.id_modalidad
JOIN   evento_envio ev          ON ev.numero_guia = e.numero_guia
JOIN   estado_envio es          ON es.id_estado = ev.id_estado
WHERE  ev.fecha_hora = (SELECT MAX(x.fecha_hora)
                        FROM   evento_envio x
                        WHERE  x.numero_guia = ev.numero_guia)
WITH READ ONLY;

COMMENT ON TABLE v_estado_actual_envio IS
'Estado actual de cada envío (el de su último evento), con cliente, zona, modalidad y fecha de compromiso.';

-- 3. Planilla de ruta: envios de cada despacho en orden de visita.
CREATE OR REPLACE VIEW v_planilla_despacho (
    id_despacho, fecha, tipo, estado_despacho, id_centro, id_mensajero, mensajero,
    placa, orden_visita, numero_intento, id_asignacion, numero_guia,
    destinatario, telefono_destinatario, tipo_documento_destinatario,
    numero_documento_destinatario, direccion_destino, id_zona, zona,
    fragil, alto_valor, resultado, hora_visita
) AS
SELECT d.id_despacho,
       d.fecha,
       d.tipo,
       d.estado,
       d.id_centro,
       d.id_mensajero,
       em.nombres || ' ' || em.apellidos,
       v.placa,
       a.orden_visita,
       a.numero_intento,
       a.id_asignacion,
       a.numero_guia,
       de.nombre,
       de.telefono,
       de.tipo_documento,
       de.numero_documento,
       e.direccion_destino,
       z.id_zona,
       z.nombre,
       e.fragil,
       e.alto_valor,
       a.resultado,
       a.hora_visita
FROM   despacho d
JOIN   asignacion_despacho a ON a.id_despacho = d.id_despacho
JOIN   envio e               ON e.numero_guia = a.numero_guia
JOIN   destinatario de       ON de.id_destinatario = e.id_destinatario
JOIN   zona z                ON z.id_zona = e.id_zona
JOIN   vehiculo v            ON v.id_vehiculo = d.id_vehiculo
JOIN   empleado em           ON em.id_empleado = d.id_mensajero
WITH READ ONLY;

COMMENT ON TABLE v_planilla_despacho IS
'Planilla de ruta: envíos de cada despacho en orden de visita, con datos del destinatario y del mensajero.';

-- 4. Envios listos para armar una ruta de entrega: estado actual CLASIFICADO
--    (o CON_NOVEDAD, que puede volver a salir en un despacho nuevo) y sin
--    asignacion en un despacho de entrega abierto.
CREATE OR REPLACE VIEW v_envios_por_despachar (
    numero_guia, id_centro, id_zona, zona, modalidad, fecha_compromiso,
    peso_kg, fragil, alto_valor, estado_actual, intentos_previos
) AS
SELECT s.numero_guia,
       s.id_centro,
       s.id_zona,
       s.zona,
       s.modalidad,
       s.fecha_compromiso,
       COALESCE(e.peso_real, e.peso_declarado),
       e.fragil,
       e.alto_valor,
       s.estado_actual,
       (SELECT COUNT(*)
        FROM   asignacion_despacho a
        WHERE  a.numero_guia = s.numero_guia)
FROM   v_estado_actual_envio s
JOIN   envio e ON e.numero_guia = s.numero_guia
WHERE  s.estado_actual IN ('CLASIFICADO', 'CON_NOVEDAD')
AND    NOT EXISTS (SELECT 1
                   FROM   asignacion_despacho a
                   JOIN   despacho d ON d.id_despacho = a.id_despacho
                   WHERE  a.numero_guia = s.numero_guia
                   AND    d.tipo = 'ENTREGA'
                   AND    d.estado <> 'CERRADO')
WITH READ ONLY;

COMMENT ON TABLE v_envios_por_despachar IS
'Envíos clasificados que todavía no están en un despacho de entrega abierto, por zona y modalidad, para armar las rutas.';

-- 5. Novedades sin cerrar, con los datos de contacto.
CREATE OR REPLACE VIEW v_novedades_abiertas (
    id_novedad, numero_guia, numero_intento, hora_visita, tipo_novedad, descripcion,
    destinatario, telefono_destinatario, id_cliente, cliente, telefono_cliente
) AS
SELECT n.id_novedad,
       a.numero_guia,
       a.numero_intento,
       a.hora_visita,
       n.tipo_novedad,
       n.descripcion,
       de.nombre,
       de.telefono,
       c.id_cliente,
       c.razon_social,
       c.telefono
FROM   novedad n
JOIN   asignacion_despacho a    ON a.id_asignacion = n.id_asignacion
JOIN   envio e                  ON e.numero_guia = a.numero_guia
JOIN   destinatario de          ON de.id_destinatario = e.id_destinatario
JOIN   solicitud_recoleccion sr ON sr.id_solicitud = e.id_solicitud
JOIN   sede_cliente sc          ON sc.id_sede = sr.id_sede
JOIN   cliente c                ON c.id_cliente = sc.id_cliente
WHERE  n.estado = 'ABIERTA'
WITH READ ONLY;

COMMENT ON TABLE v_novedades_abiertas IS
'Novedades sin cerrar, con el intento en que ocurrieron y los datos para contactar al destinatario y al cliente.';

-- 6. Reclamaciones abiertas (sin respuesta) y horas desde su radicacion.
--    fecha_radicacion es TIMESTAMP, asi que se compara con LOCALTIMESTAMP
--    (hora de la sesion, America/Bogota).
CREATE OR REPLACE VIEW v_reclamaciones_pendientes (
    id_reclamacion, fecha_radicacion, id_cliente, cliente, numero_guia, tipo,
    descripcion, horas_transcurridas
) AS
SELECT r.id_reclamacion,
       r.fecha_radicacion,
       c.id_cliente,
       c.razon_social,
       r.numero_guia,
       r.tipo,
       r.descripcion,
       ROUND(EXTRACT(DAY FROM (LOCALTIMESTAMP - r.fecha_radicacion)) * 24
           + EXTRACT(HOUR FROM (LOCALTIMESTAMP - r.fecha_radicacion))
           + EXTRACT(MINUTE FROM (LOCALTIMESTAMP - r.fecha_radicacion)) / 60, 1)
FROM   reclamacion r
JOIN   cliente c ON c.id_cliente = r.id_cliente
WHERE  r.estado = 'ABIERTA'
WITH READ ONLY;

COMMENT ON TABLE v_reclamaciones_pendientes IS
'Reclamaciones abiertas, con el cliente y el envío reclamado; insumo del indicador de tiempo de respuesta.';

-- 7. Cumplimiento de entregas por centro y zona (indicador de OE1).
CREATE OR REPLACE VIEW v_cumplimiento_entregas (
    id_centro, id_zona, zona, entregados, entregados_a_tiempo, porcentaje_a_tiempo
) AS
SELECT z.id_centro,
       z.id_zona,
       z.nombre,
       COUNT(*),
       COUNT(CASE WHEN TRUNC(ev.fecha_hora) <= e.fecha_compromiso THEN 1 END),
       ROUND(100 * COUNT(CASE WHEN TRUNC(ev.fecha_hora) <= e.fecha_compromiso THEN 1 END)
             / COUNT(*), 1)
FROM   envio e
JOIN   zona z          ON z.id_zona = e.id_zona
JOIN   evento_envio ev ON ev.numero_guia = e.numero_guia
JOIN   estado_envio es ON es.id_estado = ev.id_estado
WHERE  es.nombre = 'ENTREGADO'
GROUP  BY z.id_centro, z.id_zona, z.nombre
WITH READ ONLY;

COMMENT ON TABLE v_cumplimiento_entregas IS
'Por centro y zona: envíos entregados y cuántos se entregaron dentro de la fecha de compromiso (indicador de OE1).';
