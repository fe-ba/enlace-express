package co.enlaceexpress.datos.infraestructura;

import static org.assertj.core.api.Assertions.assertThat;

import java.sql.Date;
import java.sql.Timestamp;
import java.time.LocalDate;
import java.time.LocalDateTime;

import org.junit.jupiter.api.Test;

class ConversorTiposTest {

    @Test
    void siNoABoolean() {
        assertThat(ConversorTipos.aBoolean("S")).isTrue();
        assertThat(ConversorTipos.aBoolean("N")).isFalse();
        assertThat(ConversorTipos.aBoolean(null)).isFalse();
        assertThat(ConversorTipos.aSiNo(true)).isEqualTo("S");
        assertThat(ConversorTipos.aSiNo(false)).isEqualTo("N");
    }

    @Test
    void fechas() {
        LocalDate dia = LocalDate.of(2026, 11, 20);
        assertThat(ConversorTipos.aFecha(Date.valueOf(dia))).isEqualTo(dia);
        assertThat(ConversorTipos.aDate(dia)).isEqualTo(Date.valueOf(dia));
        assertThat(ConversorTipos.aFecha(null)).isNull();
        assertThat(ConversorTipos.aDate(null)).isNull();
    }

    @Test
    void instantes() {
        LocalDateTime t = LocalDateTime.of(2026, 11, 20, 8, 43, 12, 345_000_000);
        assertThat(ConversorTipos.aInstante(Timestamp.valueOf(t))).isEqualTo(t);
        assertThat(ConversorTipos.aTimestamp(t)).isEqualTo(Timestamp.valueOf(t));
        assertThat(ConversorTipos.aInstante(null)).isNull();
        assertThat(ConversorTipos.aTimestamp(null)).isNull();
    }
}
