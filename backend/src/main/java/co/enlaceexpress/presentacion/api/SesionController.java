package co.enlaceexpress.presentacion.api;

import java.util.List;
import java.util.Map;

import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContext;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.web.context.SecurityContextRepository;
import org.springframework.security.web.csrf.CsrfToken;
import org.springframework.security.web.csrf.CsrfTokenRepository;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import co.enlaceexpress.casosdeuso.seguridad.ServicioAutenticacion;
import co.enlaceexpress.casosdeuso.seguridad.UsuarioSesion;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

/** Sesion en el servidor: iniciar, consultar y cerrar, mas el token CSRF para el frontend. */
@RestController
@RequestMapping("/api")
public class SesionController {

    /** Cuerpo de POST /api/sesion. */
    public record SolicitudSesion(String usuario, String contrasena) {
    }

    /** Lo que el frontend necesita saber del usuario de la sesion. */
    public record RespuestaSesion(String usuario, String rol, Long idEmpleado, Long idCliente) {
        static RespuestaSesion de(UsuarioSesion u) {
            return new RespuestaSesion(u.usuario(), u.rol().name(), u.idEmpleado(), u.idCliente());
        }
    }

    private final ServicioAutenticacion autenticacion;
    private final SecurityContextRepository repositorioDeContexto;
    private final CsrfTokenRepository repositorioCsrf;

    public SesionController(ServicioAutenticacion autenticacion, SecurityContextRepository repositorioDeContexto,
            CsrfTokenRepository repositorioCsrf) {
        this.autenticacion = autenticacion;
        this.repositorioDeContexto = repositorioDeContexto;
        this.repositorioCsrf = repositorioCsrf;
    }

    /** Entrega el token CSRF (y deja la cookie XSRF-TOKEN) antes del primer POST. */
    @GetMapping("/csrf")
    public Map<String, String> csrf(CsrfToken token) {
        return Map.of("encabezado", token.getHeaderName(), "token", token.getToken());
    }

    @PostMapping("/sesion")
    public RespuestaSesion iniciar(@RequestBody SolicitudSesion solicitud, HttpServletRequest peticion, HttpServletResponse respuesta) {
        UsuarioSesion usuario = autenticacion.autenticar(solicitud.usuario(), solicitud.contrasena());
        var autenticado = UsernamePasswordAuthenticationToken.authenticated(usuario, null,
                List.of(new SimpleGrantedAuthority("ROLE_" + usuario.rol().name())));
        SecurityContext contexto = SecurityContextHolder.createEmptyContext();
        contexto.setAuthentication(autenticado);
        SecurityContextHolder.setContext(contexto);
        // contra la fijacion de sesion: id nuevo si ya habia una sesion
        if (peticion.getSession(false) != null) {
            peticion.changeSessionId();
        } else {
            peticion.getSession(true);
        }
        repositorioDeContexto.saveContext(contexto, peticion, respuesta);
        // token CSRF nuevo para la sesion autenticada
        repositorioCsrf.saveToken(repositorioCsrf.generateToken(peticion), peticion, respuesta);
        return RespuestaSesion.de(usuario);
    }

    /** El usuario de la sesion actual; sin sesion la cadena de seguridad responde 401. */
    @GetMapping("/sesion")
    public RespuestaSesion actual(@AuthenticationPrincipal UsuarioSesion usuario) {
        return RespuestaSesion.de(usuario);
    }

    @PostMapping("/sesion/cerrar")
    public ResponseEntity<Void> cerrar(HttpServletRequest peticion) {
        HttpSession sesion = peticion.getSession(false);
        if (sesion != null) {
            sesion.invalidate();
        }
        SecurityContextHolder.clearContext();
        return ResponseEntity.noContent().build();
    }
}
