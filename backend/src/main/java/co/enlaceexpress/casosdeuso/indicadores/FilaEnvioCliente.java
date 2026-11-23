package co.enlaceexpress.casosdeuso.indicadores;

import java.time.LocalDateTime;

/** Un envio de la empresa del cliente con su estado actual y la fecha de su ultimo evento. */
public record FilaEnvioCliente(String numeroGuia, String estadoActual, LocalDateTime fechaHora) {
}
