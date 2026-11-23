package co.enlaceexpress.dominio.despacho;

import static co.enlaceexpress.dominio.Ejemplos.AHORA;
import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import org.junit.jupiter.api.Test;

import co.enlaceexpress.dominio.Ejemplos;
import co.enlaceexpress.dominio.enums.EstadoNovedad;
import co.enlaceexpress.dominio.enums.EstadoEnvio;
import co.enlaceexpress.dominio.enums.ResultadoVisita;
import co.enlaceexpress.dominio.enums.TipoNovedad;
import co.enlaceexpress.dominio.envio.Envio;
import co.enlaceexpress.dominio.reglas.ReglaNegocioException;

class AsignacionDespachoTest {

    private static Envio clasificado(boolean fragil, boolean altoValor) {
        Envio e = Ejemplos.envioNuevo(fragil, altoValor);
        e.registrarEvento(EstadoEnvio.RECOLECTADO, 6L, "r", AHORA);
        e.registrarEvento(EstadoEnvio.EN_CENTRO, 2L, "c", AHORA);
        e.registrarEvento(EstadoEnvio.CLASIFICADO, 2L, "k", AHORA);
        return e;
    }

    private static AsignacionDespacho intento(Envio e, int n) {
        AsignacionDespacho ultimo = null;
        for (int i = 1; i <= n; i++) {
            if (ultimo != null) {
                ultimo.registrarNovedad(Novedad.nueva(TipoNovedad.OTRA, "n" + i));
            }
            ultimo = Ejemplos.despachoDeEntrega().asignar(e);
        }
        return ultimo;
    }

    private static void esRegla(Runnable accion, String codigo, int oracle) {
        assertThatThrownBy(accion::run).isInstanceOfSatisfying(ReglaNegocioException.class, e -> {
            assertThat(e.codigo()).isEqualTo(codigo);
            assertThat(e.codigoOracle()).isEqualTo(oracle);
        });
    }

    @Test
    void entregaValidaGuardaLaPruebaYElResultado() {
        AsignacionDespacho a = intento(clasificado(false, false), 1);
        assertThat(a.estaPendiente()).isTrue();
        a.registrarEntrega(Ejemplos.prueba("cualquiera"));
        assertThat(a.resultado()).isEqualTo(ResultadoVisita.ENTREGADO);
        assertThat(a.prueba()).isNotNull();
        assertThat(a.horaVisita()).isEqualTo(a.prueba().fechaHora());
        assertThat(a.estaPendiente()).isFalse();
    }

    @Test
    void rn05SinPruebaNoHayEntregaNiDevolucion() {
        esRegla(() -> intento(clasificado(false, false), 1).registrarEntrega(null), "RN05", 20005);
        esRegla(() -> intento(clasificado(false, false), 3).registrarDevolucion(null), "RN05", 20005);
    }

    @Test
    void rn06FragilOAltoValorSoloAlDestinatario() {
        String documentoDelDestinatario = Ejemplos.LUIS.numeroDocumento();
        for (boolean[] banderas : new boolean[][] {{true, false}, {false, true}}) {
            esRegla(() -> intento(clasificado(banderas[0], banderas[1]), 1).registrarEntrega(Ejemplos.prueba("99999")), "RN06", 20006);
            AsignacionDespacho ok = intento(clasificado(banderas[0], banderas[1]), 1);
            ok.registrarEntrega(Ejemplos.prueba(documentoDelDestinatario));
            assertThat(ok.resultado()).isEqualTo(ResultadoVisita.ENTREGADO);
        }
        // un envio normal admite a cualquier receptor
        intento(clasificado(false, false), 1).registrarEntrega(Ejemplos.prueba("99999"));
    }

    @Test
    void rn06TambienEnLaDevolucion() {
        esRegla(() -> intento(clasificado(true, false), 3).registrarDevolucion(Ejemplos.prueba("99999")), "RN06", 20006);
    }

    @Test
    void rn07ElTercerIntentoSoloPuedeSerDevolucion() {
        AsignacionDespacho tercero = intento(clasificado(false, false), 3);
        esRegla(() -> tercero.registrarEntrega(Ejemplos.prueba("x")), "RN07", 20007);
        esRegla(() -> tercero.registrarNovedad(Novedad.nueva(TipoNovedad.OTRA, "x")), "RN07", 20007);
        tercero.registrarDevolucion(Ejemplos.prueba("x"));
        assertThat(tercero.resultado()).isEqualTo(ResultadoVisita.DEVUELTO);
    }

    @Test
    void rn07LaDevolucionSoloEnElTercerIntento() {
        esRegla(() -> intento(clasificado(false, false), 1).registrarDevolucion(Ejemplos.prueba("x")), "RN07", 20007);
        esRegla(() -> intento(clasificado(false, false), 2).registrarDevolucion(Ejemplos.prueba("x")), "RN07", 20007);
    }

    @Test
    void rn08NovedadObligatoriaYUnSoloResultadoPorIntento() {
        esRegla(() -> intento(clasificado(false, false), 1).registrarNovedad(null), "RN08", 20008);
        AsignacionDespacho a = intento(clasificado(false, false), 1);
        Novedad n = Novedad.nueva(TipoNovedad.DESTINATARIO_AUSENTE, "ausente");
        a.registrarNovedad(n);
        assertThat(a.resultado()).isEqualTo(ResultadoVisita.NOVEDAD);
        assertThat(n.estado()).isEqualTo(EstadoNovedad.ABIERTA);
        esRegla(() -> a.registrarEntrega(Ejemplos.prueba("x")), "RN08", 20008);
        esRegla(() -> a.registrarNovedad(Novedad.nueva(TipoNovedad.OTRA, "otra")), "RN08", 20008);
    }

    @Test
    void gestionarYCerrarUnaNovedad() {
        Novedad n = Novedad.nueva(TipoNovedad.RECHAZADO, "rechazo");
        n.gestionar(co.enlaceexpress.dominio.enums.AccionNovedad.REINTENTO, "se reprograma");
        n.cerrar();
        assertThat(n.accion()).isEqualTo(co.enlaceexpress.dominio.enums.AccionNovedad.REINTENTO);
        assertThat(n.solucion()).isEqualTo("se reprograma");
        assertThat(n.estado()).isEqualTo(EstadoNovedad.CERRADA);
    }
}
