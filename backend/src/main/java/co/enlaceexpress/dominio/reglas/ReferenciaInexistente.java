package co.enlaceexpress.dominio.reglas;

/** La fila referenciada no existe (ORA-02291). */
public class ReferenciaInexistente extends ErrorDeDatos {

    public ReferenciaInexistente(String mensaje, int codigoOracle, String restriccion, Throwable causa) {
        super(mensaje, codigoOracle, restriccion, causa);
    }
}
