package co.enlaceexpress.casosdeuso.servicioalcliente;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * Reclamacion para la lista de la mesa de servicio. Las horas son las transcurridas desde la radicacion (si esta
 * ABIERTA) o las que tardo la respuesta (si esta RESPONDIDA); {@code superaMeta} marca las que pasan de las 4 horas
 * de la regla RN14.
 */
public record FilaReclamacionMesa(long idReclamacion, LocalDateTime fechaRadicacion, long idCliente, String cliente,
        String numeroGuia, String tipo, String descripcion, String estado, String respuesta, LocalDateTime fechaRespuesta,
        BigDecimal horas, boolean superaMeta) {
}
