package co.enlaceexpress.datos.mapeadores;

import static co.enlaceexpress.datos.infraestructura.ConversorTipos.aEnum;
import static co.enlaceexpress.datos.infraestructura.ConversorTipos.aFecha;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

import co.enlaceexpress.datos.infraestructura.ConversorTipos;
import co.enlaceexpress.datos.infraestructura.UnidadDeTrabajo;
import co.enlaceexpress.dominio.enums.EstadoSolicitud;
import co.enlaceexpress.dominio.enums.FranjaHoraria;
import co.enlaceexpress.dominio.repositorios.RepositorioSolicitud;
import co.enlaceexpress.dominio.solicitud.SolicitudRecoleccion;

/** Mapeador de las solicitudes de recoleccion. */
public class SolicitudMapper extends MapeadorJdbc implements RepositorioSolicitud {

    private static final String COLUMNAS = """
            SELECT id_solicitud, id_sede, id_despacho, fecha_solicitud, fecha_programada, franja_horaria, estado
            FROM   solicitud_recoleccion """;
    private static final String SQL_POR_ID = COLUMNAS + " WHERE id_solicitud = ?";
    private static final String SQL_PENDIENTES = COLUMNAS + " WHERE fecha_programada = ? AND estado IN (?, ?) ORDER BY id_solicitud";

    private static final String SQL_INSERTAR = """
            INSERT INTO solicitud_recoleccion (id_sede, id_despacho, fecha_solicitud, fecha_programada, franja_horaria, estado)
            VALUES (?, ?, ?, ?, ?, ?)""";

    private static final String SQL_ACTUALIZAR_ESTADO = "UPDATE solicitud_recoleccion SET estado = ?, id_despacho = ? WHERE id_solicitud = ?";
    private static final String SQL_BLOQUEAR = "SELECT id_solicitud FROM solicitud_recoleccion WHERE id_solicitud = ? FOR UPDATE";

    public SolicitudMapper(UnidadDeTrabajo uow) {
        super(uow);
    }

    @Override
    public Optional<SolicitudRecoleccion> buscarPorId(long idSolicitud) {
        return consultarUno(SQL_POR_ID, new Object[] {idSolicitud}, SolicitudMapper::aSolicitud);
    }

    @Override
    public long insertar(SolicitudRecoleccion s) {
        long id = insertarConClave(SQL_INSERTAR, new Object[] {s.idSede(), s.idDespacho(), s.fechaSolicitud(),
            s.fechaProgramada(), s.franjaHoraria(), s.estado()}, "ID_SOLICITUD");
        s.asignarId(id);
        return id;
    }

    @Override
    public void actualizarEstado(SolicitudRecoleccion s) {
        ejecutar(SQL_ACTUALIZAR_ESTADO, new Object[] {s.estado(), s.idDespacho(), s.idSolicitud()});
    }

    @Override
    public List<SolicitudRecoleccion> pendientes(LocalDate fecha) {
        return consultar(SQL_PENDIENTES, new Object[] {fecha, EstadoSolicitud.PENDIENTE, EstadoSolicitud.PROGRAMADA},
                SolicitudMapper::aSolicitud);
    }

    @Override
    public boolean bloquearPorId(long idSolicitud) {
        return consultarUno(SQL_BLOQUEAR, new Object[] {idSolicitud}, f -> f.getLong(1)).isPresent();
    }

    private static SolicitudRecoleccion aSolicitud(ResultSet f) throws SQLException {
        return new SolicitudRecoleccion(f.getLong(1), f.getLong(2), ConversorTipos.aLongONulo(f, "ID_DESPACHO"),
                aFecha(f.getDate(4)), aFecha(f.getDate(5)), aEnum(FranjaHoraria.class, f.getString(6)),
                aEnum(EstadoSolicitud.class, f.getString(7)));
    }
}
