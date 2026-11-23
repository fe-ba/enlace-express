package co.enlaceexpress.datos.mapeadores;

import static co.enlaceexpress.datos.infraestructura.ConversorTipos.aEnum;

import java.util.List;
import java.util.Optional;

import co.enlaceexpress.datos.infraestructura.UnidadDeTrabajo;
import co.enlaceexpress.dominio.enums.EstadoActivo;
import co.enlaceexpress.dominio.referencia.CentroDistribucion;
import co.enlaceexpress.dominio.referencia.Zona;
import co.enlaceexpress.dominio.repositorios.RepositorioCentro;

/** Mapeador de los centros de distribucion y sus zonas (CU13). No borra filas (RN16). */
public class CentroZonaMapper extends MapeadorJdbc implements RepositorioCentro {

    private static final String COLUMNAS_CENTRO = "SELECT id_centro, nombre, direccion, telefono, estado FROM centro_distribucion";
    private static final String SQL_CENTROS = COLUMNAS_CENTRO + " ORDER BY id_centro";
    private static final String SQL_CENTRO = COLUMNAS_CENTRO + " WHERE id_centro = ?";
    private static final String SQL_INSERTAR_CENTRO = """
            INSERT INTO centro_distribucion (nombre, direccion, telefono, estado) VALUES (?, ?, ?, ?)""";
    private static final String SQL_ACTUALIZAR_CENTRO = """
            UPDATE centro_distribucion SET nombre = ?, direccion = ?, telefono = ?, estado = ? WHERE id_centro = ?""";
    private static final String SQL_BLOQUEAR_CENTRO = "SELECT id_centro FROM centro_distribucion WHERE id_centro = ? FOR UPDATE";

    private static final String COLUMNAS_ZONA = "SELECT id_zona, id_centro, nombre, localidades FROM zona";
    private static final String SQL_ZONAS = COLUMNAS_ZONA + " ORDER BY id_centro, id_zona";
    private static final String SQL_ZONA = COLUMNAS_ZONA + " WHERE id_zona = ?";
    private static final String SQL_INSERTAR_ZONA = "INSERT INTO zona (id_centro, nombre, localidades) VALUES (?, ?, ?)";
    private static final String SQL_ACTUALIZAR_ZONA = "UPDATE zona SET id_centro = ?, nombre = ?, localidades = ? WHERE id_zona = ?";
    private static final String SQL_BLOQUEAR_ZONA = "SELECT id_zona FROM zona WHERE id_zona = ? FOR UPDATE";

    public CentroZonaMapper(UnidadDeTrabajo uow) {
        super(uow);
    }

    private static CentroDistribucion aCentro(java.sql.ResultSet f) throws java.sql.SQLException {
        return new CentroDistribucion(f.getLong(1), f.getString(2), f.getString(3), f.getString(4),
                aEnum(EstadoActivo.class, f.getString(5)));
    }

    private static Zona aZona(java.sql.ResultSet f) throws java.sql.SQLException {
        return new Zona(f.getLong(1), f.getLong(2), f.getString(3), f.getString(4));
    }

    @Override
    public List<CentroDistribucion> centros() {
        return consultar(SQL_CENTROS, new Object[0], CentroZonaMapper::aCentro);
    }

    @Override
    public Optional<CentroDistribucion> centro(long idCentro) {
        return consultarUno(SQL_CENTRO, new Object[] {idCentro}, CentroZonaMapper::aCentro);
    }

    @Override
    public long insertarCentro(CentroDistribucion c) {
        return insertarConClave(SQL_INSERTAR_CENTRO, new Object[] {c.nombre(), c.direccion(), c.telefono(), c.estado()}, "ID_CENTRO");
    }

    @Override
    public void actualizarCentro(CentroDistribucion c) {
        ejecutar(SQL_ACTUALIZAR_CENTRO, new Object[] {c.nombre(), c.direccion(), c.telefono(), c.estado(), c.idCentro()});
    }

    @Override
    public boolean bloquearCentro(long idCentro) {
        return consultarUno(SQL_BLOQUEAR_CENTRO, new Object[] {idCentro}, f -> f.getLong(1)).isPresent();
    }

    @Override
    public List<Zona> zonas() {
        return consultar(SQL_ZONAS, new Object[0], CentroZonaMapper::aZona);
    }

    @Override
    public Optional<Zona> zona(long idZona) {
        return consultarUno(SQL_ZONA, new Object[] {idZona}, CentroZonaMapper::aZona);
    }

    @Override
    public long insertarZona(Zona z) {
        return insertarConClave(SQL_INSERTAR_ZONA, new Object[] {z.idCentro(), z.nombre(), z.localidades()}, "ID_ZONA");
    }

    @Override
    public void actualizarZona(Zona z) {
        ejecutar(SQL_ACTUALIZAR_ZONA, new Object[] {z.idCentro(), z.nombre(), z.localidades(), z.idZona()});
    }

    @Override
    public boolean bloquearZona(long idZona) {
        return consultarUno(SQL_BLOQUEAR_ZONA, new Object[] {idZona}, f -> f.getLong(1)).isPresent();
    }
}
