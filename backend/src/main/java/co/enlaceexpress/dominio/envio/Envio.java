package co.enlaceexpress.dominio.envio;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

import co.enlaceexpress.dominio.despacho.AsignacionDespacho;
import co.enlaceexpress.dominio.enums.EstadoEnvio;
import co.enlaceexpress.dominio.enums.ResultadoVisita;
import co.enlaceexpress.dominio.referencia.Empleado;
import co.enlaceexpress.dominio.referencia.Modalidad;
import co.enlaceexpress.dominio.reglas.CicloDeVidaEnvio;
import co.enlaceexpress.dominio.reglas.ReglaNegocioException;
import co.enlaceexpress.dominio.reglas.ReglasDeNegocio;

/**
 * Raiz del agregado Envio: sus datos, su historial de eventos y, cuando se necesitan, sus intentos de
 * entrega. Valida el ciclo de vida (RN12) antes de aceptar un evento.
 */
public class Envio {

    private String numeroGuia;
    private final long idSolicitud;
    private Destinatario destinatario;
    private final Long idDestinatario;
    private final long idZona;
    private final int idModalidad;
    private final LocalDate fechaRegistro;
    private final String direccionDestino;
    private final BigDecimal pesoDeclarado;
    private BigDecimal pesoReal;
    private final String contenido;
    private final BigDecimal valorDeclarado;
    private final boolean fragil;
    private final boolean altoValor;
    private BigDecimal valorFlete;
    private final LocalDate fechaCompromiso;
    private final List<EventoEnvio> historial = new ArrayList<>();
    private final List<AsignacionDespacho> intentos = new ArrayList<>();

    /** Reconstruye un envio guardado (lo usa el mapeador). */
    public Envio(String numeroGuia, long idSolicitud, Long idDestinatario, long idZona, int idModalidad,
            LocalDate fechaRegistro, String direccionDestino, BigDecimal pesoDeclarado, BigDecimal pesoReal,
            String contenido, BigDecimal valorDeclarado, boolean fragil, boolean altoValor, BigDecimal valorFlete,
            LocalDate fechaCompromiso) {
        this.numeroGuia = numeroGuia;
        this.idSolicitud = idSolicitud;
        this.idDestinatario = idDestinatario;
        this.idZona = idZona;
        this.idModalidad = idModalidad;
        this.fechaRegistro = fechaRegistro;
        this.direccionDestino = direccionDestino;
        this.pesoDeclarado = pesoDeclarado;
        this.pesoReal = pesoReal;
        this.contenido = contenido;
        this.valorDeclarado = valorDeclarado;
        this.fragil = fragil;
        this.altoValor = altoValor;
        this.valorFlete = valorFlete;
        this.fechaCompromiso = fechaCompromiso;
    }

    /**
     * Envio nuevo para registrar: valida los datos obligatorios (RN02) y las magnitudes (RN03), calcula la
     * fecha de compromiso con la modalidad si no se da, y nace con el evento REGISTRADO (RN12, RN13).
     * La guia la genera la base de datos al registrar.
     */
    public static Envio nuevo(long idSolicitud, Destinatario destinatario, long idZona, Modalidad modalidad,
            String direccionDestino, BigDecimal pesoDeclarado, String contenido, BigDecimal valorDeclarado,
            boolean fragil, boolean altoValor, LocalDate fechaCompromiso, long idEmpleado, LocalDateTime ahora) {
        ReglasDeNegocio.exigir(destinatario != null && destinatario.tipoDocumento() != null
                && destinatario.numeroDocumento() != null && destinatario.nombre() != null
                && destinatario.telefono() != null, "el destinatario completo (tipo y numero de documento, nombre y telefono)");
        ReglasDeNegocio.exigir(direccionDestino != null && !direccionDestino.isBlank(), "la direccion de destino");
        ReglasDeNegocio.exigir(modalidad != null, "la modalidad");
        ReglasDeNegocio.exigir(pesoDeclarado != null, "el peso");
        ReglasDeNegocio.exigir(contenido != null && !contenido.isBlank(), "el contenido");
        ReglasDeNegocio.exigir(valorDeclarado != null, "el valor declarado");
        LocalDate registro = ahora.toLocalDate();
        LocalDate compromiso = fechaCompromiso != null ? fechaCompromiso : modalidad.fechaCompromiso(registro);
        ReglasDeNegocio.validarMagnitudes(registro, compromiso, pesoDeclarado, valorDeclarado);
        Envio envio = new Envio(null, idSolicitud, destinatario.idDestinatario(), idZona, modalidad.idModalidad(), registro,
                direccionDestino, pesoDeclarado, null, contenido, valorDeclarado, fragil, altoValor, null, compromiso);
        envio.destinatario = destinatario;
        envio.historial.add(new EventoEnvio(null, EstadoEnvio.REGISTRADO, idEmpleado, ahora, "Envio registrado"));
        return envio;
    }

    /** Formato del numero de guia: "EE" y 13 digitos. */
    public static boolean formatoDeGuiaValido(String numeroGuia) {
        return numeroGuia != null && numeroGuia.matches("EE\\d{13}");
    }

    /** El estado actual es el del evento mas reciente (nulo si todavia no tiene eventos). */
    public EstadoEnvio estadoActual() {
        return historial.isEmpty() ? null : historial.get(historial.size() - 1).estado();
    }

    /** Instante para un evento nuevo: nunca anterior ni igual al ultimo evento de la guia (decision C5). */
    public LocalDateTime siguienteInstante(LocalDateTime ahora) {
        if (historial.isEmpty()) {
            return ahora;
        }
        LocalDateTime minimo = historial.get(historial.size() - 1).fechaHora().plusSeconds(1);
        return ahora.isAfter(minimo) ? ahora : minimo;
    }

    /**
     * Agrega un evento si la transicion esta permitida (RN12) y, para ENTREGADO o DEVUELTO, si algun
     * intento tiene ese resultado (RN05). Los instantes de los eventos de una misma operacion
     * quedan distintos y crecientes. La persistencia la hace el mapeador con el evento devuelto.
     */
    public EventoEnvio registrarEvento(EstadoEnvio estado, long idResponsable, String observacion, LocalDateTime ahora) {
        CicloDeVidaEnvio.validarTransicion(numeroGuia, estadoActual(), estado);
        if (estado == EstadoEnvio.ENTREGADO || estado == EstadoEnvio.DEVUELTO) {
            ResultadoVisita esperado = estado == EstadoEnvio.ENTREGADO ? ResultadoVisita.ENTREGADO : ResultadoVisita.DEVUELTO;
            boolean hayIntento = intentos.stream().anyMatch(i -> i.resultado() == esperado);
            if (!hayIntento) {
                throw ReglaNegocioException.deDominio("RN05", "la guía " + numeroGuia + " no puede pasar a " + estado
                        + " sin una asignación con resultado " + esperado + " y su prueba de entrega");
            }
        }
        EventoEnvio evento = new EventoEnvio(null, estado, idResponsable, siguienteInstante(ahora), observacion);
        historial.add(evento);
        return evento;
    }

    public EventoEnvio registrarEvento(EstadoEnvio estado, Empleado responsable, String observacion, LocalDateTime ahora) {
        return registrarEvento(estado, responsable.idEmpleado(), observacion, ahora);
    }

    /** Peso real y flete que se registran al clasificar (RN03: ambos positivos). */
    public void clasificar(BigDecimal pesoReal, BigDecimal flete) {
        ReglasDeNegocio.validarPesoYFlete(pesoReal, flete);
        this.pesoReal = pesoReal;
        this.valorFlete = flete;
    }

    /** Anula el envio: solo antes de salir a ruta (RN12 lo rechaza despues). */
    public EventoEnvio anular(Empleado responsable, LocalDateTime ahora) {
        return registrarEvento(EstadoEnvio.ANULADO, responsable, "Anulado", ahora);
    }

    /** RN06: si es fragil o de alto valor, quien recibe debe ser el destinatario. */
    public boolean exigeDocumentoDestinatario() {
        return fragil || altoValor;
    }

    public int intentosRealizados() {
        return intentos.size();
    }

    /** Carga los intentos de entrega (asignaciones) del envio y los enlaza con este envio. */
    public void cargarIntentos(List<AsignacionDespacho> asignaciones) {
        intentos.clear();
        intentos.addAll(asignaciones);
        intentos.forEach(a -> a.asignarEnvio(this));
    }

    /** Agrega un intento recien creado por un despacho. */
    public void agregarIntento(AsignacionDespacho asignacion) {
        intentos.add(asignacion);
        asignacion.asignarEnvio(this);
    }

    /** Carga el historial leido de la base, ordenado por fecha. */
    public void cargarHistorial(List<EventoEnvio> eventos) {
        historial.clear();
        historial.addAll(eventos);
    }

    public void asignarGuia(String guia) {
        this.numeroGuia = guia;
    }

    public void asignarDestinatario(Destinatario destinatario) {
        this.destinatario = destinatario;
    }

    public String numeroGuia() { return numeroGuia; }
    public long idSolicitud() { return idSolicitud; }
    public Destinatario destinatario() { return destinatario; }
    public Long idDestinatario() { return idDestinatario; }
    public long idZona() { return idZona; }
    public int idModalidad() { return idModalidad; }
    public LocalDate fechaRegistro() { return fechaRegistro; }
    public String direccionDestino() { return direccionDestino; }
    public BigDecimal pesoDeclarado() { return pesoDeclarado; }
    public BigDecimal pesoReal() { return pesoReal; }
    public String contenido() { return contenido; }
    public BigDecimal valorDeclarado() { return valorDeclarado; }
    public boolean fragil() { return fragil; }
    public boolean altoValor() { return altoValor; }
    public BigDecimal valorFlete() { return valorFlete; }
    public LocalDate fechaCompromiso() { return fechaCompromiso; }
    public List<EventoEnvio> historial() { return Collections.unmodifiableList(historial); }
    public List<AsignacionDespacho> intentos() { return Collections.unmodifiableList(intentos); }
}
