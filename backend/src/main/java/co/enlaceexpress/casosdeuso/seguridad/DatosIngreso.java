package co.enlaceexpress.casosdeuso.seguridad;

/** Lo que devuelve pkg_seguridad.datos_ingreso para el inicio de sesion. */
public record DatosIngreso(String hash, String rol, String estado, Long idEmpleado, Long idCliente) {

    public boolean estaActivo() {
        return "ACTIVO".equals(estado);
    }
}
