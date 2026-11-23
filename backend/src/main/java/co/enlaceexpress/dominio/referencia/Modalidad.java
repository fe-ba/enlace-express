package co.enlaceexpress.dominio.referencia;

import java.time.DayOfWeek;
import java.time.LocalDate;

/** Catalogo de modalidades de entrega (MISMO_DIA, DIA_SIGUIENTE, ESTANDAR) con su plazo en dias habiles. */
public record Modalidad(int idModalidad, String nombre, int plazoDiasHabiles) {

    /**
     * Fecha de compromiso: el plazo cuenta el dia del registro como dia 1, en dias habiles de lunes a
     * sabado; si el registro cae en domingo, el dia 1 es el lunes siguiente. Es la misma cuenta de
     * pkg_calendario en la base de datos.
     */
    public LocalDate fechaCompromiso(LocalDate registro) {
        LocalDate fecha = registro;
        if (fecha.getDayOfWeek() == DayOfWeek.SUNDAY) {
            fecha = fecha.plusDays(1);
        }
        int pendientes = plazoDiasHabiles - 1;
        while (pendientes > 0) {
            fecha = fecha.plusDays(1);
            if (fecha.getDayOfWeek() != DayOfWeek.SUNDAY) {
                pendientes--;
            }
        }
        return fecha;
    }
}
