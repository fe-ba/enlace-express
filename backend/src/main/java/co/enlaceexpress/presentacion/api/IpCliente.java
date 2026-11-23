package co.enlaceexpress.presentacion.api;

import jakarta.servlet.http.HttpServletRequest;

/**
 * Direccion IP del cliente. Por defecto la del socket. Detras de un proxy de confianza (Caddy) se toma la
 * ultima direccion de X-Forwarded-For, que es la que ese proxy agrego; las anteriores las puede escribir
 * cualquiera, asi que nunca se usan.
 */
final class IpCliente {

    private IpCliente() {
    }

    static String de(HttpServletRequest peticion, boolean confiarEnProxy) {
        if (confiarEnProxy) {
            String reenviadas = peticion.getHeader("X-Forwarded-For");
            if (reenviadas != null && !reenviadas.isBlank()) {
                String[] partes = reenviadas.split(",");
                return partes[partes.length - 1].strip();
            }
        }
        return peticion.getRemoteAddr();
    }
}
