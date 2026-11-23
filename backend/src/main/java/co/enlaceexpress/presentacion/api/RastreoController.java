package co.enlaceexpress.presentacion.api;

import java.util.List;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RestController;

import co.enlaceexpress.casosdeuso.indicadores.FilaSeguimiento;
import co.enlaceexpress.casosdeuso.seguridad.UsuarioSesion;
import co.enlaceexpress.casosdeuso.servicioalcliente.Rastreo;
import co.enlaceexpress.casosdeuso.servicioalcliente.ServicioRastreo;
import co.enlaceexpress.configuracion.PropiedadesRastreo;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.security.core.annotation.AuthenticationPrincipal;

/** CU20: rastreo publico por guia (sin cuenta, con limite por IP) y seguimiento completo del cliente con sesion. */
@RestController
public class RastreoController {

    private final ServicioRastreo servicio;
    private final LimitadorDeConsultas limitador;
    private final PropiedadesRastreo propiedades;

    public RastreoController(ServicioRastreo servicio, LimitadorDeConsultas limitador, PropiedadesRastreo propiedades) {
        this.servicio = servicio;
        this.limitador = limitador;
        this.propiedades = propiedades;
    }

    /** Solo fecha, estado y zona de cada evento (D2). */
    @GetMapping("/api/publico/rastreo/{guia}")
    public Rastreo rastreoPublico(@PathVariable String guia, HttpServletRequest peticion) {
        long espera = limitador.intentar(IpCliente.de(peticion, propiedades.confiarEnProxy()));
        if (espera > 0) {
            throw new DemasiadasConsultas(espera);
        }
        return servicio.rastreoPublico(guia);
    }

    /** Recorrido completo de un envio de la empresa del cliente de la sesion; las demas guias dan 404. */
    @GetMapping("/api/cliente/envios/{guia}/seguimiento")
    public List<FilaSeguimiento> seguimientoDelCliente(@PathVariable String guia, @AuthenticationPrincipal UsuarioSesion cliente) {
        return servicio.seguimientoDeCliente(cliente, guia);
    }
}
