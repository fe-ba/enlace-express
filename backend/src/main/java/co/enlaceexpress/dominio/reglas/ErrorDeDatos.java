package co.enlaceexpress.dominio.reglas;

/**
 * Error al acceder a los datos, ya traducido desde Oracle: el dominio y la API no
 * ven excepciones de JDBC. Las subclases son los casos con significado propio;
 * esta clase se usa tal cual para lo que no tiene una traduccion especifica.
 */
public class ErrorDeDatos extends RuntimeException {

    private final int codigoOracle;
    private final String restriccion;

    public ErrorDeDatos(String mensaje, int codigoOracle, String restriccion, Throwable causa) {
        super(mensaje, causa);
        this.codigoOracle = codigoOracle;
        this.restriccion = restriccion;
    }

    /** Numero del error de Oracle (por ejemplo 1 para ORA-00001). */
    public int codigoOracle() {
        return codigoOracle;
    }

    /** Nombre de la restriccion violada (sin el esquema), si el mensaje de Oracle la trae; si no, nulo. */
    public String restriccion() {
        return restriccion;
    }
}
