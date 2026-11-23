-- Extension E1: permisos. La parte publica de la aplicacion (inicio de sesion,
-- registro y rastreo por guia) trabaja antes de saber quien es el usuario, asi que
-- usa la cuenta de servicio de menor privilegio, svc_cliente (rol_cliente). Las
-- tablas USUARIO_APLICACION y CODIGO_ACTIVACION no se conceden a ningun rol: solo
-- se llega a ellas por pkg_seguridad. pkg_codigos_activacion es del administrador.
WHENEVER SQLERROR EXIT FAILURE

GRANT EXECUTE ON pkg_seguridad TO rol_cliente;
