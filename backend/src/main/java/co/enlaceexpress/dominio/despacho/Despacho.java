package co.enlaceexpress.dominio.despacho;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

import co.enlaceexpress.dominio.envio.Envio;
import co.enlaceexpress.dominio.enums.EstadoDespacho;
import co.enlaceexpress.dominio.enums.ResultadoVisita;
import co.enlaceexpress.dominio.enums.TipoDespacho;
import co.enlaceexpress.dominio.referencia.Mensajero;
import co.enlaceexpress.dominio.referencia.Vehiculo;
import co.enlaceexpress.dominio.reglas.EntradaInvalida;
import co.enlaceexpress.dominio.reglas.EstadoIncorrecto;
import co.enlaceexpress.dominio.reglas.ReglaNegocioException;
import co.enlaceexpress.dominio.reglas.ReglasDeNegocio;

/** Salida de un mensajero con un vehiculo; agrupa las asignaciones (intentos de entrega) de sus envios. */
public class Despacho {

    private Long idDespacho;
    private final long idCentro;
    private final long idVehiculo;
    private final long idMensajero;
    private final LocalDate fecha;
    private final TipoDespacho tipo;
    private LocalDateTime horaSalida;
    private LocalDateTime horaCierre;
    private EstadoDespacho estado;
    private final List<AsignacionDespacho> asignaciones = new ArrayList<>();

    public Despacho(Long idDespacho, long idCentro, long idVehiculo, long idMensajero, LocalDate fecha, TipoDespacho tipo,
            LocalDateTime horaSalida, LocalDateTime horaCierre, EstadoDespacho estado) {
        this.idDespacho = idDespacho;
        this.idCentro = idCentro;
        this.idVehiculo = idVehiculo;
        this.idMensajero = idMensajero;
        this.fecha = fecha;
        this.tipo = tipo;
        this.horaSalida = horaSalida;
        this.horaCierre = horaCierre;
        this.estado = estado;
    }

    /**
     * Arma un despacho nuevo (ARMADO) verificando que el vehiculo este DISPONIBLE y el mensajero ACTIVO
     * (RN10) y que el vehiculo sea del tipo que conduce el mensajero (RN11).
     */
    public static Despacho armar(long idCentro, Vehiculo vehiculo, Mensajero mensajero, LocalDate fecha, TipoDespacho tipo) {
        ReglasDeNegocio.validarVehiculoYMensajero(vehiculo, mensajero);
        return new Despacho(null, idCentro, vehiculo.idVehiculo(), mensajero.idEmpleado(), fecha, tipo, null, null,
                EstadoDespacho.ARMADO);
    }

    /**
     * Asigna un envio a este despacho de entrega. El numero de intento es 1 mas los intentos previos; el
     * nuevo intento solo se crea si todos los anteriores terminaron en NOVEDAD, y no puede pasar del tercero (RN07).
     */
    public AsignacionDespacho asignar(Envio envio) {
        if (tipo != TipoDespacho.ENTREGA) {
            throw ReglaNegocioException.deDominio("RN07",
                    "el despacho " + idDespacho + " es de " + tipo + "; solo se asignan envios a despachos de ENTREGA");
        }
        if (!estaAbierto()) {
            throw ReglaNegocioException.deDominio("RN07", "el despacho " + idDespacho + " está CERRADO y no admite asignaciones");
        }
        int intento = envio.intentosRealizados() + 1;
        boolean previosEnNovedad = envio.intentos().stream().allMatch(a -> a.resultado() == ResultadoVisita.NOVEDAD);
        if (intento > 3 || !previosEnNovedad) {
            throw ReglaNegocioException.deDominio("RN07", "el intento " + intento + " de la guía " + envio.numeroGuia()
                    + " solo se crea si los " + (intento - 1) + " anteriores terminaron en NOVEDAD");
        }
        AsignacionDespacho asignacion = new AsignacionDespacho(null, envio.numeroGuia(),
                idDespacho == null ? 0 : idDespacho, intento, asignaciones.size() + 1, null, ResultadoVisita.PENDIENTE);
        asignaciones.add(asignacion);
        envio.agregarIntento(asignacion);
        return asignacion;
    }

    public void salir(LocalDateTime hora) {
        if (estado != EstadoDespacho.ARMADO) {
            throw new EstadoIncorrecto("Solo un despacho ARMADO puede salir; esta " + estado);
        }
        this.horaSalida = hora;
        this.estado = EstadoDespacho.EN_RUTA;
    }

    public void cerrar(LocalDateTime hora) {
        if (estado == EstadoDespacho.CERRADO) {
            throw new EstadoIncorrecto("El despacho " + idDespacho + " ya está CERRADO");
        }
        if (horaSalida != null && !hora.isAfter(horaSalida)) {
            throw new EntradaInvalida("horaCierre", "La hora de cierre debe ser posterior a la de salida");
        }
        this.horaCierre = hora;
        this.estado = EstadoDespacho.CERRADO;
    }

    public boolean estaAbierto() {
        return estado != EstadoDespacho.CERRADO;
    }

    public void asignarId(long id) {
        this.idDespacho = id;
    }

    public void cargarAsignaciones(List<AsignacionDespacho> lista) {
        asignaciones.clear();
        asignaciones.addAll(lista);
    }

    public Long idDespacho() { return idDespacho; }
    public long idCentro() { return idCentro; }
    public long idVehiculo() { return idVehiculo; }
    public long idMensajero() { return idMensajero; }
    public LocalDate fecha() { return fecha; }
    public TipoDespacho tipo() { return tipo; }
    public LocalDateTime horaSalida() { return horaSalida; }
    public LocalDateTime horaCierre() { return horaCierre; }
    public EstadoDespacho estado() { return estado; }
    public List<AsignacionDespacho> asignaciones() { return Collections.unmodifiableList(asignaciones); }
}
