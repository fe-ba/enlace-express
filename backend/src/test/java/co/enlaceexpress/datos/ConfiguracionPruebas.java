package co.enlaceexpress.datos;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.EnumMap;
import java.util.HashMap;
import java.util.Map;

import co.enlaceexpress.configuracion.PropiedadesBaseDatos;
import co.enlaceexpress.configuracion.PropiedadesBaseDatos.Cuenta;
import co.enlaceexpress.dominio.enums.Rol;

/**
 * Credenciales de las pruebas de integracion: las mismas del compose. Se leen de las variables
 * de entorno o, si no estan, del .env de la raiz del repositorio (nunca de un archivo versionado).
 * En modo Testcontainers (ver {@link EntornoPruebas}) son las del contenedor de la corrida.
 */
public final class ConfiguracionPruebas {

    private static final Map<String, String> VARIABLES = cargar();

    private ConfiguracionPruebas() {
    }

    private static Map<String, String> cargar() {
        Map<String, String> v = new HashMap<>();
        for (Path ruta : new Path[] {Path.of("../.env"), Path.of(".env")}) {
            if (Files.isReadable(ruta)) {
                try {
                    for (String linea : Files.readAllLines(ruta)) {
                        int igual = linea.indexOf('=');
                        if (igual > 0 && !linea.startsWith("#")) {
                            v.put(linea.substring(0, igual).trim(), linea.substring(igual + 1).trim());
                        }
                    }
                } catch (IOException e) {
                    throw new IllegalStateException("No se pudo leer " + ruta, e);
                }
                break;
            }
        }
        System.getenv().forEach(v::put);
        return v;
    }

    public static String variable(String nombre) {
        String valor = EntornoPruebas.usaTestcontainers() ? EntornoPruebas.clave(nombre) : VARIABLES.get(nombre);
        if (valor == null || valor.isBlank()) {
            throw new IllegalStateException("Falta la variable " + nombre + " (defina el .env de la raiz)");
        }
        return valor;
    }

    public static PropiedadesBaseDatos propiedades(int poolMinimo, int poolMaximo) {
        Map<Rol, Cuenta> cuentas = new EnumMap<>(Rol.class);
        for (Rol rol : Rol.values()) {
            cuentas.put(rol, new Cuenta(rol.cuentaServicio(), variable(rol.cuentaServicio().toUpperCase() + "_PASSWORD")));
        }
        return new PropiedadesBaseDatos(EntornoPruebas.url(), "BD_ENLACE_EXPRESS", "America/Bogota", poolMinimo, poolMaximo, cuentas);
    }

    /** Conexion del propietario del esquema: solo para preparar y limpiar pruebas. */
    public static Connection conexionPropietario() throws SQLException {
        return DriverManager.getConnection(EntornoPruebas.url(), "BD_ENLACE_EXPRESS", variable("PROPIETARIO_PASSWORD"));
    }
}
