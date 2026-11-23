package co.enlaceexpress.dominio.reclamacion;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.time.LocalDateTime;

import org.junit.jupiter.api.Test;

import co.enlaceexpress.dominio.enums.EstadoReclamacion;
import co.enlaceexpress.dominio.enums.TipoReclamacion;
import co.enlaceexpress.dominio.reglas.DatoInvalido;
import co.enlaceexpress.dominio.reglas.EntradaInvalida;
import co.enlaceexpress.dominio.reglas.EstadoIncorrecto;

class ReclamacionTest {

    private static final LocalDateTime RADICACION = LocalDateTime.of(2026, 11, 20, 9, 0);

    private static Reclamacion abierta() {
        return Reclamacion.radicar(1, "ee0000000000015", TipoReclamacion.ENTREGA, "  El paquete llegó tarde ", RADICACION);
    }

    @Test
    void radicarCreaUnaReclamacionAbiertaConLaGuiaNormalizada() {
        Reclamacion r = abierta();
        assertThat(r.estado()).isEqualTo(EstadoReclamacion.ABIERTA);
        assertThat(r.numeroGuia()).isEqualTo("EE0000000000015");
        assertThat(r.descripcion()).isEqualTo("El paquete llegó tarde");
        assertThat(r.fechaRadicacion()).isEqualTo(RADICACION);
        assertThat(Reclamacion.radicar(1, "  ", TipoReclamacion.OTRO, "x", RADICACION).numeroGuia()).isNull();
    }

    @Test
    void radicarExigeTipoYDescripcion() {
        assertThatThrownBy(() -> Reclamacion.radicar(1, null, null, "x", RADICACION)).isInstanceOf(EntradaInvalida.class);
        assertThatThrownBy(() -> Reclamacion.radicar(1, null, TipoReclamacion.OTRO, "   ", RADICACION)).isInstanceOf(EntradaInvalida.class);
        assertThatThrownBy(() -> Reclamacion.radicar(1, null, TipoReclamacion.OTRO, "x".repeat(501), RADICACION))
                .isInstanceOf(EntradaInvalida.class);
    }

    @Test
    void responderGuardaLaRespuestaYLaFechaYPasaARespondida() {
        Reclamacion r = abierta();
        r.responder(" Se pidieron disculpas ", RADICACION.plusHours(3));
        assertThat(r.estado()).isEqualTo(EstadoReclamacion.RESPONDIDA);
        assertThat(r.respuesta()).isEqualTo("Se pidieron disculpas");
        assertThat(r.fechaRespuesta()).isEqualTo(RADICACION.plusHours(3));
        assertThat(r.horasDeRespuesta(RADICACION.plusDays(5))).isEqualTo(3.0);
        assertThat(r.superaLaMeta(laManana())).isFalse();
    }

    private static LocalDateTime laManana() {
        return RADICACION.plusDays(1);
    }

    @Test
    void laMetaDeCuatroHorasSeMideDesdeLaRadicacion() {
        Reclamacion pendiente = abierta();
        assertThat(pendiente.superaLaMeta(RADICACION.plusHours(4))).isFalse();
        assertThat(pendiente.superaLaMeta(RADICACION.plusHours(5))).isTrue();
        Reclamacion tarde = abierta();
        tarde.responder("Respuesta", RADICACION.plusHours(6));
        assertThat(tarde.superaLaMeta(RADICACION.plusDays(2))).isTrue();
    }

    @Test
    void rn14LaRespuestaNoPuedeSerAnteriorALaRadicacionConElResultadoDelCheck() {
        Reclamacion r = abierta();
        assertThatThrownBy(() -> r.responder("Respuesta", RADICACION.minusMinutes(1)))
                .isInstanceOfSatisfying(DatoInvalido.class, e -> {
                    assertThat(e.codigoOracle()).isEqualTo(2290);
                    assertThat(e.restriccion()).isEqualTo("RECLAMACION_RESP_CK");
                    assertThat(e.getMessage()).startsWith("RN14");
                });
        assertThat(r.estado()).isEqualTo(EstadoReclamacion.ABIERTA);
        assertThat(r.fechaRespuesta()).isNull();
    }

    @Test
    void soloSeRespondeUnaAbiertaYSoloSeCierraUnaRespondida() {
        Reclamacion r = abierta();
        assertThatThrownBy(r::cerrar).isInstanceOf(EstadoIncorrecto.class);
        assertThatThrownBy(() -> r.responder(" ", RADICACION.plusHours(1))).isInstanceOf(EntradaInvalida.class);
        r.responder("Respuesta", RADICACION.plusHours(1));
        assertThatThrownBy(() -> r.responder("Otra", RADICACION.plusHours(2))).isInstanceOf(EstadoIncorrecto.class);
        r.cerrar();
        assertThat(r.estado()).isEqualTo(EstadoReclamacion.CERRADA);
        assertThatThrownBy(r::cerrar).isInstanceOf(EstadoIncorrecto.class);
    }
}
