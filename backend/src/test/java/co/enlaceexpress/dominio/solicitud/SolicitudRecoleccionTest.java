package co.enlaceexpress.dominio.solicitud;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.time.LocalDate;

import org.junit.jupiter.api.Test;

import co.enlaceexpress.dominio.Ejemplos;
import co.enlaceexpress.dominio.enums.EstadoActivo;
import co.enlaceexpress.dominio.enums.EstadoSolicitud;
import co.enlaceexpress.dominio.enums.FranjaHoraria;
import co.enlaceexpress.dominio.referencia.Modalidad;
import co.enlaceexpress.dominio.referencia.SedeCliente;
import co.enlaceexpress.dominio.reglas.DatoInvalido;
import co.enlaceexpress.dominio.reglas.ReglaNegocioException;

class SolicitudRecoleccionTest {

    private static final SedeCliente SEDE = new SedeCliente(1L, 1, 1, "Sede", "Carrera 7", "Marta", "3001");
    private static final LocalDate HOY = LocalDate.of(2026, 11, 20);

    @Test
    void rn15ClienteActivoSiClienteInactivoNo() {
        SolicitudRecoleccion s = SolicitudRecoleccion.registrar(SEDE, Ejemplos.cliente(EstadoActivo.ACTIVO), HOY, HOY.plusDays(1), FranjaHoraria.MANANA);
        assertThat(s.estado()).isEqualTo(EstadoSolicitud.PENDIENTE);
        assertThat(s.idSede()).isEqualTo(1L);
        assertThatThrownBy(() -> SolicitudRecoleccion.registrar(SEDE, Ejemplos.cliente(EstadoActivo.INACTIVO), HOY, HOY, FranjaHoraria.TARDE))
                .isInstanceOfSatisfying(ReglaNegocioException.class, e -> {
                    assertThat(e.codigo()).isEqualTo("RN15");
                    assertThat(e.codigoOracle()).isEqualTo(20015);
                });
    }

    @Test
    void laFechaProgramadaNoEsAnteriorALaSolicitud() {
        assertThatThrownBy(() -> SolicitudRecoleccion.registrar(SEDE, Ejemplos.cliente(EstadoActivo.ACTIVO), HOY, HOY.minusDays(1), FranjaHoraria.MANANA))
                .isInstanceOf(DatoInvalido.class);
    }

    @Test
    void atenderUnaSolicitud() {
        SolicitudRecoleccion s = SolicitudRecoleccion.registrar(SEDE, Ejemplos.cliente(EstadoActivo.ACTIVO), HOY, HOY, FranjaHoraria.MANANA);
        s.programar(Ejemplos.despachoDeEntrega());
        assertThat(s.estado()).isEqualTo(EstadoSolicitud.PROGRAMADA);
        assertThat(s.idDespacho()).isEqualTo(15L);
        s.marcarAtendida();
        assertThat(s.estado()).isEqualTo(EstadoSolicitud.ATENDIDA);
        assertThatThrownBy(s::marcarAtendida).isInstanceOf(co.enlaceexpress.dominio.reglas.EstadoIncorrecto.class);
    }

    @Test
    void laModalidadCuentaElDiaDelRegistroComoDiaUno() {
        Modalidad mismoDia = new Modalidad(1, "MISMO_DIA", 1);
        Modalidad siguiente = new Modalidad(2, "DIA_SIGUIENTE", 2);
        Modalidad estandar = new Modalidad(3, "ESTANDAR", 3);
        LocalDate sabado = LocalDate.of(2026, 11, 7);
        LocalDate viernes = LocalDate.of(2026, 11, 6);
        LocalDate domingo = LocalDate.of(2026, 11, 8);
        // los mismos casos de la prueba de pkg_calendario en la base de datos
        assertThat(mismoDia.fechaCompromiso(sabado)).isEqualTo(sabado);
        assertThat(siguiente.fechaCompromiso(sabado)).isEqualTo(LocalDate.of(2026, 11, 9));
        assertThat(estandar.fechaCompromiso(viernes)).isEqualTo(LocalDate.of(2026, 11, 9));
        assertThat(mismoDia.fechaCompromiso(domingo)).isEqualTo(LocalDate.of(2026, 11, 9));
        assertThat(siguiente.fechaCompromiso(domingo)).isEqualTo(LocalDate.of(2026, 11, 10));
        assertThat(estandar.fechaCompromiso(LocalDate.of(2026, 11, 3))).isEqualTo(LocalDate.of(2026, 11, 5));
        assertThat(estandar.fechaCompromiso(sabado)).isEqualTo(LocalDate.of(2026, 11, 10));
    }
}
