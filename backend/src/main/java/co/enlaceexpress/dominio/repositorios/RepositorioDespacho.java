package co.enlaceexpress.dominio.repositorios;

import java.util.List;
import java.util.Optional;

import co.enlaceexpress.dominio.despacho.AsignacionDespacho;
import co.enlaceexpress.dominio.despacho.Despacho;
import co.enlaceexpress.dominio.referencia.Vehiculo;

/** Persistencia del agregado Despacho y sus asignaciones. */
public interface RepositorioDespacho {

    /** El despacho con sus asignaciones (sin pruebas ni novedades). */
    Optional<Despacho> buscarPorId(long idDespacho);

    long insertar(Despacho despacho);

    long guardarAsignacion(Despacho despacho, AsignacionDespacho asignacion);

    /** Actualiza resultado y hora de visita de la asignacion, e inserta su prueba o novedad si es nueva. */
    void guardarResultado(AsignacionDespacho asignacion);

    void actualizarEstado(Despacho despacho);

    /** C9: vehiculos DISPONIBLES del tipo que conduce el mensajero. */
    List<Vehiculo> vehiculosDisponibles(long idMensajero);

    /** Agregado a lo del diagrama: bloquea el despacho con SELECT ... FOR UPDATE. */
    boolean bloquearPorId(long idDespacho);

    /** Agregado a lo del diagrama: los intentos de entrega de una guia (para RN07). */
    List<AsignacionDespacho> asignacionesDeGuia(String numeroGuia);

    /** Agregado a lo del diagrama: una asignacion (sin su prueba ni novedad; ver cargarPruebaYNovedad). */
    Optional<AsignacionDespacho> buscarAsignacion(long idAsignacion);

    /** Agregado a lo del diagrama: lee la prueba y la novedad de la asignacion; exige SELECT sobre esas tablas (no lo tiene rol_centro). */
    void cargarPruebaYNovedad(AsignacionDespacho asignacion);

    /** Agregado a lo del diagrama: bloquea la asignacion con SELECT ... FOR UPDATE. */
    boolean bloquearAsignacion(long idAsignacion);
}
