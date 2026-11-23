-- Catalogos fijos (capitulo 4): estados del envio, modalidades y tipos de
-- vehiculo. Claves fijas 1..n: las reglas, las vistas y las consultas se
-- refieren a ellas por nombre.
WHENEVER SQLERROR EXIT FAILURE

INSERT INTO estado_envio (id_estado, nombre, es_final) VALUES (1, 'REGISTRADO', 'N');
INSERT INTO estado_envio (id_estado, nombre, es_final) VALUES (2, 'RECOLECTADO', 'N');
INSERT INTO estado_envio (id_estado, nombre, es_final) VALUES (3, 'EN_CENTRO', 'N');
INSERT INTO estado_envio (id_estado, nombre, es_final) VALUES (4, 'CLASIFICADO', 'N');
INSERT INTO estado_envio (id_estado, nombre, es_final) VALUES (5, 'EN_RUTA', 'N');
INSERT INTO estado_envio (id_estado, nombre, es_final) VALUES (6, 'ENTREGADO', 'S');
INSERT INTO estado_envio (id_estado, nombre, es_final) VALUES (7, 'CON_NOVEDAD', 'N');
INSERT INTO estado_envio (id_estado, nombre, es_final) VALUES (8, 'DEVUELTO', 'S');
INSERT INTO estado_envio (id_estado, nombre, es_final) VALUES (9, 'ANULADO', 'S');

-- El plazo cuenta el dia del registro como dia 1 (CHECK plazo > 0)
INSERT INTO modalidad (id_modalidad, nombre, plazo_dias_habiles) VALUES (1, 'MISMO_DIA', 1);
INSERT INTO modalidad (id_modalidad, nombre, plazo_dias_habiles) VALUES (2, 'DIA_SIGUIENTE', 2);
INSERT INTO modalidad (id_modalidad, nombre, plazo_dias_habiles) VALUES (3, 'ESTANDAR', 3);

INSERT INTO tipo_vehiculo (id_tipo_vehiculo, nombre, capacidad_max_kg) VALUES (1, 'MOTOCICLETA', 40);
INSERT INTO tipo_vehiculo (id_tipo_vehiculo, nombre, capacidad_max_kg) VALUES (2, 'FURGONETA', 800);
INSERT INTO tipo_vehiculo (id_tipo_vehiculo, nombre, capacidad_max_kg) VALUES (3, 'BICICLETA_ELECTRICA', 20);

COMMIT;
