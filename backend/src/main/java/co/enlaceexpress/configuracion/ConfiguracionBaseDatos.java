package co.enlaceexpress.configuracion;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import co.enlaceexpress.datos.infraestructura.FabricaConexiones;

/** Crea la fabrica de conexiones (un pool por rol); Spring la cierra al apagar la aplicacion. */
@Configuration
public class ConfiguracionBaseDatos {

    @Bean(destroyMethod = "close")
    public FabricaConexiones fabricaConexiones(PropiedadesBaseDatos propiedades) {
        return new FabricaConexiones(propiedades);
    }
}
