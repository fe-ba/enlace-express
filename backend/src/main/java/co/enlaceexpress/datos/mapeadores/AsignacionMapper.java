package co.enlaceexpress.datos.mapeadores;

import static co.enlaceexpress.datos.infraestructura.ConversorTipos.aEnum;
import static co.enlaceexpress.datos.infraestructura.ConversorTipos.aInstante;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.List;
import java.util.Optional;

import co.enlaceexpress.datos.infraestructura.UnidadDeTrabajo;
import co.enlaceexpress.dominio.despacho.AsignacionDespacho;
import co.enlaceexpress.dominio.enums.ResultadoVisita;

/** Mapeador de las asignaciones (intentos de entrega); usa los de prueba y novedad para guardar el resultado. */
public class AsignacionMapper extends MapeadorJdbc {

    private static final String COLUMNAS = """
            SELECT id_asignacion, numero_guia, id_despacho, numero_intento, orden_visita, hora_visita, resultado
            FROM   asignacion_despacho """;
    private static final String SQL_POR_DESPACHO = COLUMNAS + " WHERE id_despacho = ? ORDER BY orden_visita";
    private static final String SQL_POR_GUIA = COLUMNAS + " WHERE numero_guia = ? ORDER BY numero_intento";
    private static final String SQL_POR_ID = COLUMNAS + " WHERE id_asignacion = ?";

    private static final String SQL_INSERTAR = """
            INSERT INTO asignacion_despacho (numero_guia, id_despacho, numero_intento, orden_visita, hora_visita, resultado)
            VALUES (?, ?, ?, ?, ?, ?)""";

    private static final String SQL_ACTUALIZAR_RESULTADO = "UPDATE asignacion_despacho SET resultado = ?, hora_visita = ? WHERE id_asignacion = ?";
    private static final String SQL_BLOQUEAR = "SELECT id_asignacion FROM asignacion_despacho WHERE id_asignacion = ? FOR UPDATE";

    private final PruebaEntregaMapper pruebas;
    private final NovedadMapper novedades;

    public AsignacionMapper(UnidadDeTrabajo uow) {
        super(uow);
        this.pruebas = new PruebaEntregaMapper(uow);
        this.novedades = new NovedadMapper(uow);
    }

    public List<AsignacionDespacho> porDespacho(long idDespacho) {
        return consultar(SQL_POR_DESPACHO, new Object[] {idDespacho}, AsignacionMapper::aAsignacion);
    }

    public List<AsignacionDespacho> porGuia(String numeroGuia) {
        return consultar(SQL_POR_GUIA, new Object[] {numeroGuia}, AsignacionMapper::aAsignacion);
    }

    public Optional<AsignacionDespacho> buscarPorId(long idAsignacion) {
        return consultarUno(SQL_POR_ID, new Object[] {idAsignacion}, AsignacionMapper::aAsignacion);
    }

    public long insertar(long idDespacho, AsignacionDespacho a) {
        long id = insertarConClave(SQL_INSERTAR, new Object[] {a.numeroGuia(), idDespacho, a.numeroIntento(), a.ordenVisita(),
            a.horaVisita(), a.resultado()}, "ID_ASIGNACION");
        a.asignarId(id);
        return id;
    }

    /** Guarda la prueba o la novedad nuevas y despues el resultado (los disparadores exigen ese orden). */
    public void actualizarResultado(AsignacionDespacho a) {
        if (a.prueba() != null && a.prueba().idPrueba() == null) {
            pruebas.insertar(a.idAsignacion(), a.prueba());
        }
        if (a.novedad() != null && a.novedad().idNovedad() == null) {
            novedades.insertar(a.idAsignacion(), a.novedad());
        }
        ejecutar(SQL_ACTUALIZAR_RESULTADO, new Object[] {a.resultado(), a.horaVisita(), a.idAsignacion()});
    }

    /** Lee la prueba y la novedad de la asignacion. */
    public void cargarPruebaYNovedad(AsignacionDespacho a) {
        pruebas.porAsignacion(a.idAsignacion()).ifPresent(a::cargarPrueba);
        novedades.porAsignacion(a.idAsignacion()).ifPresent(a::cargarNovedad);
    }

    public boolean bloquearPorId(long idAsignacion) {
        return consultarUno(SQL_BLOQUEAR, new Object[] {idAsignacion}, f -> f.getLong(1)).isPresent();
    }

    private static AsignacionDespacho aAsignacion(ResultSet f) throws SQLException {
        return new AsignacionDespacho(f.getLong(1), f.getString(2), f.getLong(3), f.getInt(4), f.getInt(5),
                aInstante(f.getTimestamp(6)), aEnum(ResultadoVisita.class, f.getString(7)));
    }
}
