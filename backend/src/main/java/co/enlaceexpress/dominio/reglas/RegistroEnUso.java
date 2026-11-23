package co.enlaceexpress.dominio.reglas;

/** La fila tiene filas dependientes (ORA-02292). */
public class RegistroEnUso extends ErrorDeDatos {

    public RegistroEnUso(String mensaje, int codigoOracle, String restriccion, Throwable causa) {
        super(mensaje, codigoOracle, restriccion, causa);
    }
}
