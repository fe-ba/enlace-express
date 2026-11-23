package co.enlaceexpress.datos.infraestructura;

import static org.assertj.core.api.Assertions.assertThat;

import java.sql.SQLException;

import org.junit.jupiter.api.Test;

import co.enlaceexpress.dominio.reglas.AccesoDenegado;
import co.enlaceexpress.dominio.reglas.DatoDuplicado;
import co.enlaceexpress.dominio.reglas.DatoInvalido;
import co.enlaceexpress.dominio.reglas.ErrorDeDatos;
import co.enlaceexpress.dominio.reglas.RecursoOcupado;
import co.enlaceexpress.dominio.reglas.ReferenciaInexistente;
import co.enlaceexpress.dominio.reglas.RegistroEnUso;
import co.enlaceexpress.dominio.reglas.ReglaNegocioException;

class TraductorErroresOracleTest {

    private final TraductorErroresOracle traductor = new TraductorErroresOracle();

    private static SQLException oracle(int codigo, String mensaje) {
        return new SQLException(mensaje, "72000", codigo);
    }

    @Test
    void ora00001EsDatoDuplicadoConLaRestriccion() {
        RuntimeException r = traductor.traducir(oracle(1,
                "ORA-00001: unique constraint (BD_ENLACE_EXPRESS.DESTINATARIO_DOCUMENTO_UK) violated on table"));
        assertThat(r).isInstanceOf(DatoDuplicado.class);
        assertThat(((ErrorDeDatos) r).restriccion()).isEqualTo("DESTINATARIO_DOCUMENTO_UK");
        assertThat(((ErrorDeDatos) r).codigoOracle()).isEqualTo(1);
    }

    @Test
    void erroresDeValorInvalido() {
        assertThat(traductor.traducir(oracle(2290, "ORA-02290: check constraint (BD_ENLACE_EXPRESS.ENVIO_PESOS_CK) violated")))
                .isInstanceOf(DatoInvalido.class);
        assertThat(traductor.traducir(oracle(1400, "ORA-01400: cannot insert NULL into (\"BD_ENLACE_EXPRESS\".\"ENVIO\".\"CONTENIDO\")")))
                .isInstanceOf(DatoInvalido.class);
        assertThat(traductor.traducir(oracle(12899, "ORA-12899: value too large for column \"X\".\"NOMBRE\" (actual: 61, maximum: 60)")))
                .isInstanceOf(DatoInvalido.class);
    }

    @Test
    void erroresDeIntegridadReferencial() {
        RuntimeException hijo = traductor.traducir(oracle(2291, "ORA-02291: integrity constraint (BD_ENLACE_EXPRESS.ENVIO_ZONA_FK) violated - parent key not found"));
        assertThat(hijo).isInstanceOf(ReferenciaInexistente.class);
        assertThat(((ErrorDeDatos) hijo).restriccion()).isEqualTo("ENVIO_ZONA_FK");
        assertThat(traductor.traducir(oracle(2292, "ORA-02292: integrity constraint (X.Y_FK) violated - child record found")))
                .isInstanceOf(RegistroEnUso.class);
    }

    @Test
    void erroresDePrivilegios() {
        assertThat(traductor.traducir(oracle(942, "ORA-00942: table or view \"X\".\"ENVIO\" does not exist"))).isInstanceOf(AccesoDenegado.class);
        assertThat(traductor.traducir(oracle(1031, "ORA-01031: insufficient privileges"))).isInstanceOf(AccesoDenegado.class);
        assertThat(traductor.traducir(oracle(41900, "ORA-41900: missing DELETE privilege on \"X\".\"ENVIO\""))).isInstanceOf(AccesoDenegado.class);
    }

    @Test
    void ora00054EsRecursoOcupado() {
        assertThat(traductor.traducir(oracle(54, "ORA-00054: resource busy and acquire with NOWAIT specified or timeout expired")))
                .isInstanceOf(RecursoOcupado.class);
    }

    @Test
    void reglaDeNegocioConCodigoYMensajeLimpio() {
        String mensaje = "ORA-20007: RN07: el intento 2 de la guía EE0000000000023 solo se crea si los 1 anteriores terminaron en NOVEDAD\n"
                + "ORA-06512: at \"BD_ENLACE_EXPRESS.PKG_ERRORES\", line 4\n"
                + "ORA-06512: at \"BD_ENLACE_EXPRESS.TRG_ASIGNACION_INTENTO\", line 58\n"
                + "ORA-04088: error during execution of trigger 'BD_ENLACE_EXPRESS.TRG_ASIGNACION_INTENTO'\n"
                + "Help: https://docs.oracle.com/error-help/db/ora-20007/";
        RuntimeException r = traductor.traducir(oracle(20007, mensaje));
        assertThat(r).isInstanceOf(ReglaNegocioException.class);
        ReglaNegocioException regla = (ReglaNegocioException) r;
        assertThat(regla.codigo()).isEqualTo("RN07");
        assertThat(regla.codigoOracle()).isEqualTo(20007);
        assertThat(regla.getMessage()).isEqualTo("el intento 2 de la guía EE0000000000023 solo se crea si los 1 anteriores terminaron en NOVEDAD");
    }

    @Test
    void reglaDeLaExtensionE1() {
        RuntimeException r = traductor.traducir(oracle(20101,
                "ORA-20101: E1: los datos de registro o el código no son válidos\nORA-06512: at \"BD_ENLACE_EXPRESS.PKG_SEGURIDAD\", line 9"));
        ReglaNegocioException regla = (ReglaNegocioException) r;
        assertThat(regla.codigo()).isEqualTo("E1");
        assertThat(regla.getMessage()).isEqualTo("los datos de registro o el código no son válidos");
    }

    @Test
    void errorDeAplicacionSinCodigoDeReglaConservaElNumero() {
        ReglaNegocioException regla = (ReglaNegocioException) traductor.traducir(oracle(20999, "ORA-20999: algo inesperado"));
        assertThat(regla.codigo()).isEqualTo("ORA-20999");
        assertThat(regla.getMessage()).isEqualTo("algo inesperado");
    }

    @Test
    void limiteDelRangoDeReglas() {
        assertThat(traductor.traducir(oracle(20000, "ORA-20000: RN00: x"))).isInstanceOf(ReglaNegocioException.class);
        assertThat(traductor.traducir(oracle(21000, "ORA-21000: otro"))).isNotInstanceOf(ReglaNegocioException.class);
    }

    @Test
    void cualquierOtroErrorEsErrorDeDatos() {
        RuntimeException r = traductor.traducir(oracle(1722, "ORA-01722: invalid number"));
        assertThat(r.getClass()).isEqualTo(ErrorDeDatos.class);
        assertThat(r.getMessage()).isEqualTo("invalid number");
        assertThat(r.getCause()).isInstanceOf(SQLException.class);
    }

    @Test
    void mensajeNuloNoRompe() {
        assertThat(traductor.traducir(new SQLException((String) null, "08006", 17002)).getMessage()).isEmpty();
    }
}
