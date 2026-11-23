package co.enlaceexpress.casosdeuso.indicadores;

import java.time.LocalDate;
import java.time.LocalDateTime;

/** Fila de v_estado_actual_envio: un envio con su estado actual, cliente, zona y modalidad. */
public record FilaEnvioEstado(String numeroGuia, LocalDate fechaRegistro, LocalDate fechaCompromiso, String razonSocial,
        String zona, String modalidad, String estadoActual, LocalDateTime fechaHoraEstado) {
}
