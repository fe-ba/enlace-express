package co.enlaceexpress.dominio.reglas;

/** La cuenta de servicio no tiene privilegios para la operacion (ORA-00942, ORA-01031, ORA-41900). */
public class AccesoDenegado extends ErrorDeDatos {

    public AccesoDenegado(String mensaje, int codigoOracle, String restriccion, Throwable causa) {
        super(mensaje, codigoOracle, restriccion, causa);
    }
}
