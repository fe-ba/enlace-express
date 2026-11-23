package co.enlaceexpress.dominio.envio;

import static co.enlaceexpress.dominio.Ejemplos.AHORA;
import static co.enlaceexpress.dominio.Ejemplos.ESTANDAR;
import static co.enlaceexpress.dominio.Ejemplos.LUIS;
import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

import org.junit.jupiter.api.Test;

import co.enlaceexpress.dominio.Ejemplos;
import co.enlaceexpress.dominio.despacho.AsignacionDespacho;
import co.enlaceexpress.dominio.enums.EstadoEnvio;
import co.enlaceexpress.dominio.enums.TipoDocumento;
import co.enlaceexpress.dominio.reglas.ReglaNegocioException;

class EnvioTest {

    private static Envio nuevo(Destinatario d, String direccion, BigDecimal peso, String contenido, BigDecimal valor, LocalDate compromiso) {
        return Envio.nuevo(1L, d, 1, ESTANDAR, direccion, peso, contenido, valor, false, false, compromiso, 4L, AHORA);
    }

    @Test
    void registroValidoNaceConElEventoRegistradoYLaFechaDeCompromisoDeLaModalidad() {
        Envio e = Ejemplos.envioNuevo(false, false);
        assertThat(e.estadoActual()).isEqualTo(EstadoEnvio.REGISTRADO);
        assertThat(e.historial()).hasSize(1);
        assertThat(e.historial().get(0).idEmpleado()).isEqualTo(4L);
        assertThat(e.fechaRegistro()).isEqualTo(LocalDate.of(2026, 11, 20));
        // viernes 20 de noviembre + 3 dias habiles (lunes a sabado, el dia del registro es el 1): lunes 23
        assertThat(e.fechaCompromiso()).isEqualTo(LocalDate.of(2026, 11, 23));
        assertThat(e.exigeDocumentoDestinatario()).isFalse();
        assertThat(Ejemplos.envioNuevo(true, false).exigeDocumentoDestinatario()).isTrue();
        assertThat(Ejemplos.envioNuevo(false, true).exigeDocumentoDestinatario()).isTrue();
    }

    @Test
    void rn02DatosObligatorios() {
        Destinatario sinNombre = new Destinatario(null, TipoDocumento.CC, "1", null, "300", null);
        assertThatThrownBy(() -> nuevo(sinNombre, "Calle", BigDecimal.ONE, "Libros", BigDecimal.TEN, null))
                .isInstanceOfSatisfying(ReglaNegocioException.class, e -> assertThat(e.codigo()).isEqualTo("RN02"));
        assertThatThrownBy(() -> nuevo(null, "Calle", BigDecimal.ONE, "Libros", BigDecimal.TEN, null)).hasMessageContaining("destinatario");
        assertThatThrownBy(() -> nuevo(LUIS, " ", BigDecimal.ONE, "Libros", BigDecimal.TEN, null)).hasMessageContaining("direccion");
        assertThatThrownBy(() -> nuevo(LUIS, "Calle", null, "Libros", BigDecimal.TEN, null)).hasMessageContaining("peso");
        assertThatThrownBy(() -> nuevo(LUIS, "Calle", BigDecimal.ONE, null, BigDecimal.TEN, null)).hasMessageContaining("contenido");
        assertThatThrownBy(() -> nuevo(LUIS, "Calle", BigDecimal.ONE, "Libros", null, null)).hasMessageContaining("valor");
        assertThatThrownBy(() -> Envio.nuevo(1L, LUIS, 1, null, "Calle", BigDecimal.ONE, "Libros", BigDecimal.TEN, false, false, null, 4L, AHORA))
                .hasMessageContaining("modalidad");
    }

    @Test
    void rn03Magnitudes() {
        assertThatThrownBy(() -> nuevo(LUIS, "Calle", BigDecimal.ONE, "Libros", BigDecimal.TEN, LocalDate.of(2026, 11, 19)))
                .isInstanceOfSatisfying(ReglaNegocioException.class, e -> assertThat(e.codigo()).isEqualTo("RN03"));
        assertThatThrownBy(() -> nuevo(LUIS, "Calle", BigDecimal.ZERO, "Libros", BigDecimal.TEN, null)).hasMessageContaining("peso");
        assertThatThrownBy(() -> nuevo(LUIS, "Calle", BigDecimal.ONE, "Libros", new BigDecimal("-1"), null)).hasMessageContaining("valor");
        // casos validos en el limite
        assertThat(nuevo(LUIS, "Calle", BigDecimal.ONE, "Libros", BigDecimal.ZERO, LocalDate.of(2026, 11, 20)).fechaCompromiso())
                .isEqualTo(LocalDate.of(2026, 11, 20));
    }

    @Test
    void clasificarExigePesoYFletePositivos() {
        Envio e = Ejemplos.envioNuevo(false, false);
        e.clasificar(new BigDecimal("2.60"), new BigDecimal("9000"));
        assertThat(e.pesoReal()).isEqualByComparingTo("2.60");
        assertThat(e.valorFlete()).isEqualByComparingTo("9000");
        assertThatThrownBy(() -> e.clasificar(new BigDecimal("-1"), new BigDecimal("9000"))).isInstanceOf(ReglaNegocioException.class)
                .hasMessageContaining("peso real");
        assertThatThrownBy(() -> e.clasificar(new BigDecimal("1"), BigDecimal.ZERO)).hasMessageContaining("flete");
    }

    @Test
    void losEventosDeUnaMismaOperacionTienenInstantesDistintosYCrecientes() {
        Envio e = Ejemplos.envioNuevo(false, false);
        LocalDateTime ahora = AHORA.plusHours(1);
        EventoEnvio a = e.registrarEvento(EstadoEnvio.RECOLECTADO, 6L, "r", ahora);
        EventoEnvio b = e.registrarEvento(EstadoEnvio.EN_CENTRO, 2L, "c", ahora);
        EventoEnvio c = e.registrarEvento(EstadoEnvio.CLASIFICADO, 2L, "k", ahora);
        assertThat(a.fechaHora()).isEqualTo(ahora);
        assertThat(b.fechaHora()).isAfter(a.fechaHora());
        assertThat(c.fechaHora()).isAfter(b.fechaHora());
        // un reloj atrasado tampoco rompe el orden: siempre despues del ultimo evento
        EventoEnvio d = e.registrarEvento(EstadoEnvio.EN_RUTA, 7L, "x", AHORA.minusDays(1));
        assertThat(d.fechaHora()).isAfter(c.fechaHora());
        assertThat(e.estadoActual()).isEqualTo(EstadoEnvio.EN_RUTA);
        assertThat(e.historial()).hasSize(5);
    }

    @Test
    void rn12LaTransicionNoPermitidaSeRechazaYNoDejaRastro() {
        Envio e = Ejemplos.envioNuevo(false, false);
        assertThatThrownBy(() -> e.registrarEvento(EstadoEnvio.ENTREGADO, 6L, "x", AHORA))
                .isInstanceOfSatisfying(ReglaNegocioException.class, ex -> assertThat(ex.codigo()).isEqualTo("RN12"));
        assertThat(e.historial()).hasSize(1);
        assertThat(e.estadoActual()).isEqualTo(EstadoEnvio.REGISTRADO);
    }

    @Test
    void rn05EntregadoODevueltoExigenUnIntentoConEseResultado() {
        Envio e = Ejemplos.envioNuevo(false, false);
        e.registrarEvento(EstadoEnvio.RECOLECTADO, 6L, "r", AHORA);
        e.registrarEvento(EstadoEnvio.EN_CENTRO, 2L, "c", AHORA);
        e.registrarEvento(EstadoEnvio.CLASIFICADO, 2L, "k", AHORA);
        AsignacionDespacho intento = Ejemplos.intentoUno(e);
        e.registrarEvento(EstadoEnvio.EN_RUTA, 7L, "x", AHORA);
        assertThatThrownBy(() -> e.registrarEvento(EstadoEnvio.ENTREGADO, 7L, "x", AHORA))
                .isInstanceOfSatisfying(ReglaNegocioException.class, ex -> assertThat(ex.codigo()).isEqualTo("RN05"));
        intento.registrarEntrega(Ejemplos.prueba("cualquiera"));
        assertThat(e.registrarEvento(EstadoEnvio.ENTREGADO, 7L, "ok", AHORA).estado()).isEqualTo(EstadoEnvio.ENTREGADO);
    }

    @Test
    void anularSoloAntesDeSalirARuta() {
        Envio antes = Ejemplos.envioNuevo(false, false);
        antes.anular(new co.enlaceexpress.dominio.referencia.Empleado(4L, 1, "d", "n", "a", "Agente de mesa de servicio", "t", null,
                LocalDate.of(2025, 1, 1), null, null, co.enlaceexpress.dominio.enums.EstadoEmpleado.ACTIVO), AHORA);
        assertThat(antes.estadoActual()).isEqualTo(EstadoEnvio.ANULADO);

        Envio enRuta = Ejemplos.envioNuevo(false, false);
        enRuta.registrarEvento(EstadoEnvio.RECOLECTADO, 6L, "r", AHORA);
        enRuta.registrarEvento(EstadoEnvio.EN_CENTRO, 2L, "c", AHORA);
        enRuta.registrarEvento(EstadoEnvio.CLASIFICADO, 2L, "k", AHORA);
        enRuta.registrarEvento(EstadoEnvio.EN_RUTA, 7L, "x", AHORA);
        assertThatThrownBy(() -> enRuta.registrarEvento(EstadoEnvio.ANULADO, 4L, "tarde", AHORA)).isInstanceOfSatisfying(ReglaNegocioException.class, ex -> assertThat(ex.codigo()).isEqualTo("RN12"));
    }
}
