package co.enlaceexpress.dominio.referencia;

import co.enlaceexpress.dominio.reglas.EstadoIncorrecto;
import co.enlaceexpress.dominio.reglas.Texto;

/** Zona de reparto cubierta por un centro de distribucion. Las longitudes son las de la tabla ZONA. */
public record Zona(Long idZona, long idCentro, String nombre, String localidades) {

    public static final int MAXIMO_NOMBRE = 60;
    public static final int MAXIMO_LOCALIDADES = 200;

    /** Zona nueva de un centro: el centro debe estar ACTIVO. */
    public static Zona nueva(CentroDistribucion centro, String nombre, String localidades) {
        exigirCentroActivo(centro);
        return new Zona(null, centro.idCentro(), Texto.obligatorio("nombre", "nombre", nombre, MAXIMO_NOMBRE),
                Texto.obligatorio("localidades", "localidades", localidades, MAXIMO_LOCALIDADES));
    }

    /** La misma zona con otros datos y, si cambia de centro, el nuevo centro debe estar ACTIVO. */
    public Zona modificar(CentroDistribucion centro, String nombre, String localidades) {
        if (centro.idCentro() != idCentro) {
            exigirCentroActivo(centro);
        }
        return new Zona(idZona, centro.idCentro(), Texto.obligatorio("nombre", "nombre", nombre, MAXIMO_NOMBRE),
                Texto.obligatorio("localidades", "localidades", localidades, MAXIMO_LOCALIDADES));
    }

    private static void exigirCentroActivo(CentroDistribucion centro) {
        if (!centro.estaActivo()) {
            throw new EstadoIncorrecto("El centro " + centro.idCentro() + " está " + centro.estado() + "; solo se asignan zonas a un centro ACTIVO");
        }
    }
}
