package co.enlaceexpress.datos.mapeadores;

import java.util.Optional;

import co.enlaceexpress.casosdeuso.seguridad.DatosIngreso;
import co.enlaceexpress.datos.infraestructura.Salida;
import co.enlaceexpress.datos.infraestructura.UnidadDeTrabajo;

/**
 * Acceso de usuarios de la extension E1: solo llama a pkg_seguridad (las tablas USUARIO_APLICACION y
 * CODIGO_ACTIVACION no se conceden a ningun rol). Funciona con la cuenta de servicio del rol CLIENTE.
 */
public class UsuarioMapper extends MapeadorJdbc {

    private static final String SQL_DATOS_INGRESO = "{call pkg_seguridad.datos_ingreso(?, ?, ?, ?, ?, ?)}";
    private static final String SQL_REGISTRAR_EMPLEADO = "{? = call pkg_seguridad.registrar_empleado(?, ?, ?, ?)}";
    private static final String SQL_REGISTRAR_CLIENTE = "{? = call pkg_seguridad.registrar_cliente(?, ?, ?, ?)}";
    private static final String SQL_REGISTRAR_INGRESO = "{call pkg_seguridad.registrar_ingreso(?)}";

    public UsuarioMapper(UnidadDeTrabajo uow) {
        super(uow);
    }

    /** Vacio si el usuario no existe. */
    public Optional<DatosIngreso> datosIngreso(String usuario) {
        Object[] s = llamar(SQL_DATOS_INGRESO, usuario, Salida.TEXTO, Salida.TEXTO, Salida.TEXTO, Salida.NUMERO, Salida.NUMERO);
        if (s[0] == null) {
            return Optional.empty();
        }
        return Optional.of(new DatosIngreso((String) s[0], (String) s[1], (String) s[2], (Long) s[3], (Long) s[4]));
    }

    public long registrarEmpleado(String documento, String codigo, String usuario, String hash) {
        return (Long) llamar(SQL_REGISTRAR_EMPLEADO, Salida.NUMERO, documento, codigo, usuario, hash)[0];
    }

    public long registrarCliente(String nit, String codigo, String usuario, String hash) {
        return (Long) llamar(SQL_REGISTRAR_CLIENTE, Salida.NUMERO, nit, codigo, usuario, hash)[0];
    }

    public void registrarIngreso(String usuario) {
        llamar(SQL_REGISTRAR_INGRESO, usuario);
    }
}
