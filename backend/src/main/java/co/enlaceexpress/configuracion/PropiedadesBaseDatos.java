package co.enlaceexpress.configuracion;

import java.util.Map;

import org.springframework.boot.context.properties.ConfigurationProperties;

import co.enlaceexpress.dominio.enums.Rol;

/**
 * Parametros de conexion a Oracle (prefijo enlace.base-datos en application.yml).
 * Las contrasenas no estan en el repositorio: vienen de las variables SVC_*_PASSWORD o del .env.
 */
@ConfigurationProperties("enlace.base-datos")
public record PropiedadesBaseDatos(
        String url,
        String esquema,
        String zonaHoraria,
        int poolMinimo,
        int poolMaximo,
        Map<Rol, Cuenta> cuentas) {

    /** Cuenta de servicio de un rol. */
    public record Cuenta(String usuario, String contrasena) {
        @Override
        public String toString() {
            return "Cuenta[usuario=" + usuario + ", contrasena=***]";
        }
    }
}
