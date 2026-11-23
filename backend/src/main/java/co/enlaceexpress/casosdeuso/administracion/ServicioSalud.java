package co.enlaceexpress.casosdeuso.administracion;

import org.springframework.stereotype.Service;

import co.enlaceexpress.datos.infraestructura.FabricaConexiones;
import co.enlaceexpress.datos.infraestructura.UnidadDeTrabajo;
import co.enlaceexpress.datos.mapeadores.SaludMapper;
import co.enlaceexpress.datos.mapeadores.SaludMapper.EstadoBase;
import co.enlaceexpress.dominio.enums.Rol;

/** Comprueba la cadena completa: aplicacion, fabrica de conexiones, cuenta de servicio y Oracle. */
@Service
public class ServicioSalud {

    private final FabricaConexiones fabrica;

    public ServicioSalud(FabricaConexiones fabrica) {
        this.fabrica = fabrica;
    }

    /** Abre una unidad de trabajo con el rol CLIENTE (la cuenta de menor privilegio) y lee el estado de la base. */
    public EstadoBase estadoDeLaBase() {
        try (UnidadDeTrabajo uow = new UnidadDeTrabajo(fabrica)) {
            uow.iniciar(Rol.CLIENTE, "salud");
            return new SaludMapper(uow).estado();
        }
    }
}
