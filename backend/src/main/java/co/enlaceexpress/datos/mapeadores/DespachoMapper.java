package co.enlaceexpress.datos.mapeadores;

import static co.enlaceexpress.datos.infraestructura.ConversorTipos.aEnum;
import static co.enlaceexpress.datos.infraestructura.ConversorTipos.aFecha;
import static co.enlaceexpress.datos.infraestructura.ConversorTipos.aInstante;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.List;
import java.util.Optional;

import co.enlaceexpress.datos.infraestructura.UnidadDeTrabajo;
import co.enlaceexpress.dominio.despacho.AsignacionDespacho;
import co.enlaceexpress.dominio.despacho.Despacho;
import co.enlaceexpress.dominio.enums.EstadoDespacho;
import co.enlaceexpress.dominio.enums.EstadoVehiculo;
import co.enlaceexpress.dominio.enums.TipoDespacho;
import co.enlaceexpress.dominio.referencia.Catalogos;
import co.enlaceexpress.dominio.referencia.Vehiculo;
import co.enlaceexpress.dominio.repositorios.RepositorioDespacho;

/** Mapeador del agregado Despacho; usa AsignacionMapper para sus asignaciones. */
public class DespachoMapper extends MapeadorJdbc implements RepositorioDespacho {

    private static final String SQL_POR_ID = """
            SELECT id_despacho, id_centro, id_vehiculo, id_mensajero, fecha, tipo, hora_salida, hora_cierre, estado
            FROM   despacho
            WHERE  id_despacho = ?""";

    private static final String SQL_INSERTAR = """
            INSERT INTO despacho (id_centro, id_vehiculo, id_mensajero, fecha, tipo, hora_salida, hora_cierre, estado)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)""";

    private static final String SQL_ACTUALIZAR_ESTADO = "UPDATE despacho SET hora_salida = ?, hora_cierre = ?, estado = ? WHERE id_despacho = ?";

    /** C9: vehiculos disponibles del tipo que conduce el mensajero (con todas las columnas del vehiculo; el estado va como variable de enlace). */
    private static final String SQL_VEHICULOS_DISPONIBLES = """
            SELECT v.id_vehiculo, v.id_centro, v.id_tipo_vehiculo, v.placa, v.marca, v.modelo, v.capacidad_kg, v.electrico, v.estado
            FROM   mensajero m
            JOIN   vehiculo v ON v.id_tipo_vehiculo = m.id_tipo_vehiculo
            WHERE  m.id_empleado = ?
            AND    v.estado = ?""";

    private static final String SQL_BLOQUEAR = "SELECT id_despacho FROM despacho WHERE id_despacho = ? FOR UPDATE";

    private final AsignacionMapper asignaciones;
    private final ReferenciaMapper referencia;

    public DespachoMapper(UnidadDeTrabajo uow) {
        super(uow);
        this.asignaciones = new AsignacionMapper(uow);
        this.referencia = new ReferenciaMapper(uow);
    }

    @Override
    public Optional<Despacho> buscarPorId(long idDespacho) {
        Optional<Despacho> despacho = consultarUno(SQL_POR_ID, new Object[] {idDespacho}, DespachoMapper::aDespacho);
        despacho.ifPresent(d -> d.cargarAsignaciones(asignaciones.porDespacho(idDespacho)));
        return despacho;
    }

    @Override
    public long insertar(Despacho d) {
        long id = insertarConClave(SQL_INSERTAR, new Object[] {d.idCentro(), d.idVehiculo(), d.idMensajero(), d.fecha(), d.tipo(),
            d.horaSalida(), d.horaCierre(), d.estado()}, "ID_DESPACHO");
        d.asignarId(id);
        return id;
    }

    @Override
    public long guardarAsignacion(Despacho despacho, AsignacionDespacho asignacion) {
        return asignaciones.insertar(despacho.idDespacho(), asignacion);
    }

    @Override
    public void guardarResultado(AsignacionDespacho asignacion) {
        asignaciones.actualizarResultado(asignacion);
    }

    @Override
    public void actualizarEstado(Despacho d) {
        ejecutar(SQL_ACTUALIZAR_ESTADO, new Object[] {d.horaSalida(), d.horaCierre(), d.estado(), d.idDespacho()});
    }

    @Override
    public List<Vehiculo> vehiculosDisponibles(long idMensajero) {
        Catalogos catalogos = referencia.catalogos();
        return consultar(SQL_VEHICULOS_DISPONIBLES, new Object[] {idMensajero, EstadoVehiculo.DISPONIBLE},
                f -> ReferenciaMapper.aVehiculo(f, catalogos));
    }

    @Override
    public boolean bloquearPorId(long idDespacho) {
        return consultarUno(SQL_BLOQUEAR, new Object[] {idDespacho}, f -> f.getLong(1)).isPresent();
    }

    @Override
    public List<AsignacionDespacho> asignacionesDeGuia(String numeroGuia) {
        return asignaciones.porGuia(numeroGuia);
    }

    @Override
    public Optional<AsignacionDespacho> buscarAsignacion(long idAsignacion) {
        return asignaciones.buscarPorId(idAsignacion);
    }

    @Override
    public void cargarPruebaYNovedad(AsignacionDespacho asignacion) {
        asignaciones.cargarPruebaYNovedad(asignacion);
    }

    @Override
    public boolean bloquearAsignacion(long idAsignacion) {
        return asignaciones.bloquearPorId(idAsignacion);
    }

    private static Despacho aDespacho(ResultSet f) throws SQLException {
        return new Despacho(f.getLong(1), f.getLong(2), f.getLong(3), f.getLong(4), aFecha(f.getDate(5)),
                aEnum(TipoDespacho.class, f.getString(6)), aInstante(f.getTimestamp(7)), aInstante(f.getTimestamp(8)),
                aEnum(EstadoDespacho.class, f.getString(9)));
    }
}
