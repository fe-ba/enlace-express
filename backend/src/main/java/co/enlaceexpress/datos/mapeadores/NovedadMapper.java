package co.enlaceexpress.datos.mapeadores;

import static co.enlaceexpress.datos.infraestructura.ConversorTipos.aEnum;

import java.util.Optional;

import co.enlaceexpress.datos.infraestructura.UnidadDeTrabajo;
import co.enlaceexpress.dominio.despacho.Novedad;
import co.enlaceexpress.dominio.enums.AccionNovedad;
import co.enlaceexpress.dominio.enums.EstadoNovedad;
import co.enlaceexpress.dominio.enums.TipoNovedad;

/** Mapeador de la novedad de una asignacion. */
public class NovedadMapper extends MapeadorJdbc {

    private static final String SQL_POR_ASIGNACION = """
            SELECT id_novedad, tipo_novedad, descripcion, accion, solucion, estado
            FROM   novedad
            WHERE  id_asignacion = ?""";

    private static final String SQL_POR_ID = """
            SELECT id_novedad, tipo_novedad, descripcion, accion, solucion, estado
            FROM   novedad
            WHERE  id_novedad = ?""";

    private static final String SQL_BLOQUEAR = "SELECT id_novedad FROM novedad WHERE id_novedad = ? FOR UPDATE";

    private static final String SQL_INSERTAR = """
            INSERT INTO novedad (id_asignacion, tipo_novedad, descripcion, accion, solucion, estado)
            VALUES (?, ?, ?, ?, ?, ?)""";

    private static final String SQL_ACTUALIZAR_GESTION = "UPDATE novedad SET accion = ?, solucion = ?, estado = ? WHERE id_novedad = ?";

    public NovedadMapper(UnidadDeTrabajo uow) {
        super(uow);
    }

    public Optional<Novedad> porAsignacion(long idAsignacion) {
        return consultarUno(SQL_POR_ASIGNACION, new Object[] {idAsignacion}, f -> new Novedad(f.getLong(1),
                aEnum(TipoNovedad.class, f.getString(2)), f.getString(3), aEnum(AccionNovedad.class, f.getString(4)),
                f.getString(5), aEnum(EstadoNovedad.class, f.getString(6))));
    }

    public Optional<Novedad> porId(long idNovedad) {
        return consultarUno(SQL_POR_ID, new Object[] {idNovedad}, f -> new Novedad(f.getLong(1),
                aEnum(TipoNovedad.class, f.getString(2)), f.getString(3), aEnum(AccionNovedad.class, f.getString(4)),
                f.getString(5), aEnum(EstadoNovedad.class, f.getString(6))));
    }

    /** Bloquea la novedad con SELECT ... FOR UPDATE (C4); falso si no existe. */
    public boolean bloquearPorId(long idNovedad) {
        return consultarUno(SQL_BLOQUEAR, new Object[] {idNovedad}, f -> f.getLong(1)).isPresent();
    }

    public long insertar(long idAsignacion, Novedad n) {
        long id = insertarConClave(SQL_INSERTAR, new Object[] {idAsignacion, n.tipoNovedad(), n.descripcion(), n.accion(),
            n.solucion(), n.estado()}, "ID_NOVEDAD");
        n.asignarId(id);
        return id;
    }

    /** La mesa de servicio gestiona la novedad: accion, solucion y estado. */
    public void actualizarGestion(Novedad n) {
        ejecutar(SQL_ACTUALIZAR_GESTION, new Object[] {n.accion(), n.solucion(), n.estado(), n.idNovedad()});
    }
}
