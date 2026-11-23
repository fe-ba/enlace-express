package co.enlaceexpress.casosdeuso.indicadores;

import java.time.LocalDateTime;

/** Fila de v_seguimiento_envio: un evento del recorrido de un envio. */
public record FilaSeguimiento(LocalDateTime fechaHora, String estado, String observacion, String responsable) {
}
