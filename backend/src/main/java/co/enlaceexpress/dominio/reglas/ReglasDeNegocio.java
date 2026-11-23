package co.enlaceexpress.dominio.reglas;

import java.math.BigDecimal;
import java.time.LocalDate;

import co.enlaceexpress.dominio.referencia.Cliente;
import co.enlaceexpress.dominio.referencia.Mensajero;
import co.enlaceexpress.dominio.referencia.Vehiculo;

/**
 * Reglas del capitulo 4 que el dominio verifica antes de tocar la base de datos. Cada una lanza
 * {@link ReglaNegocioException} con el codigo de la regla (el mismo de los disparadores). La
 * base las verifica de nuevo como garantia final. Las reglas de la entrega (RN05 a RN08) estan
 * en AsignacionDespacho y Despacho, que son quienes tienen los datos.
 */
public final class ReglasDeNegocio {

    private ReglasDeNegocio() {
    }

    /** RN02: datos obligatorios del envio. */
    public static void exigir(boolean presente, String dato) {
        if (!presente) {
            throw ReglaNegocioException.deDominio("RN02", "el envío exige " + dato + " (dato obligatorio ausente)");
        }
    }

    /** RN03: la fecha de compromiso no es anterior a la de registro, los pesos son positivos y el valor no es negativo. */
    public static void validarMagnitudes(LocalDate registro, LocalDate compromiso, BigDecimal pesoDeclarado, BigDecimal valorDeclarado) {
        if (compromiso.isBefore(registro)) {
            throw ReglaNegocioException.deDominio("RN03", "la fecha de compromiso no puede ser anterior a la de registro");
        }
        if (pesoDeclarado.signum() <= 0) {
            throw ReglaNegocioException.deDominio("RN03", "el peso declarado debe ser positivo");
        }
        if (valorDeclarado.signum() < 0) {
            throw ReglaNegocioException.deDominio("RN03", "el valor declarado no puede ser negativo");
        }
    }

    public static void validarPesoYFlete(BigDecimal pesoReal, BigDecimal flete) {
        if (pesoReal == null || pesoReal.signum() <= 0) {
            throw ReglaNegocioException.deDominio("RN03", "el peso real debe ser positivo");
        }
        if (flete == null || flete.signum() <= 0) {
            throw ReglaNegocioException.deDominio("RN03", "el flete debe ser positivo");
        }
    }

    /** RN15: solo se registran solicitudes de clientes activos. */
    public static void validarClienteActivo(Cliente cliente) {
        if (!cliente.estaActivo()) {
            throw ReglaNegocioException.deDominio("RN15",
                    "el cliente dueño de la sede está " + cliente.estado() + "; solo se registran solicitudes de clientes activos");
        }
    }

    /** RN10 (vehiculo DISPONIBLE y mensajero ACTIVO) y RN11 (el vehiculo es del tipo que conduce el mensajero). */
    public static void validarVehiculoYMensajero(Vehiculo vehiculo, Mensajero mensajero) {
        if (!vehiculo.estaDisponible()) {
            throw ReglaNegocioException.deDominio("RN10",
                    "el vehículo " + vehiculo.idVehiculo() + " está " + vehiculo.estado() + "; debe estar DISPONIBLE");
        }
        if (!mensajero.estaActivo()) {
            throw ReglaNegocioException.deDominio("RN10",
                    "el mensajero " + mensajero.idEmpleado() + " está " + mensajero.estado() + "; debe estar ACTIVO");
        }
        if (!mensajero.puedeConducir(vehiculo.tipo())) {
            throw ReglaNegocioException.deDominio("RN11",
                    "el vehículo " + vehiculo.idVehiculo() + " no es del tipo que conduce el mensajero " + mensajero.idEmpleado());
        }
    }
}
