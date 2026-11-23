package co.enlaceexpress.datos.mapeadores;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.LinkedHashMap;
import java.util.Map;

import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;

import co.enlaceexpress.datos.ConfiguracionPruebas;
import co.enlaceexpress.datos.infraestructura.FabricaConexiones;
import co.enlaceexpress.datos.infraestructura.UnidadDeTrabajo;
import co.enlaceexpress.dominio.enums.EstadoEnvio;
import co.enlaceexpress.dominio.enums.Rol;
import co.enlaceexpress.dominio.referencia.Catalogos;

/** Los ids, nombres y el indicador de final de EstadoEnvio coinciden con la tabla ESTADO_ENVIO; y los catalogos se leen. */
class CatalogoEstadosIT {

    private static FabricaConexiones fabrica;

    @BeforeAll
    static void abrir() {
        fabrica = new FabricaConexiones(ConfiguracionPruebas.propiedades(1, 2));
    }

    @AfterAll
    static void cerrar() {
        fabrica.close();
    }

    /** Lector de prueba con SQL fijo (rol_centro si puede leer ESTADO_ENVIO; rol_mensajero no). */
    private static class LectorEstados extends MapeadorJdbc {
        private static final String SQL = "SELECT id_estado, nombre, es_final FROM estado_envio ORDER BY id_estado";

        LectorEstados(UnidadDeTrabajo uow) {
            super(uow);
        }

        Map<Integer, String[]> leer() {
            Map<Integer, String[]> estados = new LinkedHashMap<>();
            consultar(SQL, new Object[0], f -> estados.put(f.getInt(1), new String[] {f.getString(2), f.getString(3)}));
            return estados;
        }
    }

    @Test
    void elEnumCoincideConLaTablaEstadoEnvio() {
        try (UnidadDeTrabajo uow = new UnidadDeTrabajo(fabrica)) {
            uow.iniciar(Rol.CENTRO, "prueba");
            Map<Integer, String[]> tabla = new LectorEstados(uow).leer();
            assertThat(tabla).hasSize(EstadoEnvio.values().length);
            for (EstadoEnvio estado : EstadoEnvio.values()) {
                String[] fila = tabla.get(estado.idEstado());
                assertThat(fila).as("id %d", estado.idEstado()).isNotNull();
                assertThat(fila[0]).isEqualTo(estado.name());
                assertThat("S".equals(fila[1])).isEqualTo(estado.esFinal());
            }
        }
    }

    @Test
    void losCatalogosDeModalidadYTipoDeVehiculo() {
        try (UnidadDeTrabajo uow = new UnidadDeTrabajo(fabrica)) {
            uow.iniciar(Rol.MESA, "prueba");
            Catalogos catalogos = new ReferenciaMapper(uow).catalogos();
            assertThat(catalogos.modalidades()).extracting("nombre").containsExactly("MISMO_DIA", "DIA_SIGUIENTE", "ESTANDAR");
            assertThat(catalogos.modalidad(3).plazoDiasHabiles()).isEqualTo(3);
            assertThat(catalogos.tiposVehiculo()).extracting("nombre").containsExactly("MOTOCICLETA", "FURGONETA", "BICICLETA_ELECTRICA");
        }
    }
}
