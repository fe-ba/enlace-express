package co.enlaceexpress.dominio.reglas;

import java.util.EnumMap;
import java.util.List;
import java.util.Map;

import co.enlaceexpress.dominio.enums.EstadoEnvio;

/**
 * Servicio de dominio con la tabla de transiciones del ciclo de vida del envio (RN12). Es la
 * misma tabla del disparador trg_evento_transicion y del capitulo 5; ENTREGADO, DEVUELTO y
 * ANULADO son finales.
 */
public final class CicloDeVidaEnvio {

    private static final Map<EstadoEnvio, List<EstadoEnvio>> SIGUIENTES = new EnumMap<>(EstadoEnvio.class);

    static {
        SIGUIENTES.put(EstadoEnvio.REGISTRADO, List.of(EstadoEnvio.RECOLECTADO, EstadoEnvio.ANULADO));
        SIGUIENTES.put(EstadoEnvio.RECOLECTADO, List.of(EstadoEnvio.EN_CENTRO, EstadoEnvio.ANULADO));
        SIGUIENTES.put(EstadoEnvio.EN_CENTRO, List.of(EstadoEnvio.CLASIFICADO, EstadoEnvio.ANULADO));
        SIGUIENTES.put(EstadoEnvio.CLASIFICADO, List.of(EstadoEnvio.EN_RUTA, EstadoEnvio.ANULADO));
        SIGUIENTES.put(EstadoEnvio.EN_RUTA, List.of(EstadoEnvio.ENTREGADO, EstadoEnvio.CON_NOVEDAD, EstadoEnvio.DEVUELTO));
        SIGUIENTES.put(EstadoEnvio.CON_NOVEDAD, List.of(EstadoEnvio.EN_RUTA));
        SIGUIENTES.put(EstadoEnvio.ENTREGADO, List.of());
        SIGUIENTES.put(EstadoEnvio.DEVUELTO, List.of());
        SIGUIENTES.put(EstadoEnvio.ANULADO, List.of());
    }

    private CicloDeVidaEnvio() {
    }

    /** Estados a los que se puede pasar desde {@code desde}; con nulo (sin eventos) solo REGISTRADO. */
    public static List<EstadoEnvio> siguientesPermitidos(EstadoEnvio desde) {
        return desde == null ? List.of(EstadoEnvio.REGISTRADO) : SIGUIENTES.get(desde);
    }

    public static boolean puedePasar(EstadoEnvio desde, EstadoEnvio hacia) {
        return siguientesPermitidos(desde).contains(hacia);
    }

    /** RN12: lanza la regla con el mismo codigo y sentido que el disparador de la base. */
    public static void validarTransicion(String numeroGuia, EstadoEnvio desde, EstadoEnvio hacia) {
        if (puedePasar(desde, hacia)) {
            return;
        }
        if (desde == null) {
            throw ReglaNegocioException.deDominio("RN12",
                    "el primer evento de la guía " + numeroGuia + " debe ser REGISTRADO, no " + hacia);
        }
        if (desde.esFinal()) {
            throw ReglaNegocioException.deDominio("RN12",
                    "la guía " + numeroGuia + " ya está en un estado final (" + desde + ") y no admite el evento " + hacia);
        }
        throw ReglaNegocioException.deDominio("RN12",
                "transición no permitida de " + desde + " a " + hacia + " en la guía " + numeroGuia);
    }
}
