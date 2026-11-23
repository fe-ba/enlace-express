package co.enlaceexpress.datos;

import static org.assertj.core.api.Assertions.assertThat;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.SecureRandom;
import java.time.Duration;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.testcontainers.containers.BindMode;
import org.testcontainers.containers.GenericContainer;
import org.testcontainers.containers.wait.strategy.Wait;

/**
 * Entorno de las pruebas de integracion (*IT). Por defecto usan el Oracle del compose, con las
 * contrasenas del .env. Con {@code ENLACE_TESTCONTAINERS=true} (o {@code -Ptestcontainers}) levantan
 * un solo contenedor de Oracle para toda la corrida, con la misma imagen del compose, instalan el
 * esquema con database/install.sh y apuntan las pruebas y la aplicacion a ese contenedor. En ese modo las
 * contrasenas se generan al azar en cada corrida: viajan por variables de entorno y propiedades del
 * sistema y no se escriben en ningun archivo.
 */
public final class EntornoPruebas {

    private static final String IMAGEN = "gvenzl/oracle-free:23-slim";
    private static final String[] VARIABLES_CLAVES = {"ORACLE_PASSWORD", "PROPIETARIO_PASSWORD", "SVC_GERENCIA_PASSWORD",
        "SVC_CENTRO_PASSWORD", "SVC_MESA_PASSWORD", "SVC_MENSAJERO_PASSWORD", "SVC_CLIENTE_PASSWORD"};
    private static final String ALFABETO = "abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789";

    private static final Map<String, String> CLAVES = new HashMap<>();
    private static GenericContainer<?> contenedor;
    private static String url = "jdbc:oracle:thin:@//localhost:1521/FREEPDB1";
    private static Path evidencia;

    private EntornoPruebas() {
    }

    public static boolean usaTestcontainers() {
        return "true".equalsIgnoreCase(System.getenv("ENLACE_TESTCONTAINERS"))
                || "true".equalsIgnoreCase(System.getProperty("enlace.testcontainers"));
    }

    /** Levanta el contenedor y la base la primera vez (solo en modo Testcontainers); despues no hace nada. */
    public static synchronized void asegurar() {
        if (!usaTestcontainers() || contenedor != null) {
            return;
        }
        for (String variable : VARIABLES_CLAVES) {
            CLAVES.put(variable, claveAleatoria());
        }
        Path db = Path.of("..", "database").toAbsolutePath().normalize();
        GenericContainer<?> nuevo = new GenericContainer<>(IMAGEN)
                .withEnv("ORACLE_PASSWORD", CLAVES.get("ORACLE_PASSWORD"))
                .withEnv("TZ", "America/Bogota")
                .withExposedPorts(1521)
                .withFileSystemBind(db.toString(), "/opt/enlace/database", BindMode.READ_ONLY)
                .waitingFor(Wait.forLogMessage(".*DATABASE IS READY TO USE!.*\\n", 1))
                .withStartupTimeout(Duration.ofMinutes(8));
        nuevo.start();
        contenedor = nuevo;
        Runtime.getRuntime().addShutdownHook(new Thread(nuevo::stop));
        url = "jdbc:oracle:thin:@//" + nuevo.getHost() + ":" + nuevo.getMappedPort(1521) + "/FREEPDB1";
        try {
            evidencia = Files.createTempFile("cifras-", ".txt");
            evidencia.toFile().deleteOnExit();
        } catch (IOException e) {
            throw new IllegalStateException("No se pudo crear el archivo temporal de la verificacion de cifras", e);
        }
        // la aplicacion (Spring) lee estos valores como propiedades del sistema
        System.setProperty("ENLACE_DB_URL", url);
        for (String variable : VARIABLES_CLAVES) {
            if (variable.startsWith("SVC_")) {
                System.setProperty(variable, CLAVES.get(variable));
            }
        }
        instalarBase();
    }

    public static String url() {
        asegurar();
        return url;
    }

    /** Valor de una variable de credenciales, del contenedor propio si se usa Testcontainers. */
    public static String clave(String nombre) {
        asegurar();
        return CLAVES.get(nombre);
    }

    /** Reinstala la base desde cero con database/install.sh (las pruebas que confirman datos la dejan como estaba). */
    public static void instalarBase() {
        try {
            ProcessBuilder pb = new ProcessBuilder("bash", "../database/install.sh").redirectErrorStream(true);
            if (usaTestcontainers()) {
                Map<String, String> entorno = pb.environment();
                entorno.putAll(CLAVES);
                entorno.put("ENLACE_CONTENEDOR", contenedor.getContainerId());
                entorno.put("ENLACE_EVIDENCIA", evidencia.toString());
                entorno.put("VERIFICACION_ESTRICTA", "1");
            }
            Process p = pb.start();
            String salida = new String(p.getInputStream().readAllBytes());
            assertThat(p.waitFor()).as("database/install.sh:\n%s", salida).isZero();
        } catch (IOException e) {
            throw new IllegalStateException("No se pudo ejecutar database/install.sh", e);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new IllegalStateException(e);
        }
    }

    private static String claveAleatoria() {
        SecureRandom azar = new SecureRandom();
        StringBuilder clave = new StringBuilder("Ee");
        for (int i = 0; i < 18; i++) {
            clave.append(ALFABETO.charAt(azar.nextInt(ALFABETO.length())));
        }
        return clave.append('7').toString();
    }

    /** Para el diagnostico: lista de variables que se generan. */
    static List<String> variables() {
        return List.of(VARIABLES_CLAVES);
    }
}
