package co.enlaceexpress.dominio.repositorios;

import java.util.List;
import java.util.Optional;

import co.enlaceexpress.dominio.envio.Envio;
import co.enlaceexpress.dominio.envio.EventoEnvio;
import co.enlaceexpress.dominio.enums.EstadoEnvio;

/** Persistencia del agregado Envio. */
public interface RepositorioEnvio {

    /** El envio con su historial de eventos (sin destinatario ni intentos: se cargan aparte). */
    Optional<Envio> buscarPorGuia(String numeroGuia);

    /** Registra el envio con pr_registrar_envio (destinatario, envio y evento REGISTRADO); devuelve la guia generada. */
    String registrar(Envio envio);

    void agregarEvento(String numeroGuia, EventoEnvio evento);

    void actualizarClasificacion(Envio envio);

    /** C4: guias con evento CLASIFICADO que no estan en ninguna asignacion. */
    List<String> clasificadosSinAsignar();

    /** C10 para una guia: el estado de su evento mas reciente. */
    EstadoEnvio estadoActual(String numeroGuia);

    /** Agregado a lo del diagrama: guias de una solicitud de recoleccion. */
    List<String> guiasDeSolicitud(long idSolicitud);

    /** Agregado a lo del diagrama (C4 de concurrencia): bloquea la fila del envio con SELECT ... FOR UPDATE. */
    boolean bloquearPorGuia(String numeroGuia);
}
