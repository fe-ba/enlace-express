package co.enlaceexpress.datos.mapeadores;

import static co.enlaceexpress.datos.infraestructura.ConversorTipos.aBoolean;
import static co.enlaceexpress.datos.infraestructura.ConversorTipos.aFecha;
import static co.enlaceexpress.datos.infraestructura.ConversorTipos.aInstante;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.List;
import java.util.Optional;

import co.enlaceexpress.datos.infraestructura.UnidadDeTrabajo;
import co.enlaceexpress.dominio.enums.EstadoEnvio;
import co.enlaceexpress.dominio.envio.Destinatario;
import co.enlaceexpress.dominio.envio.Envio;
import co.enlaceexpress.dominio.envio.EventoEnvio;
import co.enlaceexpress.dominio.repositorios.RepositorioEnvio;

/** Mapeador del agregado Envio. */
public class EnvioMapper extends MapeadorJdbc implements RepositorioEnvio {

    /** C1 (datos de un envio) con las columnas que necesita el dominio; no une otras tablas, asi lo puede leer cualquier rol que vea ENVIO. */
    private static final String SQL_POR_GUIA = """
            SELECT numero_guia, id_solicitud, id_destinatario, id_zona, id_modalidad, fecha_registro,
                   direccion_destino, peso_declarado, peso_real, contenido, valor_declarado, fragil,
                   alto_valor, valor_flete, fecha_compromiso
            FROM   envio
            WHERE  numero_guia = ?""";

    /** C2 sin las uniones con ESTADO_ENVIO y EMPLEADO (el estado sale del catalogo del dominio): el historial para el dominio. */
    private static final String SQL_EVENTOS = """
            SELECT id_evento, id_estado, id_empleado, fecha_hora, observacion
            FROM   evento_envio
            WHERE  numero_guia = ?
            ORDER  BY fecha_hora""";

    private static final String SQL_REGISTRAR = "{call pr_registrar_envio(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)}";

    private static final String SQL_INSERTAR_EVENTO = """
            INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion)
            VALUES (?, ?, ?, ?, ?)""";

    private static final String SQL_ACTUALIZAR_CLASIFICACION = "UPDATE envio SET peso_real = ?, valor_flete = ? WHERE numero_guia = ?";

    /** C4: envios clasificados sin asignar (el nombre del estado va como variable de enlace). */
    private static final String SQL_SIN_ASIGNAR = """
            SELECT ev.numero_guia
            FROM   evento_envio ev
            JOIN   estado_envio es ON es.id_estado = ev.id_estado
            WHERE  es.nombre = ?
            AND    ev.numero_guia NOT IN (SELECT numero_guia
                                          FROM   asignacion_despacho)""";

    /** C10 para una guia, sin la union con ESTADO_ENVIO: el id del estado del evento mas reciente. */
    private static final String SQL_ESTADO_ACTUAL = """
            SELECT ev.id_estado
            FROM   evento_envio ev
            WHERE  ev.numero_guia = ?
            AND    ev.fecha_hora = (SELECT MAX(x.fecha_hora)
                                    FROM   evento_envio x
                                    WHERE  x.numero_guia = ev.numero_guia)""";

    private static final String SQL_GUIAS_DE_SOLICITUD = "SELECT numero_guia FROM envio WHERE id_solicitud = ? ORDER BY numero_guia";
    private static final String SQL_BLOQUEAR = "SELECT numero_guia FROM envio WHERE numero_guia = ? FOR UPDATE";

    public EnvioMapper(UnidadDeTrabajo uow) {
        super(uow);
    }

    @Override
    public Optional<Envio> buscarPorGuia(String numeroGuia) {
        Optional<Envio> envio = consultarUno(SQL_POR_GUIA, new Object[] {numeroGuia}, EnvioMapper::aEnvio);
        envio.ifPresent(e -> e.cargarHistorial(consultar(SQL_EVENTOS, new Object[] {numeroGuia}, EnvioMapper::aEvento)));
        return envio;
    }

    /** Registra con el procedimiento del capitulo 5: crea o reutiliza el destinatario, genera la guia y deja el evento REGISTRADO. */
    @Override
    public String registrar(Envio envio) {
        Destinatario d = envio.destinatario();
        EventoEnvio registro = envio.historial().get(0);
        Object[] entradas = {envio.idSolicitud(), d.tipoDocumento(), d.numeroDocumento(), d.nombre(), d.telefono(), d.correo(),
            envio.idZona(), envio.idModalidad(), envio.direccionDestino(), envio.pesoDeclarado(), envio.contenido(),
            envio.valorDeclarado(), envio.fragil(), envio.altoValor(), envio.fechaCompromiso(), registro.idEmpleado()};
        String guia = (String) llamarProcedimiento(SQL_REGISTRAR, entradas);
        envio.asignarGuia(guia);
        return guia;
    }

    @Override
    public void agregarEvento(String numeroGuia, EventoEnvio evento) {
        long id = insertarConClave(SQL_INSERTAR_EVENTO, new Object[] {numeroGuia, evento.estado().idEstado(), evento.idEmpleado(),
            evento.fechaHora(), evento.observacion()}, "ID_EVENTO");
        evento.asignarId(id);
    }

    @Override
    public void actualizarClasificacion(Envio envio) {
        ejecutar(SQL_ACTUALIZAR_CLASIFICACION, new Object[] {envio.pesoReal(), envio.valorFlete(), envio.numeroGuia()});
    }

    @Override
    public List<String> clasificadosSinAsignar() {
        return consultar(SQL_SIN_ASIGNAR, new Object[] {EstadoEnvio.CLASIFICADO.name()}, f -> f.getString(1));
    }

    @Override
    public EstadoEnvio estadoActual(String numeroGuia) {
        return consultarUno(SQL_ESTADO_ACTUAL, new Object[] {numeroGuia}, f -> EstadoEnvio.porId(f.getInt(1))).orElse(null);
    }

    @Override
    public List<String> guiasDeSolicitud(long idSolicitud) {
        return consultar(SQL_GUIAS_DE_SOLICITUD, new Object[] {idSolicitud}, f -> f.getString(1));
    }

    @Override
    public boolean bloquearPorGuia(String numeroGuia) {
        return consultarUno(SQL_BLOQUEAR, new Object[] {numeroGuia}, f -> f.getString(1)).isPresent();
    }

    private static Envio aEnvio(ResultSet f) throws SQLException {
        return new Envio(f.getString(1), f.getLong(2), f.getLong(3), f.getLong(4), f.getInt(5), aFecha(f.getDate(6)),
                f.getString(7), f.getBigDecimal(8), f.getBigDecimal(9), f.getString(10), f.getBigDecimal(11),
                aBoolean(f.getString(12)), aBoolean(f.getString(13)), f.getBigDecimal(14), aFecha(f.getDate(15)));
    }

    private static EventoEnvio aEvento(ResultSet f) throws SQLException {
        return new EventoEnvio(f.getLong(1), EstadoEnvio.porId(f.getInt(2)), f.getLong(3), aInstante(f.getTimestamp(4)), f.getString(5));
    }
}
