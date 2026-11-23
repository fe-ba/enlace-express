package co.enlaceexpress.dominio.despacho;

import co.enlaceexpress.dominio.enums.AccionNovedad;
import co.enlaceexpress.dominio.enums.EstadoNovedad;
import co.enlaceexpress.dominio.enums.TipoNovedad;
import co.enlaceexpress.dominio.reglas.EntradaInvalida;
import co.enlaceexpress.dominio.reglas.EstadoIncorrecto;

/** Problema ocurrido en un intento de entrega; la mesa de servicio decide la accion y la cierra. */
public class Novedad {

    public static final int MAXIMO_SOLUCION = 300;

    private Long idNovedad;
    private final TipoNovedad tipoNovedad;
    private final String descripcion;
    private AccionNovedad accion;
    private String solucion;
    private EstadoNovedad estado;

    public Novedad(Long idNovedad, TipoNovedad tipoNovedad, String descripcion, AccionNovedad accion, String solucion,
            EstadoNovedad estado) {
        this.idNovedad = idNovedad;
        this.tipoNovedad = tipoNovedad;
        this.descripcion = descripcion;
        this.accion = accion;
        this.solucion = solucion;
        this.estado = estado;
    }

    /** Novedad recien registrada por el mensajero: ABIERTA y sin gestion. */
    public static Novedad nueva(TipoNovedad tipo, String descripcion) {
        return new Novedad(null, tipo, descripcion, null, null, EstadoNovedad.ABIERTA);
    }

    /** La mesa de servicio decide que hacer (reintento o devolucion) y deja la solucion. */
    public void gestionar(AccionNovedad accion, String solucion) {
        this.accion = accion;
        this.solucion = solucion;
    }

    public void cerrar() {
        this.estado = EstadoNovedad.CERRADA;
    }

    public boolean estaAbierta() {
        return estado == EstadoNovedad.ABIERTA;
    }

    /**
     * CU21: la mesa decide la accion (REINTENTO o DEVOLUCION), deja la solucion y cierra la novedad. Solo se
     * gestiona una novedad ABIERTA; la accion y la solucion son obligatorias (la base las protege con el CHECK
     * NOVEDAD_ACCION_CK y los NOT NULL).
     */
    public void gestionarYCerrar(AccionNovedad accion, String solucion) {
        if (!estaAbierta()) {
            throw new EstadoIncorrecto("La novedad " + idNovedad + " ya está " + estado + "; solo se gestiona una novedad ABIERTA");
        }
        if (accion == null) {
            throw new EntradaInvalida("accion", "La acción es obligatoria (REINTENTO o DEVOLUCION)");
        }
        String texto = solucion == null ? "" : solucion.strip();
        if (texto.isEmpty()) {
            throw new EntradaInvalida("solucion", "La solución es obligatoria");
        }
        if (texto.length() > MAXIMO_SOLUCION) {
            throw new EntradaInvalida("solucion", "La solución no puede pasar de " + MAXIMO_SOLUCION + " caracteres");
        }
        gestionar(accion, texto);
        cerrar();
    }

    public Long idNovedad() { return idNovedad; }
    public TipoNovedad tipoNovedad() { return tipoNovedad; }
    public String descripcion() { return descripcion; }
    public AccionNovedad accion() { return accion; }
    public String solucion() { return solucion; }
    public EstadoNovedad estado() { return estado; }

    public void asignarId(long id) {
        this.idNovedad = id;
    }
}
