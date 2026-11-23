package co.enlaceexpress.dominio.referencia;

/** Sede de un cliente donde se recogen los envios. */
public record SedeCliente(Long idSede, long idCliente, long idZona, String nombre, String direccion, String contacto, String telefono) {
}
