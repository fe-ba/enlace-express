package co.enlaceexpress.casosdeuso.servicioalcliente;

import java.util.List;

import org.springframework.stereotype.Service;

import co.enlaceexpress.casosdeuso.indicadores.FilaNovedadAbierta;
import co.enlaceexpress.casosdeuso.seguridad.FabricaUnidadesDeTrabajo;
import co.enlaceexpress.casosdeuso.seguridad.UsuarioSesion;
import co.enlaceexpress.datos.informes.InformesMapper;
import co.enlaceexpress.datos.infraestructura.UnidadDeTrabajo;
import co.enlaceexpress.datos.mapeadores.NovedadMapper;
import co.enlaceexpress.dominio.despacho.Novedad;
import co.enlaceexpress.dominio.enums.AccionNovedad;
import co.enlaceexpress.dominio.enums.Rol;
import co.enlaceexpress.dominio.reglas.RecursoNoEncontrado;

/**
 * CU21 Gestionar novedad (U3, T10): la mesa de servicio ve las novedades abiertas (I06) y decide la accion, deja la
 * solucion y cierra la novedad. La operacion es una transaccion con SELECT ... FOR UPDATE de la novedad.
 */
@Service
public class ServicioNovedades {

    public record NovedadGestionada(long idNovedad, String accion, String estado) {
    }

    private final FabricaUnidadesDeTrabajo unidades;

    public ServicioNovedades(FabricaUnidadesDeTrabajo unidades) {
        this.unidades = unidades;
    }

    /** I06: novedades abiertas con los datos de contacto, por hora de la visita. */
    public List<FilaNovedadAbierta> abiertas(UsuarioSesion usuario) {
        try (UnidadDeTrabajo uow = unidades.para(usuario, Rol.MESA)) {
            return new InformesMapper(uow).novedadesAbiertas();
        }
    }

    /** Rechazos: novedad inexistente (404), ya cerrada (409), accion o solucion invalidas (400). */
    public NovedadGestionada gestionar(UsuarioSesion usuario, long idNovedad, AccionNovedad accion, String solucion) {
        try (UnidadDeTrabajo uow = unidades.para(usuario, Rol.MESA)) {
            NovedadMapper novedades = new NovedadMapper(uow);
            if (!novedades.bloquearPorId(idNovedad)) {
                throw new RecursoNoEncontrado("No se encontró la novedad " + idNovedad);
            }
            Novedad novedad = novedades.porId(idNovedad).orElseThrow();
            novedad.gestionarYCerrar(accion, solucion);
            novedades.actualizarGestion(novedad);
            uow.confirmar();
            return new NovedadGestionada(idNovedad, novedad.accion().name(), novedad.estado().name());
        }
    }
}
