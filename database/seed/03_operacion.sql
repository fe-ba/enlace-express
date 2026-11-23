-- Operacion de noviembre de 2026 (3 al 20): 29 envios con su historia completa.
-- Archivo generado con un script auxiliar (el .sql es la fuente versionada); se carga INSERTANDO directamente en las
-- tablas (no con el procedimiento, porque fecha_registro es historica) y con
-- los disparadores activos: los datos quedan validados por ellos. Orden por
-- envio: asignacion PENDIENTE, prueba o novedad, UPDATE del resultado y evento.
-- Los despachos de entrega se insertan ARMADO (el disparador de asignacion no
-- admite despachos CERRADOS) y se cierran al final.
WHENEVER SQLERROR EXIT FAILURE
SET DEFINE OFF
ALTER SESSION SET TIME_ZONE = 'America/Bogota';

-- Despachos de recoleccion (cerrados)
INSERT INTO despacho (id_despacho, id_centro, id_vehiculo, id_mensajero, fecha, tipo, hora_salida, hora_cierre, estado) VALUES (1, 1, 1, 6, DATE '2026-11-03', 'RECOLECCION', TIMESTAMP '2026-11-03 08:00:00', TIMESTAMP '2026-11-03 12:30:00', 'CERRADO');
INSERT INTO despacho (id_despacho, id_centro, id_vehiculo, id_mensajero, fecha, tipo, hora_salida, hora_cierre, estado) VALUES (2, 1, 2, 7, DATE '2026-11-04', 'RECOLECCION', TIMESTAMP '2026-11-04 08:00:00', TIMESTAMP '2026-11-04 12:30:00', 'CERRADO');
INSERT INTO despacho (id_despacho, id_centro, id_vehiculo, id_mensajero, fecha, tipo, hora_salida, hora_cierre, estado) VALUES (3, 2, 4, 10, DATE '2026-11-05', 'RECOLECCION', TIMESTAMP '2026-11-05 08:00:00', TIMESTAMP '2026-11-05 12:30:00', 'CERRADO');
INSERT INTO despacho (id_despacho, id_centro, id_vehiculo, id_mensajero, fecha, tipo, hora_salida, hora_cierre, estado) VALUES (4, 2, 7, 9, DATE '2026-11-06', 'RECOLECCION', TIMESTAMP '2026-11-06 08:00:00', TIMESTAMP '2026-11-06 12:30:00', 'CERRADO');
INSERT INTO despacho (id_despacho, id_centro, id_vehiculo, id_mensajero, fecha, tipo, hora_salida, hora_cierre, estado) VALUES (5, 2, 7, 9, DATE '2026-11-10', 'RECOLECCION', TIMESTAMP '2026-11-10 08:00:00', TIMESTAMP '2026-11-10 12:30:00', 'CERRADO');
INSERT INTO despacho (id_despacho, id_centro, id_vehiculo, id_mensajero, fecha, tipo, hora_salida, hora_cierre, estado) VALUES (6, 2, 4, 10, DATE '2026-11-11', 'RECOLECCION', TIMESTAMP '2026-11-11 08:00:00', TIMESTAMP '2026-11-11 12:30:00', 'CERRADO');
INSERT INTO despacho (id_despacho, id_centro, id_vehiculo, id_mensajero, fecha, tipo, hora_salida, hora_cierre, estado) VALUES (7, 1, 2, 8, DATE '2026-11-13', 'RECOLECCION', TIMESTAMP '2026-11-13 08:00:00', TIMESTAMP '2026-11-13 12:30:00', 'CERRADO');
INSERT INTO despacho (id_despacho, id_centro, id_vehiculo, id_mensajero, fecha, tipo, hora_salida, hora_cierre, estado) VALUES (8, 1, 1, 6, DATE '2026-11-17', 'RECOLECCION', TIMESTAMP '2026-11-17 08:00:00', TIMESTAMP '2026-11-17 12:30:00', 'CERRADO');
INSERT INTO despacho (id_despacho, id_centro, id_vehiculo, id_mensajero, fecha, tipo, hora_salida, hora_cierre, estado) VALUES (9, 2, 7, 9, DATE '2026-11-18', 'RECOLECCION', TIMESTAMP '2026-11-18 08:00:00', TIMESTAMP '2026-11-18 12:30:00', 'CERRADO');
INSERT INTO despacho (id_despacho, id_centro, id_vehiculo, id_mensajero, fecha, tipo, hora_salida, hora_cierre, estado) VALUES (10, 2, 4, 10, DATE '2026-11-19', 'RECOLECCION', TIMESTAMP '2026-11-19 08:00:00', TIMESTAMP '2026-11-19 12:30:00', 'CERRADO');

-- Despachos de entrega (se cierran al final)
INSERT INTO despacho (id_despacho, id_centro, id_vehiculo, id_mensajero, fecha, tipo, hora_salida, estado) VALUES (11, 1, 1, 6, DATE '2026-11-04', 'ENTREGA', TIMESTAMP '2026-11-04 08:30:00', 'ARMADO');
INSERT INTO despacho (id_despacho, id_centro, id_vehiculo, id_mensajero, fecha, tipo, hora_salida, estado) VALUES (12, 1, 2, 8, DATE '2026-11-05', 'ENTREGA', TIMESTAMP '2026-11-05 08:30:00', 'ARMADO');
INSERT INTO despacho (id_despacho, id_centro, id_vehiculo, id_mensajero, fecha, tipo, hora_salida, estado) VALUES (13, 1, 1, 6, DATE '2026-11-06', 'ENTREGA', TIMESTAMP '2026-11-06 08:30:00', 'ARMADO');
INSERT INTO despacho (id_despacho, id_centro, id_vehiculo, id_mensajero, fecha, tipo, hora_salida, estado) VALUES (14, 2, 4, 10, DATE '2026-11-05', 'ENTREGA', TIMESTAMP '2026-11-05 13:30:00', 'ARMADO');
INSERT INTO despacho (id_despacho, id_centro, id_vehiculo, id_mensajero, fecha, tipo, hora_salida, estado) VALUES (15, 1, 2, 7, DATE '2026-11-20', 'ENTREGA', TIMESTAMP '2026-11-20 08:30:00', 'ARMADO');
INSERT INTO despacho (id_despacho, id_centro, id_vehiculo, id_mensajero, fecha, tipo, hora_salida, estado) VALUES (16, 2, 4, 10, DATE '2026-11-07', 'ENTREGA', TIMESTAMP '2026-11-07 08:30:00', 'ARMADO');
INSERT INTO despacho (id_despacho, id_centro, id_vehiculo, id_mensajero, fecha, tipo, hora_salida, estado) VALUES (17, 1, 1, 6, DATE '2026-11-09', 'ENTREGA', TIMESTAMP '2026-11-09 08:30:00', 'ARMADO');
INSERT INTO despacho (id_despacho, id_centro, id_vehiculo, id_mensajero, fecha, tipo, hora_salida, estado) VALUES (18, 1, 2, 8, DATE '2026-11-10', 'ENTREGA', TIMESTAMP '2026-11-10 08:30:00', 'ARMADO');
INSERT INTO despacho (id_despacho, id_centro, id_vehiculo, id_mensajero, fecha, tipo, hora_salida, estado) VALUES (19, 2, 4, 10, DATE '2026-11-12', 'ENTREGA', TIMESTAMP '2026-11-12 08:30:00', 'ARMADO');
INSERT INTO despacho (id_despacho, id_centro, id_vehiculo, id_mensajero, fecha, tipo, hora_salida, estado) VALUES (20, 2, 7, 9, DATE '2026-11-10', 'ENTREGA', TIMESTAMP '2026-11-10 13:30:00', 'ARMADO');
INSERT INTO despacho (id_despacho, id_centro, id_vehiculo, id_mensajero, fecha, tipo, hora_salida, estado) VALUES (21, 1, 1, 6, DATE '2026-11-12', 'ENTREGA', TIMESTAMP '2026-11-12 08:30:00', 'ARMADO');
INSERT INTO despacho (id_despacho, id_centro, id_vehiculo, id_mensajero, fecha, tipo, hora_salida, estado) VALUES (22, 1, 2, 8, DATE '2026-11-16', 'ENTREGA', TIMESTAMP '2026-11-16 08:30:00', 'ARMADO');
INSERT INTO despacho (id_despacho, id_centro, id_vehiculo, id_mensajero, fecha, tipo, hora_salida, estado) VALUES (23, 2, 4, 10, DATE '2026-11-18', 'ENTREGA', TIMESTAMP '2026-11-18 08:30:00', 'ARMADO');
INSERT INTO despacho (id_despacho, id_centro, id_vehiculo, id_mensajero, fecha, tipo, hora_salida, estado) VALUES (24, 2, 7, 9, DATE '2026-11-19', 'ENTREGA', TIMESTAMP '2026-11-19 08:30:00', 'ARMADO');
INSERT INTO despacho (id_despacho, id_centro, id_vehiculo, id_mensajero, fecha, tipo, hora_salida, estado) VALUES (25, 2, 7, 9, DATE '2026-11-18', 'ENTREGA', TIMESTAMP '2026-11-18 13:30:00', 'ARMADO');
INSERT INTO despacho (id_despacho, id_centro, id_vehiculo, id_mensajero, fecha, tipo, hora_salida, estado) VALUES (26, 1, 8, 11, DATE '2026-11-20', 'ENTREGA', NULL, 'ARMADO');

-- Solicitudes de recoleccion
INSERT INTO solicitud_recoleccion (id_solicitud, id_sede, id_despacho, fecha_solicitud, fecha_programada, franja_horaria, estado) VALUES (1, 1, 1, DATE '2026-11-03', DATE '2026-11-03', 'MANANA', 'ATENDIDA');
INSERT INTO solicitud_recoleccion (id_solicitud, id_sede, id_despacho, fecha_solicitud, fecha_programada, franja_horaria, estado) VALUES (2, 2, 2, DATE '2026-11-03', DATE '2026-11-04', 'TARDE', 'ATENDIDA');
INSERT INTO solicitud_recoleccion (id_solicitud, id_sede, id_despacho, fecha_solicitud, fecha_programada, franja_horaria, estado) VALUES (3, 3, 3, DATE '2026-11-04', DATE '2026-11-05', 'MANANA', 'ATENDIDA');
INSERT INTO solicitud_recoleccion (id_solicitud, id_sede, id_despacho, fecha_solicitud, fecha_programada, franja_horaria, estado) VALUES (4, 5, 4, DATE '2026-11-05', DATE '2026-11-06', 'MANANA', 'ATENDIDA');
INSERT INTO solicitud_recoleccion (id_solicitud, id_sede, id_despacho, fecha_solicitud, fecha_programada, franja_horaria, estado) VALUES (5, 6, 5, DATE '2026-11-09', DATE '2026-11-10', 'TARDE', 'ATENDIDA');
INSERT INTO solicitud_recoleccion (id_solicitud, id_sede, id_despacho, fecha_solicitud, fecha_programada, franja_horaria, estado) VALUES (6, 4, 6, DATE '2026-11-10', DATE '2026-11-11', 'MANANA', 'ATENDIDA');
INSERT INTO solicitud_recoleccion (id_solicitud, id_sede, id_despacho, fecha_solicitud, fecha_programada, franja_horaria, estado) VALUES (7, 1, 7, DATE '2026-11-12', DATE '2026-11-13', 'MANANA', 'ATENDIDA');
INSERT INTO solicitud_recoleccion (id_solicitud, id_sede, id_despacho, fecha_solicitud, fecha_programada, franja_horaria, estado) VALUES (8, 2, 8, DATE '2026-11-16', DATE '2026-11-17', 'TARDE', 'ATENDIDA');
INSERT INTO solicitud_recoleccion (id_solicitud, id_sede, id_despacho, fecha_solicitud, fecha_programada, franja_horaria, estado) VALUES (9, 5, 9, DATE '2026-11-17', DATE '2026-11-18', 'MANANA', 'ATENDIDA');
INSERT INTO solicitud_recoleccion (id_solicitud, id_sede, id_despacho, fecha_solicitud, fecha_programada, franja_horaria, estado) VALUES (10, 3, 10, DATE '2026-11-18', DATE '2026-11-19', 'MANANA', 'ATENDIDA');
INSERT INTO solicitud_recoleccion (id_solicitud, id_sede, id_despacho, fecha_solicitud, fecha_programada, franja_horaria, estado) VALUES (11, 6, NULL, DATE '2026-11-19', DATE '2026-11-20', 'TARDE', 'PROGRAMADA');
INSERT INTO solicitud_recoleccion (id_solicitud, id_sede, id_despacho, fecha_solicitud, fecha_programada, franja_horaria, estado) VALUES (12, 1, NULL, DATE '2026-11-19', DATE '2026-11-20', 'MANANA', 'PENDIENTE');
INSERT INTO solicitud_recoleccion (id_solicitud, id_sede, id_despacho, fecha_solicitud, fecha_programada, franja_horaria, estado) VALUES (13, 4, NULL, DATE '2026-11-12', DATE '2026-11-13', 'MANANA', 'NO_ATENDIDA');

-- Destinatarios
INSERT INTO destinatario (id_destinatario, tipo_documento, numero_documento, nombre, telefono, correo) VALUES (1, 'CC', '79456123', 'Luis Alberto Pérez', '3153334401', 'luis.perez@example.com');
INSERT INTO destinatario (id_destinatario, tipo_documento, numero_documento, nombre, telefono, correo) VALUES (2, 'CC', '52789456', 'María Fernanda Ortega', '3153334402', NULL);
INSERT INTO destinatario (id_destinatario, tipo_documento, numero_documento, nombre, telefono, correo) VALUES (3, 'CC', '1012345678', 'Ricardo Gómez Salazar', '3153334403', 'ricardo.gomez@example.com');
INSERT INTO destinatario (id_destinatario, tipo_documento, numero_documento, nombre, telefono, correo) VALUES (4, 'CE', '456789012', 'Giovanni Rossi', '3153334404', NULL);
INSERT INTO destinatario (id_destinatario, tipo_documento, numero_documento, nombre, telefono, correo) VALUES (5, 'CC', '80123987', 'Claudia Patricia Rincón', '3153334405', 'claudia.rincon@example.com');
INSERT INTO destinatario (id_destinatario, tipo_documento, numero_documento, nombre, telefono, correo) VALUES (6, 'NIT', '900765432', 'Clínica Santa Teresa S.A.', '6015552006', 'recepcion@santateresa.example.com');
INSERT INTO destinatario (id_destinatario, tipo_documento, numero_documento, nombre, telefono, correo) VALUES (7, 'CC', '1098765432', 'Daniela Martínez', '3153334407', NULL);
INSERT INTO destinatario (id_destinatario, tipo_documento, numero_documento, nombre, telefono, correo) VALUES (8, 'CC', '51654321', 'Beatriz Elena Cruz', '3153334408', 'beatriz.cruz@example.com');
INSERT INTO destinatario (id_destinatario, tipo_documento, numero_documento, nombre, telefono, correo) VALUES (9, 'CC', '1000234567', 'Santiago Vargas', '3153334409', NULL);
INSERT INTO destinatario (id_destinatario, tipo_documento, numero_documento, nombre, telefono, correo) VALUES (10, 'PAS', 'AB1234567', 'Emily Johnson', '3153334410', 'emily.johnson@example.com');
INSERT INTO destinatario (id_destinatario, tipo_documento, numero_documento, nombre, telefono, correo) VALUES (11, 'CC', '79852147', 'Héctor Mauricio Silva', '3153334411', NULL);
INSERT INTO destinatario (id_destinatario, tipo_documento, numero_documento, nombre, telefono, correo) VALUES (12, 'CC', '52963852', 'Paola Andrea Navarro', '3153334412', 'paola.navarro@example.com');
INSERT INTO destinatario (id_destinatario, tipo_documento, numero_documento, nombre, telefono, correo) VALUES (13, 'TI', '1100456789', 'Valentina Ríos', '3153334413', NULL);
INSERT INTO destinatario (id_destinatario, tipo_documento, numero_documento, nombre, telefono, correo) VALUES (14, 'CC', '80741852', 'Jairo Enrique Mejía', '3153334414', 'jairo.mejia@example.com');

-- Envio 1: EE0000000000001
INSERT INTO envio (numero_guia, id_solicitud, id_destinatario, id_zona, id_modalidad, fecha_registro, direccion_destino, peso_declarado, peso_real, contenido, valor_declarado, fragil, alto_valor, valor_flete, fecha_compromiso) VALUES ('EE0000000000001', 1, 1, 1, 2, DATE '2026-11-03', 'Calle 13 # 6-21', 1.50, 1.60, 'Medicamentos de venta libre', 180000, 'N', 'N', 8010.00, DATE '2026-11-04');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000001', 1, 4, TIMESTAMP '2026-11-03 08:31:00', 'Envío registrado en la mesa de servicio');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000001', 2, 6, TIMESTAMP '2026-11-03 10:31:00', 'Recogido en la sede del cliente');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000001', 3, 2, TIMESTAMP '2026-11-03 14:01:00', 'Recibido y pesado en el centro de distribución');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000001', 4, 2, TIMESTAMP '2026-11-03 16:01:00', 'Clasificado por zona de destino');
INSERT INTO asignacion_despacho (id_asignacion, numero_guia, id_despacho, numero_intento, orden_visita, hora_visita, resultado) VALUES (1, 'EE0000000000001', 11, 1, 1, TIMESTAMP '2026-11-04 10:10:00', 'PENDIENTE');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000001', 5, 6, TIMESTAMP '2026-11-04 08:41:00', 'Sale en el despacho 11 (intento 1)');
INSERT INTO prueba_entrega (id_prueba, id_asignacion, fecha_hora, nombre_receptor, documento_receptor, tipo_prueba, archivo_soporte) VALUES (1, 1, TIMESTAMP '2026-11-04 10:10:00', 'Recepción del edificio', '1012000037', 'FIRMA', 'soportes/EE0000000000001_1.png');
UPDATE asignacion_despacho SET resultado = 'ENTREGADO' WHERE id_asignacion = 1;
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000001', 6, 6, TIMESTAMP '2026-11-04 10:11:00', 'Entregado a Recepción del edificio');

-- Envio 2: EE0000000000002
INSERT INTO envio (numero_guia, id_solicitud, id_destinatario, id_zona, id_modalidad, fecha_registro, direccion_destino, peso_declarado, peso_real, contenido, valor_declarado, fragil, alto_valor, valor_flete, fecha_compromiso) VALUES ('EE0000000000002', 1, 2, 2, 3, DATE '2026-11-03', 'Calle 16 # 7-22', 2.00, 2.10, 'Equipo de medición de glucosa', 350000, 'S', 'N', 8100.00, DATE '2026-11-05');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000002', 1, 4, TIMESTAMP '2026-11-03 08:32:00', 'Envío registrado en la mesa de servicio');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000002', 2, 6, TIMESTAMP '2026-11-03 10:32:00', 'Recogido en la sede del cliente');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000002', 3, 2, TIMESTAMP '2026-11-03 14:02:00', 'Recibido y pesado en el centro de distribución');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000002', 4, 2, TIMESTAMP '2026-11-03 16:02:00', 'Clasificado por zona de destino');
INSERT INTO asignacion_despacho (id_asignacion, numero_guia, id_despacho, numero_intento, orden_visita, hora_visita, resultado) VALUES (2, 'EE0000000000002', 11, 1, 2, TIMESTAMP '2026-11-04 10:40:00', 'PENDIENTE');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000002', 5, 6, TIMESTAMP '2026-11-04 08:42:00', 'Sale en el despacho 11 (intento 1)');
INSERT INTO prueba_entrega (id_prueba, id_asignacion, fecha_hora, nombre_receptor, documento_receptor, tipo_prueba, archivo_soporte) VALUES (2, 2, TIMESTAMP '2026-11-04 10:40:00', 'María Fernanda Ortega', '52789456', 'FOTOGRAFIA', 'soportes/EE0000000000002_1.png');
UPDATE asignacion_despacho SET resultado = 'ENTREGADO' WHERE id_asignacion = 2;
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000002', 6, 6, TIMESTAMP '2026-11-04 10:41:00', 'Entregado a María Fernanda Ortega');

-- Envio 3: EE0000000000003
INSERT INTO envio (numero_guia, id_solicitud, id_destinatario, id_zona, id_modalidad, fecha_registro, direccion_destino, peso_declarado, peso_real, contenido, valor_declarado, fragil, alto_valor, valor_flete, fecha_compromiso) VALUES ('EE0000000000003', 1, 3, 3, 3, DATE '2026-11-03', 'Calle 19 # 8-23', 3.00, 3.10, 'Suministros de oficina', 90000, 'N', 'N', 9900.00, DATE '2026-11-05');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000003', 1, 4, TIMESTAMP '2026-11-03 08:33:00', 'Envío registrado en la mesa de servicio');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000003', 2, 6, TIMESTAMP '2026-11-03 10:33:00', 'Recogido en la sede del cliente');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000003', 3, 2, TIMESTAMP '2026-11-03 14:03:00', 'Recibido y pesado en el centro de distribución');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000003', 4, 2, TIMESTAMP '2026-11-03 16:03:00', 'Clasificado por zona de destino');
INSERT INTO asignacion_despacho (id_asignacion, numero_guia, id_despacho, numero_intento, orden_visita, hora_visita, resultado) VALUES (3, 'EE0000000000003', 11, 1, 3, TIMESTAMP '2026-11-04 11:10:00', 'PENDIENTE');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000003', 5, 6, TIMESTAMP '2026-11-04 08:43:00', 'Sale en el despacho 11 (intento 1)');
INSERT INTO novedad (id_novedad, id_asignacion, tipo_novedad, descripcion, accion, solucion, estado) VALUES (1, 3, 'DESTINATARIO_AUSENTE', 'No había nadie en la dirección al momento de la visita', 'REINTENTO', 'Se reprogramó la entrega para el día siguiente', 'CERRADA');
UPDATE asignacion_despacho SET resultado = 'NOVEDAD' WHERE id_asignacion = 3;
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000003', 7, 6, TIMESTAMP '2026-11-04 11:11:00', 'Novedad: DESTINATARIO_AUSENTE');
INSERT INTO asignacion_despacho (id_asignacion, numero_guia, id_despacho, numero_intento, orden_visita, hora_visita, resultado) VALUES (4, 'EE0000000000003', 12, 2, 1, TIMESTAMP '2026-11-05 10:10:00', 'PENDIENTE');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000003', 5, 8, TIMESTAMP '2026-11-05 08:43:00', 'Sale en el despacho 12 (intento 2)');
INSERT INTO prueba_entrega (id_prueba, id_asignacion, fecha_hora, nombre_receptor, documento_receptor, tipo_prueba, archivo_soporte) VALUES (3, 4, TIMESTAMP '2026-11-05 10:10:00', 'Recepción del edificio', '1012000111', 'DOCUMENTO', NULL);
UPDATE asignacion_despacho SET resultado = 'ENTREGADO' WHERE id_asignacion = 4;
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000003', 6, 8, TIMESTAMP '2026-11-05 10:11:00', 'Entregado a Recepción del edificio');

-- Envio 4: EE0000000000004
INSERT INTO envio (numero_guia, id_solicitud, id_destinatario, id_zona, id_modalidad, fecha_registro, direccion_destino, peso_declarado, peso_real, contenido, valor_declarado, fragil, alto_valor, valor_flete, fecha_compromiso) VALUES ('EE0000000000004', 1, 4, 4, 2, DATE '2026-11-03', 'Calle 22 # 9-24', 0.80, 0.90, 'Dispositivo médico', 620000, 'N', 'N', NULL, DATE '2026-11-04');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000004', 1, 4, TIMESTAMP '2026-11-03 08:34:00', 'Envío registrado en la mesa de servicio');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000004', 9, 4, TIMESTAMP '2026-11-03 09:19:00', 'Anulado a solicitud del cliente antes de la recolección');

-- Envio 5: EE0000000000005
INSERT INTO envio (numero_guia, id_solicitud, id_destinatario, id_zona, id_modalidad, fecha_registro, direccion_destino, peso_declarado, peso_real, contenido, valor_declarado, fragil, alto_valor, valor_flete, fecha_compromiso) VALUES ('EE0000000000005', 2, 5, 1, 3, DATE '2026-11-04', 'Calle 25 # 10-25', 2.50, 2.60, 'Equipo electrónico', 4500000, 'N', 'S', 9000.00, DATE '2026-11-06');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000005', 1, 4, TIMESTAMP '2026-11-04 08:35:00', 'Envío registrado en la mesa de servicio');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000005', 2, 7, TIMESTAMP '2026-11-04 10:35:00', 'Recogido en la sede del cliente');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000005', 3, 2, TIMESTAMP '2026-11-04 14:05:00', 'Recibido y pesado en el centro de distribución');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000005', 4, 2, TIMESTAMP '2026-11-04 16:05:00', 'Clasificado por zona de destino');
INSERT INTO asignacion_despacho (id_asignacion, numero_guia, id_despacho, numero_intento, orden_visita, hora_visita, resultado) VALUES (5, 'EE0000000000005', 12, 1, 2, TIMESTAMP '2026-11-05 10:40:00', 'PENDIENTE');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000005', 5, 8, TIMESTAMP '2026-11-05 08:45:00', 'Sale en el despacho 12 (intento 1)');
INSERT INTO prueba_entrega (id_prueba, id_asignacion, fecha_hora, nombre_receptor, documento_receptor, tipo_prueba, archivo_soporte) VALUES (4, 5, TIMESTAMP '2026-11-05 10:40:00', 'Claudia Patricia Rincón', '80123987', 'FIRMA', 'soportes/EE0000000000005_1.png');
UPDATE asignacion_despacho SET resultado = 'ENTREGADO' WHERE id_asignacion = 5;
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000005', 6, 8, TIMESTAMP '2026-11-05 10:41:00', 'Entregado a Claudia Patricia Rincón');

-- Envio 6: EE0000000000006
INSERT INTO envio (numero_guia, id_solicitud, id_destinatario, id_zona, id_modalidad, fecha_registro, direccion_destino, peso_declarado, peso_real, contenido, valor_declarado, fragil, alto_valor, valor_flete, fecha_compromiso) VALUES ('EE0000000000006', 2, 6, 5, 2, DATE '2026-11-04', 'Calle 28 # 11-26', 1.20, 1.30, 'Documentos contractuales', 150000, 'N', 'N', 7308.00, DATE '2026-11-05');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000006', 1, 4, TIMESTAMP '2026-11-04 08:36:00', 'Envío registrado en la mesa de servicio');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000006', 2, 7, TIMESTAMP '2026-11-04 10:36:00', 'Recogido en la sede del cliente');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000006', 3, 2, TIMESTAMP '2026-11-04 14:06:00', 'Recibido y pesado en el centro de distribución');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000006', 4, 2, TIMESTAMP '2026-11-04 16:06:00', 'Clasificado por zona de destino');
INSERT INTO asignacion_despacho (id_asignacion, numero_guia, id_despacho, numero_intento, orden_visita, hora_visita, resultado) VALUES (6, 'EE0000000000006', 13, 1, 1, TIMESTAMP '2026-11-06 10:10:00', 'PENDIENTE');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000006', 5, 6, TIMESTAMP '2026-11-06 08:46:00', 'Sale en el despacho 13 (intento 1)');
INSERT INTO prueba_entrega (id_prueba, id_asignacion, fecha_hora, nombre_receptor, documento_receptor, tipo_prueba, archivo_soporte) VALUES (5, 6, TIMESTAMP '2026-11-06 10:10:00', 'Recepción del edificio', '1012000185', 'FOTOGRAFIA', 'soportes/EE0000000000006_1.png');
UPDATE asignacion_despacho SET resultado = 'ENTREGADO' WHERE id_asignacion = 6;
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000006', 6, 6, TIMESTAMP '2026-11-06 10:11:00', 'Entregado a Recepción del edificio');

-- Envio 7: EE0000000000007
INSERT INTO envio (numero_guia, id_solicitud, id_destinatario, id_zona, id_modalidad, fecha_registro, direccion_destino, peso_declarado, peso_real, contenido, valor_declarado, fragil, alto_valor, valor_flete, fecha_compromiso) VALUES ('EE0000000000007', 3, 7, 3, 1, DATE '2026-11-05', 'Calle 31 # 12-27', 0.60, 0.70, 'Repuestos de computador', 80000, 'N', 'N', 6228.00, DATE '2026-11-05');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000007', 1, 5, TIMESTAMP '2026-11-05 08:30:00', 'Envío registrado en la mesa de servicio');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000007', 2, 10, TIMESTAMP '2026-11-05 09:30:00', 'Recogido en la sede del cliente');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000007', 3, 3, TIMESTAMP '2026-11-05 11:00:00', 'Recibido y pesado en el centro de distribución');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000007', 4, 3, TIMESTAMP '2026-11-05 12:00:00', 'Clasificado por zona de destino');
INSERT INTO asignacion_despacho (id_asignacion, numero_guia, id_despacho, numero_intento, orden_visita, hora_visita, resultado) VALUES (7, 'EE0000000000007', 14, 1, 1, TIMESTAMP '2026-11-05 15:10:00', 'PENDIENTE');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000007', 5, 10, TIMESTAMP '2026-11-05 13:40:00', 'Sale en el despacho 14 (intento 1)');
INSERT INTO prueba_entrega (id_prueba, id_asignacion, fecha_hora, nombre_receptor, documento_receptor, tipo_prueba, archivo_soporte) VALUES (6, 7, TIMESTAMP '2026-11-05 15:10:00', 'Recepción del edificio', '1012000222', 'DOCUMENTO', NULL);
UPDATE asignacion_despacho SET resultado = 'ENTREGADO' WHERE id_asignacion = 7;
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000007', 6, 10, TIMESTAMP '2026-11-05 15:11:00', 'Entregado a Recepción del edificio');

-- Envio 8: EE0000000000008
INSERT INTO envio (numero_guia, id_solicitud, id_destinatario, id_zona, id_modalidad, fecha_registro, direccion_destino, peso_declarado, peso_real, contenido, valor_declarado, fragil, alto_valor, valor_flete, fecha_compromiso) VALUES ('EE0000000000008', 3, 8, 4, 3, DATE '2026-11-05', 'Calle 34 # 13-28', 4.00, 4.10, 'Material de laboratorio', 260000, 'N', 'N', 11700.00, DATE '2026-11-07');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000008', 1, 5, TIMESTAMP '2026-11-05 08:31:00', 'Envío registrado en la mesa de servicio');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000008', 2, 10, TIMESTAMP '2026-11-05 10:31:00', 'Recogido en la sede del cliente');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000008', 3, 3, TIMESTAMP '2026-11-05 14:01:00', 'Recibido y pesado en el centro de distribución');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000008', 4, 3, TIMESTAMP '2026-11-05 16:01:00', 'Clasificado por zona de destino');
INSERT INTO asignacion_despacho (id_asignacion, numero_guia, id_despacho, numero_intento, orden_visita, hora_visita, resultado) VALUES (8, 'EE0000000000008', 16, 1, 1, TIMESTAMP '2026-11-07 10:10:00', 'PENDIENTE');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000008', 5, 10, TIMESTAMP '2026-11-07 08:41:00', 'Sale en el despacho 16 (intento 1)');
INSERT INTO prueba_entrega (id_prueba, id_asignacion, fecha_hora, nombre_receptor, documento_receptor, tipo_prueba, archivo_soporte) VALUES (7, 8, TIMESTAMP '2026-11-07 10:10:00', 'Recepción del edificio', '1012000259', 'FIRMA', 'soportes/EE0000000000008_1.png');
UPDATE asignacion_despacho SET resultado = 'ENTREGADO' WHERE id_asignacion = 8;
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000008', 6, 10, TIMESTAMP '2026-11-07 10:11:00', 'Entregado a Recepción del edificio');

-- Envio 9: EE0000000000009
INSERT INTO envio (numero_guia, id_solicitud, id_destinatario, id_zona, id_modalidad, fecha_registro, direccion_destino, peso_declarado, peso_real, contenido, valor_declarado, fragil, alto_valor, valor_flete, fecha_compromiso) VALUES ('EE0000000000009', 4, 9, 5, 3, DATE '2026-11-06', 'Calle 37 # 14-29', 5.50, 5.60, 'Ropa deportiva', 310000, 'N', 'N', 14400.00, DATE '2026-11-09');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000009', 1, 4, TIMESTAMP '2026-11-06 08:32:00', 'Envío registrado en la mesa de servicio');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000009', 2, 9, TIMESTAMP '2026-11-06 10:32:00', 'Recogido en la sede del cliente');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000009', 3, 2, TIMESTAMP '2026-11-06 14:02:00', 'Recibido y pesado en el centro de distribución');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000009', 4, 2, TIMESTAMP '2026-11-06 16:02:00', 'Clasificado por zona de destino');
INSERT INTO asignacion_despacho (id_asignacion, numero_guia, id_despacho, numero_intento, orden_visita, hora_visita, resultado) VALUES (9, 'EE0000000000009', 17, 1, 1, TIMESTAMP '2026-11-09 10:10:00', 'PENDIENTE');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000009', 5, 6, TIMESTAMP '2026-11-09 08:42:00', 'Sale en el despacho 17 (intento 1)');
INSERT INTO novedad (id_novedad, id_asignacion, tipo_novedad, descripcion, accion, solucion, estado) VALUES (2, 9, 'DIRECCION_ERRADA', 'La dirección no existe en la nomenclatura del barrio', 'REINTENTO', 'La mesa de servicio confirmó una dirección nueva con el destinatario', 'CERRADA');
UPDATE asignacion_despacho SET resultado = 'NOVEDAD' WHERE id_asignacion = 9;
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000009', 7, 6, TIMESTAMP '2026-11-09 10:11:00', 'Novedad: DIRECCION_ERRADA');
INSERT INTO asignacion_despacho (id_asignacion, numero_guia, id_despacho, numero_intento, orden_visita, hora_visita, resultado) VALUES (10, 'EE0000000000009', 18, 2, 1, TIMESTAMP '2026-11-10 10:10:00', 'PENDIENTE');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000009', 5, 8, TIMESTAMP '2026-11-10 08:42:00', 'Sale en el despacho 18 (intento 2)');
INSERT INTO novedad (id_novedad, id_asignacion, tipo_novedad, descripcion, accion, solucion, estado) VALUES (3, 10, 'DESTINATARIO_AUSENTE', 'El destinatario no atendió en la segunda visita', 'DEVOLUCION', 'Se autorizó la devolución al remitente', 'CERRADA');
UPDATE asignacion_despacho SET resultado = 'NOVEDAD' WHERE id_asignacion = 10;
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000009', 7, 8, TIMESTAMP '2026-11-10 10:11:00', 'Novedad: DESTINATARIO_AUSENTE');
INSERT INTO asignacion_despacho (id_asignacion, numero_guia, id_despacho, numero_intento, orden_visita, hora_visita, resultado) VALUES (11, 'EE0000000000009', 19, 3, 1, TIMESTAMP '2026-11-12 10:10:00', 'PENDIENTE');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000009', 5, 10, TIMESTAMP '2026-11-12 08:42:00', 'Sale en el despacho 19 (intento 3)');
INSERT INTO prueba_entrega (id_prueba, id_asignacion, fecha_hora, nombre_receptor, documento_receptor, tipo_prueba, archivo_soporte) VALUES (8, 11, TIMESTAMP '2026-11-12 10:10:00', 'Sandra Vega', '51888777', 'FOTOGRAFIA', 'soportes/EE0000000000009_3.png');
UPDATE asignacion_despacho SET resultado = 'DEVUELTO' WHERE id_asignacion = 11;
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000009', 8, 10, TIMESTAMP '2026-11-12 10:11:00', 'Devuelto a la sede del cliente remitente');

-- Envio 10: EE0000000000010
INSERT INTO envio (numero_guia, id_solicitud, id_destinatario, id_zona, id_modalidad, fecha_registro, direccion_destino, peso_declarado, peso_real, contenido, valor_declarado, fragil, alto_valor, valor_flete, fecha_compromiso) VALUES ('EE0000000000010', 4, 10, 1, 2, DATE '2026-11-06', 'Calle 40 # 15-30', 1.00, 1.10, 'Libros', 120000, 'N', 'N', 6840.00, DATE '2026-11-07');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000010', 1, 4, TIMESTAMP '2026-11-06 08:33:00', 'Envío registrado en la mesa de servicio');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000010', 2, 9, TIMESTAMP '2026-11-06 10:33:00', 'Recogido en la sede del cliente');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000010', 3, 2, TIMESTAMP '2026-11-06 14:03:00', 'Recibido y pesado en el centro de distribución');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000010', 4, 2, TIMESTAMP '2026-11-06 16:03:00', 'Clasificado por zona de destino');
INSERT INTO asignacion_despacho (id_asignacion, numero_guia, id_despacho, numero_intento, orden_visita, hora_visita, resultado) VALUES (12, 'EE0000000000010', 16, 1, 2, TIMESTAMP '2026-11-07 10:40:00', 'PENDIENTE');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000010', 5, 10, TIMESTAMP '2026-11-07 08:43:00', 'Sale en el despacho 16 (intento 1)');
INSERT INTO prueba_entrega (id_prueba, id_asignacion, fecha_hora, nombre_receptor, documento_receptor, tipo_prueba, archivo_soporte) VALUES (9, 12, TIMESTAMP '2026-11-07 10:40:00', 'Recepción del edificio', '1012000333', 'DOCUMENTO', NULL);
UPDATE asignacion_despacho SET resultado = 'ENTREGADO' WHERE id_asignacion = 12;
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000010', 6, 10, TIMESTAMP '2026-11-07 10:41:00', 'Entregado a Recepción del edificio');

-- Envio 11: EE0000000000011
INSERT INTO envio (numero_guia, id_solicitud, id_destinatario, id_zona, id_modalidad, fecha_registro, direccion_destino, peso_declarado, peso_real, contenido, valor_declarado, fragil, alto_valor, valor_flete, fecha_compromiso) VALUES ('EE0000000000011', 4, 11, 2, 3, DATE '2026-11-06', 'Calle 43 # 16-31', 2.20, 2.30, 'Accesorios de celular', 95000, 'N', 'N', 8460.00, DATE '2026-11-09');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000011', 1, 4, TIMESTAMP '2026-11-06 08:34:00', 'Envío registrado en la mesa de servicio');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000011', 2, 9, TIMESTAMP '2026-11-06 10:34:00', 'Recogido en la sede del cliente');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000011', 3, 2, TIMESTAMP '2026-11-06 14:04:00', 'Recibido y pesado en el centro de distribución');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000011', 4, 2, TIMESTAMP '2026-11-06 16:04:00', 'Clasificado por zona de destino');
INSERT INTO asignacion_despacho (id_asignacion, numero_guia, id_despacho, numero_intento, orden_visita, hora_visita, resultado) VALUES (13, 'EE0000000000011', 17, 1, 2, TIMESTAMP '2026-11-09 10:40:00', 'PENDIENTE');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000011', 5, 6, TIMESTAMP '2026-11-09 08:44:00', 'Sale en el despacho 17 (intento 1)');
INSERT INTO prueba_entrega (id_prueba, id_asignacion, fecha_hora, nombre_receptor, documento_receptor, tipo_prueba, archivo_soporte) VALUES (10, 13, TIMESTAMP '2026-11-09 10:40:00', 'Recepción del edificio', '1012000370', 'FIRMA', 'soportes/EE0000000000011_1.png');
UPDATE asignacion_despacho SET resultado = 'ENTREGADO' WHERE id_asignacion = 13;
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000011', 6, 6, TIMESTAMP '2026-11-09 10:41:00', 'Entregado a Recepción del edificio');

-- Envio 12: EE0000000000012
INSERT INTO envio (numero_guia, id_solicitud, id_destinatario, id_zona, id_modalidad, fecha_registro, direccion_destino, peso_declarado, peso_real, contenido, valor_declarado, fragil, alto_valor, valor_flete, fecha_compromiso) VALUES ('EE0000000000012', 5, 12, 3, 1, DATE '2026-11-10', 'Calle 46 # 17-32', 0.90, 1.00, 'Productos de aseo', 70000, 'N', 'N', 7092.00, DATE '2026-11-10');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000012', 1, 5, TIMESTAMP '2026-11-10 08:35:00', 'Envío registrado en la mesa de servicio');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000012', 2, 9, TIMESTAMP '2026-11-10 09:35:00', 'Recogido en la sede del cliente');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000012', 3, 3, TIMESTAMP '2026-11-10 11:05:00', 'Recibido y pesado en el centro de distribución');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000012', 4, 3, TIMESTAMP '2026-11-10 12:05:00', 'Clasificado por zona de destino');
INSERT INTO asignacion_despacho (id_asignacion, numero_guia, id_despacho, numero_intento, orden_visita, hora_visita, resultado) VALUES (14, 'EE0000000000012', 20, 1, 1, TIMESTAMP '2026-11-10 15:10:00', 'PENDIENTE');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000012', 5, 9, TIMESTAMP '2026-11-10 13:45:00', 'Sale en el despacho 20 (intento 1)');
INSERT INTO prueba_entrega (id_prueba, id_asignacion, fecha_hora, nombre_receptor, documento_receptor, tipo_prueba, archivo_soporte) VALUES (11, 14, TIMESTAMP '2026-11-10 15:10:00', 'Recepción del edificio', '1012000407', 'FOTOGRAFIA', 'soportes/EE0000000000012_1.png');
UPDATE asignacion_despacho SET resultado = 'ENTREGADO' WHERE id_asignacion = 14;
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000012', 6, 9, TIMESTAMP '2026-11-10 15:11:00', 'Entregado a Recepción del edificio');

-- Envio 13: EE0000000000013
INSERT INTO envio (numero_guia, id_solicitud, id_destinatario, id_zona, id_modalidad, fecha_registro, direccion_destino, peso_declarado, peso_real, contenido, valor_declarado, fragil, alto_valor, valor_flete, fecha_compromiso) VALUES ('EE0000000000013', 6, 13, 4, 3, DATE '2026-11-11', 'Calle 49 # 18-33', 3.40, 3.50, 'Muestras de laboratorio', 210000, 'N', 'N', 10620.00, DATE '2026-11-13');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000013', 1, 4, TIMESTAMP '2026-11-11 08:36:00', 'Envío registrado en la mesa de servicio');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000013', 2, 10, TIMESTAMP '2026-11-11 10:36:00', 'Recogido en la sede del cliente');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000013', 3, 2, TIMESTAMP '2026-11-11 14:06:00', 'Recibido y pesado en el centro de distribución');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000013', 4, 2, TIMESTAMP '2026-11-11 16:06:00', 'Clasificado por zona de destino');
INSERT INTO asignacion_despacho (id_asignacion, numero_guia, id_despacho, numero_intento, orden_visita, hora_visita, resultado) VALUES (15, 'EE0000000000013', 19, 1, 2, TIMESTAMP '2026-11-12 10:40:00', 'PENDIENTE');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000013', 5, 10, TIMESTAMP '2026-11-12 08:46:00', 'Sale en el despacho 19 (intento 1)');
INSERT INTO prueba_entrega (id_prueba, id_asignacion, fecha_hora, nombre_receptor, documento_receptor, tipo_prueba, archivo_soporte) VALUES (12, 15, TIMESTAMP '2026-11-12 10:40:00', 'Recepción del edificio', '1012000444', 'DOCUMENTO', NULL);
UPDATE asignacion_despacho SET resultado = 'ENTREGADO' WHERE id_asignacion = 15;
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000013', 6, 10, TIMESTAMP '2026-11-12 10:41:00', 'Entregado a Recepción del edificio');

-- Envio 14: EE0000000000014
INSERT INTO envio (numero_guia, id_solicitud, id_destinatario, id_zona, id_modalidad, fecha_registro, direccion_destino, peso_declarado, peso_real, contenido, valor_declarado, fragil, alto_valor, valor_flete, fecha_compromiso) VALUES ('EE0000000000014', 6, 14, 5, 3, DATE '2026-11-11', 'Calle 52 # 19-34', 1.80, 1.90, 'Calzado', 130000, 'N', 'N', 7740.00, DATE '2026-11-13');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000014', 1, 4, TIMESTAMP '2026-11-11 08:30:00', 'Envío registrado en la mesa de servicio');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000014', 2, 10, TIMESTAMP '2026-11-11 10:30:00', 'Recogido en la sede del cliente');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000014', 3, 2, TIMESTAMP '2026-11-11 14:00:00', 'Recibido y pesado en el centro de distribución');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000014', 4, 2, TIMESTAMP '2026-11-11 16:00:00', 'Clasificado por zona de destino');
INSERT INTO asignacion_despacho (id_asignacion, numero_guia, id_despacho, numero_intento, orden_visita, hora_visita, resultado) VALUES (16, 'EE0000000000014', 21, 1, 1, TIMESTAMP '2026-11-12 10:10:00', 'PENDIENTE');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000014', 5, 6, TIMESTAMP '2026-11-12 08:40:00', 'Sale en el despacho 21 (intento 1)');
INSERT INTO novedad (id_novedad, id_asignacion, tipo_novedad, descripcion, accion, solucion, estado) VALUES (4, 16, 'PAQUETE_AVERIADO', 'El empaque llegó roto a la dirección de entrega', NULL, NULL, 'ABIERTA');
UPDATE asignacion_despacho SET resultado = 'NOVEDAD' WHERE id_asignacion = 16;
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000014', 7, 6, TIMESTAMP '2026-11-12 10:11:00', 'Novedad: PAQUETE_AVERIADO');

-- Envio 15: EE0000000000015
INSERT INTO envio (numero_guia, id_solicitud, id_destinatario, id_zona, id_modalidad, fecha_registro, direccion_destino, peso_declarado, peso_real, contenido, valor_declarado, fragil, alto_valor, valor_flete, fecha_compromiso) VALUES ('EE0000000000015', 7, 1, 1, 2, DATE '2026-11-13', 'Calle 55 # 20-35', 1.10, 1.20, 'Juguetes', 99000, 'N', 'N', 7074.00, DATE '2026-11-14');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000015', 1, 4, TIMESTAMP '2026-11-13 08:31:00', 'Envío registrado en la mesa de servicio');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000015', 2, 8, TIMESTAMP '2026-11-13 10:31:00', 'Recogido en la sede del cliente');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000015', 3, 2, TIMESTAMP '2026-11-13 14:01:00', 'Recibido y pesado en el centro de distribución');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000015', 4, 2, TIMESTAMP '2026-11-13 16:01:00', 'Clasificado por zona de destino');
INSERT INTO asignacion_despacho (id_asignacion, numero_guia, id_despacho, numero_intento, orden_visita, hora_visita, resultado) VALUES (17, 'EE0000000000015', 22, 1, 1, TIMESTAMP '2026-11-16 10:10:00', 'PENDIENTE');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000015', 5, 8, TIMESTAMP '2026-11-16 08:41:00', 'Sale en el despacho 22 (intento 1)');
INSERT INTO prueba_entrega (id_prueba, id_asignacion, fecha_hora, nombre_receptor, documento_receptor, tipo_prueba, archivo_soporte) VALUES (13, 17, TIMESTAMP '2026-11-16 10:10:00', 'Recepción del edificio', '1012000481', 'FIRMA', 'soportes/EE0000000000015_1.png');
UPDATE asignacion_despacho SET resultado = 'ENTREGADO' WHERE id_asignacion = 17;
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000015', 6, 8, TIMESTAMP '2026-11-16 10:11:00', 'Entregado a Recepción del edificio');

-- Envio 16: EE0000000000016
INSERT INTO envio (numero_guia, id_solicitud, id_destinatario, id_zona, id_modalidad, fecha_registro, direccion_destino, peso_declarado, peso_real, contenido, valor_declarado, fragil, alto_valor, valor_flete, fecha_compromiso) VALUES ('EE0000000000016', 7, 2, 2, 3, DATE '2026-11-13', 'Calle 58 # 21-36', 2.70, 2.80, 'Papelería', 175000, 'N', 'N', 9360.00, DATE '2026-11-16');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000016', 1, 4, TIMESTAMP '2026-11-13 08:32:00', 'Envío registrado en la mesa de servicio');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000016', 2, 8, TIMESTAMP '2026-11-13 10:32:00', 'Recogido en la sede del cliente');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000016', 3, 2, TIMESTAMP '2026-11-13 14:02:00', 'Recibido y pesado en el centro de distribución');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000016', 4, 2, TIMESTAMP '2026-11-13 16:02:00', 'Clasificado por zona de destino');
INSERT INTO asignacion_despacho (id_asignacion, numero_guia, id_despacho, numero_intento, orden_visita, hora_visita, resultado) VALUES (18, 'EE0000000000016', 22, 1, 2, TIMESTAMP '2026-11-16 10:40:00', 'PENDIENTE');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000016', 5, 8, TIMESTAMP '2026-11-16 08:42:00', 'Sale en el despacho 22 (intento 1)');
INSERT INTO novedad (id_novedad, id_asignacion, tipo_novedad, descripcion, accion, solucion, estado) VALUES (5, 18, 'RECHAZADO', 'El destinatario rechazó el paquete por demora', 'REINTENTO', 'El cliente remitente autorizó un nuevo intento', 'CERRADA');
UPDATE asignacion_despacho SET resultado = 'NOVEDAD' WHERE id_asignacion = 18;
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000016', 7, 8, TIMESTAMP '2026-11-16 10:41:00', 'Novedad: RECHAZADO');
INSERT INTO asignacion_despacho (id_asignacion, numero_guia, id_despacho, numero_intento, orden_visita, hora_visita, resultado) VALUES (19, 'EE0000000000016', 23, 2, 1, TIMESTAMP '2026-11-18 10:10:00', 'PENDIENTE');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000016', 5, 10, TIMESTAMP '2026-11-18 08:42:00', 'Sale en el despacho 23 (intento 2)');
INSERT INTO prueba_entrega (id_prueba, id_asignacion, fecha_hora, nombre_receptor, documento_receptor, tipo_prueba, archivo_soporte) VALUES (14, 19, TIMESTAMP '2026-11-18 10:10:00', 'Recepción del edificio', '1012000518', 'FOTOGRAFIA', 'soportes/EE0000000000016_2.png');
UPDATE asignacion_despacho SET resultado = 'ENTREGADO' WHERE id_asignacion = 19;
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000016', 6, 10, TIMESTAMP '2026-11-18 10:11:00', 'Entregado a Recepción del edificio');

-- Envio 17: EE0000000000017
INSERT INTO envio (numero_guia, id_solicitud, id_destinatario, id_zona, id_modalidad, fecha_registro, direccion_destino, peso_declarado, peso_real, contenido, valor_declarado, fragil, alto_valor, valor_flete, fecha_compromiso) VALUES ('EE0000000000017', 8, 3, 3, 3, DATE '2026-11-17', 'Calle 61 # 22-37', 6.00, 6.10, 'Cosméticos', 280000, 'N', 'N', 15300.00, DATE '2026-11-19');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000017', 1, 4, TIMESTAMP '2026-11-17 08:33:00', 'Envío registrado en la mesa de servicio');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000017', 2, 6, TIMESTAMP '2026-11-17 10:33:00', 'Recogido en la sede del cliente');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000017', 3, 2, TIMESTAMP '2026-11-17 14:03:00', 'Recibido y pesado en el centro de distribución');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000017', 4, 2, TIMESTAMP '2026-11-17 16:03:00', 'Clasificado por zona de destino');
INSERT INTO asignacion_despacho (id_asignacion, numero_guia, id_despacho, numero_intento, orden_visita, hora_visita, resultado) VALUES (20, 'EE0000000000017', 23, 1, 2, TIMESTAMP '2026-11-18 10:40:00', 'PENDIENTE');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000017', 5, 10, TIMESTAMP '2026-11-18 08:43:00', 'Sale en el despacho 23 (intento 1)');
INSERT INTO prueba_entrega (id_prueba, id_asignacion, fecha_hora, nombre_receptor, documento_receptor, tipo_prueba, archivo_soporte) VALUES (15, 20, TIMESTAMP '2026-11-18 10:40:00', 'Recepción del edificio', '1012000555', 'DOCUMENTO', NULL);
UPDATE asignacion_despacho SET resultado = 'ENTREGADO' WHERE id_asignacion = 20;
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000017', 6, 10, TIMESTAMP '2026-11-18 10:41:00', 'Entregado a Recepción del edificio');

-- Envio 18: EE0000000000018
INSERT INTO envio (numero_guia, id_solicitud, id_destinatario, id_zona, id_modalidad, fecha_registro, direccion_destino, peso_declarado, peso_real, contenido, valor_declarado, fragil, alto_valor, valor_flete, fecha_compromiso) VALUES ('EE0000000000018', 9, 4, 4, 1, DATE '2026-11-18', 'Calle 64 # 23-38', 0.70, 0.80, 'Audífonos', 60000, 'N', 'N', 6516.00, DATE '2026-11-18');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000018', 1, 4, TIMESTAMP '2026-11-18 08:34:00', 'Envío registrado en la mesa de servicio');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000018', 2, 9, TIMESTAMP '2026-11-18 09:34:00', 'Recogido en la sede del cliente');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000018', 3, 2, TIMESTAMP '2026-11-18 11:04:00', 'Recibido y pesado en el centro de distribución');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000018', 4, 2, TIMESTAMP '2026-11-18 12:04:00', 'Clasificado por zona de destino');
INSERT INTO asignacion_despacho (id_asignacion, numero_guia, id_despacho, numero_intento, orden_visita, hora_visita, resultado) VALUES (21, 'EE0000000000018', 25, 1, 1, TIMESTAMP '2026-11-18 15:10:00', 'PENDIENTE');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000018', 5, 9, TIMESTAMP '2026-11-18 13:44:00', 'Sale en el despacho 25 (intento 1)');
INSERT INTO prueba_entrega (id_prueba, id_asignacion, fecha_hora, nombre_receptor, documento_receptor, tipo_prueba, archivo_soporte) VALUES (16, 21, TIMESTAMP '2026-11-18 15:10:00', 'Recepción del edificio', '1012000592', 'FIRMA', 'soportes/EE0000000000018_1.png');
UPDATE asignacion_despacho SET resultado = 'ENTREGADO' WHERE id_asignacion = 21;
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000018', 6, 9, TIMESTAMP '2026-11-18 15:11:00', 'Entregado a Recepción del edificio');

-- Envio 19: EE0000000000019
INSERT INTO envio (numero_guia, id_solicitud, id_destinatario, id_zona, id_modalidad, fecha_registro, direccion_destino, peso_declarado, peso_real, contenido, valor_declarado, fragil, alto_valor, valor_flete, fecha_compromiso) VALUES ('EE0000000000019', 9, 5, 5, 2, DATE '2026-11-18', 'Calle 67 # 24-39', 1.40, 1.50, 'Cartuchos de impresora', 140000, 'N', 'N', 7776.00, DATE '2026-11-19');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000019', 1, 4, TIMESTAMP '2026-11-18 08:35:00', 'Envío registrado en la mesa de servicio');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000019', 2, 9, TIMESTAMP '2026-11-18 10:35:00', 'Recogido en la sede del cliente');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000019', 3, 2, TIMESTAMP '2026-11-18 14:05:00', 'Recibido y pesado en el centro de distribución');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000019', 4, 2, TIMESTAMP '2026-11-18 16:05:00', 'Clasificado por zona de destino');
INSERT INTO asignacion_despacho (id_asignacion, numero_guia, id_despacho, numero_intento, orden_visita, hora_visita, resultado) VALUES (22, 'EE0000000000019', 24, 1, 1, TIMESTAMP '2026-11-19 10:10:00', 'PENDIENTE');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000019', 5, 9, TIMESTAMP '2026-11-19 08:45:00', 'Sale en el despacho 24 (intento 1)');
INSERT INTO prueba_entrega (id_prueba, id_asignacion, fecha_hora, nombre_receptor, documento_receptor, tipo_prueba, archivo_soporte) VALUES (17, 22, TIMESTAMP '2026-11-19 10:10:00', 'Recepción del edificio', '1012000629', 'FOTOGRAFIA', 'soportes/EE0000000000019_1.png');
UPDATE asignacion_despacho SET resultado = 'ENTREGADO' WHERE id_asignacion = 22;
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000019', 6, 9, TIMESTAMP '2026-11-19 10:11:00', 'Entregado a Recepción del edificio');

-- Envio 20: EE0000000000020
INSERT INTO envio (numero_guia, id_solicitud, id_destinatario, id_zona, id_modalidad, fecha_registro, direccion_destino, peso_declarado, peso_real, contenido, valor_declarado, fragil, alto_valor, valor_flete, fecha_compromiso) VALUES ('EE0000000000020', 9, 6, 1, 3, DATE '2026-11-18', 'Calle 70 # 25-40', 2.30, 2.40, 'Repuestos de bicicleta', 110000, 'N', 'N', 8640.00, DATE '2026-11-20');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000020', 1, 4, TIMESTAMP '2026-11-18 08:36:00', 'Envío registrado en la mesa de servicio');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000020', 2, 9, TIMESTAMP '2026-11-18 10:36:00', 'Recogido en la sede del cliente');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000020', 3, 2, TIMESTAMP '2026-11-18 14:06:00', 'Recibido y pesado en el centro de distribución');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000020', 4, 2, TIMESTAMP '2026-11-18 16:06:00', 'Clasificado por zona de destino');
INSERT INTO asignacion_despacho (id_asignacion, numero_guia, id_despacho, numero_intento, orden_visita, hora_visita, resultado) VALUES (23, 'EE0000000000020', 15, 1, 1, TIMESTAMP '2026-11-20 10:10:00', 'PENDIENTE');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000020', 5, 7, TIMESTAMP '2026-11-20 08:46:00', 'Sale en el despacho 15 (intento 1)');
INSERT INTO prueba_entrega (id_prueba, id_asignacion, fecha_hora, nombre_receptor, documento_receptor, tipo_prueba, archivo_soporte) VALUES (18, 23, TIMESTAMP '2026-11-20 10:10:00', 'Recepción del edificio', '1012000666', 'DOCUMENTO', NULL);
UPDATE asignacion_despacho SET resultado = 'ENTREGADO' WHERE id_asignacion = 23;
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000020', 6, 7, TIMESTAMP '2026-11-20 10:11:00', 'Entregado a Recepción del edificio');

-- Envio 21: EE0000000000021
INSERT INTO envio (numero_guia, id_solicitud, id_destinatario, id_zona, id_modalidad, fecha_registro, direccion_destino, peso_declarado, peso_real, contenido, valor_declarado, fragil, alto_valor, valor_flete, fecha_compromiso) VALUES ('EE0000000000021', 9, 7, 2, 3, DATE '2026-11-18', 'Calle 73 # 26-41', 1.90, 2.00, 'Termómetros', 85000, 'N', 'N', 7920.00, DATE '2026-11-20');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000021', 1, 4, TIMESTAMP '2026-11-18 08:30:00', 'Envío registrado en la mesa de servicio');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000021', 2, 9, TIMESTAMP '2026-11-18 10:30:00', 'Recogido en la sede del cliente');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000021', 3, 2, TIMESTAMP '2026-11-18 14:00:00', 'Recibido y pesado en el centro de distribución');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000021', 4, 2, TIMESTAMP '2026-11-18 16:00:00', 'Clasificado por zona de destino');
INSERT INTO asignacion_despacho (id_asignacion, numero_guia, id_despacho, numero_intento, orden_visita, hora_visita, resultado) VALUES (24, 'EE0000000000021', 15, 1, 2, TIMESTAMP '2026-11-20 10:40:00', 'PENDIENTE');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000021', 5, 7, TIMESTAMP '2026-11-20 08:40:00', 'Sale en el despacho 15 (intento 1)');
INSERT INTO prueba_entrega (id_prueba, id_asignacion, fecha_hora, nombre_receptor, documento_receptor, tipo_prueba, archivo_soporte) VALUES (19, 24, TIMESTAMP '2026-11-20 10:40:00', 'Recepción del edificio', '1012000703', 'FIRMA', 'soportes/EE0000000000021_1.png');
UPDATE asignacion_despacho SET resultado = 'ENTREGADO' WHERE id_asignacion = 24;
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000021', 6, 7, TIMESTAMP '2026-11-20 10:41:00', 'Entregado a Recepción del edificio');

-- Envio 22: EE0000000000022
INSERT INTO envio (numero_guia, id_solicitud, id_destinatario, id_zona, id_modalidad, fecha_registro, direccion_destino, peso_declarado, peso_real, contenido, valor_declarado, fragil, alto_valor, valor_flete, fecha_compromiso) VALUES ('EE0000000000022', 9, 8, 3, 3, DATE '2026-11-18', 'Calle 76 # 27-42', 3.80, 3.90, 'Tabletas', 230000, 'N', 'N', 11340.00, DATE '2026-11-20');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000022', 1, 4, TIMESTAMP '2026-11-18 08:31:00', 'Envío registrado en la mesa de servicio');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000022', 2, 9, TIMESTAMP '2026-11-18 10:31:00', 'Recogido en la sede del cliente');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000022', 3, 2, TIMESTAMP '2026-11-18 14:01:00', 'Recibido y pesado en el centro de distribución');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000022', 4, 2, TIMESTAMP '2026-11-18 16:01:00', 'Clasificado por zona de destino');
INSERT INTO asignacion_despacho (id_asignacion, numero_guia, id_despacho, numero_intento, orden_visita, hora_visita, resultado) VALUES (25, 'EE0000000000022', 15, 1, 3, TIMESTAMP '2026-11-20 11:10:00', 'PENDIENTE');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000022', 5, 7, TIMESTAMP '2026-11-20 08:41:00', 'Sale en el despacho 15 (intento 1)');
INSERT INTO novedad (id_novedad, id_asignacion, tipo_novedad, descripcion, accion, solucion, estado) VALUES (6, 25, 'DESTINATARIO_AUSENTE', 'Local cerrado en el horario de visita', NULL, NULL, 'ABIERTA');
UPDATE asignacion_despacho SET resultado = 'NOVEDAD' WHERE id_asignacion = 25;
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000022', 7, 7, TIMESTAMP '2026-11-20 11:11:00', 'Novedad: DESTINATARIO_AUSENTE');

-- Envio 23: EE0000000000023
INSERT INTO envio (numero_guia, id_solicitud, id_destinatario, id_zona, id_modalidad, fecha_registro, direccion_destino, peso_declarado, peso_real, contenido, valor_declarado, fragil, alto_valor, valor_flete, fecha_compromiso) VALUES ('EE0000000000023', 10, 9, 4, 3, DATE '2026-11-19', 'Calle 79 # 28-43', 2.00, 2.10, 'Cámaras', 160000, 'N', 'N', 8100.00, DATE '2026-11-21');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000023', 1, 5, TIMESTAMP '2026-11-19 08:32:00', 'Envío registrado en la mesa de servicio');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000023', 2, 10, TIMESTAMP '2026-11-19 10:32:00', 'Recogido en la sede del cliente');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000023', 3, 3, TIMESTAMP '2026-11-19 14:02:00', 'Recibido y pesado en el centro de distribución');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000023', 4, 3, TIMESTAMP '2026-11-19 16:02:00', 'Clasificado por zona de destino');
INSERT INTO asignacion_despacho (id_asignacion, numero_guia, id_despacho, numero_intento, orden_visita, hora_visita, resultado) VALUES (26, 'EE0000000000023', 15, 1, 4, NULL, 'PENDIENTE');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000023', 5, 7, TIMESTAMP '2026-11-20 08:42:00', 'Sale en el despacho 15 (intento 1)');

-- Envio 24: EE0000000000024
INSERT INTO envio (numero_guia, id_solicitud, id_destinatario, id_zona, id_modalidad, fecha_registro, direccion_destino, peso_declarado, peso_real, contenido, valor_declarado, fragil, alto_valor, valor_flete, fecha_compromiso) VALUES ('EE0000000000024', 10, 10, 5, 3, DATE '2026-11-19', 'Calle 82 # 29-44', 1.60, 1.70, 'Impresos', 120000, 'N', 'N', 7380.00, DATE '2026-11-21');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000024', 1, 5, TIMESTAMP '2026-11-19 08:33:00', 'Envío registrado en la mesa de servicio');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000024', 2, 10, TIMESTAMP '2026-11-19 10:33:00', 'Recogido en la sede del cliente');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000024', 3, 3, TIMESTAMP '2026-11-19 14:03:00', 'Recibido y pesado en el centro de distribución');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000024', 4, 3, TIMESTAMP '2026-11-19 16:03:00', 'Clasificado por zona de destino');
INSERT INTO asignacion_despacho (id_asignacion, numero_guia, id_despacho, numero_intento, orden_visita, hora_visita, resultado) VALUES (27, 'EE0000000000024', 15, 1, 5, NULL, 'PENDIENTE');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000024', 5, 7, TIMESTAMP '2026-11-20 08:43:00', 'Sale en el despacho 15 (intento 1)');

-- Envio 25: EE0000000000025
INSERT INTO envio (numero_guia, id_solicitud, id_destinatario, id_zona, id_modalidad, fecha_registro, direccion_destino, peso_declarado, peso_real, contenido, valor_declarado, fragil, alto_valor, valor_flete, fecha_compromiso) VALUES ('EE0000000000025', 10, 11, 1, 3, DATE '2026-11-19', 'Calle 85 # 30-45', 2.40, 2.50, 'Perfumería', 105000, 'N', 'N', 8820.00, DATE '2026-11-21');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000025', 1, 5, TIMESTAMP '2026-11-19 08:34:00', 'Envío registrado en la mesa de servicio');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000025', 2, 10, TIMESTAMP '2026-11-19 10:34:00', 'Recogido en la sede del cliente');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000025', 3, 3, TIMESTAMP '2026-11-19 14:04:00', 'Recibido y pesado en el centro de distribución');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000025', 4, 3, TIMESTAMP '2026-11-19 16:04:00', 'Clasificado por zona de destino');

-- Envio 26: EE0000000000026
INSERT INTO envio (numero_guia, id_solicitud, id_destinatario, id_zona, id_modalidad, fecha_registro, direccion_destino, peso_declarado, peso_real, contenido, valor_declarado, fragil, alto_valor, valor_flete, fecha_compromiso) VALUES ('EE0000000000026', 10, 12, 2, 3, DATE '2026-11-19', 'Calle 88 # 31-46', 1.30, 1.40, 'Herramientas', 90000, 'N', 'N', 6840.00, DATE '2026-11-21');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000026', 1, 5, TIMESTAMP '2026-11-19 08:35:00', 'Envío registrado en la mesa de servicio');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000026', 2, 10, TIMESTAMP '2026-11-19 10:35:00', 'Recogido en la sede del cliente');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000026', 3, 3, TIMESTAMP '2026-11-19 14:05:00', 'Recibido y pesado en el centro de distribución');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000026', 4, 3, TIMESTAMP '2026-11-19 16:05:00', 'Clasificado por zona de destino');

-- Envio 27: EE0000000000027
INSERT INTO envio (numero_guia, id_solicitud, id_destinatario, id_zona, id_modalidad, fecha_registro, direccion_destino, peso_declarado, peso_real, contenido, valor_declarado, fragil, alto_valor, valor_flete, fecha_compromiso) VALUES ('EE0000000000027', 10, 13, 3, 3, DATE '2026-11-19', 'Calle 91 # 32-47', 3.10, 3.20, 'Cables', 200000, 'N', 'N', 10080.00, DATE '2026-11-21');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000027', 1, 5, TIMESTAMP '2026-11-19 08:36:00', 'Envío registrado en la mesa de servicio');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000027', 2, 10, TIMESTAMP '2026-11-19 10:36:00', 'Recogido en la sede del cliente');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000027', 3, 3, TIMESTAMP '2026-11-19 14:06:00', 'Recibido y pesado en el centro de distribución');

-- Envio 28: EE0000000000028
INSERT INTO envio (numero_guia, id_solicitud, id_destinatario, id_zona, id_modalidad, fecha_registro, direccion_destino, peso_declarado, peso_real, contenido, valor_declarado, fragil, alto_valor, valor_flete, fecha_compromiso) VALUES ('EE0000000000028', 10, 14, 4, 3, DATE '2026-11-19', 'Calle 94 # 33-48', 0.50, NULL, 'Alimentos empacados', 45000, 'N', 'N', NULL, DATE '2026-11-21');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000028', 1, 5, TIMESTAMP '2026-11-19 08:30:00', 'Envío registrado en la mesa de servicio');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000028', 2, 10, TIMESTAMP '2026-11-19 10:30:00', 'Recogido en la sede del cliente');

-- Envio 29: EE0000000000029
INSERT INTO envio (numero_guia, id_solicitud, id_destinatario, id_zona, id_modalidad, fecha_registro, direccion_destino, peso_declarado, peso_real, contenido, valor_declarado, fragil, alto_valor, valor_flete, fecha_compromiso) VALUES ('EE0000000000029', 10, 1, 5, 3, DATE '2026-11-19', 'Calle 97 # 34-49', 1.00, NULL, 'Maletas', 75000, 'N', 'N', NULL, DATE '2026-11-21');
INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion) VALUES ('EE0000000000029', 1, 5, TIMESTAMP '2026-11-19 08:31:00', 'Envío registrado en la mesa de servicio');

-- Reclamaciones
INSERT INTO reclamacion (id_reclamacion, id_cliente, numero_guia, fecha_radicacion, tipo, descripcion, respuesta, fecha_respuesta, estado) VALUES (1, 1, 'EE0000000000006', TIMESTAMP '2026-11-06 15:00:00', 'ENTREGA', 'El envío llegó un día después de la fecha de compromiso', 'Se pidieron disculpas y se ajustó el flete', TIMESTAMP '2026-11-06 18:00:00', 'RESPONDIDA');
INSERT INTO reclamacion (id_reclamacion, id_cliente, numero_guia, fecha_radicacion, tipo, descripcion, respuesta, fecha_respuesta, estado) VALUES (2, 3, 'EE0000000000009', TIMESTAMP '2026-11-12 14:00:00', 'ENTREGA', 'El envío fue devuelto sin haber agotado los datos de contacto', 'Se explicó el proceso de dos novedades y devolución', TIMESTAMP '2026-11-12 20:30:00', 'RESPONDIDA');
INSERT INTO reclamacion (id_reclamacion, id_cliente, numero_guia, fecha_radicacion, tipo, descripcion, respuesta, fecha_respuesta, estado) VALUES (3, 1, 'EE0000000000005', TIMESTAMP '2026-11-09 10:00:00', 'FACTURACION', 'El flete facturado no coincide con la tarifa de alto valor', 'Se emitió nota crédito', TIMESTAMP '2026-11-09 11:30:00', 'CERRADA');
INSERT INTO reclamacion (id_reclamacion, id_cliente, numero_guia, fecha_radicacion, tipo, descripcion, respuesta, fecha_respuesta, estado) VALUES (4, 2, 'EE0000000000014', TIMESTAMP '2026-11-18 09:30:00', 'DANO', 'El paquete llegó averiado a la dirección del destinatario', NULL, NULL, 'ABIERTA');
INSERT INTO reclamacion (id_reclamacion, id_cliente, numero_guia, fecha_radicacion, tipo, descripcion, respuesta, fecha_respuesta, estado) VALUES (5, 3, NULL, TIMESTAMP '2026-11-19 16:00:00', 'FACTURACION', 'La factura de octubre trae un cobro de recolección duplicado', NULL, NULL, 'ABIERTA');
INSERT INTO reclamacion (id_reclamacion, id_cliente, numero_guia, fecha_radicacion, tipo, descripcion, respuesta, fecha_respuesta, estado) VALUES (6, 3, 'EE0000000000011', TIMESTAMP '2026-11-19 09:15:00', 'OTRO', 'Solicitud de certificación de entrega para auditoría', NULL, NULL, 'ABIERTA');
INSERT INTO reclamacion (id_reclamacion, id_cliente, numero_guia, fecha_radicacion, tipo, descripcion, respuesta, fecha_respuesta, estado) VALUES (7, 1, 'EE0000000000015', TIMESTAMP '2026-11-17 08:45:00', 'ENTREGA', 'El paquete se entregó fuera de la fecha de compromiso', NULL, NULL, 'ABIERTA');

-- Cierre de los despachos de entrega
UPDATE despacho SET estado = 'CERRADO', hora_cierre = TIMESTAMP '2026-11-04 17:30:00' WHERE id_despacho = 11;
UPDATE despacho SET estado = 'CERRADO', hora_cierre = TIMESTAMP '2026-11-05 17:30:00' WHERE id_despacho = 12;
UPDATE despacho SET estado = 'CERRADO', hora_cierre = TIMESTAMP '2026-11-06 17:30:00' WHERE id_despacho = 13;
UPDATE despacho SET estado = 'CERRADO', hora_cierre = TIMESTAMP '2026-11-05 18:30:00' WHERE id_despacho = 14;
UPDATE despacho SET estado = 'EN_RUTA' WHERE id_despacho = 15;
UPDATE despacho SET estado = 'CERRADO', hora_cierre = TIMESTAMP '2026-11-07 17:30:00' WHERE id_despacho = 16;
UPDATE despacho SET estado = 'CERRADO', hora_cierre = TIMESTAMP '2026-11-09 17:30:00' WHERE id_despacho = 17;
UPDATE despacho SET estado = 'CERRADO', hora_cierre = TIMESTAMP '2026-11-10 17:30:00' WHERE id_despacho = 18;
UPDATE despacho SET estado = 'CERRADO', hora_cierre = TIMESTAMP '2026-11-12 17:30:00' WHERE id_despacho = 19;
UPDATE despacho SET estado = 'CERRADO', hora_cierre = TIMESTAMP '2026-11-10 18:30:00' WHERE id_despacho = 20;
UPDATE despacho SET estado = 'CERRADO', hora_cierre = TIMESTAMP '2026-11-12 17:30:00' WHERE id_despacho = 21;
UPDATE despacho SET estado = 'CERRADO', hora_cierre = TIMESTAMP '2026-11-16 17:30:00' WHERE id_despacho = 22;
UPDATE despacho SET estado = 'CERRADO', hora_cierre = TIMESTAMP '2026-11-18 17:30:00' WHERE id_despacho = 23;
UPDATE despacho SET estado = 'CERRADO', hora_cierre = TIMESTAMP '2026-11-19 17:30:00' WHERE id_despacho = 24;
UPDATE despacho SET estado = 'CERRADO', hora_cierre = TIMESTAMP '2026-11-18 18:30:00' WHERE id_despacho = 25;

COMMIT;
