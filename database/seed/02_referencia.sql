-- Datos de referencia: centros, zonas, clientes y sedes, vehiculos y
-- empleados. Claves fijas. El cargo del empleado toma uno de estos valores
-- exactos (la extension E1 deriva de el el rol del usuario): Gerente,
-- Auxiliar de centro, Agente de mesa de servicio, Mensajero.
WHENEVER SQLERROR EXIT FAILURE

INSERT INTO centro_distribucion (id_centro, nombre, direccion, telefono) VALUES (1, 'Centro Norte', 'Autopista Norte # 127-45, Bogotá', '6012000001');
INSERT INTO centro_distribucion (id_centro, nombre, direccion, telefono) VALUES (2, 'Centro Sur', 'Avenida Boyacá # 38A-10 Sur, Bogotá', '6012000002');

INSERT INTO zona (id_zona, id_centro, nombre, localidades) VALUES (1, 1, 'Norte', 'Usaquén, Suba, Chapinero');
INSERT INTO zona (id_zona, id_centro, nombre, localidades) VALUES (2, 1, 'Occidente', 'Engativá, Fontibón, Barrios Unidos');
INSERT INTO zona (id_zona, id_centro, nombre, localidades) VALUES (3, 2, 'Sur', 'Kennedy, Bosa, Puente Aranda');
INSERT INTO zona (id_zona, id_centro, nombre, localidades) VALUES (4, 2, 'Centro', 'Santa Fe, La Candelaria, Teusaquillo, Los Mártires');
INSERT INTO zona (id_zona, id_centro, nombre, localidades) VALUES (5, 2, 'Suroriente', 'Rafael Uribe Uribe, San Cristóbal, Antonio Nariño');

INSERT INTO cliente (id_cliente, nit, razon_social, tipo_cliente, telefono, correo, fecha_vinculacion, estado)
    VALUES (1, '900123456', 'Droguería Nueva Salud S.A.S.', 'DROGUERIA', '6015551001', 'logistica@nuevasalud.example.com', DATE '2026-02-10', 'ACTIVO');
INSERT INTO cliente (id_cliente, nit, razon_social, tipo_cliente, telefono, correo, fecha_vinculacion, estado)
    VALUES (2, '900234567', 'Oficinas Andinas Ltda.', 'OFICINA', '6015551002', 'despachos@oficinasandinas.example.com', DATE '2026-03-15', 'ACTIVO');
INSERT INTO cliente (id_cliente, nit, razon_social, tipo_cliente, telefono, correo, fecha_vinculacion, estado)
    VALUES (3, '900345678', 'TiendaOnline Colombia S.A.S.', 'TIENDA_LINEA', '6015551003', 'envios@tiendaonline.example.com', DATE '2026-01-20', 'ACTIVO');
INSERT INTO cliente (id_cliente, nit, razon_social, tipo_cliente, telefono, correo, fecha_vinculacion, estado)
    VALUES (4, '900456789', 'Droguería San Jorge', 'DROGUERIA', '6015551004', 'contacto@sanjorge.example.com', DATE '2026-04-02', 'INACTIVO');

INSERT INTO sede_cliente (id_sede, id_cliente, id_zona, nombre, direccion, contacto, telefono) VALUES (1, 1, 1, 'Sede Usaquén', 'Carrera 7 # 119-14', 'Marta Ruiz', '3101110001');
INSERT INTO sede_cliente (id_sede, id_cliente, id_zona, nombre, direccion, contacto, telefono) VALUES (2, 1, 2, 'Sede Engativá', 'Avenida Boyacá # 68-30', 'Jorge Peña', '3101110002');
INSERT INTO sede_cliente (id_sede, id_cliente, id_zona, nombre, direccion, contacto, telefono) VALUES (3, 2, 3, 'Oficina Kennedy', 'Avenida Primero de Mayo # 72-15', 'Laura Gómez', '3101110003');
INSERT INTO sede_cliente (id_sede, id_cliente, id_zona, nombre, direccion, contacto, telefono) VALUES (4, 2, 1, 'Oficina Chapinero', 'Calle 63 # 11-20', 'Andrés Mora', '3101110004');
INSERT INTO sede_cliente (id_sede, id_cliente, id_zona, nombre, direccion, contacto, telefono) VALUES (5, 3, 2, 'Bodega Fontibón', 'Calle 17 # 99-50', 'Sandra Vega', '3101110005');
INSERT INTO sede_cliente (id_sede, id_cliente, id_zona, nombre, direccion, contacto, telefono) VALUES (6, 3, 3, 'Bodega Bosa', 'Carrera 80 # 65 Sur-12', 'Camilo Duarte', '3101110006');
INSERT INTO sede_cliente (id_sede, id_cliente, id_zona, nombre, direccion, contacto, telefono) VALUES (7, 4, 4, 'Sede Teusaquillo', 'Carrera 24 # 39-40', 'Rosa Beltrán', '3101110007');

-- Vehiculos: tipo 1 moto, 2 furgoneta, 3 bicicleta electrica
INSERT INTO vehiculo (id_vehiculo, id_centro, id_tipo_vehiculo, placa, marca, modelo, capacidad_kg, electrico, estado) VALUES (1, 1, 1, 'ABC12D', 'Honda', 'CB 125F', 40, 'N', 'DISPONIBLE');
INSERT INTO vehiculo (id_vehiculo, id_centro, id_tipo_vehiculo, placa, marca, modelo, capacidad_kg, electrico, estado) VALUES (2, 1, 1, 'DEF34G', 'Yamaha', 'FZ 150', 40, 'N', 'DISPONIBLE');
INSERT INTO vehiculo (id_vehiculo, id_centro, id_tipo_vehiculo, placa, marca, modelo, capacidad_kg, electrico, estado) VALUES (3, 1, 1, 'GHI56J', 'Suzuki', 'Gixxer 150', 40, 'N', 'EN_MANTENIMIENTO');
INSERT INTO vehiculo (id_vehiculo, id_centro, id_tipo_vehiculo, placa, marca, modelo, capacidad_kg, electrico, estado) VALUES (4, 2, 1, 'JKL78M', 'Honda', 'XR 150L', 40, 'N', 'DISPONIBLE');
INSERT INTO vehiculo (id_vehiculo, id_centro, id_tipo_vehiculo, placa, marca, modelo, capacidad_kg, electrico, estado) VALUES (5, 2, 1, 'MNO90P', 'Bajaj', 'Pulsar NS 160', 40, 'N', 'FUERA_SERVICIO');
INSERT INTO vehiculo (id_vehiculo, id_centro, id_tipo_vehiculo, placa, marca, modelo, capacidad_kg, electrico, estado) VALUES (6, 1, 2, 'QRS123', 'Renault', 'Kangoo', 650, 'N', 'DISPONIBLE');
INSERT INTO vehiculo (id_vehiculo, id_centro, id_tipo_vehiculo, placa, marca, modelo, capacidad_kg, electrico, estado) VALUES (7, 2, 2, 'TUV456', 'Chevrolet', 'N300 Cargo', 700, 'N', 'DISPONIBLE');
INSERT INTO vehiculo (id_vehiculo, id_centro, id_tipo_vehiculo, placa, marca, modelo, capacidad_kg, electrico, estado) VALUES (8, 1, 3, NULL, 'Rodado', 'Cargo E-Bike', 20, 'S', 'DISPONIBLE');
INSERT INTO vehiculo (id_vehiculo, id_centro, id_tipo_vehiculo, placa, marca, modelo, capacidad_kg, electrico, estado) VALUES (9, 2, 1, 'WXY12Z', 'Honda', 'CB 125F', 40, 'N', 'DISPONIBLE');

-- Empleados: 1 gerente, 2 y 3 auxiliares, 4 y 5 agentes de mesa, 6 a 12 mensajeros (el 12 retirado)
INSERT INTO empleado (id_empleado, id_centro, documento, nombres, apellidos, cargo, telefono, correo, fecha_ingreso, estado)
    VALUES (1, 1, '52111001', 'Patricia', 'Herrera Lozano', 'Gerente', '3201000001', 'patricia.herrera@enlaceexpress.example.com', DATE '2025-06-02', 'ACTIVO');
INSERT INTO empleado (id_empleado, id_centro, documento, nombres, apellidos, cargo, telefono, correo, fecha_ingreso, estado)
    VALUES (2, 1, '80222002', 'Diego', 'Ramírez Torres', 'Auxiliar de centro', '3201000002', 'diego.ramirez@enlaceexpress.example.com', DATE '2025-07-01', 'ACTIVO');
INSERT INTO empleado (id_empleado, id_centro, documento, nombres, apellidos, cargo, telefono, correo, fecha_ingreso, estado)
    VALUES (3, 2, '79333003', 'Lucía', 'Fernández Castro', 'Auxiliar de centro', '3201000003', 'lucia.fernandez@enlaceexpress.example.com', DATE '2025-07-15', 'ACTIVO');
INSERT INTO empleado (id_empleado, id_centro, documento, nombres, apellidos, cargo, telefono, correo, fecha_ingreso, estado)
    VALUES (4, 1, '1019444004', 'Natalia', 'Quintero Rojas', 'Agente de mesa de servicio', '3201000004', 'natalia.quintero@enlaceexpress.example.com', DATE '2025-08-04', 'ACTIVO');
INSERT INTO empleado (id_empleado, id_centro, documento, nombres, apellidos, cargo, telefono, correo, fecha_ingreso, estado)
    VALUES (5, 2, '1020555005', 'Sebastián', 'Londoño Pardo', 'Agente de mesa de servicio', '3201000005', 'sebastian.londono@enlaceexpress.example.com', DATE '2025-08-18', 'ACTIVO');
INSERT INTO empleado (id_empleado, id_centro, documento, nombres, apellidos, cargo, telefono, correo, fecha_ingreso, estado)
    VALUES (6, 1, '1030666006', 'Carlos', 'Peña Morales', 'Mensajero', '3201000006', NULL, DATE '2025-09-01', 'ACTIVO');
INSERT INTO empleado (id_empleado, id_centro, documento, nombres, apellidos, cargo, telefono, correo, fecha_ingreso, estado)
    VALUES (7, 1, '1040777007', 'Andrea', 'Salazar Niño', 'Mensajero', '3201000007', NULL, DATE '2025-09-01', 'ACTIVO');
INSERT INTO empleado (id_empleado, id_centro, documento, nombres, apellidos, cargo, telefono, correo, fecha_ingreso, estado)
    VALUES (8, 1, '1050888008', 'Julián', 'Cárdenas Vega', 'Mensajero', '3201000008', NULL, DATE '2025-10-06', 'ACTIVO');
INSERT INTO empleado (id_empleado, id_centro, documento, nombres, apellidos, cargo, telefono, correo, fecha_ingreso, estado)
    VALUES (9, 2, '1060999009', 'Óscar', 'Moreno Gil', 'Mensajero', '3201000009', NULL, DATE '2025-10-20', 'ACTIVO');
INSERT INTO empleado (id_empleado, id_centro, documento, nombres, apellidos, cargo, telefono, correo, fecha_ingreso, estado)
    VALUES (10, 2, '1071000010', 'Mónica', 'Ortiz Suárez', 'Mensajero', '3201000010', NULL, DATE '2025-11-03', 'ACTIVO');
INSERT INTO empleado (id_empleado, id_centro, documento, nombres, apellidos, cargo, telefono, correo, fecha_ingreso, estado)
    VALUES (11, 1, '1081100011', 'Felipe', 'Aguirre Páez', 'Mensajero', '3201000011', NULL, DATE '2026-01-12', 'ACTIVO');
INSERT INTO empleado (id_empleado, id_centro, documento, nombres, apellidos, cargo, telefono, correo, fecha_ingreso, fecha_retiro, motivo_retiro, estado)
    VALUES (12, 1, '1091200012', 'Hernán', 'Cortés Ibarra', 'Mensajero', '3201000012', NULL, DATE '2025-06-16', DATE '2026-09-30', 'Renuncia voluntaria', 'RETIRADO');

-- Mensajeros (subtipo): el 7 conduce motocicleta (consulta C9)
INSERT INTO mensajero (id_empleado, id_zona, id_tipo_vehiculo) VALUES (6, 1, 1);
INSERT INTO mensajero (id_empleado, id_zona, id_tipo_vehiculo) VALUES (7, 1, 1);
INSERT INTO mensajero (id_empleado, id_zona, id_tipo_vehiculo) VALUES (8, 2, 1);
INSERT INTO mensajero (id_empleado, id_zona, id_tipo_vehiculo) VALUES (9, 3, 2);
INSERT INTO mensajero (id_empleado, id_zona, id_tipo_vehiculo) VALUES (10, 4, 1);
INSERT INTO mensajero (id_empleado, id_zona, id_tipo_vehiculo) VALUES (11, 1, 3);
INSERT INTO mensajero (id_empleado, id_zona, id_tipo_vehiculo) VALUES (12, 2, 1);

COMMIT;
