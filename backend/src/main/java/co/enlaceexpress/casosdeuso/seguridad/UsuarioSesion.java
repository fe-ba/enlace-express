package co.enlaceexpress.casosdeuso.seguridad;

import java.io.Serializable;

import co.enlaceexpress.dominio.enums.Rol;

/**
 * Usuario autenticado que guarda la sesion: el rol de la aplicacion elige la cuenta de servicio de Oracle
 * (usuario -> rol -> cuenta de servicio -> rol de la base de datos). Un empleado tiene idEmpleado y un
 * cliente tiene idCliente.
 */
public record UsuarioSesion(String usuario, Rol rol, Long idEmpleado, Long idCliente) implements Serializable {
}
