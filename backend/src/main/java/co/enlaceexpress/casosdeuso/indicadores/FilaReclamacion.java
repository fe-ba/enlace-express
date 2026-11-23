package co.enlaceexpress.casosdeuso.indicadores;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/** Fila de v_reclamaciones_pendientes. */
public record FilaReclamacion(long idReclamacion, LocalDateTime fechaRadicacion, long idCliente, String cliente,
        String numeroGuia, String tipo, String descripcion, BigDecimal horasTranscurridas) {
}
