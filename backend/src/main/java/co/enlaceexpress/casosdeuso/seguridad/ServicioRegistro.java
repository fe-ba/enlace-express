package co.enlaceexpress.casosdeuso.seguridad;

import java.nio.charset.StandardCharsets;
import java.util.regex.Pattern;

import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import co.enlaceexpress.datos.infraestructura.UnidadDeTrabajo;
import co.enlaceexpress.datos.mapeadores.UsuarioMapper;
import co.enlaceexpress.dominio.reglas.EntradaInvalida;

/**
 * Registro con codigo de activacion (decision D1). Valida la contrasena, calcula el hash BCrypt (la base
 * nunca ve la contrasena) y llama a pkg_seguridad con la cuenta CLIENTE en una unidad de trabajo que se
 * confirma. Los errores E1 de la base llegan como ReglaNegocioException.
 */
@Service
public class ServicioRegistro {

    private static final Pattern USUARIO = Pattern.compile("[A-Za-z0-9._-]{3,60}");
    private static final Pattern TIENE_LETRA = Pattern.compile(".*\\p{L}.*", Pattern.DOTALL);
    private static final Pattern TIENE_NUMERO = Pattern.compile(".*\\d.*", Pattern.DOTALL);

    /** Cuenta creada: el nombre de usuario y el rol que la base derivo. */
    public record UsuarioRegistrado(String usuario, String rol) {
    }

    private final FabricaUnidadesDeTrabajo unidades;
    private final PasswordEncoder codificador;

    public ServicioRegistro(FabricaUnidadesDeTrabajo unidades, PasswordEncoder codificador) {
        this.unidades = unidades;
        this.codificador = codificador;
    }

    public UsuarioRegistrado registrarEmpleado(String documento, String codigo, String usuario, String contrasena) {
        exigir("documento", documento);
        exigir("codigo", codigo);
        validarUsuarioYContrasena(usuario, contrasena);
        String hash = codificador.encode(contrasena);
        try (UnidadDeTrabajo uow = unidades.publica()) {
            UsuarioMapper mapper = new UsuarioMapper(uow);
            mapper.registrarEmpleado(documento.strip(), codigo.strip(), usuario.strip(), hash);
            return confirmar(uow, mapper, usuario.strip());
        }
    }

    public UsuarioRegistrado registrarCliente(String nit, String codigo, String usuario, String contrasena) {
        exigir("nit", nit);
        exigir("codigo", codigo);
        validarUsuarioYContrasena(usuario, contrasena);
        String hash = codificador.encode(contrasena);
        try (UnidadDeTrabajo uow = unidades.publica()) {
            UsuarioMapper mapper = new UsuarioMapper(uow);
            mapper.registrarCliente(nit.strip(), codigo.strip(), usuario.strip(), hash);
            return confirmar(uow, mapper, usuario.strip());
        }
    }

    private static UsuarioRegistrado confirmar(UnidadDeTrabajo uow, UsuarioMapper mapper, String usuario) {
        String rol = mapper.datosIngreso(usuario).map(DatosIngreso::rol).orElseThrow();
        uow.confirmar();
        return new UsuarioRegistrado(usuario, rol);
    }

    private static void exigir(String campo, String valor) {
        if (valor == null || valor.isBlank()) {
            throw new EntradaInvalida(campo, "El campo " + campo + " es obligatorio");
        }
        if (valor.length() > 100) {
            throw new EntradaInvalida(campo, "El campo " + campo + " es demasiado largo");
        }
    }

    private static void validarUsuarioYContrasena(String usuario, String contrasena) {
        exigir("usuario", usuario);
        if (!USUARIO.matcher(usuario.strip()).matches()) {
            throw new EntradaInvalida("usuario", "El usuario debe tener de 3 a 60 caracteres: letras, numeros, punto, guion o guion bajo");
        }
        if (contrasena == null || contrasena.length() < 8) {
            throw new EntradaInvalida("contrasena", "La contraseña debe tener al menos 8 caracteres");
        }
        // BCrypt solo usa los primeros 72 bytes
        if (contrasena.getBytes(StandardCharsets.UTF_8).length > 72) {
            throw new EntradaInvalida("contrasena", "La contraseña no puede pasar de 72 bytes");
        }
        if (!TIENE_LETRA.matcher(contrasena).matches() || !TIENE_NUMERO.matcher(contrasena).matches()) {
            throw new EntradaInvalida("contrasena", "La contraseña debe tener al menos una letra y un número");
        }
    }
}
