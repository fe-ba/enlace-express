package co.enlaceexpress.dominio.enums;

/**
 * Estados del envio (catalogo ESTADO_ENVIO). Los ids son fijos y coinciden con
 * database/seed/01_catalogos.sql: rol_mensajero no puede leer la tabla, asi que el dominio
 * los conoce. Una prueba de integracion comprueba que no se desvian de la base.
 */
public enum EstadoEnvio {
    REGISTRADO(1, false),
    RECOLECTADO(2, false),
    EN_CENTRO(3, false),
    CLASIFICADO(4, false),
    EN_RUTA(5, false),
    ENTREGADO(6, true),
    CON_NOVEDAD(7, false),
    DEVUELTO(8, true),
    ANULADO(9, true);

    private final int idEstado;
    private final boolean esFinal;

    EstadoEnvio(int idEstado, boolean esFinal) {
        this.idEstado = idEstado;
        this.esFinal = esFinal;
    }

    public int idEstado() {
        return idEstado;
    }

    /** ENTREGADO, DEVUELTO y ANULADO: el envio ya no cambia de estado. */
    public boolean esFinal() {
        return esFinal;
    }

    public static EstadoEnvio porId(int idEstado) {
        for (EstadoEnvio e : values()) {
            if (e.idEstado == idEstado) {
                return e;
            }
        }
        throw new IllegalArgumentException("Estado de envio desconocido: " + idEstado);
    }
}
