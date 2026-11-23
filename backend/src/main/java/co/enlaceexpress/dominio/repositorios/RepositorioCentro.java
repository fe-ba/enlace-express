package co.enlaceexpress.dominio.repositorios;

import java.util.List;
import java.util.Optional;

import co.enlaceexpress.dominio.referencia.CentroDistribucion;
import co.enlaceexpress.dominio.referencia.Zona;

/** Centros de distribucion y sus zonas (CU13). No hay operaciones de borrado: un centro se inactiva (RN16). */
public interface RepositorioCentro {

    List<CentroDistribucion> centros();

    Optional<CentroDistribucion> centro(long idCentro);

    long insertarCentro(CentroDistribucion centro);

    void actualizarCentro(CentroDistribucion centro);

    /** Bloquea el centro con SELECT ... FOR UPDATE; falso si no existe. */
    boolean bloquearCentro(long idCentro);

    List<Zona> zonas();

    Optional<Zona> zona(long idZona);

    long insertarZona(Zona zona);

    void actualizarZona(Zona zona);

    /** Bloquea la zona con SELECT ... FOR UPDATE; falso si no existe. */
    boolean bloquearZona(long idZona);
}
