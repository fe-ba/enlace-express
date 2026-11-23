package co.enlaceexpress.dominio.repositorios;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

import co.enlaceexpress.dominio.solicitud.SolicitudRecoleccion;

/** Persistencia de las solicitudes de recoleccion. */
public interface RepositorioSolicitud {

    Optional<SolicitudRecoleccion> buscarPorId(long idSolicitud);

    long insertar(SolicitudRecoleccion solicitud);

    void actualizarEstado(SolicitudRecoleccion solicitud);

    /** Solicitudes PENDIENTES o PROGRAMADAS para la fecha. */
    List<SolicitudRecoleccion> pendientes(LocalDate fecha);

    /** Agregado a lo del diagrama: bloquea la solicitud con SELECT ... FOR UPDATE. */
    boolean bloquearPorId(long idSolicitud);
}
