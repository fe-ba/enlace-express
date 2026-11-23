package co.enlaceexpress.presentacion.api;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import co.enlaceexpress.casosdeuso.indicadores.FilaNovedadAbierta;
import co.enlaceexpress.casosdeuso.seguridad.UsuarioSesion;
import co.enlaceexpress.casosdeuso.servicioalcliente.FilaReclamacionMesa;
import co.enlaceexpress.casosdeuso.servicioalcliente.ServicioNovedades;
import co.enlaceexpress.casosdeuso.servicioalcliente.ServicioNovedades.NovedadGestionada;
import co.enlaceexpress.casosdeuso.servicioalcliente.ServicioReclamaciones;
import co.enlaceexpress.casosdeuso.servicioalcliente.ServicioReclamaciones.Cerrada;
import co.enlaceexpress.casosdeuso.servicioalcliente.ServicioReclamaciones.Radicada;
import co.enlaceexpress.casosdeuso.servicioalcliente.ServicioReclamaciones.Respondida;
import co.enlaceexpress.dominio.enums.AccionNovedad;
import co.enlaceexpress.dominio.enums.EstadoReclamacion;
import co.enlaceexpress.dominio.enums.TipoReclamacion;

/** Gestion de novedades (CU21) y reclamaciones (CU22 y CU23) de la mesa de servicio (U3), solo para el rol MESA. */
@RestController
@RequestMapping("/api/mesa")
public class MesaGestionController {

    public record GestionNovedad(AccionNovedad accion, String solucion) {
    }

    public record ReclamacionNueva(Long idCliente, String numeroGuia, TipoReclamacion tipo, String descripcion) {
    }

    public record RespuestaReclamacion(String respuesta) {
    }

    private final ServicioNovedades novedades;
    private final ServicioReclamaciones reclamaciones;

    public MesaGestionController(ServicioNovedades novedades, ServicioReclamaciones reclamaciones) {
        this.novedades = novedades;
        this.reclamaciones = reclamaciones;
    }

    /** I06: novedades abiertas. */
    @GetMapping("/novedades")
    public List<FilaNovedadAbierta> novedadesAbiertas(@AuthenticationPrincipal UsuarioSesion usuario) {
        return novedades.abiertas(usuario);
    }

    /** CU21: decide la accion, deja la solucion y cierra la novedad. */
    @PostMapping("/novedades/{id}/gestionar")
    public NovedadGestionada gestionarNovedad(@AuthenticationPrincipal UsuarioSesion usuario, @PathVariable long id,
            @RequestBody GestionNovedad gestion) {
        return novedades.gestionar(usuario, id, gestion.accion(), gestion.solucion());
    }

    /** Reclamaciones ABIERTAS (por defecto, con las horas desde la radicacion) o RESPONDIDAS por cerrar. */
    @GetMapping("/reclamaciones")
    public List<FilaReclamacionMesa> reclamaciones(@AuthenticationPrincipal UsuarioSesion usuario,
            @RequestParam(required = false) EstadoReclamacion estado) {
        return reclamaciones.listar(usuario, estado);
    }

    /** CU22. */
    @PostMapping("/reclamaciones")
    public ResponseEntity<Radicada> registrarReclamacion(@AuthenticationPrincipal UsuarioSesion usuario, @RequestBody ReclamacionNueva r) {
        return ResponseEntity.status(HttpStatus.CREATED).body(
                reclamaciones.registrar(usuario, r.idCliente(), r.numeroGuia(), r.tipo(), r.descripcion()));
    }

    /** CU23: responde una reclamacion abierta (RN14). */
    @PostMapping("/reclamaciones/{id}/responder")
    public Respondida responder(@AuthenticationPrincipal UsuarioSesion usuario, @PathVariable long id,
            @RequestBody RespuestaReclamacion respuesta) {
        return reclamaciones.responder(usuario, id, respuesta.respuesta());
    }

    /** Cierra una reclamacion ya respondida. */
    @PostMapping("/reclamaciones/{id}/cerrar")
    public Cerrada cerrar(@AuthenticationPrincipal UsuarioSesion usuario, @PathVariable long id) {
        return reclamaciones.cerrar(usuario, id);
    }
}
