package co.enlaceexpress.casosdeuso.servicioalcliente;

import java.util.List;

/** Respuesta del rastreo publico de una guia. */
public record Rastreo(String guia, String estadoActual, List<EventoRastreo> eventos) {
}
