package co.enlaceexpress.casosdeuso.seguridad;

import java.util.Optional;

import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import co.enlaceexpress.datos.infraestructura.UnidadDeTrabajo;
import co.enlaceexpress.datos.mapeadores.UsuarioMapper;
import co.enlaceexpress.dominio.enums.Rol;

/**
 * Inicio de sesion con pkg_seguridad.datos_ingreso. Un usuario inexistente, INACTIVO (cuenta, empleado
 * retirado o cliente inactivo) o una contrasena erronea dan el mismo error, y en todos los casos se calcula
 * una comparacion BCrypt para que el tiempo de respuesta no revele si la cuenta existe.
 */
@Service
public class ServicioAutenticacion {

    public static final String MENSAJE_ERROR = "Usuario o contraseña incorrectos";

    private final FabricaUnidadesDeTrabajo unidades;
    private final PasswordEncoder codificador;
    private final String hashFalso;

    public ServicioAutenticacion(FabricaUnidadesDeTrabajo unidades, PasswordEncoder codificador) {
        this.unidades = unidades;
        this.codificador = codificador;
        this.hashFalso = codificador.encode("contrasena-inexistente-" + System.nanoTime());
    }

    public UsuarioSesion autenticar(String usuario, String contrasena) {
        if (usuario == null || contrasena == null || usuario.isBlank() || contrasena.isEmpty()
                || usuario.length() > 60 || contrasena.length() > 200) {
            codificador.matches("x", hashFalso);
            throw new BadCredentialsException(MENSAJE_ERROR);
        }
        try (UnidadDeTrabajo uow = unidades.publica()) {
            UsuarioMapper mapper = new UsuarioMapper(uow);
            Optional<DatosIngreso> datos = mapper.datosIngreso(usuario);
            boolean valido;
            if (datos.isEmpty() || !datos.get().estaActivo()) {
                codificador.matches(contrasena, hashFalso);
                valido = false;
            } else {
                valido = codificador.matches(contrasena, datos.get().hash());
            }
            if (!valido) {
                throw new BadCredentialsException(MENSAJE_ERROR);
            }
            mapper.registrarIngreso(usuario);
            uow.confirmar();
            DatosIngreso d = datos.get();
            return new UsuarioSesion(usuario, Rol.valueOf(d.rol()), d.idEmpleado(), d.idCliente());
        }
    }
}
