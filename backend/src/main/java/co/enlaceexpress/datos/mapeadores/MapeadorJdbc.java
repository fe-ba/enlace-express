package co.enlaceexpress.datos.mapeadores;

import java.math.BigDecimal;
import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

import co.enlaceexpress.datos.infraestructura.ConversorTipos;
import co.enlaceexpress.datos.infraestructura.Salida;
import co.enlaceexpress.datos.infraestructura.TraductorErroresOracle;
import co.enlaceexpress.datos.infraestructura.UnidadDeTrabajo;

/**
 * Base de los mapeadores (Data Mapper sin ORM). Cada metodo ejecuta una sentencia SQL fija,
 * guardada como constante en la subclase, con PreparedStatement y variables de enlace: los valores
 * nunca se concatenan en el SQL. Todos usan la conexion de la unidad de trabajo y traducen los
 * errores de Oracle a excepciones del dominio.
 */
public abstract class MapeadorJdbc {

    protected final UnidadDeTrabajo uow;
    private final TraductorErroresOracle traductor = new TraductorErroresOracle();

    protected MapeadorJdbc(UnidadDeTrabajo uow) {
        this.uow = uow;
    }

    protected <T> List<T> consultar(String sql, Object[] params, MapeadorFila<T> fila) {
        try (PreparedStatement ps = uow.conexion().prepareStatement(sql)) {
            enlazar(ps, params);
            try (ResultSet rs = ps.executeQuery()) {
                List<T> filas = new ArrayList<>();
                while (rs.next()) {
                    filas.add(fila.mapear(rs));
                }
                return filas;
            }
        } catch (SQLException e) {
            throw traductor.traducir(e);
        }
    }

    /** La primera fila, si hay una. */
    protected <T> Optional<T> consultarUno(String sql, Object[] params, MapeadorFila<T> fila) {
        try (PreparedStatement ps = uow.conexion().prepareStatement(sql)) {
            enlazar(ps, params);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? Optional.ofNullable(fila.mapear(rs)) : Optional.empty();
            }
        } catch (SQLException e) {
            throw traductor.traducir(e);
        }
    }

    /** INSERT, UPDATE o DELETE; devuelve el numero de filas afectadas. */
    protected int ejecutar(String sql, Object[] params) {
        try (PreparedStatement ps = uow.conexion().prepareStatement(sql)) {
            enlazar(ps, params);
            return ps.executeUpdate();
        } catch (SQLException e) {
            throw traductor.traducir(e);
        }
    }

    /** INSERT en una tabla con columna de identidad; devuelve la clave generada (Oracle exige el nombre de la columna). */
    protected long insertarConClave(String sql, Object[] params, String columnaId) {
        try (PreparedStatement ps = uow.conexion().prepareStatement(sql, new String[] {columnaId})) {
            enlazar(ps, params);
            ps.executeUpdate();
            try (ResultSet claves = ps.getGeneratedKeys()) {
                if (!claves.next()) {
                    throw new IllegalStateException("Oracle no devolvio la clave generada de " + columnaId);
                }
                return claves.getLong(1);
            }
        } catch (SQLException e) {
            throw traductor.traducir(e);
        }
    }

    /**
     * Llama a un procedimiento con CallableStatement: {@code {call pr_x(?, ?, ?)}}. Los primeros
     * marcadores reciben {@code entradas}; si sobra uno (el ultimo) es un parametro OUT de texto y
     * su valor es el resultado. Sin parametro OUT devuelve nulo.
     */
    protected Object llamarProcedimiento(String llamada, Object[] entradas) {
        int marcadores = (int) llamada.chars().filter(c -> c == '?').count();
        boolean conSalida = marcadores == entradas.length + 1;
        try (CallableStatement cs = uow.conexion().prepareCall(llamada)) {
            enlazar(cs, entradas);
            if (conSalida) {
                cs.registerOutParameter(marcadores, Types.VARCHAR);
            }
            cs.execute();
            return conSalida ? cs.getString(marcadores) : null;
        } catch (SQLException e) {
            throw traductor.traducir(e);
        }
    }

    /**
     * Llama a un procedimiento o funcion con parametros de entrada y de salida mezclados, en el orden
     * de los marcadores: los valores son entradas y cada {@link Salida} marca un OUT. Devuelve los
     * valores de salida en el mismo orden (texto como String, numeros como Long o BigDecimal).
     * Para una funcion, la llamada es {@code {? = call paquete.funcion(?, ?)}} con {@code Salida.NUMERO} primero.
     */
    protected Object[] llamar(String llamada, Object... parametros) {
        try (CallableStatement cs = uow.conexion().prepareCall(llamada)) {
            for (int i = 0; i < parametros.length; i++) {
                if (parametros[i] instanceof Salida salida) {
                    cs.registerOutParameter(i + 1, salida == Salida.TEXTO ? Types.VARCHAR : Types.NUMERIC);
                } else {
                    enlazar(cs, i + 1, parametros[i]);
                }
            }
            cs.execute();
            List<Object> salidas = new ArrayList<>();
            for (int i = 0; i < parametros.length; i++) {
                if (parametros[i] instanceof Salida salida) {
                    if (salida == Salida.TEXTO) {
                        salidas.add(cs.getString(i + 1));
                    } else {
                        BigDecimal n = cs.getBigDecimal(i + 1);
                        salidas.add(n == null ? null : n.scale() <= 0 ? (Object) n.longValue() : n);
                    }
                }
            }
            return salidas.toArray();
        } catch (SQLException e) {
            throw traductor.traducir(e);
        }
    }

    /** Conexion de la unidad de trabajo, por si un mapeador necesita algo especial (por ejemplo lotes). */
    protected Connection conexion() {
        return uow.conexion();
    }

    private static void enlazar(PreparedStatement ps, Object[] params) throws SQLException {
        if (params == null) {
            return;
        }
        for (int i = 0; i < params.length; i++) {
            enlazar(ps, i + 1, params[i]);
        }
    }

    private static void enlazar(PreparedStatement ps, int posicion, Object valor) throws SQLException {
        if (valor == null) {
            ps.setNull(posicion, Types.NULL);
        } else if (valor instanceof Boolean b) {
            ps.setString(posicion, ConversorTipos.aSiNo(b));
        } else if (valor instanceof LocalDate d) {
            ps.setDate(posicion, ConversorTipos.aDate(d));
        } else if (valor instanceof LocalDateTime t) {
            ps.setTimestamp(posicion, ConversorTipos.aTimestamp(t));
        } else if (valor instanceof Enum<?> e) {
            ps.setString(posicion, e.name());
        } else {
            ps.setObject(posicion, valor);
        }
    }
}
