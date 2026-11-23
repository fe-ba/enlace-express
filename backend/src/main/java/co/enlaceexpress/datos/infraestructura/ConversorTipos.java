package co.enlaceexpress.datos.infraestructura;

import java.sql.Date;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * Conversiones entre los tipos de Oracle y los del dominio (CHAR(1) S/N, DATE, TIMESTAMP).
 * La JVM y la base usan America/Bogota, asi que no hay desfase de zona.
 */
public final class ConversorTipos {

    private ConversorTipos() {
    }

    /** CHAR(1) 'S' -> verdadero; cualquier otro valor (N, nulo) -> falso. */
    public static boolean aBoolean(String valor) {
        return "S".equals(valor);
    }

    public static String aSiNo(boolean valor) {
        return valor ? "S" : "N";
    }

    public static LocalDate aFecha(Date valor) {
        return valor == null ? null : valor.toLocalDate();
    }

    public static LocalDateTime aInstante(Timestamp valor) {
        return valor == null ? null : valor.toLocalDateTime();
    }

    public static Date aDate(LocalDate valor) {
        return valor == null ? null : Date.valueOf(valor);
    }

    public static Timestamp aTimestamp(LocalDateTime valor) {
        return valor == null ? null : Timestamp.valueOf(valor);
    }

    /** Columna NUMBER que puede ser nula. */
    public static Long aLongONulo(ResultSet fila, String columna) throws SQLException {
        long valor = fila.getLong(columna);
        return fila.wasNull() ? null : valor;
    }

    /** Columna de texto con los valores de un enum (nula si la columna es nula). */
    public static <E extends Enum<E>> E aEnum(Class<E> tipo, String valor) {
        return valor == null ? null : Enum.valueOf(tipo, valor);
    }
}
