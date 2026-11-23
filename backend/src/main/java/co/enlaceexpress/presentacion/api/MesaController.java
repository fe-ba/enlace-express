package co.enlaceexpress.presentacion.api;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;

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

import co.enlaceexpress.casosdeuso.recoleccion.ServicioRecoleccion;
import co.enlaceexpress.casosdeuso.seguridad.UsuarioSesion;
import co.enlaceexpress.casosdeuso.servicioalcliente.ServicioMesa;
import co.enlaceexpress.casosdeuso.servicioalcliente.ServicioMesa.DatosEnvio;
import co.enlaceexpress.casosdeuso.servicioalcliente.ServicioMesa.DetalleEnvio;
import co.enlaceexpress.casosdeuso.servicioalcliente.ServicioMesa.EnvioAnulado;
import co.enlaceexpress.casosdeuso.servicioalcliente.ServicioMesa.EnvioRegistrado;
import co.enlaceexpress.casosdeuso.servicioalcliente.ServicioMesa.ResumenCliente;
import co.enlaceexpress.dominio.enums.FranjaHoraria;
import co.enlaceexpress.dominio.referencia.Modalidad;
import co.enlaceexpress.dominio.referencia.SedeCliente;
import co.enlaceexpress.dominio.referencia.Zona;

/** API de la mesa de servicio (U3), solo para el rol MESA. */
@RestController
@RequestMapping("/api/mesa")
public class MesaController {

    public record SolicitudNueva(Long idSede, LocalDate fechaProgramada, FranjaHoraria franjaHoraria) {
    }

    public record Anulacion(String observacion) {
    }

    private final ServicioMesa mesa;
    private final ServicioRecoleccion recoleccion;

    public MesaController(ServicioMesa mesa, ServicioRecoleccion recoleccion) {
        this.mesa = mesa;
        this.recoleccion = recoleccion;
    }

    @GetMapping("/clientes")
    public List<ResumenCliente> clientes(@AuthenticationPrincipal UsuarioSesion usuario,
            @RequestParam(defaultValue = "false") boolean todos) {
        return mesa.clientes(usuario, todos);
    }

    @GetMapping("/clientes/{id}/sedes")
    public List<SedeCliente> sedes(@AuthenticationPrincipal UsuarioSesion usuario, @PathVariable long id) {
        return mesa.sedes(usuario, id);
    }

    @GetMapping("/zonas")
    public List<Zona> zonas(@AuthenticationPrincipal UsuarioSesion usuario) {
        return mesa.zonas(usuario);
    }

    @GetMapping("/modalidades")
    public List<Modalidad> modalidades(@AuthenticationPrincipal UsuarioSesion usuario) {
        return mesa.modalidades(usuario);
    }

    /** CU01. */
    @PostMapping("/solicitudes")
    public ResponseEntity<Map<String, Long>> registrarSolicitud(@AuthenticationPrincipal UsuarioSesion usuario, @RequestBody SolicitudNueva s) {
        long id = recoleccion.registrarSolicitud(usuario, s.idSede(), s.fechaProgramada(), s.franjaHoraria());
        return ResponseEntity.status(HttpStatus.CREATED).body(Map.of("idSolicitud", id));
    }

    /** CU02, CU03 y CU04. */
    @PostMapping("/envios")
    public ResponseEntity<EnvioRegistrado> registrarEnvio(@AuthenticationPrincipal UsuarioSesion usuario, @RequestBody DatosEnvio datos) {
        return ResponseEntity.status(HttpStatus.CREATED).body(mesa.registrarEnvio(usuario, datos));
    }

    /** C1 y C2: datos del envio y su recorrido. */
    @GetMapping("/envios/{guia}")
    public DetalleEnvio envio(@AuthenticationPrincipal UsuarioSesion usuario, @PathVariable String guia) {
        return mesa.consultar(usuario, guia);
    }

    /** CU05: solo antes de salir a ruta (RN12). */
    @PostMapping("/envios/{guia}/anular")
    public EnvioAnulado anular(@AuthenticationPrincipal UsuarioSesion usuario, @PathVariable String guia,
            @RequestBody(required = false) Anulacion anulacion) {
        return mesa.anular(usuario, guia, anulacion == null ? null : anulacion.observacion());
    }
}
