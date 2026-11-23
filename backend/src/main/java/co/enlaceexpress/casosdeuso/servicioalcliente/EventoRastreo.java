package co.enlaceexpress.casosdeuso.servicioalcliente;

import java.time.LocalDateTime;

/** Un evento del rastreo publico: solo fecha, estado y zona (decision D2). */
public record EventoRastreo(LocalDateTime fechaHora, String estado, String zona) {
}
