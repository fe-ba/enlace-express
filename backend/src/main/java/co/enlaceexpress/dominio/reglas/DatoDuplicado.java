package co.enlaceexpress.dominio.reglas;

/** Un valor unico ya existe (ORA-00001). */
public class DatoDuplicado extends ErrorDeDatos {

    public DatoDuplicado(String mensaje, int codigoOracle, String restriccion, Throwable causa) {
        super(mensaje, codigoOracle, restriccion, causa);
    }
}
