package co.enlaceexpress.datos.mapeadores;

import static co.enlaceexpress.datos.infraestructura.ConversorTipos.aEnum;
import static co.enlaceexpress.datos.infraestructura.ConversorTipos.aInstante;

import java.util.Optional;

import co.enlaceexpress.datos.infraestructura.UnidadDeTrabajo;
import co.enlaceexpress.dominio.despacho.PruebaEntrega;
import co.enlaceexpress.dominio.enums.TipoPrueba;

/** Mapeador de la prueba de entrega de una asignacion. */
public class PruebaEntregaMapper extends MapeadorJdbc {

    private static final String SQL_POR_ASIGNACION = """
            SELECT id_prueba, fecha_hora, nombre_receptor, documento_receptor, tipo_prueba, archivo_soporte
            FROM   prueba_entrega
            WHERE  id_asignacion = ?""";

    private static final String SQL_INSERTAR = """
            INSERT INTO prueba_entrega (id_asignacion, fecha_hora, nombre_receptor, documento_receptor, tipo_prueba, archivo_soporte)
            VALUES (?, ?, ?, ?, ?, ?)""";

    public PruebaEntregaMapper(UnidadDeTrabajo uow) {
        super(uow);
    }

    public Optional<PruebaEntrega> porAsignacion(long idAsignacion) {
        return consultarUno(SQL_POR_ASIGNACION, new Object[] {idAsignacion}, f -> new PruebaEntrega(f.getLong(1),
                aInstante(f.getTimestamp(2)), f.getString(3), f.getString(4), aEnum(TipoPrueba.class, f.getString(5)), f.getString(6)));
    }

    public long insertar(long idAsignacion, PruebaEntrega p) {
        long id = insertarConClave(SQL_INSERTAR, new Object[] {idAsignacion, p.fechaHora(), p.nombreReceptor(),
            p.documentoReceptor(), p.tipoPrueba(), p.archivoSoporte()}, "ID_PRUEBA");
        p.asignarId(id);
        return id;
    }
}
