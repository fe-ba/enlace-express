package co.enlaceexpress.dominio.referencia;

import co.enlaceexpress.dominio.enums.EstadoActivo;
import co.enlaceexpress.dominio.reglas.Texto;

/**
 * Centro donde se reciben, clasifican y despachan los envios. No se borra (RN16): se inactiva por estado.
 * Las longitudes son las de la tabla CENTRO_DISTRIBUCION.
 */
public record CentroDistribucion(Long idCentro, String nombre, String direccion, String telefono, EstadoActivo estado) {

    public static final int MAXIMO_NOMBRE = 60;
    public static final int MAXIMO_DIRECCION = 120;
    public static final int MAXIMO_TELEFONO = 20;

    /** Centro nuevo: ACTIVO y con los textos validados. */
    public static CentroDistribucion nuevo(String nombre, String direccion, String telefono) {
        return new CentroDistribucion(null, Texto.obligatorio("nombre", "nombre", nombre, MAXIMO_NOMBRE),
                Texto.obligatorio("direccion", "dirección", direccion, MAXIMO_DIRECCION),
                Texto.opcional("telefono", "teléfono", telefono, MAXIMO_TELEFONO), EstadoActivo.ACTIVO);
    }

    /** El mismo centro con otros datos de contacto, validados; el estado no cambia. */
    public CentroDistribucion modificar(String nombre, String direccion, String telefono) {
        return new CentroDistribucion(idCentro, Texto.obligatorio("nombre", "nombre", nombre, MAXIMO_NOMBRE),
                Texto.obligatorio("direccion", "dirección", direccion, MAXIMO_DIRECCION),
                Texto.opcional("telefono", "teléfono", telefono, MAXIMO_TELEFONO), estado);
    }

    public CentroDistribucion conEstado(EstadoActivo nuevoEstado) {
        return new CentroDistribucion(idCentro, nombre, direccion, telefono, nuevoEstado);
    }

    public boolean estaActivo() {
        return estado == EstadoActivo.ACTIVO;
    }
}
