package co.enlaceexpress.presentacion.api;

import java.util.List;

import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import co.enlaceexpress.casosdeuso.indicadores.FilaConteo;
import co.enlaceexpress.casosdeuso.indicadores.FilaCumplimiento;
import co.enlaceexpress.casosdeuso.indicadores.FilaEnvioCliente;
import co.enlaceexpress.casosdeuso.indicadores.FilaReclamacion;
import co.enlaceexpress.casosdeuso.indicadores.ServicioIndicadores;
import co.enlaceexpress.casosdeuso.seguridad.UsuarioSesion;

/** Tablero de la gerencia (U1, rol GERENCIA) y lista de envios del portal de clientes (U9, rol CLIENTE). */
@RestController
public class TableroController {

    private final ServicioIndicadores indicadores;

    public TableroController(ServicioIndicadores indicadores) {
        this.indicadores = indicadores;
    }

    /** I04. */
    @GetMapping("/api/tablero/cumplimiento")
    public List<FilaCumplimiento> cumplimiento(@AuthenticationPrincipal UsuarioSesion usuario, @RequestParam(required = false) Long centro) {
        return indicadores.cumplimiento(usuario, centro);
    }

    /** I03. */
    @GetMapping("/api/tablero/envios-por-estado")
    public List<FilaConteo> enviosPorEstado(@AuthenticationPrincipal UsuarioSesion usuario, @RequestParam(required = false) Long centro) {
        return indicadores.enviosPorEstado(usuario, centro);
    }

    /** I07. */
    @GetMapping("/api/tablero/reclamaciones-pendientes")
    public List<FilaReclamacion> reclamaciones(@AuthenticationPrincipal UsuarioSesion usuario) {
        return indicadores.reclamacionesPendientes(usuario);
    }

    @GetMapping("/api/cliente/envios")
    public List<FilaEnvioCliente> enviosDelCliente(@AuthenticationPrincipal UsuarioSesion usuario) {
        return indicadores.enviosDelCliente(usuario);
    }
}
