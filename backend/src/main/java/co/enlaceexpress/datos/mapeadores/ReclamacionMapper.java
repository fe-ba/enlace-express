package co.enlaceexpress.datos.mapeadores;

import static co.enlaceexpress.datos.infraestructura.ConversorTipos.aEnum;
import static co.enlaceexpress.datos.infraestructura.ConversorTipos.aInstante;

import java.util.List;
import java.util.Optional;

import co.enlaceexpress.casosdeuso.servicioalcliente.FilaReclamacionMesa;
import co.enlaceexpress.datos.infraestructura.UnidadDeTrabajo;
import co.enlaceexpress.dominio.enums.EstadoReclamacion;
import co.enlaceexpress.dominio.enums.TipoReclamacion;
import co.enlaceexpress.dominio.reclamacion.Reclamacion;
import co.enlaceexpress.dominio.repositorios.RepositorioReclamacion;

/** Mapeador de las reclamaciones (CU22 y CU23). */
public class ReclamacionMapper extends MapeadorJdbc implements RepositorioReclamacion {

    private static final String SQL_POR_ID = """
            SELECT id_reclamacion, id_cliente, numero_guia, fecha_radicacion, tipo, descripcion, respuesta,
                   fecha_respuesta, estado
            FROM   reclamacion
            WHERE  id_reclamacion = ?""";

    private static final String SQL_INSERTAR = """
            INSERT INTO reclamacion (id_cliente, numero_guia, fecha_radicacion, tipo, descripcion, estado)
            VALUES (?, ?, ?, ?, ?, ?)""";

    private static final String SQL_ACTUALIZAR_RESPUESTA = """
            UPDATE reclamacion SET respuesta = ?, fecha_respuesta = ?, estado = ?
            WHERE  id_reclamacion = ?""";

    private static final String SQL_BLOQUEAR = "SELECT id_reclamacion FROM reclamacion WHERE id_reclamacion = ? FOR UPDATE";

    /** La guia existe y es de un envio del cliente: el envio, su solicitud y la sede de esa solicitud. */
    private static final String SQL_GUIA_DEL_CLIENTE = """
            SELECT 1
            FROM   envio e
            JOIN   solicitud_recoleccion sr ON sr.id_solicitud = e.id_solicitud
            JOIN   sede_cliente sc          ON sc.id_sede = sr.id_sede
            WHERE  e.numero_guia = ?
            AND    sc.id_cliente = ?""";

    /** Las respondidas que todavia no se cierran (las abiertas salen de v_reclamaciones_pendientes). */
    private static final String SQL_RESPONDIDAS = """
            SELECT r.id_reclamacion, r.fecha_radicacion, c.id_cliente, c.razon_social, r.numero_guia, r.tipo,
                   r.descripcion, r.estado, r.respuesta, r.fecha_respuesta
            FROM   reclamacion r
            JOIN   cliente c ON c.id_cliente = r.id_cliente
            WHERE  r.estado = ?
            ORDER  BY r.fecha_respuesta, r.id_reclamacion""";

    public ReclamacionMapper(UnidadDeTrabajo uow) {
        super(uow);
    }

    @Override
    public Optional<Reclamacion> buscarPorId(long idReclamacion) {
        return consultarUno(SQL_POR_ID, new Object[] {idReclamacion}, f -> new Reclamacion(f.getLong(1), f.getLong(2),
                f.getString(3), aInstante(f.getTimestamp(4)), aEnum(TipoReclamacion.class, f.getString(5)), f.getString(6),
                f.getString(7), aInstante(f.getTimestamp(8)), aEnum(EstadoReclamacion.class, f.getString(9))));
    }

    @Override
    public long insertar(Reclamacion r) {
        long id = insertarConClave(SQL_INSERTAR, new Object[] {r.idCliente(), r.numeroGuia(), r.fechaRadicacion(), r.tipo(),
            r.descripcion(), r.estado()}, "ID_RECLAMACION");
        r.asignarId(id);
        return id;
    }

    @Override
    public void actualizarRespuesta(Reclamacion r) {
        ejecutar(SQL_ACTUALIZAR_RESPUESTA, new Object[] {r.respuesta(), r.fechaRespuesta(), r.estado(), r.idReclamacion()});
    }

    @Override
    public boolean bloquearPorId(long idReclamacion) {
        return consultarUno(SQL_BLOQUEAR, new Object[] {idReclamacion}, f -> f.getLong(1)).isPresent();
    }

    @Override
    public boolean guiaEsDelCliente(String numeroGuia, long idCliente) {
        return consultarUno(SQL_GUIA_DEL_CLIENTE, new Object[] {numeroGuia, idCliente}, f -> f.getInt(1)).isPresent();
    }

    /** Reclamaciones RESPONDIDAS, con las horas que tardo la respuesta. */
    public List<FilaReclamacionMesa> respondidas() {
        return consultar(SQL_RESPONDIDAS, new Object[] {EstadoReclamacion.RESPONDIDA}, f -> {
            var radicacion = aInstante(f.getTimestamp(2));
            var respuesta = aInstante(f.getTimestamp(10));
            double horas = java.time.Duration.between(radicacion, respuesta).toSeconds() / 3600.0;
            return new FilaReclamacionMesa(f.getLong(1), radicacion, f.getLong(3), f.getString(4), f.getString(5),
                    f.getString(6), f.getString(7), f.getString(8), f.getString(9), respuesta,
                    java.math.BigDecimal.valueOf(horas).setScale(1, java.math.RoundingMode.HALF_UP),
                    horas > Reclamacion.META_HORAS);
        });
    }
}
