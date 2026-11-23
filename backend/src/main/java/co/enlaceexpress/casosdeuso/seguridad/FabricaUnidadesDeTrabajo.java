package co.enlaceexpress.casosdeuso.seguridad;

import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.authentication.AuthenticationCredentialsNotFoundException;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;

import co.enlaceexpress.datos.infraestructura.FabricaConexiones;
import co.enlaceexpress.datos.infraestructura.UnidadDeTrabajo;
import co.enlaceexpress.dominio.enums.Rol;

/**
 * Abre la unidad de trabajo de un caso de uso con el rol y el usuario reales de la sesion (decisiones 12.1 y
 * A2): la cuenta de servicio del rol decide los permisos y Oracle sabe quien hizo cada operacion
 * (CLIENT_IDENTIFIER). Los casos de uso la usan con try-with-resources.
 */
@Component
public class FabricaUnidadesDeTrabajo {

    /** Identificador de cliente de las operaciones sin sesion (rastreo, registro e inicio de sesion). */
    public static final String USUARIO_PUBLICO = "publico";

    private final FabricaConexiones conexiones;

    public FabricaUnidadesDeTrabajo(FabricaConexiones conexiones) {
        this.conexiones = conexiones;
    }

    /** Unidad del usuario de la sesion actual; falla si no hay sesion. */
    public UnidadDeTrabajo delUsuarioActual() {
        return para(usuarioActual());
    }

    /** Unidad del usuario, verificando que tenga el rol que exige la operacion (ademas de la regla de la ruta). */
    public UnidadDeTrabajo para(UsuarioSesion usuario, Rol rolExigido) {
        if (usuario.rol() != rolExigido) {
            throw new AccessDeniedException("La operacion es del rol " + rolExigido);
        }
        return para(usuario);
    }

    public UnidadDeTrabajo para(UsuarioSesion usuario) {
        UnidadDeTrabajo uow = new UnidadDeTrabajo(conexiones);
        uow.iniciar(usuario.rol(), usuario.usuario());
        return uow;
    }

    /** Unidad para las operaciones publicas: cuenta de menor privilegio (CLIENTE) e identificador "publico". */
    public UnidadDeTrabajo publica() {
        UnidadDeTrabajo uow = new UnidadDeTrabajo(conexiones);
        uow.iniciar(Rol.CLIENTE, USUARIO_PUBLICO);
        return uow;
    }

    public static UsuarioSesion usuarioActual() {
        Authentication autenticacion = SecurityContextHolder.getContext().getAuthentication();
        if (autenticacion == null || !(autenticacion.getPrincipal() instanceof UsuarioSesion usuario)) {
            throw new AuthenticationCredentialsNotFoundException("No hay una sesion iniciada");
        }
        return usuario;
    }
}
