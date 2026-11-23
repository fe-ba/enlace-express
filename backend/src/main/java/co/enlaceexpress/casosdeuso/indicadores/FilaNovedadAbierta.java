package co.enlaceexpress.casosdeuso.indicadores;

import java.time.LocalDateTime;

/** Fila de v_novedades_abiertas (I06): la novedad sin cerrar con los datos para contactar al destinatario y al cliente. */
public record FilaNovedadAbierta(long idNovedad, String numeroGuia, int numeroIntento, LocalDateTime horaVisita,
        String tipoNovedad, String descripcion, String destinatario, String telefonoDestinatario, long idCliente,
        String cliente, String telefonoCliente) {
}
