package co.enlaceexpress.datos.infraestructura;

import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.SQLException;

import co.enlaceexpress.dominio.enums.Rol;
import co.enlaceexpress.dominio.reglas.ErrorDeDatos;

/**
 * Una transaccion: una conexion de la cuenta de servicio del rol, sin autocommit, compartida por
 * todos los mapeadores del caso de uso (se confirma o se deshace todo junto). No usa
 * {@code @Transactional}. Al abrirla fija el identificador de cliente de la sesion de Oracle con
 * el usuario real (A2), para que la base sepa quien hizo cada operacion. Se usa con
 * try-with-resources: si no se confirmo, {@link #close()} deshace.
 */
public class UnidadDeTrabajo implements AutoCloseable {

    private static final String SQL_FIJAR_IDENTIFICADOR = "{call DBMS_SESSION.SET_IDENTIFIER(?)}";
    private static final String SQL_LIMPIAR_IDENTIFICADOR = "{call DBMS_SESSION.CLEAR_IDENTIFIER}";

    private final FabricaConexiones fabrica;
    private final TraductorErroresOracle traductor = new TraductorErroresOracle();
    private Connection conexion;
    private boolean confirmada;

    public UnidadDeTrabajo(FabricaConexiones fabrica) {
        this.fabrica = fabrica;
    }

    /** Abre la transaccion con la cuenta de servicio del rol y a nombre del usuario. */
    public void iniciar(Rol rol, String usuario) {
        if (conexion != null) {
            throw new IllegalStateException("La unidad de trabajo ya esta iniciada");
        }
        try {
            conexion = fabrica.obtener(rol);
            conexion.setAutoCommit(false);
            try (CallableStatement cs = conexion.prepareCall(SQL_FIJAR_IDENTIFICADOR)) {
                cs.setString(1, usuario);
                cs.execute();
            }
        } catch (SQLException e) {
            cerrarConexion();
            throw traductor.traducir(e);
        }
    }

    public void confirmar() {
        try {
            conexion().commit();
            confirmada = true;
        } catch (SQLException e) {
            throw traductor.traducir(e);
        }
    }

    public void deshacer() {
        try {
            conexion().rollback();
        } catch (SQLException e) {
            throw traductor.traducir(e);
        }
    }

    /** Conexion de la transaccion; solo para los mapeadores. */
    public Connection conexion() {
        if (conexion == null) {
            throw new IllegalStateException("La unidad de trabajo no esta iniciada");
        }
        return conexion;
    }

    /** Deshace si no se confirmo, limpia el identificador del cliente y devuelve la conexion al pool. */
    @Override
    public void close() {
        if (conexion == null) {
            return;
        }
        try {
            if (!confirmada) {
                conexion.rollback();
            }
            try (CallableStatement cs = conexion.prepareCall(SQL_LIMPIAR_IDENTIFICADOR)) {
                cs.execute();
            }
            conexion.commit();
            conexion.setAutoCommit(true);
        } catch (SQLException e) {
            throw new ErrorDeDatos("No se pudo cerrar la unidad de trabajo: " + e.getMessage(), e.getErrorCode(), null, e);
        } finally {
            cerrarConexion();
        }
    }

    private void cerrarConexion() {
        if (conexion != null) {
            try {
                conexion.close();
            } catch (SQLException ignorada) {
                // la conexion ya estaba inservible; el pool la descarta
            }
            conexion = null;
        }
    }
}
