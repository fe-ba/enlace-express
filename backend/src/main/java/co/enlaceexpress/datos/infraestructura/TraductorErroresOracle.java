package co.enlaceexpress.datos.infraestructura;

import java.sql.SQLException;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import co.enlaceexpress.dominio.reglas.AccesoDenegado;
import co.enlaceexpress.dominio.reglas.DatoDuplicado;
import co.enlaceexpress.dominio.reglas.DatoInvalido;
import co.enlaceexpress.dominio.reglas.ErrorDeDatos;
import co.enlaceexpress.dominio.reglas.RecursoOcupado;
import co.enlaceexpress.dominio.reglas.ReferenciaInexistente;
import co.enlaceexpress.dominio.reglas.RegistroEnUso;
import co.enlaceexpress.dominio.reglas.ReglaNegocioException;

/**
 * Convierte un {@link SQLException} de Oracle en una excepcion del dominio. Los errores
 * ORA-20000 a ORA-20999 son los de las reglas de negocio (disparadores y paquetes): el mensaje
 * empieza con el codigo de la regla ("RN07: ...", "E1: ...").
 */
public class TraductorErroresOracle {

    /** "ORA-20007: " al comienzo del mensaje. */
    private static final Pattern PREFIJO_ORA = Pattern.compile("^ORA-\\d{5}:\\s*");
    /** "RN07: " o "E1: " al comienzo del mensaje de aplicacion. */
    private static final Pattern CODIGO_REGLA = Pattern.compile("^(RN\\d{2}|E\\d+):\\s*");
    /** "(BD_ENLACE_EXPRESS.ENVIO_PESOS_CK)" en los errores de restriccion. */
    private static final Pattern RESTRICCION = Pattern.compile("\\((?:[A-Za-z0-9_$#]+\\.)?([A-Za-z0-9_$#]+)\\)");

    public RuntimeException traducir(SQLException e) {
        int codigo = e.getErrorCode();
        String mensaje = limpiar(e.getMessage());
        String restriccion = restriccion(e.getMessage());
        if (codigo >= 20000 && codigo <= 20999) {
            return traducirRegla(codigo, mensaje, e);
        }
        return switch (codigo) {
            case 1 -> new DatoDuplicado(mensaje, codigo, restriccion, e);
            case 2290, 1400, 12899 -> new DatoInvalido(mensaje, codigo, restriccion, e);
            case 2291 -> new ReferenciaInexistente(mensaje, codigo, restriccion, e);
            case 2292 -> new RegistroEnUso(mensaje, codigo, restriccion, e);
            case 942, 1031, 41900 -> new AccesoDenegado(mensaje, codigo, restriccion, e);
            case 54 -> new RecursoOcupado(mensaje, codigo, restriccion, e);
            default -> new ErrorDeDatos(mensaje, codigo, restriccion, e);
        };
    }

    private ReglaNegocioException traducirRegla(int codigoOracle, String mensaje, SQLException causa) {
        Matcher regla = CODIGO_REGLA.matcher(mensaje);
        if (regla.find()) {
            return new ReglaNegocioException(regla.group(1), mensaje.substring(regla.end()), codigoOracle, causa);
        }
        return new ReglaNegocioException("ORA-" + codigoOracle, mensaje, codigoOracle, causa);
    }

    /** Quita el prefijo ORA-nnnnn y la pila (lineas ORA-06512, ORA-04088, ...). */
    static String limpiar(String mensajeOracle) {
        if (mensajeOracle == null) {
            return "";
        }
        String primera = mensajeOracle.strip();
        int salto = primera.indexOf("\nORA-");
        if (salto >= 0) {
            primera = primera.substring(0, salto);
        }
        // la ayuda que agrega el controlador ("Help: https://...") no es del mensaje
        int ayuda = primera.indexOf("\nHelp:");
        if (ayuda >= 0) {
            primera = primera.substring(0, ayuda);
        }
        return PREFIJO_ORA.matcher(primera.strip()).replaceFirst("").strip();
    }

    private static String restriccion(String mensajeOracle) {
        if (mensajeOracle == null) {
            return null;
        }
        Matcher m = RESTRICCION.matcher(mensajeOracle);
        return m.find() ? m.group(1) : null;
    }
}
