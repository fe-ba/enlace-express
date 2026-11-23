package co.enlaceexpress.presentacion.api;

import java.util.List;

import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import co.enlaceexpress.casosdeuso.indicadores.FilaPlanilla;
import co.enlaceexpress.casosdeuso.indicadores.FilaRecoleccion;
import co.enlaceexpress.casosdeuso.recoleccion.ServicioRecoleccion;
import co.enlaceexpress.casosdeuso.recoleccion.ServicioRecoleccion.Recoleccion;
import co.enlaceexpress.casosdeuso.ruta.ServicioRuta;
import co.enlaceexpress.casosdeuso.ruta.ServicioRuta.DatosNovedad;
import co.enlaceexpress.casosdeuso.ruta.ServicioRuta.DatosPrueba;
import co.enlaceexpress.casosdeuso.ruta.ServicioRuta.ResultadoAsignacion;
import co.enlaceexpress.casosdeuso.seguridad.UsuarioSesion;

/** API del mensajero (U4), solo para el rol MENSAJERO. */
@RestController
@RequestMapping("/api/mensajero")
public class MensajeroController {

    private final ServicioRecoleccion recoleccion;
    private final ServicioRuta ruta;

    public MensajeroController(ServicioRecoleccion recoleccion, ServicioRuta ruta) {
        this.recoleccion = recoleccion;
        this.ruta = ruta;
    }

    @GetMapping("/recolecciones")
    public List<FilaRecoleccion> recolecciones(@AuthenticationPrincipal UsuarioSesion usuario) {
        return recoleccion.pendientes(usuario);
    }

    /** CU15. */
    @PostMapping("/solicitudes/{id}/recolectar")
    public Recoleccion recolectar(@AuthenticationPrincipal UsuarioSesion usuario, @PathVariable long id) {
        return recoleccion.recolectar(usuario, id);
    }

    /** CU14. */
    @GetMapping("/planilla")
    public List<FilaPlanilla> planilla(@AuthenticationPrincipal UsuarioSesion usuario) {
        return ruta.planilla(usuario);
    }

    /** CU16 y CU19. */
    @PostMapping("/asignaciones/{id}/entrega")
    public ResultadoAsignacion entrega(@AuthenticationPrincipal UsuarioSesion usuario, @PathVariable long id, @RequestBody DatosPrueba datos) {
        return ruta.registrarEntrega(usuario, id, datos);
    }

    /** CU17. */
    @PostMapping("/asignaciones/{id}/novedad")
    public ResultadoAsignacion novedad(@AuthenticationPrincipal UsuarioSesion usuario, @PathVariable long id, @RequestBody DatosNovedad datos) {
        return ruta.registrarNovedad(usuario, id, datos);
    }

    /** CU18: solo en el tercer intento. */
    @PostMapping("/asignaciones/{id}/devolucion")
    public ResultadoAsignacion devolucion(@AuthenticationPrincipal UsuarioSesion usuario, @PathVariable long id, @RequestBody DatosPrueba datos) {
        return ruta.registrarDevolucion(usuario, id, datos);
    }
}
