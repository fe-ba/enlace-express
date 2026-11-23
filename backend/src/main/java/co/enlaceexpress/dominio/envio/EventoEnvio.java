package co.enlaceexpress.dominio.envio;

import java.time.LocalDateTime;

import co.enlaceexpress.dominio.enums.EstadoEnvio;

/** Cambio de estado de un envio, con su responsable (RN13) y el instante en que ocurrio. */
public class EventoEnvio {

    private Long idEvento;
    private final EstadoEnvio estado;
    private final long idEmpleado;
    private final LocalDateTime fechaHora;
    private final String observacion;

    public EventoEnvio(Long idEvento, EstadoEnvio estado, long idEmpleado, LocalDateTime fechaHora, String observacion) {
        this.idEvento = idEvento;
        this.estado = estado;
        this.idEmpleado = idEmpleado;
        this.fechaHora = fechaHora;
        this.observacion = observacion;
    }

    public Long idEvento() { return idEvento; }
    public EstadoEnvio estado() { return estado; }
    public long idEmpleado() { return idEmpleado; }
    public LocalDateTime fechaHora() { return fechaHora; }
    public String observacion() { return observacion; }

    /** La asigna el mapeador al insertar (columna de identidad). */
    public void asignarId(long id) {
        this.idEvento = id;
    }
}
