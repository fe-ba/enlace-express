package co.enlaceexpress.casosdeuso.indicadores;

import java.util.List;

import org.springframework.stereotype.Service;

import co.enlaceexpress.casosdeuso.seguridad.FabricaUnidadesDeTrabajo;
import co.enlaceexpress.casosdeuso.seguridad.UsuarioSesion;
import co.enlaceexpress.datos.informes.InformesMapper;
import co.enlaceexpress.datos.infraestructura.UnidadDeTrabajo;
import co.enlaceexpress.dominio.enums.Rol;

/** Tablero de la gerencia (U1: cumplimiento, envios por estado y reclamaciones pendientes) y lista de envios del cliente (U9). */
@Service
public class ServicioIndicadores {

    private final FabricaUnidadesDeTrabajo unidades;

    public ServicioIndicadores(FabricaUnidadesDeTrabajo unidades) {
        this.unidades = unidades;
    }

    /** I04: cumplimiento de entregas por zona; con {@code idCentro} nulo, de todos los centros. */
    public List<FilaCumplimiento> cumplimiento(UsuarioSesion usuario, Long idCentro) {
        try (UnidadDeTrabajo uow = unidades.para(usuario, Rol.GERENCIA)) {
            return new InformesMapper(uow).cumplimiento(idCentro);
        }
    }

    /** I03: envios por estado actual. */
    public List<FilaConteo> enviosPorEstado(UsuarioSesion usuario, Long idCentro) {
        try (UnidadDeTrabajo uow = unidades.para(usuario, Rol.GERENCIA)) {
            return new InformesMapper(uow).enviosPorEstado(idCentro);
        }
    }

    /** I07: reclamaciones pendientes, de la mas antigua a la mas reciente. */
    public List<FilaReclamacion> reclamacionesPendientes(UsuarioSesion usuario) {
        try (UnidadDeTrabajo uow = unidades.para(usuario, Rol.GERENCIA)) {
            return new InformesMapper(uow).reclamacionesPendientes();
        }
    }

    /** U9: los envios de la empresa del cliente de la sesion, con su estado actual. */
    public List<FilaEnvioCliente> enviosDelCliente(UsuarioSesion usuario) {
        try (UnidadDeTrabajo uow = unidades.para(usuario, Rol.CLIENTE)) {
            return new InformesMapper(uow).enviosDeCliente(usuario.idCliente());
        }
    }
}
