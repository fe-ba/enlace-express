package co.enlaceexpress.presentacion.api;

/** Se superó el límite de consultas por IP: la API responde 429 con Retry-After. */
public class DemasiadasConsultas extends RuntimeException {

    private final long reintentarEnSegundos;

    public DemasiadasConsultas(long reintentarEnSegundos) {
        super("Demasiadas consultas desde su dirección; intente de nuevo en " + reintentarEnSegundos + " segundos");
        this.reintentarEnSegundos = reintentarEnSegundos;
    }

    public long reintentarEnSegundos() {
        return reintentarEnSegundos;
    }
}
