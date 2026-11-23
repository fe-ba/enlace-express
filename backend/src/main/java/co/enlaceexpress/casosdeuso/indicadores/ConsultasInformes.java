package co.enlaceexpress.casosdeuso.indicadores;

import java.util.List;

import co.enlaceexpress.dominio.enums.EstadoEnvio;

/**
 * Consultas e informes de solo lectura sobre las vistas de usuario del capitulo 4. Estan los del flujo
 * principal y los del tablero y del portal; los demas del diagrama (novedades abiertas y C5 a C8) se agregan con
 * los informes restantes.
 */
public interface ConsultasInformes {

    /** Planilla de ruta de un despacho, por orden de visita (v_planilla_despacho). */
    List<FilaPlanilla> planilla(long idDespacho);

    /** Asignaciones de los despachos no cerrados de un mensajero, por fecha y orden de visita (v_planilla_despacho). */
    List<FilaPlanilla> planillaDelMensajero(long idMensajero);

    /**
     * Recorrido de un envio por fecha (v_seguimiento_envio). Con {@code idCliente} solo devuelve las filas de
     * ese cliente (el portal filtra siempre por su empresa); con nulo, todas.
     */
    List<FilaSeguimiento> seguimiento(String numeroGuia, Long idCliente);

    /** Envios listos para armar una ruta en un centro, por fecha de compromiso (v_envios_por_despachar). */
    List<FilaPorDespachar> enviosPorDespachar(long idCentro);

    /** Solicitudes PENDIENTES o PROGRAMADAS con su sede y numero de envios. */
    List<FilaRecoleccion> recolecciones();

    /** Envios de un centro cuyo estado actual es el dado (v_estado_actual_envio). */
    List<FilaEnvioEstado> enviosEnEstado(long idCentro, EstadoEnvio estado);

    /** I03: numero de envios por estado actual; con {@code idCentro} nulo, de todos los centros. */
    List<FilaConteo> enviosPorEstado(Long idCentro);

    /** I04: cumplimiento de entregas por zona, de menor a mayor porcentaje; con {@code idCentro} nulo, de todos. */
    List<FilaCumplimiento> cumplimiento(Long idCentro);

    /** I06: novedades abiertas con los datos de contacto, por hora de la visita (v_novedades_abiertas). */
    List<FilaNovedadAbierta> novedadesAbiertas();

    /** I07: reclamaciones abiertas, de la mas antigua a la mas reciente. */
    List<FilaReclamacion> reclamacionesPendientes();

    /** Envios de la empresa con su estado actual (v_seguimiento_envio), del ultimo evento mas reciente primero. */
    List<FilaEnvioCliente> enviosDeCliente(long idCliente);
}
