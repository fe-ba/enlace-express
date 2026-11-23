package co.enlaceexpress.dominio.referencia;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import org.junit.jupiter.api.Test;

import co.enlaceexpress.dominio.enums.EstadoActivo;
import co.enlaceexpress.dominio.reglas.EntradaInvalida;
import co.enlaceexpress.dominio.reglas.EstadoIncorrecto;

class CentroZonaTest {

    private static CentroDistribucion centro(long id, EstadoActivo estado) {
        return new CentroDistribucion(id, "Centro " + id, "Calle 1", null, estado);
    }

    @Test
    void unCentroNuevoNaceActivoConLosTextosValidados() {
        CentroDistribucion c = CentroDistribucion.nuevo("  Centro Oriente ", " Calle 80 # 10-20 ", "  ");
        assertThat(c.idCentro()).isNull();
        assertThat(c.nombre()).isEqualTo("Centro Oriente");
        assertThat(c.direccion()).isEqualTo("Calle 80 # 10-20");
        assertThat(c.telefono()).isNull();
        assertThat(c.estado()).isEqualTo(EstadoActivo.ACTIVO);
    }

    @Test
    void elNombreYLaDireccionSonObligatoriosYTienenLongitudMaxima() {
        assertThatThrownBy(() -> CentroDistribucion.nuevo(" ", "Calle", null)).isInstanceOf(EntradaInvalida.class);
        assertThatThrownBy(() -> CentroDistribucion.nuevo("C", "", null)).isInstanceOf(EntradaInvalida.class);
        assertThatThrownBy(() -> CentroDistribucion.nuevo("x".repeat(61), "Calle", null)).isInstanceOf(EntradaInvalida.class);
        assertThatThrownBy(() -> CentroDistribucion.nuevo("C", "x".repeat(121), null)).isInstanceOf(EntradaInvalida.class);
        assertThatThrownBy(() -> CentroDistribucion.nuevo("C", "Calle", "1".repeat(21))).isInstanceOf(EntradaInvalida.class);
    }

    @Test
    void modificarConservaElEstadoYInactivarNoBorra() {
        CentroDistribucion c = centro(3, EstadoActivo.ACTIVO).modificar("Nuevo nombre", "Otra calle", "6012000009");
        assertThat(c.idCentro()).isEqualTo(3);
        assertThat(c.estaActivo()).isTrue();
        CentroDistribucion inactivo = c.conEstado(EstadoActivo.INACTIVO);
        assertThat(inactivo.estaActivo()).isFalse();
        assertThat(inactivo.nombre()).isEqualTo("Nuevo nombre");
    }

    @Test
    void soloSeAsignanZonasACentrosActivos() {
        Zona z = Zona.nueva(centro(1, EstadoActivo.ACTIVO), " Norte alto ", "Usaquén, Suba");
        assertThat(z.idCentro()).isEqualTo(1);
        assertThat(z.nombre()).isEqualTo("Norte alto");
        assertThatThrownBy(() -> Zona.nueva(centro(2, EstadoActivo.INACTIVO), "Z", "L")).isInstanceOf(EstadoIncorrecto.class);
        assertThatThrownBy(() -> Zona.nueva(centro(1, EstadoActivo.ACTIVO), "", "L")).isInstanceOf(EntradaInvalida.class);
        assertThatThrownBy(() -> Zona.nueva(centro(1, EstadoActivo.ACTIVO), "Z", "x".repeat(201))).isInstanceOf(EntradaInvalida.class);
    }

    @Test
    void modificarUnaZonaPuedeCambiarDeCentroSoloHaciaUnoActivo() {
        Zona z = new Zona(5L, 1, "Sur", "Kennedy");
        assertThat(z.modificar(centro(1, EstadoActivo.INACTIVO), "Sur nuevo", "Bosa").nombre()).isEqualTo("Sur nuevo");
        assertThat(z.modificar(centro(2, EstadoActivo.ACTIVO), "Sur", "Kennedy").idCentro()).isEqualTo(2);
        assertThatThrownBy(() -> z.modificar(centro(2, EstadoActivo.INACTIVO), "Sur", "Kennedy")).isInstanceOf(EstadoIncorrecto.class);
    }
}
