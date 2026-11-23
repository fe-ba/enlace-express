-- Prueba de las 7 vistas con un juego minimo de datos temporal.
-- Se ejecuta como BD_ENLACE_EXPRESS y termina con ROLLBACK: no deja datos.
-- Uso: database/run.sh propietario tests/prueba_vistas.sql
WHENEVER SQLERROR EXIT FAILURE
SET LINESIZE 220 PAGESIZE 100 FEEDBACK OFF VERIFY OFF TRIMSPOOL ON
SET DEFINE OFF

INSERT INTO centro_distribucion (id_centro, nombre, direccion, telefono) VALUES (1, 'Centro Norte', 'Calle 100 # 10-20', '6010000001');
INSERT INTO zona (id_zona, id_centro, nombre, localidades) VALUES (1, 1, 'Zona Norte', 'Usaquén, Suba');
INSERT INTO cliente (id_cliente, nit, razon_social, tipo_cliente, telefono, correo, fecha_vinculacion)
    VALUES (1, '900111222', 'Droguería La Salud', 'DROGUERIA', '3001112233', 'salud@example.com', DATE '2026-01-10');
INSERT INTO sede_cliente (id_sede, id_cliente, id_zona, nombre, direccion, contacto, telefono)
    VALUES (1, 1, 1, 'Sede Principal', 'Carrera 7 # 50-10', 'Marta Ruiz', '3001112244');
INSERT INTO modalidad (id_modalidad, nombre, plazo_dias_habiles) VALUES (1, 'MISMO_DIA', 1);
INSERT INTO modalidad (id_modalidad, nombre, plazo_dias_habiles) VALUES (2, 'ESTANDAR', 3);
INSERT INTO estado_envio (id_estado, nombre, es_final) VALUES (1, 'REGISTRADO', 'N');
INSERT INTO estado_envio (id_estado, nombre, es_final) VALUES (2, 'RECOLECTADO', 'N');
INSERT INTO estado_envio (id_estado, nombre, es_final) VALUES (3, 'EN_CENTRO', 'N');
INSERT INTO estado_envio (id_estado, nombre, es_final) VALUES (4, 'CLASIFICADO', 'N');
INSERT INTO estado_envio (id_estado, nombre, es_final) VALUES (5, 'EN_RUTA', 'N');
INSERT INTO estado_envio (id_estado, nombre, es_final) VALUES (6, 'ENTREGADO', 'S');
INSERT INTO estado_envio (id_estado, nombre, es_final) VALUES (7, 'CON_NOVEDAD', 'N');
INSERT INTO estado_envio (id_estado, nombre, es_final) VALUES (8, 'DEVUELTO', 'S');
INSERT INTO estado_envio (id_estado, nombre, es_final) VALUES (9, 'ANULADO', 'S');
INSERT INTO tipo_vehiculo (id_tipo_vehiculo, nombre, capacidad_max_kg) VALUES (1, 'MOTOCICLETA', 30);
INSERT INTO vehiculo (id_vehiculo, id_centro, id_tipo_vehiculo, placa, marca, modelo, capacidad_kg, electrico)
    VALUES (1, 1, 1, 'ABC123', 'Honda', 'CB125', 30, 'N');
INSERT INTO empleado (id_empleado, id_centro, documento, nombres, apellidos, cargo, telefono, fecha_ingreso)
    VALUES (1, 1, '1010101010', 'Carlos', 'Peña', 'Mensajero', '3101010101', DATE '2026-01-05');
INSERT INTO empleado (id_empleado, id_centro, documento, nombres, apellidos, cargo, telefono, fecha_ingreso)
    VALUES (2, 1, '2020202020', 'Ana', 'Gómez', 'Operaria de centro', '3202020202', DATE '2026-01-05');
INSERT INTO mensajero (id_empleado, id_zona, id_tipo_vehiculo) VALUES (1, 1, 1);
INSERT INTO destinatario (id_destinatario, tipo_documento, numero_documento, nombre, telefono)
    VALUES (1, 'CC', '52000111', 'Luis Pérez', '3153334444');
INSERT INTO solicitud_recoleccion (id_solicitud, id_sede, fecha_solicitud, fecha_programada, franja_horaria, estado)
    VALUES (1, 1, TRUNC(SYSDATE) - 3, TRUNC(SYSDATE) - 3, 'MANANA', 'ATENDIDA');

-- Cinco envios: 1 y 4 CLASIFICADOS, 2 ENTREGADO a tiempo, 3 CON_NOVEDAD, 5 ENTREGADO tarde
INSERT INTO envio (numero_guia, id_solicitud, id_destinatario, id_zona, id_modalidad, fecha_registro, direccion_destino, peso_declarado, peso_real, contenido, valor_declarado, fragil, alto_valor, fecha_compromiso)
    VALUES ('EE0000000000001', 1, 1, 1, 2, TRUNC(SYSDATE) - 2, 'Calle 1 # 1-1', 2.50, 2.60, 'Medicamentos', 100000, 'S', 'N', TRUNC(SYSDATE) + 1);
INSERT INTO envio (numero_guia, id_solicitud, id_destinatario, id_zona, id_modalidad, fecha_registro, direccion_destino, peso_declarado, contenido, valor_declarado, fecha_compromiso)
    VALUES ('EE0000000000002', 1, 1, 1, 1, TRUNC(SYSDATE) - 2, 'Calle 2 # 2-2', 1.00, 'Documentos', 50000, TRUNC(SYSDATE));
INSERT INTO envio (numero_guia, id_solicitud, id_destinatario, id_zona, id_modalidad, fecha_registro, direccion_destino, peso_declarado, contenido, valor_declarado, alto_valor, fecha_compromiso)
    VALUES ('EE0000000000003', 1, 1, 1, 2, TRUNC(SYSDATE) - 2, 'Calle 3 # 3-3', 4.00, 'Equipo', 3000000, 'S', TRUNC(SYSDATE) + 1);
INSERT INTO envio (numero_guia, id_solicitud, id_destinatario, id_zona, id_modalidad, fecha_registro, direccion_destino, peso_declarado, contenido, valor_declarado, fecha_compromiso)
    VALUES ('EE0000000000004', 1, 1, 1, 2, TRUNC(SYSDATE) - 2, 'Calle 4 # 4-4', 0.50, 'Cartas', 10000, TRUNC(SYSDATE) + 2);
INSERT INTO envio (numero_guia, id_solicitud, id_destinatario, id_zona, id_modalidad, fecha_registro, direccion_destino, peso_declarado, contenido, valor_declarado, fecha_compromiso)
    VALUES ('EE0000000000005', 1, 1, 1, 2, TRUNC(SYSDATE) - 3, 'Calle 5 # 5-5', 0.70, 'Muestras', 20000, TRUNC(SYSDATE) - 1);

-- Eventos: fecha_hora distinta por envio y por evento (indice unico). Los de
-- los envios 2, 3 y 5 se fijan respecto a la medianoche para que el resultado
-- de a tiempo / tarde no dependa de la hora en que se corre la prueba.
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion)
    SELECT g.guia, e.id_estado, 2, LOCALTIMESTAMP - NUMTODSINTERVAL(g.n * 100 + (10 - e.id_estado), 'MINUTE'), 'Prueba'
    FROM (SELECT 'EE0000000000001' guia, 1 n FROM dual UNION ALL SELECT 'EE0000000000004', 2 FROM dual) g
    CROSS JOIN (SELECT level id_estado FROM dual CONNECT BY level <= 4) e;
-- Envio 2 y 5: hasta ENTREGADO (6); envio 3: hasta CON_NOVEDAD (7)
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000002', 1, 2, TRUNC(LOCALTIMESTAMP) - INTERVAL '15' HOUR, 'Registrado');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000002', 5, 1, TRUNC(LOCALTIMESTAMP) + INTERVAL '1' HOUR, 'En ruta');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000002', 6, 1, TRUNC(LOCALTIMESTAMP) + INTERVAL '2' HOUR, 'Entregado');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000003', 1, 2, TRUNC(LOCALTIMESTAMP) - INTERVAL '14' HOUR, 'Registrado');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000003', 5, 1, TRUNC(LOCALTIMESTAMP) + INTERVAL '1' HOUR, 'En ruta');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000003', 7, 1, TRUNC(LOCALTIMESTAMP) + INTERVAL '150' MINUTE, 'Destinatario ausente');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000005', 1, 2, TRUNC(LOCALTIMESTAMP) - INTERVAL '40' HOUR, 'Registrado');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000005', 6, 1, TRUNC(LOCALTIMESTAMP) + INTERVAL '1' HOUR, 'Entregado tarde');

-- Despacho 1 de entrega cerrado (envios 2 y 3); despacho 2 de entrega armado (envio 4)
INSERT INTO despacho (id_despacho, id_centro, id_vehiculo, id_mensajero, fecha, tipo, hora_salida, hora_cierre, estado)
    VALUES (1, 1, 1, 1, TRUNC(SYSDATE), 'ENTREGA', TRUNC(LOCALTIMESTAMP) + INTERVAL '30' MINUTE, TRUNC(LOCALTIMESTAMP) + INTERVAL '3' HOUR, 'CERRADO');
INSERT INTO despacho (id_despacho, id_centro, id_vehiculo, id_mensajero, fecha, tipo, estado)
    VALUES (2, 1, 1, 1, TRUNC(SYSDATE), 'ENTREGA', 'ARMADO');
INSERT INTO asignacion_despacho (id_asignacion, numero_guia, id_despacho, numero_intento, orden_visita, hora_visita, resultado)
    VALUES (1, 'EE0000000000002', 1, 1, 1, TRUNC(LOCALTIMESTAMP) + INTERVAL '2' HOUR, 'ENTREGADO');
INSERT INTO asignacion_despacho (id_asignacion, numero_guia, id_despacho, numero_intento, orden_visita, hora_visita, resultado)
    VALUES (2, 'EE0000000000003', 1, 1, 2, TRUNC(LOCALTIMESTAMP) + INTERVAL '150' MINUTE, 'NOVEDAD');
INSERT INTO asignacion_despacho (id_asignacion, numero_guia, id_despacho, numero_intento, orden_visita, resultado)
    VALUES (3, 'EE0000000000004', 2, 1, 1, 'PENDIENTE');
INSERT INTO novedad (id_novedad, id_asignacion, tipo_novedad, descripcion)
    VALUES (1, 2, 'DESTINATARIO_AUSENTE', 'Nadie atendió en la dirección');
INSERT INTO reclamacion (id_reclamacion, id_cliente, numero_guia, fecha_radicacion, tipo, descripcion)
    VALUES (1, 1, 'EE0000000000002', LOCALTIMESTAMP - INTERVAL '5' HOUR, 'ENTREGA', 'Reclamo por demora');
INSERT INTO reclamacion (id_reclamacion, id_cliente, fecha_radicacion, tipo, descripcion, respuesta, fecha_respuesta, estado)
    VALUES (2, 1, LOCALTIMESTAMP - INTERVAL '2' DAY, 'OTRO', 'Reclamo antiguo', 'Resuelto', LOCALTIMESTAMP - INTERVAL '1' DAY, 'CERRADA');

SET FEEDBACK ON
COLUMN numero_guia FORMAT A16
COLUMN estado FORMAT A12
COLUMN observacion FORMAT A22
COLUMN responsable FORMAT A14
COLUMN zona FORMAT A11
COLUMN modalidad FORMAT A10
COLUMN estado_actual FORMAT A12
COLUMN estado_despacho FORMAT A9
COLUMN tipo FORMAT A8
COLUMN mensajero FORMAT A12
COLUMN placa FORMAT A7
COLUMN destinatario FORMAT A11
COLUMN td FORMAT A3
COLUMN doc FORMAT A9
COLUMN resultado FORMAT A10
COLUMN tipo_novedad FORMAT A22
COLUMN telefono_destinatario FORMAT A12
COLUMN telefono_cliente FORMAT A12
COLUMN cliente FORMAT A20
COLUMN horas_transcurridas FORMAT 999.9
COLUMN porcentaje_a_tiempo FORMAT 999.9
COLUMN fecha_hora FORMAT A30

PROMPT === v_seguimiento_envio (guia 2) ===
SELECT numero_guia, id_cliente, fecha_hora, estado, observacion, responsable
FROM   v_seguimiento_envio WHERE numero_guia = 'EE0000000000002' ORDER BY fecha_hora;

PROMPT === v_estado_actual_envio ===
SELECT numero_guia, id_cliente, zona, id_centro, modalidad, estado_actual, es_final, fecha_compromiso
FROM   v_estado_actual_envio ORDER BY numero_guia;

PROMPT === v_planilla_despacho (despacho 1) ===
SELECT id_despacho, tipo, estado_despacho, mensajero, placa, orden_visita, numero_intento, numero_guia,
       destinatario, tipo_documento_destinatario td, numero_documento_destinatario doc, zona, fragil, alto_valor, resultado
FROM   v_planilla_despacho WHERE id_despacho = 1 ORDER BY orden_visita;

PROMPT === v_envios_por_despachar (esperado: guias 1 y 3; la 4 esta en despacho abierto) ===
SELECT numero_guia, id_centro, zona, modalidad, fecha_compromiso, peso_kg, fragil, alto_valor, estado_actual, intentos_previos
FROM   v_envios_por_despachar ORDER BY fecha_compromiso, numero_guia;

PROMPT === v_novedades_abiertas ===
SELECT id_novedad, numero_guia, numero_intento, tipo_novedad, destinatario, telefono_destinatario, cliente, telefono_cliente
FROM   v_novedades_abiertas;

PROMPT === v_reclamaciones_pendientes (esperado: solo la 1, ~5 horas) ===
SELECT id_reclamacion, cliente, numero_guia, tipo, horas_transcurridas FROM v_reclamaciones_pendientes;

PROMPT === v_cumplimiento_entregas (esperado: 2 entregados, 1 a tiempo, 50.0) ===
SELECT id_centro, id_zona, zona, entregados, entregados_a_tiempo, porcentaje_a_tiempo FROM v_cumplimiento_entregas;

ROLLBACK;
PROMPT Prueba terminada: ROLLBACK ejecutado, sin datos persistentes.
