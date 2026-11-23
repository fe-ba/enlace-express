package co.enlaceexpress.dominio.reglas;

/** Un dato de entrada no cumple el formato o la politica (por ejemplo una contrasena debil): la API responde 400. */
public class EntradaInvalida extends RuntimeException {

    private final String campo;

    public EntradaInvalida(String campo, String mensaje) {
        super(mensaje);
        this.campo = campo;
    }

    /** Nombre del campo de la solicitud que no es valido. */
    public String campo() {
        return campo;
    }
}
