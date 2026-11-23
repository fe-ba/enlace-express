package co.enlaceexpress.configuracion;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.boot.context.properties.bind.DefaultValue;

/** Limite de consultas del rastreo publico por direccion IP (decision D2). */
@ConfigurationProperties("enlace.rastreo")
public record PropiedadesRastreo(
        @DefaultValue("30") int limitePorMinuto,
        @DefaultValue("false") boolean confiarEnProxy) {
}
