package co.enlaceexpress.dominio.despacho;

import java.time.LocalDateTime;

import co.enlaceexpress.dominio.enums.TipoPrueba;

/** Prueba de que el envio se entrego (o se devolvio): quien recibio y con que documento. */
public class PruebaEntrega {

    private Long idPrueba;
    private final LocalDateTime fechaHora;
    private final String nombreReceptor;
    private final String documentoReceptor;
    private final TipoPrueba tipoPrueba;
    private final String archivoSoporte;

    public PruebaEntrega(Long idPrueba, LocalDateTime fechaHora, String nombreReceptor, String documentoReceptor,
            TipoPrueba tipoPrueba, String archivoSoporte) {
        this.idPrueba = idPrueba;
        this.fechaHora = fechaHora;
        this.nombreReceptor = nombreReceptor;
        this.documentoReceptor = documentoReceptor;
        this.tipoPrueba = tipoPrueba;
        this.archivoSoporte = archivoSoporte;
    }

    public Long idPrueba() { return idPrueba; }
    public LocalDateTime fechaHora() { return fechaHora; }
    public String nombreReceptor() { return nombreReceptor; }
    public String documentoReceptor() { return documentoReceptor; }
    public TipoPrueba tipoPrueba() { return tipoPrueba; }
    public String archivoSoporte() { return archivoSoporte; }

    public void asignarId(long id) {
        this.idPrueba = id;
    }
}
