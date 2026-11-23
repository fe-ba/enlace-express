package co.enlaceexpress.dominio.referencia;

import java.math.BigDecimal;

import co.enlaceexpress.dominio.enums.EstadoVehiculo;

/** Vehiculo de un centro; solo uno DISPONIBLE puede asignarse a un despacho (RN10). */
public record Vehiculo(Long idVehiculo, long idCentro, TipoVehiculo tipo, String placa, String marca, String modelo,
        BigDecimal capacidadKg, boolean electrico, EstadoVehiculo estado) {

    public boolean estaDisponible() {
        return estado == EstadoVehiculo.DISPONIBLE;
    }
}
