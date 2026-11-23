package co.enlaceexpress.datos.infraestructura;

/** Marca un parametro OUT al llamar a un procedimiento o funcion con MapeadorJdbc.llamar. */
public enum Salida {
    /** Texto (VARCHAR2). */
    TEXTO,
    /** Numero (NUMBER); se devuelve como Long si es entero o BigDecimal. */
    NUMERO
}
