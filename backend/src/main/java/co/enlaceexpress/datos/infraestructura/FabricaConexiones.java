package co.enlaceexpress.datos.infraestructura;

import java.sql.Connection;
import java.sql.SQLException;
import java.util.EnumMap;
import java.util.Map;
import java.util.regex.Pattern;

import com.zaxxer.hikari.HikariConfig;
import com.zaxxer.hikari.HikariDataSource;

import co.enlaceexpress.configuracion.PropiedadesBaseDatos;
import co.enlaceexpress.configuracion.PropiedadesBaseDatos.Cuenta;
import co.enlaceexpress.dominio.enums.Rol;

/**
 * Una fuente de conexiones (pool HikariCP pequeno) por rol, cada una con la cuenta de servicio
 * del rol (decision 12.1). Cada conexion nueva fija CURRENT_SCHEMA = BD_ENLACE_EXPRESS, para
 * que el SQL sea el mismo de la seccion 6.1, y la zona horaria America/Bogota (decision C6).
 */
public class FabricaConexiones implements AutoCloseable {

    private static final Pattern IDENTIFICADOR = Pattern.compile("[A-Za-z][A-Za-z0-9_$#]*");
    private static final Pattern ZONA = Pattern.compile("[A-Za-z_]+(/[A-Za-z_+\\-0-9]+)*");

    private final Map<Rol, HikariDataSource> fuentes = new EnumMap<>(Rol.class);

    public FabricaConexiones(PropiedadesBaseDatos propiedades) {
        // los valores de la configuracion se validan porque van dentro de una sentencia ALTER SESSION
        if (!IDENTIFICADOR.matcher(propiedades.esquema()).matches() || !ZONA.matcher(propiedades.zonaHoraria()).matches()) {
            throw new IllegalArgumentException("Esquema o zona horaria invalidos en enlace.base-datos");
        }
        String inicio = "ALTER SESSION SET CURRENT_SCHEMA = " + propiedades.esquema()
                + " TIME_ZONE = '" + propiedades.zonaHoraria() + "'";
        for (Rol rol : Rol.values()) {
            Cuenta cuenta = propiedades.cuentas().get(rol);
            if (cuenta == null) {
                throw new IllegalArgumentException("Falta la cuenta de servicio del rol " + rol);
            }
            HikariConfig config = new HikariConfig();
            config.setPoolName("enlace-" + rol.name().toLowerCase());
            config.setJdbcUrl(propiedades.url());
            config.setUsername(cuenta.usuario());
            config.setPassword(cuenta.contrasena());
            config.setMinimumIdle(propiedades.poolMinimo());
            config.setMaximumPoolSize(propiedades.poolMaximo());
            config.setConnectionInitSql(inicio);
            config.setAutoCommit(true);
            // la aplicacion puede arrancar con Oracle apagado; la salud lo informa
            config.setInitializationFailTimeout(-1);
            config.setConnectionTimeout(10_000);
            fuentes.put(rol, new HikariDataSource(config));
        }
    }

    /** Toma una conexion del pool del rol. Quien la pide debe cerrarla (devolverla al pool). */
    public Connection obtener(Rol rol) throws SQLException {
        return fuentes.get(rol).getConnection();
    }

    @Override
    public void close() {
        fuentes.values().forEach(HikariDataSource::close);
    }
}
