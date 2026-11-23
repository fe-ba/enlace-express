package co.enlaceexpress.dominio.referencia;

import java.util.List;

/** Catalogos pequenos y fijos que se cargan juntos: modalidades y tipos de vehiculo. */
public record Catalogos(List<Modalidad> modalidades, List<TipoVehiculo> tiposVehiculo) {

    public Modalidad modalidad(int idModalidad) {
        return modalidades.stream().filter(m -> m.idModalidad() == idModalidad).findFirst()
                .orElseThrow(() -> new IllegalArgumentException("Modalidad inexistente: " + idModalidad));
    }

    public TipoVehiculo tipoVehiculo(int idTipoVehiculo) {
        return tiposVehiculo.stream().filter(t -> t.idTipoVehiculo() == idTipoVehiculo).findFirst()
                .orElseThrow(() -> new IllegalArgumentException("Tipo de vehiculo inexistente: " + idTipoVehiculo));
    }
}
