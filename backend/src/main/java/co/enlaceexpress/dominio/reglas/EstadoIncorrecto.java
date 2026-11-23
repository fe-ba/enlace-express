package co.enlaceexpress.dominio.reglas;

/** La operacion no se puede hacer en el estado actual del objeto (por ejemplo cerrar un despacho ya cerrado): la API responde 409. */
public class EstadoIncorrecto extends RuntimeException {

    public EstadoIncorrecto(String mensaje) {
        super(mensaje);
    }
}
