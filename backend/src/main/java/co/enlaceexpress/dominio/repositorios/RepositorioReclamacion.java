package co.enlaceexpress.dominio.repositorios;

import java.util.Optional;

import co.enlaceexpress.dominio.reclamacion.Reclamacion;

/** Lectura y escritura de las reclamaciones. */
public interface RepositorioReclamacion {

    Optional<Reclamacion> buscarPorId(long idReclamacion);

    /** Guarda una reclamacion nueva y le asigna su clave. */
    long insertar(Reclamacion reclamacion);

    /** Guarda la respuesta, su fecha y el estado. */
    void actualizarRespuesta(Reclamacion reclamacion);

    /** Agregado a lo del diagrama (C4): bloquea la reclamacion con SELECT ... FOR UPDATE; falso si no existe. */
    boolean bloquearPorId(long idReclamacion);

    /** Agregado a lo del diagrama: la guia existe y es de un envio de ese cliente (por la solicitud y su sede). */
    boolean guiaEsDelCliente(String numeroGuia, long idCliente);
}
