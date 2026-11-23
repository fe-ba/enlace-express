package co.enlaceexpress;

import java.util.TimeZone;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.ConfigurationPropertiesScan;
import org.springframework.boot.security.autoconfigure.UserDetailsServiceAutoConfiguration;

/**
 * Punto de entrada de la aplicacion del modulo M1. Se excluye UserDetailsServiceAutoConfiguration: la
 * autenticacion la hace SesionController con pkg_seguridad, asi que no debe existir el usuario "user" con
 * contrasena generada que Spring Boot crea por defecto.
 */
@SpringBootApplication(exclude = UserDetailsServiceAutoConfiguration.class)
@ConfigurationPropertiesScan
public class EnlaceExpressApplication {

    /** Zona horaria de la JVM y de Oracle (decision C6). */
    public static final String ZONA_HORARIA = "America/Bogota";

    public static void main(String[] args) {
        TimeZone.setDefault(TimeZone.getTimeZone(ZONA_HORARIA));
        SpringApplication.run(EnlaceExpressApplication.class, args);
    }
}
