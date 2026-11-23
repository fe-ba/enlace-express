package co.enlaceexpress.dominio.envio;

import co.enlaceexpress.dominio.enums.TipoDocumento;

/** Persona o empresa que recibe el envio; existe una sola vez por tipo y numero de documento (RN04). */
public record Destinatario(Long idDestinatario, TipoDocumento tipoDocumento, String numeroDocumento, String nombre,
        String telefono, String correo) {
}
