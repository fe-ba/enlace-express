package co.enlaceexpress.dominio.despacho;

import java.time.LocalDateTime;

import co.enlaceexpress.dominio.envio.Envio;
import co.enlaceexpress.dominio.enums.ResultadoVisita;
import co.enlaceexpress.dominio.reglas.ReglaNegocioException;

/**
 * Intento de entrega de un envio en un despacho (1 y 2: entrega; 3: devolucion). Registra su resultado
 * verificando RN05 (prueba), RN06 (documento de quien recibe), RN07 (intentos) y RN08 (un resultado por intento).
 */
public class AsignacionDespacho {

    private Long idAsignacion;
    private final String numeroGuia;
    private final long idDespacho;
    private final int numeroIntento;
    private final int ordenVisita;
    private LocalDateTime horaVisita;
    private ResultadoVisita resultado;
    private PruebaEntrega prueba;
    private Novedad novedad;
    private Envio envio;

    public AsignacionDespacho(Long idAsignacion, String numeroGuia, long idDespacho, int numeroIntento, int ordenVisita,
            LocalDateTime horaVisita, ResultadoVisita resultado) {
        this.idAsignacion = idAsignacion;
        this.numeroGuia = numeroGuia;
        this.idDespacho = idDespacho;
        this.numeroIntento = numeroIntento;
        this.ordenVisita = ordenVisita;
        this.horaVisita = horaVisita;
        this.resultado = resultado;
    }

    public boolean estaPendiente() {
        return resultado == ResultadoVisita.PENDIENTE;
    }

    /** Entrega en el intento 1 o 2 con su prueba; el intento 3 solo puede terminar en DEVUELTO. */
    public void registrarEntrega(PruebaEntrega prueba) {
        exigirPendiente();
        if (numeroIntento >= 3) {
            throw ReglaNegocioException.deDominio("RN07", "el intento 3 solo puede terminar en DEVUELTO, no en ENTREGADO");
        }
        aceptarPrueba(prueba, ResultadoVisita.ENTREGADO);
    }

    /** Novedad en el intento 1 o 2; el intento 3 solo puede terminar en DEVUELTO. */
    public void registrarNovedad(Novedad novedad) {
        exigirPendiente();
        if (numeroIntento >= 3) {
            throw ReglaNegocioException.deDominio("RN07", "el intento 3 solo puede terminar en DEVUELTO, no en NOVEDAD");
        }
        if (novedad == null) {
            throw ReglaNegocioException.deDominio("RN08", "la asignación " + idAsignacion + " no puede quedar en NOVEDAD sin la novedad registrada");
        }
        this.novedad = novedad;
        this.resultado = ResultadoVisita.NOVEDAD;
    }

    /** Devolucion: solo en el tercer intento, con su prueba. */
    public void registrarDevolucion(PruebaEntrega prueba) {
        exigirPendiente();
        if (numeroIntento != 3) {
            throw ReglaNegocioException.deDominio("RN07",
                    "DEVUELTO solo es posible en el intento 3 (esta asignación es el intento " + numeroIntento + ")");
        }
        aceptarPrueba(prueba, ResultadoVisita.DEVUELTO);
    }

    private void exigirPendiente() {
        if (!estaPendiente()) {
            throw ReglaNegocioException.deDominio("RN08",
                    "el intento " + numeroIntento + " de la guía " + numeroGuia + " ya tiene resultado " + resultado
                            + "; cada intento tiene una sola prueba o novedad");
        }
    }

    private void aceptarPrueba(PruebaEntrega prueba, ResultadoVisita nuevoResultado) {
        if (prueba == null) {
            throw ReglaNegocioException.deDominio("RN05",
                    "la asignación " + idAsignacion + " no puede quedar " + nuevoResultado + " sin prueba de entrega");
        }
        verificarDocumentoDeQuienRecibe(prueba);
        this.prueba = prueba;
        this.resultado = nuevoResultado;
        this.horaVisita = prueba.fechaHora();
    }

    /** RN06: envio fragil o de alto valor, el documento de quien recibe es el del destinatario. */
    private void verificarDocumentoDeQuienRecibe(PruebaEntrega prueba) {
        if (envio == null || !envio.exigeDocumentoDestinatario()) {
            return;
        }
        if (envio.destinatario() == null) {
            throw new IllegalStateException("Falta el destinatario del envio " + numeroGuia + " para verificar RN06");
        }
        if (!envio.destinatario().numeroDocumento().equals(prueba.documentoReceptor())) {
            throw ReglaNegocioException.deDominio("RN06", "el envío es frágil o de alto valor y solo se entrega al destinatario; "
                    + "el documento de quien recibe no coincide con el del destinatario");
        }
    }

    public void asignarId(long id) {
        this.idAsignacion = id;
    }

    public void asignarEnvio(Envio envio) {
        this.envio = envio;
    }

    /** Las carga el mapeador cuando se leen de la base. */
    public void cargarPrueba(PruebaEntrega prueba) {
        this.prueba = prueba;
    }

    public void cargarNovedad(Novedad novedad) {
        this.novedad = novedad;
    }

    public Long idAsignacion() { return idAsignacion; }
    public String numeroGuia() { return numeroGuia; }
    public long idDespacho() { return idDespacho; }
    public int numeroIntento() { return numeroIntento; }
    public int ordenVisita() { return ordenVisita; }
    public LocalDateTime horaVisita() { return horaVisita; }
    public ResultadoVisita resultado() { return resultado; }
    public PruebaEntrega prueba() { return prueba; }
    public Novedad novedad() { return novedad; }
    public Envio envio() { return envio; }
}
