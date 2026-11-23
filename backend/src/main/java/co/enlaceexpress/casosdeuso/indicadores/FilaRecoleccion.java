package co.enlaceexpress.casosdeuso.indicadores;

import java.time.LocalDate;

/** Solicitud de recoleccion por atender, con la sede donde se recoge y cuantos envios tiene. */
public record FilaRecoleccion(long idSolicitud, LocalDate fechaProgramada, String franjaHoraria, String estado,
        String sede, String direccion, String contacto, String telefono, int envios) {
}
