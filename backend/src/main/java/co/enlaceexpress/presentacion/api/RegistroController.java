package co.enlaceexpress.presentacion.api;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import co.enlaceexpress.casosdeuso.seguridad.ServicioRegistro;
import co.enlaceexpress.casosdeuso.seguridad.ServicioRegistro.UsuarioRegistrado;

/** Registro con codigo de activacion: empleados (documento) y clientes (NIT). El rol no se elige: lo deriva la base. */
@RestController
@RequestMapping("/api/registro")
public class RegistroController {

    public record RegistroEmpleado(String documento, String codigo, String usuario, String contrasena) {
    }

    public record RegistroCliente(String nit, String codigo, String usuario, String contrasena) {
    }

    private final ServicioRegistro servicio;

    public RegistroController(ServicioRegistro servicio) {
        this.servicio = servicio;
    }

    @PostMapping("/empleado")
    public ResponseEntity<UsuarioRegistrado> empleado(@RequestBody RegistroEmpleado s) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(servicio.registrarEmpleado(s.documento(), s.codigo(), s.usuario(), s.contrasena()));
    }

    @PostMapping("/cliente")
    public ResponseEntity<UsuarioRegistrado> cliente(@RequestBody RegistroCliente s) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(servicio.registrarCliente(s.nit(), s.codigo(), s.usuario(), s.contrasena()));
    }
}
