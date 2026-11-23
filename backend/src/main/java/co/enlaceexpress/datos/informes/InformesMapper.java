package co.enlaceexpress.datos.informes;

import static co.enlaceexpress.datos.infraestructura.ConversorTipos.aBoolean;
import static co.enlaceexpress.datos.infraestructura.ConversorTipos.aEnum;
import static co.enlaceexpress.datos.infraestructura.ConversorTipos.aFecha;
import static co.enlaceexpress.datos.infraestructura.ConversorTipos.aInstante;

import java.util.List;

import co.enlaceexpress.casosdeuso.indicadores.ConsultasInformes;
import co.enlaceexpress.casosdeuso.indicadores.FilaConteo;
import co.enlaceexpress.casosdeuso.indicadores.FilaCumplimiento;
import co.enlaceexpress.casosdeuso.indicadores.FilaEnvioCliente;
import co.enlaceexpress.casosdeuso.indicadores.FilaEnvioEstado;
import co.enlaceexpress.casosdeuso.indicadores.FilaNovedadAbierta;
import co.enlaceexpress.casosdeuso.indicadores.FilaPlanilla;
import co.enlaceexpress.casosdeuso.indicadores.FilaReclamacion;
import co.enlaceexpress.casosdeuso.indicadores.FilaRecoleccion;
import co.enlaceexpress.casosdeuso.indicadores.FilaPorDespachar;
import co.enlaceexpress.casosdeuso.indicadores.FilaSeguimiento;
import co.enlaceexpress.datos.infraestructura.UnidadDeTrabajo;
import co.enlaceexpress.datos.mapeadores.MapeadorFila;
import co.enlaceexpress.datos.mapeadores.MapeadorJdbc;
import co.enlaceexpress.dominio.enums.EstadoDespacho;
import co.enlaceexpress.dominio.enums.EstadoEnvio;
import co.enlaceexpress.dominio.enums.EstadoSolicitud;
import co.enlaceexpress.dominio.enums.ResultadoVisita;
import co.enlaceexpress.dominio.enums.TipoDocumento;

/** Consultas e informes: leen las vistas de usuario del capitulo 4. */
public class InformesMapper extends MapeadorJdbc implements ConsultasInformes {

    /** Planilla de ruta (v_planilla_despacho, C3): con los datos que necesita el mensajero para entregar. */
    private static final String SQL_PLANILLA = """
            SELECT orden_visita, numero_guia, destinatario, telefono_destinatario, direccion_destino, resultado,
                   id_asignacion, numero_intento, tipo_documento_destinatario, numero_documento_destinatario,
                   zona, fragil, alto_valor, id_despacho, estado_despacho
            FROM   v_planilla_despacho
            WHERE  id_despacho = ?
            ORDER  BY orden_visita""";

    /** Lo mismo para todos los despachos no cerrados del mensajero. */
    private static final String SQL_PLANILLA_DEL_MENSAJERO = """
            SELECT orden_visita, numero_guia, destinatario, telefono_destinatario, direccion_destino, resultado,
                   id_asignacion, numero_intento, tipo_documento_destinatario, numero_documento_destinatario,
                   zona, fragil, alto_valor, id_despacho, estado_despacho
            FROM   v_planilla_despacho
            WHERE  id_mensajero = ?
            AND    estado_despacho <> ?
            ORDER  BY fecha, id_despacho, orden_visita""";

    private static final String SQL_RECOLECCIONES = """
            SELECT r.id_solicitud, r.fecha_programada, r.franja_horaria, r.estado, s.nombre, s.direccion, s.contacto,
                   s.telefono, (SELECT COUNT(*) FROM envio e WHERE e.id_solicitud = r.id_solicitud)
            FROM   solicitud_recoleccion r
            JOIN   sede_cliente s ON s.id_sede = r.id_sede
            WHERE  r.estado IN (?, ?)
            ORDER  BY r.fecha_programada, r.id_solicitud""";

    private static final String SQL_EN_ESTADO = """
            SELECT numero_guia, fecha_registro, fecha_compromiso, razon_social, zona, modalidad, estado_actual, fecha_hora_estado
            FROM   v_estado_actual_envio
            WHERE  id_centro = ?
            AND    estado_actual = ?
            ORDER  BY fecha_compromiso, numero_guia""";

    /** I03: envios por estado actual. */
    private static final String SQL_POR_ESTADO = """
            SELECT estado_actual, COUNT(*)
            FROM   v_estado_actual_envio
            WHERE  id_centro = ?
            GROUP  BY estado_actual
            ORDER  BY MIN(CASE estado_actual WHEN 'REGISTRADO' THEN 1 WHEN 'RECOLECTADO' THEN 2 WHEN 'EN_CENTRO' THEN 3
                              WHEN 'CLASIFICADO' THEN 4 WHEN 'EN_RUTA' THEN 5 WHEN 'ENTREGADO' THEN 6
                              WHEN 'CON_NOVEDAD' THEN 7 WHEN 'DEVUELTO' THEN 8 ELSE 9 END)""";

    private static final String SQL_POR_ESTADO_TODOS = """
            SELECT estado_actual, COUNT(*)
            FROM   v_estado_actual_envio
            GROUP  BY estado_actual
            ORDER  BY MIN(CASE estado_actual WHEN 'REGISTRADO' THEN 1 WHEN 'RECOLECTADO' THEN 2 WHEN 'EN_CENTRO' THEN 3
                              WHEN 'CLASIFICADO' THEN 4 WHEN 'EN_RUTA' THEN 5 WHEN 'ENTREGADO' THEN 6
                              WHEN 'CON_NOVEDAD' THEN 7 WHEN 'DEVUELTO' THEN 8 ELSE 9 END)""";

    /** I04: cumplimiento de entregas. */
    private static final String SQL_CUMPLIMIENTO = """
            SELECT id_centro, id_zona, zona, entregados, entregados_a_tiempo, porcentaje_a_tiempo
            FROM   v_cumplimiento_entregas
            WHERE  id_centro = ?
            ORDER  BY porcentaje_a_tiempo, id_zona""";

    private static final String SQL_CUMPLIMIENTO_TODOS = """
            SELECT id_centro, id_zona, zona, entregados, entregados_a_tiempo, porcentaje_a_tiempo
            FROM   v_cumplimiento_entregas
            ORDER  BY porcentaje_a_tiempo, id_centro, id_zona""";

    /** I06: novedades abiertas, por hora de la visita. */
    private static final String SQL_NOVEDADES_ABIERTAS = """
            SELECT id_novedad, numero_guia, numero_intento, hora_visita, tipo_novedad, descripcion, destinatario,
                   telefono_destinatario, id_cliente, cliente, telefono_cliente
            FROM   v_novedades_abiertas
            ORDER  BY hora_visita, id_novedad""";

    /** I07: reclamaciones pendientes. */
    private static final String SQL_RECLAMACIONES = """
            SELECT id_reclamacion, fecha_radicacion, id_cliente, cliente, numero_guia, tipo, descripcion, horas_transcurridas
            FROM   v_reclamaciones_pendientes
            ORDER  BY fecha_radicacion, id_reclamacion""";

    /** El ultimo evento de cada envio de la empresa (hasta 200). */
    private static final String SQL_ENVIOS_DE_CLIENTE = """
            SELECT numero_guia, estado, fecha_hora
            FROM  (SELECT numero_guia, estado, fecha_hora,
                          ROW_NUMBER() OVER (PARTITION BY numero_guia ORDER BY fecha_hora DESC, id_evento DESC) AS orden
                   FROM   v_seguimiento_envio
                   WHERE  id_cliente = ?)
            WHERE  orden = 1
            ORDER  BY fecha_hora DESC
            FETCH  FIRST 200 ROWS ONLY""";

    /** Seguimiento de un envio (v_seguimiento_envio, C2). */
    private static final String SQL_SEGUIMIENTO = """
            SELECT fecha_hora, estado, observacion, responsable
            FROM   v_seguimiento_envio
            WHERE  numero_guia = ?
            ORDER  BY fecha_hora, id_evento""";

    /** El mismo seguimiento filtrado por la empresa dueña de la guia (portal de clientes). */
    private static final String SQL_SEGUIMIENTO_DE_CLIENTE = """
            SELECT fecha_hora, estado, observacion, responsable
            FROM   v_seguimiento_envio
            WHERE  numero_guia = ?
            AND    id_cliente = ?
            ORDER  BY fecha_hora, id_evento""";

    private static final String SQL_POR_DESPACHAR = """
            SELECT numero_guia, id_centro, id_zona, zona, modalidad, fecha_compromiso, peso_kg, fragil, alto_valor,
                   estado_actual, intentos_previos
            FROM   v_envios_por_despachar
            WHERE  id_centro = ?
            ORDER  BY fecha_compromiso, numero_guia""";

    public InformesMapper(UnidadDeTrabajo uow) {
        super(uow);
    }

    @Override
    public List<FilaPlanilla> planilla(long idDespacho) {
        return consultar(SQL_PLANILLA, new Object[] {idDespacho}, InformesMapper::aPlanilla);
    }

    @Override
    public List<FilaPlanilla> planillaDelMensajero(long idMensajero) {
        return consultar(SQL_PLANILLA_DEL_MENSAJERO, new Object[] {idMensajero, EstadoDespacho.CERRADO}, InformesMapper::aPlanilla);
    }

    @Override
    public List<FilaRecoleccion> recolecciones() {
        return consultar(SQL_RECOLECCIONES, new Object[] {EstadoSolicitud.PENDIENTE, EstadoSolicitud.PROGRAMADA},
                f -> new FilaRecoleccion(f.getLong(1), aFecha(f.getDate(2)), f.getString(3), f.getString(4), f.getString(5),
                        f.getString(6), f.getString(7), f.getString(8), f.getInt(9)));
    }

    @Override
    public List<FilaEnvioEstado> enviosEnEstado(long idCentro, EstadoEnvio estado) {
        return consultar(SQL_EN_ESTADO, new Object[] {idCentro, estado.name()},
                f -> new FilaEnvioEstado(f.getString(1), aFecha(f.getDate(2)), aFecha(f.getDate(3)), f.getString(4),
                        f.getString(5), f.getString(6), f.getString(7), aInstante(f.getTimestamp(8))));
    }

    @Override
    public List<FilaConteo> enviosPorEstado(Long idCentro) {
        return idCentro == null
                ? consultar(SQL_POR_ESTADO_TODOS, new Object[0], f -> new FilaConteo(f.getString(1), f.getLong(2)))
                : consultar(SQL_POR_ESTADO, new Object[] {idCentro}, f -> new FilaConteo(f.getString(1), f.getLong(2)));
    }

    @Override
    public List<FilaCumplimiento> cumplimiento(Long idCentro) {
        MapeadorFila<FilaCumplimiento> fila = f -> new FilaCumplimiento(f.getLong(1), f.getLong(2), f.getString(3), f.getLong(4),
                f.getLong(5), f.getBigDecimal(6));
        return idCentro == null
                ? consultar(SQL_CUMPLIMIENTO_TODOS, new Object[0], fila)
                : consultar(SQL_CUMPLIMIENTO, new Object[] {idCentro}, fila);
    }

    @Override
    public List<FilaNovedadAbierta> novedadesAbiertas() {
        return consultar(SQL_NOVEDADES_ABIERTAS, new Object[0], f -> new FilaNovedadAbierta(f.getLong(1), f.getString(2),
                f.getInt(3), aInstante(f.getTimestamp(4)), f.getString(5), f.getString(6), f.getString(7), f.getString(8),
                f.getLong(9), f.getString(10), f.getString(11)));
    }

    @Override
    public List<FilaReclamacion> reclamacionesPendientes() {
        return consultar(SQL_RECLAMACIONES, new Object[0], f -> new FilaReclamacion(f.getLong(1), aInstante(f.getTimestamp(2)),
                f.getLong(3), f.getString(4), f.getString(5), f.getString(6), f.getString(7), f.getBigDecimal(8)));
    }

    @Override
    public List<FilaEnvioCliente> enviosDeCliente(long idCliente) {
        return consultar(SQL_ENVIOS_DE_CLIENTE, new Object[] {idCliente},
                f -> new FilaEnvioCliente(f.getString(1), f.getString(2), aInstante(f.getTimestamp(3))));
    }

    private static FilaPlanilla aPlanilla(java.sql.ResultSet f) throws java.sql.SQLException {
        return new FilaPlanilla(f.getInt(1), f.getString(2), f.getString(3), f.getString(4), f.getString(5),
                aEnum(ResultadoVisita.class, f.getString(6)), f.getLong(7), f.getInt(8), aEnum(TipoDocumento.class, f.getString(9)),
                f.getString(10), f.getString(11), aBoolean(f.getString(12)), aBoolean(f.getString(13)), f.getLong(14), f.getString(15));
    }

    @Override
    public List<FilaSeguimiento> seguimiento(String numeroGuia, Long idCliente) {
        if (idCliente == null) {
            return consultar(SQL_SEGUIMIENTO, new Object[] {numeroGuia}, InformesMapper::aSeguimiento);
        }
        return consultar(SQL_SEGUIMIENTO_DE_CLIENTE, new Object[] {numeroGuia, idCliente}, InformesMapper::aSeguimiento);
    }

    @Override
    public List<FilaPorDespachar> enviosPorDespachar(long idCentro) {
        return consultar(SQL_POR_DESPACHAR, new Object[] {idCentro}, f -> new FilaPorDespachar(f.getString(1), f.getLong(2),
                f.getLong(3), f.getString(4), f.getString(5), aFecha(f.getDate(6)), f.getBigDecimal(7), aBoolean(f.getString(8)),
                aBoolean(f.getString(9)), f.getString(10), f.getInt(11)));
    }

    private static FilaSeguimiento aSeguimiento(java.sql.ResultSet f) throws java.sql.SQLException {
        return new FilaSeguimiento(aInstante(f.getTimestamp(1)), f.getString(2), f.getString(3), f.getString(4));
    }
}
