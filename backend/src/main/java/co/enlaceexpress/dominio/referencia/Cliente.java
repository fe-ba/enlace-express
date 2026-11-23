package co.enlaceexpress.dominio.referencia;

import java.time.LocalDate;

import co.enlaceexpress.dominio.enums.EstadoActivo;
import co.enlaceexpress.dominio.enums.TipoCliente;

/** Empresa que contrata el servicio. */
public record Cliente(Long idCliente, String nit, String razonSocial, TipoCliente tipoCliente, String telefono,
        String correo, LocalDate fechaVinculacion, EstadoActivo estado) {

    public boolean estaActivo() {
        return estado == EstadoActivo.ACTIVO;
    }
}
