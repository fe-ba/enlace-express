package co.enlaceexpress.dominio.solicitud;

import java.time.LocalDate;

import co.enlaceexpress.dominio.despacho.Despacho;
import co.enlaceexpress.dominio.enums.EstadoSolicitud;
import co.enlaceexpress.dominio.enums.FranjaHoraria;
import co.enlaceexpress.dominio.referencia.Cliente;
import co.enlaceexpress.dominio.referencia.SedeCliente;
import co.enlaceexpress.dominio.reglas.DatoInvalido;
import co.enlaceexpress.dominio.reglas.EstadoIncorrecto;
import co.enlaceexpress.dominio.reglas.ReglasDeNegocio;

/** Pedido de un cliente para que un mensajero recoja envios en una de sus sedes. */
public class SolicitudRecoleccion {

    private Long idSolicitud;
    private final long idSede;
    private Long idDespacho;
    private final LocalDate fechaSolicitud;
    private final LocalDate fechaProgramada;
    private final FranjaHoraria franjaHoraria;
    private EstadoSolicitud estado;

    public SolicitudRecoleccion(Long idSolicitud, long idSede, Long idDespacho, LocalDate fechaSolicitud,
            LocalDate fechaProgramada, FranjaHoraria franjaHoraria, EstadoSolicitud estado) {
        this.idSolicitud = idSolicitud;
        this.idSede = idSede;
        this.idDespacho = idDespacho;
        this.fechaSolicitud = fechaSolicitud;
        this.fechaProgramada = fechaProgramada;
        this.franjaHoraria = franjaHoraria;
        this.estado = estado;
    }

    /** Solicitud nueva (PENDIENTE); solo se registra si el cliente dueño de la sede esta activo (RN15). */
    public static SolicitudRecoleccion registrar(SedeCliente sede, Cliente cliente, LocalDate fechaSolicitud,
            LocalDate fechaProgramada, FranjaHoraria franja) {
        ReglasDeNegocio.validarClienteActivo(cliente);
        if (fechaProgramada.isBefore(fechaSolicitud)) {
            throw new DatoInvalido("la fecha programada no puede ser anterior a la de la solicitud", 2290,
                    "SOLICITUD_FECHAS_CK", null);
        }
        return new SolicitudRecoleccion(null, sede.idSede(), null, fechaSolicitud, fechaProgramada, franja,
                EstadoSolicitud.PENDIENTE);
    }

    /** Asigna el despacho de recoleccion y la deja PROGRAMADA. */
    public void programar(Despacho despacho) {
        this.idDespacho = despacho.idDespacho();
        this.estado = EstadoSolicitud.PROGRAMADA;
    }

    public void marcarAtendida() {
        if (estado == EstadoSolicitud.ATENDIDA) {
            throw new EstadoIncorrecto("La solicitud " + idSolicitud + " ya fue atendida");
        }
        this.estado = EstadoSolicitud.ATENDIDA;
    }

    public void asignarId(long id) {
        this.idSolicitud = id;
    }

    public Long idSolicitud() { return idSolicitud; }
    public long idSede() { return idSede; }
    public Long idDespacho() { return idDespacho; }
    public LocalDate fechaSolicitud() { return fechaSolicitud; }
    public LocalDate fechaProgramada() { return fechaProgramada; }
    public FranjaHoraria franjaHoraria() { return franjaHoraria; }
    public EstadoSolicitud estado() { return estado; }
}
