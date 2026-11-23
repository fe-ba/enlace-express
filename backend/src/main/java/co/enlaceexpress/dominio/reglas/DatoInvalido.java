package co.enlaceexpress.dominio.reglas;

/** El dato no cumple una restriccion CHECK, es nulo o excede su longitud (ORA-02290, ORA-01400, ORA-12899). */
public class DatoInvalido extends ErrorDeDatos {

    public DatoInvalido(String mensaje, int codigoOracle, String restriccion, Throwable causa) {
        super(mensaje, codigoOracle, restriccion, causa);
    }
}
