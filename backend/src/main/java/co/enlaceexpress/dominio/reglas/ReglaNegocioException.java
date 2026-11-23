package co.enlaceexpress.dominio.reglas;

/**
 * Una regla de negocio (RN) o de la extension E1 rechazo la operacion: un disparador o un
 * paquete de la base de datos lanzo un error ORA-20000 a ORA-20999. El mensaje de Oracle
 * empieza con el codigo de la regla ("RN07: ..."); aqui el codigo y el texto van separados.
 */
public class ReglaNegocioException extends RuntimeException {

    private final String codigo;
    private final int codigoOracle;

    public ReglaNegocioException(String codigo, String mensaje, int codigoOracle, Throwable causa) {
        super(mensaje, causa);
        this.codigo = codigo;
        this.codigoOracle = codigoOracle;
    }

    /**
     * Regla incumplida detectada por el dominio antes de tocar la base. Usa el mismo codigo que daria
     * Oracle (RN07 -> 20007) para que la API responda igual venga de donde venga; las reglas sin
     * disparador (RN02, RN03) llevan codigoOracle 0.
     */
    public static ReglaNegocioException deDominio(String codigo, String mensaje) {
        int numero = codigo.matches("RN\\d{2}") ? Integer.parseInt(codigo.substring(2)) : 0;
        boolean conDisparador = numero == 5 || numero == 6 || numero == 7 || numero == 8 || numero == 10
                || numero == 11 || numero == 12 || numero == 15;
        return new ReglaNegocioException(codigo, mensaje, conDisparador ? 20000 + numero : 0, null);
    }

    /** Codigo de la regla: "RN07", "E1", ... o "ORA-20999" si el mensaje no trae uno. */
    public String codigo() {
        return codigo;
    }

    /** Numero del error de aplicacion (20007 para ORA-20007). */
    public int codigoOracle() {
        return codigoOracle;
    }
}
