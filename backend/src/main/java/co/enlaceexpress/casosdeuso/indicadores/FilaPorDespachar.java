package co.enlaceexpress.casosdeuso.indicadores;

import java.math.BigDecimal;
import java.time.LocalDate;

/** Fila de v_envios_por_despachar: envio clasificado que todavia no esta en un despacho de entrega abierto. */
public record FilaPorDespachar(String numeroGuia, long idCentro, long idZona, String zona, String modalidad,
        LocalDate fechaCompromiso, BigDecimal pesoKg, boolean fragil, boolean altoValor, String estadoActual,
        int intentosPrevios) {
}
