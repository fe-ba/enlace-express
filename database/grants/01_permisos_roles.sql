-- Privilegios de los 5 roles (capitulo 5, tabla de roles; capitulo 4, columna
-- de usuarios de la tabla de vistas). Se ejecuta como BD_ENLACE_EXPRESS.
-- Ningun rol tiene DELETE (RN16).
-- Regla general: todo rol que inserta o actualiza una tabla recibe tambien
-- SELECT sobre ella, porque UPDATE con WHERE, SELECT ... FOR UPDATE (C4) y
-- leer lo recien guardado lo necesitan. UPDATE es por tabla, no por columna.
WHENEVER SQLERROR EXIT FAILURE

-- rol_gerencia: U1. Consulta los indicadores: las 7 vistas y las tablas de C5, C6, C8 y C10.
GRANT SELECT ON envio TO rol_gerencia;
GRANT SELECT ON zona TO rol_gerencia;
GRANT SELECT ON modalidad TO rol_gerencia;
GRANT SELECT ON novedad TO rol_gerencia;
GRANT SELECT ON asignacion_despacho TO rol_gerencia;
GRANT SELECT ON despacho TO rol_gerencia;
GRANT SELECT ON empleado TO rol_gerencia;
GRANT SELECT ON cliente TO rol_gerencia;
GRANT SELECT ON sede_cliente TO rol_gerencia;
GRANT SELECT ON solicitud_recoleccion TO rol_gerencia;
GRANT SELECT ON evento_envio TO rol_gerencia;
GRANT SELECT ON estado_envio TO rol_gerencia;
GRANT SELECT ON centro_distribucion TO rol_gerencia;
GRANT SELECT ON v_seguimiento_envio TO rol_gerencia;
GRANT SELECT ON v_estado_actual_envio TO rol_gerencia;
GRANT SELECT ON v_planilla_despacho TO rol_gerencia;
GRANT SELECT ON v_envios_por_despachar TO rol_gerencia;
GRANT SELECT ON v_novedades_abiertas TO rol_gerencia;
GRANT SELECT ON v_reclamaciones_pendientes TO rol_gerencia;
GRANT SELECT ON v_cumplimiento_entregas TO rol_gerencia;

-- rol_centro: U2. Centro de distribucion: arma despachos y asigna envios.
GRANT INSERT ON centro_distribucion TO rol_centro;
GRANT INSERT ON zona TO rol_centro;
GRANT INSERT ON despacho TO rol_centro;
GRANT INSERT ON asignacion_despacho TO rol_centro;
GRANT INSERT ON evento_envio TO rol_centro;
GRANT UPDATE ON centro_distribucion TO rol_centro;
GRANT UPDATE ON zona TO rol_centro;
GRANT UPDATE ON despacho TO rol_centro;
GRANT UPDATE ON asignacion_despacho TO rol_centro;
GRANT UPDATE ON solicitud_recoleccion TO rol_centro;
GRANT UPDATE ON envio TO rol_centro;
GRANT UPDATE ON empleado TO rol_centro;
GRANT UPDATE ON mensajero TO rol_centro;
GRANT SELECT ON estado_envio TO rol_centro;
GRANT SELECT ON modalidad TO rol_centro;
GRANT SELECT ON tipo_vehiculo TO rol_centro;
GRANT SELECT ON sede_cliente TO rol_centro;
GRANT SELECT ON vehiculo TO rol_centro;
-- lo exige la consulta C3 del capitulo 6
GRANT SELECT ON destinatario TO rol_centro;
GRANT SELECT ON empleado TO rol_centro;
GRANT SELECT ON mensajero TO rol_centro;
GRANT SELECT ON v_planilla_despacho TO rol_centro;
GRANT SELECT ON v_envios_por_despachar TO rol_centro;
GRANT SELECT ON v_estado_actual_envio TO rol_centro;
GRANT SELECT ON centro_distribucion TO rol_centro;
GRANT SELECT ON zona TO rol_centro;
GRANT SELECT ON despacho TO rol_centro;
GRANT SELECT ON asignacion_despacho TO rol_centro;
GRANT SELECT ON evento_envio TO rol_centro;
GRANT SELECT ON solicitud_recoleccion TO rol_centro;
GRANT SELECT ON envio TO rol_centro;

-- rol_mesa: U3. Mesa de servicio: registra solicitudes, envios y reclamaciones.
GRANT INSERT ON solicitud_recoleccion TO rol_mesa;
GRANT INSERT ON envio TO rol_mesa;
GRANT INSERT ON destinatario TO rol_mesa;
GRANT INSERT ON evento_envio TO rol_mesa;
GRANT INSERT ON reclamacion TO rol_mesa;
GRANT UPDATE ON envio TO rol_mesa;
GRANT UPDATE ON destinatario TO rol_mesa;
GRANT UPDATE ON novedad TO rol_mesa;
GRANT UPDATE ON reclamacion TO rol_mesa;
GRANT SELECT ON cliente TO rol_mesa;
GRANT SELECT ON sede_cliente TO rol_mesa;
-- lo exige la consulta C2 del capitulo 6
GRANT SELECT ON empleado TO rol_mesa;
-- lo exige la consulta C7 del capitulo 6
GRANT SELECT ON asignacion_despacho TO rol_mesa;
GRANT SELECT ON zona TO rol_mesa;
GRANT SELECT ON estado_envio TO rol_mesa;
GRANT SELECT ON modalidad TO rol_mesa;
GRANT SELECT ON tipo_vehiculo TO rol_mesa;
GRANT SELECT ON v_seguimiento_envio TO rol_mesa;
GRANT SELECT ON v_novedades_abiertas TO rol_mesa;
GRANT SELECT ON v_reclamaciones_pendientes TO rol_mesa;
GRANT SELECT ON v_estado_actual_envio TO rol_mesa;
GRANT SELECT ON solicitud_recoleccion TO rol_mesa;
GRANT SELECT ON envio TO rol_mesa;
GRANT SELECT ON destinatario TO rol_mesa;
GRANT SELECT ON evento_envio TO rol_mesa;
GRANT SELECT ON reclamacion TO rol_mesa;
GRANT SELECT ON novedad TO rol_mesa;
GRANT EXECUTE ON pr_registrar_envio TO rol_mesa;

-- rol_mensajero: U4. Mensajero: registra pruebas, novedades y eventos de su ruta (la aplicacion filtra por mensajero).
GRANT INSERT ON evento_envio TO rol_mensajero;
GRANT INSERT ON prueba_entrega TO rol_mensajero;
GRANT INSERT ON novedad TO rol_mensajero;
GRANT UPDATE ON solicitud_recoleccion TO rol_mensajero;
GRANT UPDATE ON asignacion_despacho TO rol_mensajero;
GRANT UPDATE ON envio TO rol_mensajero;
GRANT SELECT ON sede_cliente TO rol_mensajero;
GRANT SELECT ON despacho TO rol_mensajero;
GRANT SELECT ON v_planilla_despacho TO rol_mensajero;
GRANT SELECT ON evento_envio TO rol_mensajero;
GRANT SELECT ON prueba_entrega TO rol_mensajero;
GRANT SELECT ON novedad TO rol_mensajero;
GRANT SELECT ON solicitud_recoleccion TO rol_mensajero;
GRANT SELECT ON asignacion_despacho TO rol_mensajero;
GRANT SELECT ON envio TO rol_mensajero;

-- rol_cliente: U9. Cliente: solo el seguimiento de sus envios (la aplicacion filtra por id_cliente).
GRANT SELECT ON v_seguimiento_envio TO rol_cliente;
