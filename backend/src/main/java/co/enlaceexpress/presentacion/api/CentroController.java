package co.enlaceexpress.presentacion.api;

import java.math.BigDecimal;
import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import co.enlaceexpress.casosdeuso.centro.ServicioCentro;
import co.enlaceexpress.casosdeuso.centro.ServicioCentro.DespachoArmado;
import co.enlaceexpress.casosdeuso.centro.ServicioCentro.DespachoCerrado;
import co.enlaceexpress.casosdeuso.centro.ServicioCentro.EnvioRecibido;
import co.enlaceexpress.casosdeuso.centro.ServicioCentro.ResumenMensajero;
import co.enlaceexpress.casosdeuso.centro.ServicioCentro.ResumenVehiculo;
import co.enlaceexpress.casosdeuso.indicadores.FilaEnvioEstado;
import co.enlaceexpress.casosdeuso.indicadores.FilaPlanilla;
import co.enlaceexpress.casosdeuso.indicadores.FilaPorDespachar;
import co.enlaceexpress.casosdeuso.seguridad.UsuarioSesion;

/** API del centro de distribucion (U2), solo para el rol CENTRO. */
@RestController
@RequestMapping("/api/centro")
public class CentroController {

    public record Recepcion(BigDecimal pesoReal, BigDecimal valorFlete) {
    }

    public record DespachoNuevo(Long idMensajero, Long idVehiculo, List<String> guias) {
    }

    private final ServicioCentro centro;

    public CentroController(ServicioCentro centro) {
        this.centro = centro;
    }

    @GetMapping("/envios/recolectados")
    public List<FilaEnvioEstado> recolectados(@AuthenticationPrincipal UsuarioSesion usuario) {
        return centro.porRecibir(usuario);
    }

    /** CU06 y CU07. */
    @PostMapping("/envios/{guia}/recepcion")
    public EnvioRecibido recepcion(@AuthenticationPrincipal UsuarioSesion usuario, @PathVariable String guia, @RequestBody Recepcion r) {
        return centro.recibirYClasificar(usuario, guia, r.pesoReal(), r.valorFlete());
    }

    /** CU08. */
    @GetMapping("/por-despachar")
    public List<FilaPorDespachar> porDespachar(@AuthenticationPrincipal UsuarioSesion usuario) {
        return centro.porDespachar(usuario);
    }

    @GetMapping("/mensajeros")
    public List<ResumenMensajero> mensajeros(@AuthenticationPrincipal UsuarioSesion usuario) {
        return centro.mensajeros(usuario);
    }

    /** C9. */
    @GetMapping("/mensajeros/{id}/vehiculos")
    public List<ResumenVehiculo> vehiculos(@AuthenticationPrincipal UsuarioSesion usuario, @PathVariable long id) {
        return centro.vehiculosDisponibles(usuario, id);
    }

    /** CU09, CU10 y CU11. */
    @PostMapping("/despachos")
    public ResponseEntity<DespachoArmado> armarDespacho(@AuthenticationPrincipal UsuarioSesion usuario, @RequestBody DespachoNuevo d) {
        return ResponseEntity.status(HttpStatus.CREATED).body(centro.armarDespacho(usuario, d.idMensajero(), d.idVehiculo(), d.guias()));
    }

    /** C3. */
    @GetMapping("/despachos/{id}/planilla")
    public List<FilaPlanilla> planilla(@AuthenticationPrincipal UsuarioSesion usuario, @PathVariable long id) {
        return centro.planilla(usuario, id);
    }

    /** CU12. */
    @PostMapping("/despachos/{id}/cerrar")
    public DespachoCerrado cerrar(@AuthenticationPrincipal UsuarioSesion usuario, @PathVariable long id) {
        return centro.cerrar(usuario, id);
    }
}
