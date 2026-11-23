package co.enlaceexpress.dominio.reglas;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.util.List;
import java.util.Map;

import org.junit.jupiter.api.Test;

import co.enlaceexpress.dominio.enums.EstadoEnvio;

class CicloDeVidaEnvioTest {

    /** La tabla de transiciones del capitulo 5, escrita de nuevo a mano para compararla con el servicio. */
    private static final Map<EstadoEnvio, List<EstadoEnvio>> PERMITIDAS = Map.of(
            EstadoEnvio.REGISTRADO, List.of(EstadoEnvio.RECOLECTADO, EstadoEnvio.ANULADO),
            EstadoEnvio.RECOLECTADO, List.of(EstadoEnvio.EN_CENTRO, EstadoEnvio.ANULADO),
            EstadoEnvio.EN_CENTRO, List.of(EstadoEnvio.CLASIFICADO, EstadoEnvio.ANULADO),
            EstadoEnvio.CLASIFICADO, List.of(EstadoEnvio.EN_RUTA, EstadoEnvio.ANULADO),
            EstadoEnvio.EN_RUTA, List.of(EstadoEnvio.ENTREGADO, EstadoEnvio.CON_NOVEDAD, EstadoEnvio.DEVUELTO),
            EstadoEnvio.CON_NOVEDAD, List.of(EstadoEnvio.EN_RUTA),
            EstadoEnvio.ENTREGADO, List.of(),
            EstadoEnvio.DEVUELTO, List.of(),
            EstadoEnvio.ANULADO, List.of());

    @Test
    void todasLasTransicionesDeLaTabla() {
        for (EstadoEnvio desde : EstadoEnvio.values()) {
            for (EstadoEnvio hacia : EstadoEnvio.values()) {
                assertThat(CicloDeVidaEnvio.puedePasar(desde, hacia))
                        .as("%s -> %s", desde, hacia).isEqualTo(PERMITIDAS.get(desde).contains(hacia));
            }
        }
    }

    @Test
    void sinEventosSoloSePuedeRegistrar() {
        assertThat(CicloDeVidaEnvio.siguientesPermitidos(null)).containsExactly(EstadoEnvio.REGISTRADO);
        assertThat(CicloDeVidaEnvio.puedePasar(null, EstadoEnvio.REGISTRADO)).isTrue();
        assertThat(CicloDeVidaEnvio.puedePasar(null, EstadoEnvio.EN_CENTRO)).isFalse();
    }

    @Test
    void losEstadosFinalesNoTienenSiguientes() {
        for (EstadoEnvio e : EstadoEnvio.values()) {
            assertThat(e.esFinal()).isEqualTo(CicloDeVidaEnvio.siguientesPermitidos(e).isEmpty());
        }
    }

    @Test
    void validarTransicionPermitidaNoLanzaNada() {
        CicloDeVidaEnvio.validarTransicion("EE1", EstadoEnvio.CON_NOVEDAD, EstadoEnvio.EN_RUTA);
        CicloDeVidaEnvio.validarTransicion("EE1", null, EstadoEnvio.REGISTRADO);
    }

    @Test
    void transicionNoPermitidaEsRn12ConElCodigoDeOracle() {
        assertThatThrownBy(() -> CicloDeVidaEnvio.validarTransicion("EE1", EstadoEnvio.REGISTRADO, EstadoEnvio.ENTREGADO))
                .isInstanceOfSatisfying(ReglaNegocioException.class, e -> {
                    assertThat(e.codigo()).isEqualTo("RN12");
                    assertThat(e.codigoOracle()).isEqualTo(20012);
                    assertThat(e.getMessage()).contains("REGISTRADO").contains("ENTREGADO");
                });
        assertThatThrownBy(() -> CicloDeVidaEnvio.validarTransicion("EE1", EstadoEnvio.EN_RUTA, EstadoEnvio.ANULADO))
                .isInstanceOf(ReglaNegocioException.class);
        assertThatThrownBy(() -> CicloDeVidaEnvio.validarTransicion("EE1", EstadoEnvio.ENTREGADO, EstadoEnvio.CON_NOVEDAD))
                .hasMessageContaining("estado final");
        assertThatThrownBy(() -> CicloDeVidaEnvio.validarTransicion("EE1", null, EstadoEnvio.EN_CENTRO))
                .hasMessageContaining("primer evento");
    }

    @Test
    void losIdsDeLosEstadosSonLosDelCatalogo() {
        assertThat(EstadoEnvio.values()).hasSize(9);
        for (int i = 0; i < EstadoEnvio.values().length; i++) {
            assertThat(EstadoEnvio.values()[i].idEstado()).isEqualTo(i + 1);
            assertThat(EstadoEnvio.porId(i + 1)).isSameAs(EstadoEnvio.values()[i]);
        }
        assertThatThrownBy(() -> EstadoEnvio.porId(10)).isInstanceOf(IllegalArgumentException.class);
    }
}
