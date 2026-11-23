package co.enlaceexpress.dominio.reglas;

/** Lo que se pidio no existe (o no es visible para quien lo pidio): la API responde 404. */
public class RecursoNoEncontrado extends RuntimeException {

    public RecursoNoEncontrado(String mensaje) {
        super(mensaje);
    }
}
