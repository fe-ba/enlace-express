package co.enlaceexpress.dominio.enums;

/**
 * Rol de la aplicacion. Cada rol trabaja con su cuenta de servicio de Oracle
 * (decision 12.1): usuario -> rol -> cuenta de servicio -> rol de la base de datos.
 */
public enum Rol {
    GERENCIA("svc_gerencia", "rol_gerencia"),
    CENTRO("svc_centro", "rol_centro"),
    MESA("svc_mesa", "rol_mesa"),
    MENSAJERO("svc_mensajero", "rol_mensajero"),
    CLIENTE("svc_cliente", "rol_cliente");

    private final String cuentaServicio;
    private final String rolBaseDatos;

    Rol(String cuentaServicio, String rolBaseDatos) {
        this.cuentaServicio = cuentaServicio;
        this.rolBaseDatos = rolBaseDatos;
    }

    /** Nombre de la cuenta de servicio de Oracle de este rol. */
    public String cuentaServicio() {
        return cuentaServicio;
    }

    /** Nombre del rol de la base de datos que tiene esa cuenta. */
    public String rolBaseDatos() {
        return rolBaseDatos;
    }
}
