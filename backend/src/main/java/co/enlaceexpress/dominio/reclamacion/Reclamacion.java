package co.enlaceexpress.dominio.reclamacion;

import java.time.LocalDateTime;

import co.enlaceexpress.dominio.enums.EstadoReclamacion;
import co.enlaceexpress.dominio.enums.TipoReclamacion;
import co.enlaceexpress.dominio.reglas.DatoInvalido;
import co.enlaceexpress.dominio.reglas.EntradaInvalida;
import co.enlaceexpress.dominio.reglas.EstadoIncorrecto;

/**
 * Reclamacion de un cliente, con o sin guia. Nace ABIERTA; la mesa de servicio la responde (RESPONDIDA, con
 * la fecha de respuesta) y despues la cierra. La regla RN14 exige que la respuesta sea posterior a la
 * radicacion; la base de datos la verifica de nuevo con el CHECK RECLAMACION_RESP_CK.
 */
public class Reclamacion {

    /** Meta de respuesta de la regla RN14, en horas. */
    public static final int META_HORAS = 4;

    public static final int MAXIMO_DESCRIPCION = 500;

    private Long idReclamacion;
    private final long idCliente;
    private final String numeroGuia;
    private final LocalDateTime fechaRadicacion;
    private final TipoReclamacion tipo;
    private final String descripcion;
    private String respuesta;
    private LocalDateTime fechaRespuesta;
    private EstadoReclamacion estado;

    public Reclamacion(Long idReclamacion, long idCliente, String numeroGuia, LocalDateTime fechaRadicacion,
            TipoReclamacion tipo, String descripcion, String respuesta, LocalDateTime fechaRespuesta, EstadoReclamacion estado) {
        this.idReclamacion = idReclamacion;
        this.idCliente = idCliente;
        this.numeroGuia = numeroGuia;
        this.fechaRadicacion = fechaRadicacion;
        this.tipo = tipo;
        this.descripcion = descripcion;
        this.respuesta = respuesta;
        this.fechaRespuesta = fechaRespuesta;
        this.estado = estado;
    }

    /** Reclamacion nueva: ABIERTA, con la fecha de radicacion dada. La guia es opcional. */
    public static Reclamacion radicar(long idCliente, String numeroGuia, TipoReclamacion tipo, String descripcion, LocalDateTime ahora) {
        if (tipo == null) {
            throw new EntradaInvalida("tipo", "El tipo es obligatorio (ENTREGA, DANO, FACTURACION u OTRO)");
        }
        String texto = descripcion == null ? "" : descripcion.strip();
        if (texto.isEmpty()) {
            throw new EntradaInvalida("descripcion", "La descripción es obligatoria");
        }
        if (texto.length() > MAXIMO_DESCRIPCION) {
            throw new EntradaInvalida("descripcion", "La descripción no puede pasar de " + MAXIMO_DESCRIPCION + " caracteres");
        }
        String guia = numeroGuia == null || numeroGuia.isBlank() ? null : numeroGuia.strip().toUpperCase();
        return new Reclamacion(null, idCliente, guia, ahora, tipo, texto, null, null, EstadoReclamacion.ABIERTA);
    }

    /**
     * Responde la reclamacion: solo si esta ABIERTA, con un texto, y RN14: la fecha de respuesta no puede ser
     * anterior a la de radicacion (mismo rechazo que daria el CHECK RECLAMACION_RESP_CK de la base).
     */
    public void responder(String texto, LocalDateTime ahora) {
        if (estado != EstadoReclamacion.ABIERTA) {
            throw new EstadoIncorrecto("La reclamación " + idReclamacion + " está " + estado + "; solo se responde una reclamación ABIERTA");
        }
        String limpio = texto == null ? "" : texto.strip();
        if (limpio.isEmpty()) {
            throw new EntradaInvalida("respuesta", "La respuesta es obligatoria");
        }
        if (limpio.length() > MAXIMO_DESCRIPCION) {
            throw new EntradaInvalida("respuesta", "La respuesta no puede pasar de " + MAXIMO_DESCRIPCION + " caracteres");
        }
        if (ahora.isBefore(fechaRadicacion)) {
            throw new DatoInvalido("RN14: la fecha de respuesta no puede ser anterior a la de radicación", 2290,
                    "RECLAMACION_RESP_CK", null);
        }
        this.respuesta = limpio;
        this.fechaRespuesta = ahora;
        this.estado = EstadoReclamacion.RESPONDIDA;
    }

    /** Cierra una reclamacion ya respondida. */
    public void cerrar() {
        if (estado != EstadoReclamacion.RESPONDIDA) {
            throw new EstadoIncorrecto("La reclamación " + idReclamacion + " está " + estado + "; solo se cierra una reclamación RESPONDIDA");
        }
        this.estado = EstadoReclamacion.CERRADA;
    }

    /** Horas entre la radicacion y la respuesta (o hasta {@code ahora} si aun no se responde). */
    public double horasDeRespuesta(LocalDateTime ahora) {
        LocalDateTime fin = fechaRespuesta != null ? fechaRespuesta : ahora;
        return java.time.Duration.between(fechaRadicacion, fin).toSeconds() / 3600.0;
    }

    public boolean superaLaMeta(LocalDateTime ahora) {
        return horasDeRespuesta(ahora) > META_HORAS;
    }

    public Long idReclamacion() { return idReclamacion; }
    public long idCliente() { return idCliente; }
    public String numeroGuia() { return numeroGuia; }
    public LocalDateTime fechaRadicacion() { return fechaRadicacion; }
    public TipoReclamacion tipo() { return tipo; }
    public String descripcion() { return descripcion; }
    public String respuesta() { return respuesta; }
    public LocalDateTime fechaRespuesta() { return fechaRespuesta; }
    public EstadoReclamacion estado() { return estado; }

    public void asignarId(long id) {
        this.idReclamacion = id;
    }
}
