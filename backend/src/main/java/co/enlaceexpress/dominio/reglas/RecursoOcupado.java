package co.enlaceexpress.dominio.reglas;

/** La fila esta bloqueada por otra transaccion (ORA-00054). */
public class RecursoOcupado extends ErrorDeDatos {

    public RecursoOcupado(String mensaje, int codigoOracle, String restriccion, Throwable causa) {
        super(mensaje, codigoOracle, restriccion, causa);
    }
}
