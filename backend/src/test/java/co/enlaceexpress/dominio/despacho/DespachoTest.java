package co.enlaceexpress.dominio.despacho;

import static co.enlaceexpress.dominio.Ejemplos.AHORA;
import static co.enlaceexpress.dominio.Ejemplos.FURGONETA;
import static co.enlaceexpress.dominio.Ejemplos.MOTO;
import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.time.LocalDate;

import org.junit.jupiter.api.Test;

import co.enlaceexpress.dominio.Ejemplos;
import co.enlaceexpress.dominio.enums.EstadoDespacho;
import co.enlaceexpress.dominio.enums.EstadoEmpleado;
import co.enlaceexpress.dominio.enums.EstadoEnvio;
import co.enlaceexpress.dominio.enums.EstadoVehiculo;
import co.enlaceexpress.dominio.enums.ResultadoVisita;
import co.enlaceexpress.dominio.enums.TipoDespacho;
import co.enlaceexpress.dominio.enums.TipoNovedad;
import co.enlaceexpress.dominio.envio.Envio;
import co.enlaceexpress.dominio.reglas.ReglaNegocioException;

class DespachoTest {

    private static final LocalDate DIA = LocalDate.of(2026, 11, 20);

    private static Envio clasificado() {
        Envio e = Ejemplos.envioNuevo(false, false);
        e.registrarEvento(EstadoEnvio.RECOLECTADO, 6L, "r", AHORA);
        e.registrarEvento(EstadoEnvio.EN_CENTRO, 2L, "c", AHORA);
        e.registrarEvento(EstadoEnvio.CLASIFICADO, 2L, "k", AHORA);
        return e;
    }

    @Test
    void armarConVehiculoDisponibleYMensajeroActivoDelTipoCorrecto() {
        Despacho d = Despacho.armar(1, Ejemplos.vehiculo(MOTO, EstadoVehiculo.DISPONIBLE), Ejemplos.mensajero(MOTO, EstadoEmpleado.ACTIVO),
                DIA, TipoDespacho.ENTREGA);
        assertThat(d.estado()).isEqualTo(EstadoDespacho.ARMADO);
        assertThat(d.estaAbierto()).isTrue();
        assertThat(d.idMensajero()).isEqualTo(7L);
        assertThat(d.idVehiculo()).isEqualTo(1L);
    }

    @Test
    void rn10VehiculoNoDisponibleOMensajeroInactivo() {
        for (EstadoVehiculo estado : new EstadoVehiculo[] {EstadoVehiculo.EN_MANTENIMIENTO, EstadoVehiculo.FUERA_SERVICIO}) {
            assertThatThrownBy(() -> Despacho.armar(1, Ejemplos.vehiculo(MOTO, estado), Ejemplos.mensajero(MOTO, EstadoEmpleado.ACTIVO), DIA, TipoDespacho.ENTREGA))
                    .isInstanceOfSatisfying(ReglaNegocioException.class, e -> {
                        assertThat(e.codigo()).isEqualTo("RN10");
                        assertThat(e.codigoOracle()).isEqualTo(20010);
                    });
        }
        assertThatThrownBy(() -> Despacho.armar(1, Ejemplos.vehiculo(MOTO, EstadoVehiculo.DISPONIBLE), Ejemplos.mensajero(MOTO, EstadoEmpleado.RETIRADO), DIA, TipoDespacho.ENTREGA))
                .isInstanceOfSatisfying(ReglaNegocioException.class, e -> assertThat(e.codigo()).isEqualTo("RN10"));
    }

    @Test
    void rn11VehiculoDeOtroTipo() {
        assertThatThrownBy(() -> Despacho.armar(1, Ejemplos.vehiculo(FURGONETA, EstadoVehiculo.DISPONIBLE), Ejemplos.mensajero(MOTO, EstadoEmpleado.ACTIVO), DIA, TipoDespacho.ENTREGA))
                .isInstanceOfSatisfying(ReglaNegocioException.class, e -> {
                    assertThat(e.codigo()).isEqualTo("RN11");
                    assertThat(e.codigoOracle()).isEqualTo(20011);
                });
    }

    @Test
    void asignarElPrimerIntentoYLosIntentosSiguientesSoloTrasNovedad() {
        Envio e = clasificado();
        Despacho d1 = Ejemplos.despachoDeEntrega();
        AsignacionDespacho a1 = d1.asignar(e);
        assertThat(a1.numeroIntento()).isEqualTo(1);
        assertThat(a1.ordenVisita()).isEqualTo(1);
        assertThat(a1.resultado()).isEqualTo(ResultadoVisita.PENDIENTE);
        assertThat(e.intentosRealizados()).isEqualTo(1);

        // el intento 2 con el 1 pendiente: RN07
        Despacho d2 = Ejemplos.despachoDeEntrega();
        assertThatThrownBy(() -> d2.asignar(e)).isInstanceOfSatisfying(ReglaNegocioException.class, ex -> {
            assertThat(ex.codigo()).isEqualTo("RN07");
            assertThat(ex.codigoOracle()).isEqualTo(20007);
        });
        assertThat(e.intentosRealizados()).isEqualTo(1);

        a1.registrarNovedad(Novedad.nueva(TipoNovedad.DESTINATARIO_AUSENTE, "no estaba"));
        AsignacionDespacho a2 = d2.asignar(e);
        assertThat(a2.numeroIntento()).isEqualTo(2);

        a2.registrarNovedad(Novedad.nueva(TipoNovedad.DIRECCION_ERRADA, "direccion"));
        Despacho d3 = Ejemplos.despachoDeEntrega();
        AsignacionDespacho a3 = d3.asignar(e);
        assertThat(a3.numeroIntento()).isEqualTo(3);

        // el tercero termina en DEVUELTO; un cuarto intento no existe
        a3.registrarDevolucion(Ejemplos.prueba("x"));
        assertThatThrownBy(() -> Ejemplos.despachoDeEntrega().asignar(e)).hasMessageContaining("intento 4");
    }

    @Test
    void rn07NoSeAsignaAUnDespachoDeRecoleccionNiCerrado() {
        Despacho recoleccion = Despacho.armar(1, Ejemplos.vehiculo(MOTO, EstadoVehiculo.DISPONIBLE), Ejemplos.mensajero(MOTO, EstadoEmpleado.ACTIVO),
                DIA, TipoDespacho.RECOLECCION);
        assertThatThrownBy(() -> recoleccion.asignar(clasificado())).isInstanceOfSatisfying(ReglaNegocioException.class,
                ex -> assertThat(ex.codigo()).isEqualTo("RN07"));

        Despacho cerrado = Ejemplos.despachoDeEntrega();
        cerrado.salir(AHORA);
        cerrado.cerrar(AHORA.plusHours(8));
        assertThat(cerrado.estaAbierto()).isFalse();
        assertThatThrownBy(() -> cerrado.asignar(clasificado())).hasMessageContaining("CERRADO");
    }

    @Test
    void salirYCerrar() {
        Despacho d = Ejemplos.despachoDeEntrega();
        d.salir(AHORA);
        assertThat(d.estado()).isEqualTo(EstadoDespacho.EN_RUTA);
        assertThatThrownBy(() -> d.salir(AHORA)).isInstanceOf(co.enlaceexpress.dominio.reglas.EstadoIncorrecto.class);
        assertThatThrownBy(() -> d.cerrar(AHORA.minusHours(1))).isInstanceOf(co.enlaceexpress.dominio.reglas.EntradaInvalida.class);
        d.cerrar(AHORA.plusHours(8));
        assertThat(d.estado()).isEqualTo(EstadoDespacho.CERRADO);
        assertThatThrownBy(() -> d.cerrar(AHORA.plusHours(9))).isInstanceOf(co.enlaceexpress.dominio.reglas.EstadoIncorrecto.class);
    }
}
