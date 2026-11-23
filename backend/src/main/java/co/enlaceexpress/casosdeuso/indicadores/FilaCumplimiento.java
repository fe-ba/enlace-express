package co.enlaceexpress.casosdeuso.indicadores;

import java.math.BigDecimal;

/** Fila de v_cumplimiento_entregas: entregas y entregas a tiempo de una zona (indicador de OE1). */
public record FilaCumplimiento(long idCentro, long idZona, String zona, long entregados, long entregadosATiempo,
        BigDecimal porcentajeATiempo) {
}
