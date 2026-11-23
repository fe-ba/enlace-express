package co.enlaceexpress.datos.mapeadores;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.List;
import java.util.Set;

import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;

import co.enlaceexpress.datos.ConfiguracionPruebas;
import co.enlaceexpress.datos.infraestructura.FabricaConexiones;
import co.enlaceexpress.datos.infraestructura.UnidadDeTrabajo;
import co.enlaceexpress.dominio.enums.Rol;
import co.enlaceexpress.dominio.reglas.AccesoDenegado;
import co.enlaceexpress.dominio.reglas.DatoDuplicado;
import co.enlaceexpress.dominio.reglas.DatoInvalido;
import co.enlaceexpress.dominio.reglas.ReferenciaInexistente;
import co.enlaceexpress.dominio.reglas.ReglaNegocioException;

/**
 * Integracion contra el Oracle del compose, con la base recien instalada (database/install.sh).
 * Cada prueba que escribe termina deshaciendo, asi que no deja datos.
 */
class InfraestructuraJdbcIT {

    private static FabricaConexiones fabrica;
    private static FabricaConexiones fabricaDeUnaConexion;

    @BeforeAll
    static void abrir() {
        fabrica = new FabricaConexiones(ConfiguracionPruebas.propiedades(1, 3));
        fabricaDeUnaConexion = new FabricaConexiones(ConfiguracionPruebas.propiedades(1, 1));
    }

    @AfterAll
    static void cerrar() throws SQLException {
        fabrica.close();
        fabricaDeUnaConexion.close();
        restaurarSecuenciaDeGuias();
    }

    /** pr_registrar_envio consume la secuencia aunque se deshaga: se deja tras la ultima guia. */
    private static void restaurarSecuenciaDeGuias() throws SQLException {
        try (Connection c = ConfiguracionPruebas.conexionPropietario(); Statement st = c.createStatement();
                ResultSet rs = st.executeQuery("SELECT NVL(MAX(TO_NUMBER(SUBSTR(numero_guia, 3))), 0) + 1 FROM envio "
                        + "WHERE REGEXP_LIKE(numero_guia, '^EE[0-9]{13}$')")) {
            rs.next();
            long siguiente = rs.getLong(1);
            try (Statement alter = c.createStatement()) {
                alter.execute("ALTER SEQUENCE seq_numero_guia RESTART START WITH " + siguiente);
            }
        }
    }

    private static String texto(UnidadDeTrabajo uow, String sql) throws SQLException {
        try (Statement st = uow.conexion().createStatement(); ResultSet rs = st.executeQuery(sql)) {
            rs.next();
            return rs.getString(1);
        }
    }

    @Test
    void lasCincoCuentasConectanConElEsquemaYLaZonaHoraria() throws SQLException {
        for (Rol rol : Rol.values()) {
            try (UnidadDeTrabajo uow = new UnidadDeTrabajo(fabrica)) {
                uow.iniciar(rol, "prueba");
                assertThat(texto(uow, "SELECT SYS_CONTEXT('USERENV', 'SESSION_USER') FROM dual"))
                        .as("cuenta de %s", rol).isEqualToIgnoringCase(rol.cuentaServicio());
                assertThat(texto(uow, "SELECT SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA') FROM dual")).isEqualTo("BD_ENLACE_EXPRESS");
                assertThat(Set.of("America/Bogota", "-05:00")).contains(texto(uow, "SELECT SESSIONTIMEZONE FROM dual"));
            }
        }
    }

    @Test
    void elIdentificadorDeClienteEsElUsuarioDentroDeLaUnidadYVuelveANuloDespues() throws SQLException {
        try (UnidadDeTrabajo uow = new UnidadDeTrabajo(fabricaDeUnaConexion)) {
            uow.iniciar(Rol.MESA, "natalia.quintero");
            assertThat(texto(uow, "SELECT SYS_CONTEXT('USERENV', 'CLIENT_IDENTIFIER') FROM dual")).isEqualTo("natalia.quintero");
        }
        // el pool tiene una sola conexion: es la misma que se acaba de devolver
        try (Connection c = fabricaDeUnaConexion.obtener(Rol.MESA); Statement st = c.createStatement();
                ResultSet rs = st.executeQuery("SELECT SYS_CONTEXT('USERENV', 'CLIENT_IDENTIFIER') FROM dual")) {
            rs.next();
            assertThat(rs.getString(1)).isNull();
        }
    }

    @Test
    void deshacerDejaTodoIgualYCloseSinConfirmarTambien() {
        int antes;
        try (UnidadDeTrabajo uow = new UnidadDeTrabajo(fabrica)) {
            uow.iniciar(Rol.MESA, "prueba");
            MapeadorDePruebas mapeador = new MapeadorDePruebas(uow);
            antes = mapeador.contarDestinatarios();
            mapeador.insertarDestinatario("CC", "IT-DESHACER-1", "Prueba deshacer");
            assertThat(mapeador.contarDestinatarios()).isEqualTo(antes + 1);
            uow.deshacer();
            assertThat(mapeador.contarDestinatarios()).isEqualTo(antes);
            mapeador.insertarDestinatario("CC", "IT-DESHACER-2", "Prueba sin confirmar");
        } // sin confirmar: close deshace
        try (UnidadDeTrabajo uow = new UnidadDeTrabajo(fabrica)) {
            uow.iniciar(Rol.MESA, "prueba");
            assertThat(new MapeadorDePruebas(uow).contarDestinatarios()).isEqualTo(antes);
        }
    }

    @Test
    void confirmarHaceDurableElCambio() throws SQLException {
        try (UnidadDeTrabajo uow = new UnidadDeTrabajo(fabrica)) {
            uow.iniciar(Rol.MESA, "prueba");
            new MapeadorDePruebas(uow).insertarDestinatario("CC", "IT-CONFIRMAR", "Prueba confirmar");
            uow.confirmar();
        }
        try (UnidadDeTrabajo uow = new UnidadDeTrabajo(fabrica)) {
            uow.iniciar(Rol.MESA, "prueba");
            assertThat(new MapeadorDePruebas(uow).nombrePorDocumento("IT-CONFIRMAR")).contains("Prueba confirmar");
        }
        // el rol de la aplicacion no puede borrar (RN16): la limpieza la hace el propietario
        try (Connection c = ConfiguracionPruebas.conexionPropietario(); Statement st = c.createStatement()) {
            st.executeUpdate("DELETE FROM destinatario WHERE numero_documento = 'IT-CONFIRMAR'");
        }
    }

    @Test
    void consultarYConsultarUnoUsanVariablesDeEnlace() {
        try (UnidadDeTrabajo uow = new UnidadDeTrabajo(fabrica)) {
            uow.iniciar(Rol.MESA, "prueba");
            MapeadorDePruebas mapeador = new MapeadorDePruebas(uow);
            mapeador.insertarDestinatario("CE", "IT-BIND-1", "Zeta");
            mapeador.insertarDestinatario("CE", "IT-BIND-2", "Alfa");
            // un valor con comillas es un dato, no SQL
            mapeador.insertarDestinatario("CE", "IT-BIND-3", "O'Brien'; DROP TABLE envio; --");
            assertThat(mapeador.nombresPorTipo("CE")).contains("Alfa", "Zeta", "O'Brien'; DROP TABLE envio; --");
            assertThat(mapeador.nombrePorDocumento("IT-BIND-1")).contains("Zeta");
            assertThat(mapeador.nombrePorDocumento("NO-EXISTE")).isEmpty();
            assertThat(mapeador.nombrePorDocumento("1' OR '1'='1")).isEmpty();
            uow.deshacer();
        }
    }

    @Test
    void insertarConClaveDevuelveElIdGenerado() {
        try (UnidadDeTrabajo uow = new UnidadDeTrabajo(fabrica)) {
            uow.iniciar(Rol.MESA, "prueba");
            MapeadorDePruebas mapeador = new MapeadorDePruebas(uow);
            long a = mapeador.insertarDestinatario("CC", "IT-CLAVE-1", "Clave uno");
            long b = mapeador.insertarDestinatario("CC", "IT-CLAVE-2", "Clave dos");
            assertThat(a).isPositive();
            assertThat(b).isGreaterThan(a);
            uow.deshacer();
        }
    }

    @Test
    void unDisparadorLlegaComoReglaDeNegocioConSuCodigo() {
        try (UnidadDeTrabajo uow = new UnidadDeTrabajo(fabrica)) {
            uow.iniciar(Rol.MESA, "prueba");
            // la sede 7 es del cliente 4, INACTIVO (RN15)
            assertThatThrownBy(() -> new MapeadorDePruebas(uow).insertarSolicitud(7))
                    .isInstanceOfSatisfying(ReglaNegocioException.class, e -> {
                        assertThat(e.codigo()).isEqualTo("RN15");
                        assertThat(e.codigoOracle()).isEqualTo(20015);
                        assertThat(e.getMessage()).doesNotContain("ORA-").doesNotContain("RN15:");
                    });
        }
    }

    @Test
    void borrarSinPrivilegioLlegaComoAccesoDenegado() {
        try (UnidadDeTrabajo uow = new UnidadDeTrabajo(fabrica)) {
            uow.iniciar(Rol.MESA, "prueba");
            assertThatThrownBy(() -> new MapeadorDePruebas(uow).borrarEnvio("EE0000000000001"))
                    .isInstanceOf(AccesoDenegado.class);
        }
    }

    @Test
    void erroresDeRestriccionSeTraducen() {
        try (UnidadDeTrabajo uow = new UnidadDeTrabajo(fabrica)) {
            uow.iniciar(Rol.MESA, "prueba");
            MapeadorDePruebas mapeador = new MapeadorDePruebas(uow);
            mapeador.insertarDestinatario("CC", "IT-UK-1", "Primero");
            assertThatThrownBy(() -> mapeador.insertarDestinatario("CC", "IT-UK-1", "Repetido"))
                    .isInstanceOfSatisfying(DatoDuplicado.class, e -> assertThat(e.restriccion()).isEqualTo("DESTINATARIO_DOCUMENTO_UK"));
            assertThatThrownBy(() -> mapeador.insertarDestinatario("XX", "IT-CK-1", "Tipo invalido"))
                    .isInstanceOfSatisfying(DatoInvalido.class, e -> assertThat(e.restriccion()).isEqualTo("DESTINATARIO_TIPO_DOC_CK"));
            assertThatThrownBy(() -> mapeador.insertarSolicitud(99999))
                    .isInstanceOf(ReferenciaInexistente.class);
            uow.deshacer();
        }
    }

    @Test
    void llamarProcedimientoDevuelveLaGuiaGenerada() {
        try (UnidadDeTrabajo uow = new UnidadDeTrabajo(fabrica)) {
            uow.iniciar(Rol.MESA, "prueba");
            MapeadorDePruebas mapeador = new MapeadorDePruebas(uow);
            String guia = mapeador.registrarEnvio(mapeador.primeraSolicitud(), "IT-GUIA-1");
            assertThat(guia).matches("EE\\d{13}");
            assertThat(mapeador.nombrePorDocumento("IT-GUIA-1")).contains("Destinatario IT");
            uow.deshacer();
        }
    }

    @Test
    void laUnidadNoSePuedeIniciarDosVecesNiUsarseSinIniciar() {
        try (UnidadDeTrabajo uow = new UnidadDeTrabajo(fabrica)) {
            assertThatThrownBy(uow::conexion).isInstanceOf(IllegalStateException.class);
            uow.iniciar(Rol.CLIENTE, "prueba");
            assertThatThrownBy(() -> uow.iniciar(Rol.CLIENTE, "otro")).isInstanceOf(IllegalStateException.class);
        }
        assertThat(List.of(Rol.values())).hasSize(5);
    }
}
