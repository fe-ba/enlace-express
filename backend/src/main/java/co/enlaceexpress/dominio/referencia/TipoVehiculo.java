package co.enlaceexpress.dominio.referencia;

import java.math.BigDecimal;

/** Catalogo de tipos de vehiculo (MOTOCICLETA, FURGONETA, BICICLETA_ELECTRICA). */
public record TipoVehiculo(int idTipoVehiculo, String nombre, BigDecimal capacidadMaxKg) {
}
