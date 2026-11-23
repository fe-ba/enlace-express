package co.enlaceexpress.dominio.referencia;

import java.time.LocalDate;

import co.enlaceexpress.dominio.enums.EstadoEmpleado;

/** Empleado que conduce un tipo de vehiculo y atiende una zona (subtipo de Empleado). */
public class Mensajero extends Empleado {

    private final Long idZona;
    private final TipoVehiculo tipoVehiculo;

    public Mensajero(Long idEmpleado, long idCentro, String documento, String nombres, String apellidos, String cargo,
            String telefono, String correo, LocalDate fechaIngreso, LocalDate fechaRetiro, String motivoRetiro,
            EstadoEmpleado estado, Long idZona, TipoVehiculo tipoVehiculo) {
        super(idEmpleado, idCentro, documento, nombres, apellidos, cargo, telefono, correo, fechaIngreso, fechaRetiro,
                motivoRetiro, estado);
        this.idZona = idZona;
        this.tipoVehiculo = tipoVehiculo;
    }

    public Long idZona() { return idZona; }
    public TipoVehiculo tipoVehiculo() { return tipoVehiculo; }

    /** RN11: el vehiculo del despacho debe ser del tipo que conduce el mensajero. */
    public boolean puedeConducir(TipoVehiculo tipo) {
        return tipoVehiculo.idTipoVehiculo() == tipo.idTipoVehiculo();
    }
}
