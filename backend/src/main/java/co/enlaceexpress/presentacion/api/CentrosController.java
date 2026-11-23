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
import org.springframework.web.bind.annotation.RestController;

import co.enlaceexpress.casosdeuso.centro.ServicioCentros;
import co.enlaceexpress.casosdeuso.seguridad.UsuarioSesion;
import co.enlaceexpress.dominio.enums.EstadoActivo;
import co.enlaceexpress.dominio.referencia.CentroDistribucion;
import co.enlaceexpress.dominio.referencia.Zona;

/** CU13 Gestionar centros y zonas, solo para el rol CENTRO. Nada se borra: un centro se inactiva (RN16). */
@RestController
@RequestMapping("/api/centro")
public class CentrosController {

    public record DatosCentro(String nombre, String direccion, String telefono) {
    }

    public record CambioDeEstado(EstadoActivo estado) {
    }

    public record DatosZona(Long idCentro, String nombre, String localidades) {
    }

    private final ServicioCentros centros;

    public CentrosController(ServicioCentros centros) {
        this.centros = centros;
    }

    @GetMapping("/centros")
    public List<CentroDistribucion> centros(@AuthenticationPrincipal UsuarioSesion usuario) {
        return centros.centros(usuario);
    }

    @PostMapping("/centros")
    public ResponseEntity<CentroDistribucion> crearCentro(@AuthenticationPrincipal UsuarioSesion usuario, @RequestBody DatosCentro d) {
        return ResponseEntity.status(HttpStatus.CREATED).body(centros.crearCentro(usuario, d.nombre(), d.direccion(), d.telefono()));
    }

    @PostMapping("/centros/{id}/modificar")
    public CentroDistribucion modificarCentro(@AuthenticationPrincipal UsuarioSesion usuario, @PathVariable long id,
            @RequestBody DatosCentro d) {
        return centros.modificarCentro(usuario, id, d.nombre(), d.direccion(), d.telefono());
    }

    @PostMapping("/centros/{id}/estado")
    public CentroDistribucion cambiarEstado(@AuthenticationPrincipal UsuarioSesion usuario, @PathVariable long id,
            @RequestBody CambioDeEstado c) {
        return centros.cambiarEstado(usuario, id, c.estado());
    }

    @GetMapping("/zonas")
    public List<Zona> zonas(@AuthenticationPrincipal UsuarioSesion usuario) {
        return centros.zonas(usuario);
    }

    @PostMapping("/zonas")
    public ResponseEntity<Zona> crearZona(@AuthenticationPrincipal UsuarioSesion usuario, @RequestBody DatosZona d) {
        return ResponseEntity.status(HttpStatus.CREATED).body(centros.crearZona(usuario, d.idCentro(), d.nombre(), d.localidades()));
    }

    @PostMapping("/zonas/{id}/modificar")
    public Zona modificarZona(@AuthenticationPrincipal UsuarioSesion usuario, @PathVariable long id, @RequestBody DatosZona d) {
        return centros.modificarZona(usuario, id, d.idCentro(), d.nombre(), d.localidades());
    }
}
