package co.enlaceexpress.dominio.despacho;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import org.junit.jupiter.api.Test;

import co.enlaceexpress.dominio.enums.AccionNovedad;
import co.enlaceexpress.dominio.enums.EstadoNovedad;
import co.enlaceexpress.dominio.enums.TipoNovedad;
import co.enlaceexpress.dominio.reglas.EntradaInvalida;
import co.enlaceexpress.dominio.reglas.EstadoIncorrecto;

class NovedadTest {

    private static Novedad abierta() {
        return new Novedad(7L, TipoNovedad.DESTINATARIO_AUSENTE, "Local cerrado", null, null, EstadoNovedad.ABIERTA);
    }

    @Test
    void gestionarYCerrarGuardaLaAccionLaSolucionYCierra() {
        Novedad n = abierta();
        n.gestionarYCerrar(AccionNovedad.REINTENTO, "  Se reprograma la entrega ");
        assertThat(n.accion()).isEqualTo(AccionNovedad.REINTENTO);
        assertThat(n.solucion()).isEqualTo("Se reprograma la entrega");
        assertThat(n.estado()).isEqualTo(EstadoNovedad.CERRADA);
        assertThat(n.estaAbierta()).isFalse();
    }

    @Test
    void unaNovedadCerradaNoSeGestionaDeNuevo() {
        Novedad n = abierta();
        n.gestionarYCerrar(AccionNovedad.DEVOLUCION, "Se devuelve");
        assertThatThrownBy(() -> n.gestionarYCerrar(AccionNovedad.REINTENTO, "Otra")).isInstanceOf(EstadoIncorrecto.class);
        assertThat(n.accion()).isEqualTo(AccionNovedad.DEVOLUCION);
    }

    @Test
    void laAccionYLaSolucionSonObligatoriasYNoCierranSiFallan() {
        Novedad n = abierta();
        assertThatThrownBy(() -> n.gestionarYCerrar(null, "Solucion")).isInstanceOf(EntradaInvalida.class);
        assertThatThrownBy(() -> n.gestionarYCerrar(AccionNovedad.REINTENTO, "  ")).isInstanceOf(EntradaInvalida.class);
        assertThatThrownBy(() -> n.gestionarYCerrar(AccionNovedad.REINTENTO, "x".repeat(301))).isInstanceOf(EntradaInvalida.class);
        assertThat(n.estaAbierta()).isTrue();
        assertThat(n.accion()).isNull();
    }
}
