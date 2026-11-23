package co.enlaceexpress.datos.mapeadores;

import static co.enlaceexpress.datos.infraestructura.ConversorTipos.aBoolean;
import static co.enlaceexpress.datos.infraestructura.ConversorTipos.aEnum;
import static co.enlaceexpress.datos.infraestructura.ConversorTipos.aFecha;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.List;
import java.util.Optional;

import co.enlaceexpress.datos.infraestructura.ConversorTipos;
import co.enlaceexpress.datos.infraestructura.UnidadDeTrabajo;
import co.enlaceexpress.dominio.enums.EstadoActivo;
import co.enlaceexpress.dominio.enums.EstadoEmpleado;
import co.enlaceexpress.dominio.enums.EstadoVehiculo;
import co.enlaceexpress.dominio.enums.TipoCliente;
import co.enlaceexpress.dominio.enums.TipoDocumento;
import co.enlaceexpress.dominio.envio.Destinatario;
import co.enlaceexpress.dominio.referencia.Catalogos;
import co.enlaceexpress.dominio.referencia.Cliente;
import co.enlaceexpress.dominio.referencia.Empleado;
import co.enlaceexpress.dominio.referencia.Mensajero;
import co.enlaceexpress.dominio.referencia.Modalidad;
import co.enlaceexpress.dominio.referencia.SedeCliente;
import co.enlaceexpress.dominio.referencia.TipoVehiculo;
import co.enlaceexpress.dominio.referencia.Vehiculo;
import co.enlaceexpress.dominio.referencia.Zona;
import co.enlaceexpress.dominio.repositorios.RepositorioReferencia;

/** Lectura de los datos de referencia y de los catalogos (que se guardan en el mapeador durante la transaccion). */
public class ReferenciaMapper extends MapeadorJdbc implements RepositorioReferencia {

    private static final String SQL_CLIENTE = """
            SELECT id_cliente, nit, razon_social, tipo_cliente, telefono, correo, fecha_vinculacion, estado
            FROM   cliente WHERE id_cliente = ?""";
    private static final String SQL_SEDE = """
            SELECT id_sede, id_cliente, id_zona, nombre, direccion, contacto, telefono
            FROM   sede_cliente WHERE id_sede = ?""";
    private static final String SQL_ZONA = "SELECT id_zona, id_centro, nombre, localidades FROM zona WHERE id_zona = ?";
    private static final String SQL_EMPLEADO = """
            SELECT id_empleado, id_centro, documento, nombres, apellidos, cargo, telefono, correo, fecha_ingreso,
                   fecha_retiro, motivo_retiro, estado
            FROM   empleado WHERE id_empleado = ?""";
    /** EMPLEADO reunido con MENSAJERO. */
    private static final String SQL_MENSAJERO = """
            SELECT e.id_empleado, e.id_centro, e.documento, e.nombres, e.apellidos, e.cargo, e.telefono, e.correo,
                   e.fecha_ingreso, e.fecha_retiro, e.motivo_retiro, e.estado, m.id_zona, m.id_tipo_vehiculo
            FROM   empleado e
            JOIN   mensajero m ON m.id_empleado = e.id_empleado
            WHERE  e.id_empleado = ?""";
    private static final String SQL_VEHICULO = """
            SELECT id_vehiculo, id_centro, id_tipo_vehiculo, placa, marca, modelo, capacidad_kg, electrico, estado
            FROM   vehiculo WHERE id_vehiculo = ?""";
    private static final String SQL_CLIENTES_ACTIVOS = """
            SELECT id_cliente, nit, razon_social, tipo_cliente, telefono, correo, fecha_vinculacion, estado
            FROM   cliente WHERE estado = ? ORDER BY razon_social""";
    private static final String SQL_CLIENTES = """
            SELECT id_cliente, nit, razon_social, tipo_cliente, telefono, correo, fecha_vinculacion, estado
            FROM   cliente ORDER BY razon_social""";
    private static final String SQL_SEDES_DE_CLIENTE = """
            SELECT id_sede, id_cliente, id_zona, nombre, direccion, contacto, telefono
            FROM   sede_cliente WHERE id_cliente = ? ORDER BY nombre""";
    private static final String SQL_ZONAS = "SELECT id_zona, id_centro, nombre, localidades FROM zona ORDER BY nombre";
    private static final String SQL_MENSAJEROS_DEL_CENTRO = """
            SELECT e.id_empleado, e.id_centro, e.documento, e.nombres, e.apellidos, e.cargo, e.telefono, e.correo,
                   e.fecha_ingreso, e.fecha_retiro, e.motivo_retiro, e.estado, m.id_zona, m.id_tipo_vehiculo
            FROM   empleado e
            JOIN   mensajero m ON m.id_empleado = e.id_empleado
            WHERE  e.id_centro = ? AND e.estado = ?
            ORDER  BY e.nombres, e.apellidos""";
    private static final String SQL_MODALIDADES = "SELECT id_modalidad, nombre, plazo_dias_habiles FROM modalidad ORDER BY id_modalidad";
    private static final String SQL_TIPOS_VEHICULO = "SELECT id_tipo_vehiculo, nombre, capacidad_max_kg FROM tipo_vehiculo ORDER BY id_tipo_vehiculo";

    private final DestinatarioMapper destinatarios;
    private Catalogos cacheCatalogos;

    public ReferenciaMapper(UnidadDeTrabajo uow) {
        super(uow);
        this.destinatarios = new DestinatarioMapper(uow);
    }

    @Override
    public Optional<Cliente> cliente(long idCliente) {
        return consultarUno(SQL_CLIENTE, new Object[] {idCliente}, ReferenciaMapper::aCliente);
    }

    @Override
    public Optional<SedeCliente> sede(long idSede) {
        return consultarUno(SQL_SEDE, new Object[] {idSede}, ReferenciaMapper::aSede);
    }

    @Override
    public List<Cliente> clientesActivos() {
        return consultar(SQL_CLIENTES_ACTIVOS, new Object[] {EstadoActivo.ACTIVO}, ReferenciaMapper::aCliente);
    }

    @Override
    public List<Cliente> clientes() {
        return consultar(SQL_CLIENTES, new Object[0], ReferenciaMapper::aCliente);
    }

    @Override
    public List<SedeCliente> sedesDeCliente(long idCliente) {
        return consultar(SQL_SEDES_DE_CLIENTE, new Object[] {idCliente}, ReferenciaMapper::aSede);
    }

    @Override
    public List<Zona> zonas() {
        return consultar(SQL_ZONAS, new Object[0], f -> new Zona(f.getLong(1), f.getLong(2), f.getString(3), f.getString(4)));
    }

    @Override
    public List<Mensajero> mensajerosActivosDelCentro(long idCentro) {
        Catalogos catalogos = catalogos();
        return consultar(SQL_MENSAJEROS_DEL_CENTRO, new Object[] {idCentro, EstadoEmpleado.ACTIVO},
                f -> aMensajero(f, catalogos));
    }

    @Override
    public Optional<Zona> zona(long idZona) {
        return consultarUno(SQL_ZONA, new Object[] {idZona}, f -> new Zona(f.getLong(1), f.getLong(2), f.getString(3), f.getString(4)));
    }

    @Override
    public Optional<Empleado> empleado(long idEmpleado) {
        return consultarUno(SQL_EMPLEADO, new Object[] {idEmpleado}, f -> new Empleado(f.getLong(1), f.getLong(2), f.getString(3),
                f.getString(4), f.getString(5), f.getString(6), f.getString(7), f.getString(8), aFecha(f.getDate(9)),
                aFecha(f.getDate(10)), f.getString(11), aEnum(EstadoEmpleado.class, f.getString(12))));
    }

    @Override
    public Optional<Mensajero> mensajero(long idMensajero) {
        Catalogos catalogos = catalogos();
        return consultarUno(SQL_MENSAJERO, new Object[] {idMensajero}, f -> aMensajero(f, catalogos));
    }

    @Override
    public Optional<Vehiculo> vehiculo(long idVehiculo) {
        Catalogos catalogos = catalogos();
        return consultarUno(SQL_VEHICULO, new Object[] {idVehiculo}, f -> aVehiculo(f, catalogos));
    }

    /** Modalidades y tipos de vehiculo; se leen una vez por mapeador. */
    @Override
    public Catalogos catalogos() {
        if (cacheCatalogos == null) {
            List<Modalidad> modalidades = consultar(SQL_MODALIDADES, new Object[0],
                    f -> new Modalidad(f.getInt(1), f.getString(2), f.getInt(3)));
            List<TipoVehiculo> tipos = consultar(SQL_TIPOS_VEHICULO, new Object[0],
                    f -> new TipoVehiculo(f.getInt(1), f.getString(2), f.getBigDecimal(3)));
            cacheCatalogos = new Catalogos(modalidades, tipos);
        }
        return cacheCatalogos;
    }

    @Override
    public Optional<Destinatario> destinatarioPorDocumento(TipoDocumento tipo, String numero) {
        return destinatarios.buscarPorDocumento(tipo, numero);
    }

    @Override
    public Optional<Destinatario> destinatario(long idDestinatario) {
        return destinatarios.buscarPorId(idDestinatario);
    }

    /** Convierte una fila con las columnas de SQL_VEHICULO (tambien las de C9) en un Vehiculo. */
    static Vehiculo aVehiculo(ResultSet f, Catalogos catalogos) throws SQLException {
        return new Vehiculo(f.getLong(1), f.getLong(2), catalogos.tipoVehiculo(f.getInt(3)), f.getString(4), f.getString(5),
                f.getString(6), f.getBigDecimal(7), aBoolean(f.getString(8)), aEnum(EstadoVehiculo.class, f.getString(9)));
    }

    private static Cliente aCliente(ResultSet f) throws SQLException {
        return new Cliente(f.getLong(1), f.getString(2), f.getString(3), aEnum(TipoCliente.class, f.getString(4)),
                f.getString(5), f.getString(6), aFecha(f.getDate(7)), aEnum(EstadoActivo.class, f.getString(8)));
    }

    private static SedeCliente aSede(ResultSet f) throws SQLException {
        return new SedeCliente(f.getLong(1), f.getLong(2), f.getLong(3), f.getString(4), f.getString(5), f.getString(6), f.getString(7));
    }

    /** Fila de SQL_MENSAJERO (empleado reunido con mensajero). */
    private static Mensajero aMensajero(ResultSet f, Catalogos catalogos) throws SQLException {
        return new Mensajero(f.getLong(1), f.getLong(2), f.getString(3), f.getString(4), f.getString(5), f.getString(6),
                f.getString(7), f.getString(8), aFecha(f.getDate(9)), aFecha(f.getDate(10)), f.getString(11),
                aEnum(EstadoEmpleado.class, f.getString(12)), ConversorTipos.aLongONulo(f, "ID_ZONA"),
                catalogos.tipoVehiculo(f.getInt(14)));
    }
}
