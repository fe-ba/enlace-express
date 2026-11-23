package co.enlaceexpress.dominio;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

import co.enlaceexpress.dominio.despacho.AsignacionDespacho;
import co.enlaceexpress.dominio.despacho.Despacho;
import co.enlaceexpress.dominio.despacho.PruebaEntrega;
import co.enlaceexpress.dominio.enums.EstadoActivo;
import co.enlaceexpress.dominio.enums.EstadoEmpleado;
import co.enlaceexpress.dominio.enums.EstadoVehiculo;
import co.enlaceexpress.dominio.enums.TipoCliente;
import co.enlaceexpress.dominio.enums.TipoDespacho;
import co.enlaceexpress.dominio.enums.TipoDocumento;
import co.enlaceexpress.dominio.enums.TipoPrueba;
import co.enlaceexpress.dominio.envio.Destinatario;
import co.enlaceexpress.dominio.envio.Envio;
import co.enlaceexpress.dominio.referencia.Cliente;
import co.enlaceexpress.dominio.referencia.Mensajero;
import co.enlaceexpress.dominio.referencia.Modalidad;
import co.enlaceexpress.dominio.referencia.TipoVehiculo;
import co.enlaceexpress.dominio.referencia.Vehiculo;

/** Objetos de ejemplo para las pruebas unitarias del dominio. */
public final class Ejemplos {

    public static final LocalDateTime AHORA = LocalDateTime.of(2026, 11, 20, 9, 0, 0);
    public static final TipoVehiculo MOTO = new TipoVehiculo(1, "MOTOCICLETA", new BigDecimal("40"));
    public static final TipoVehiculo FURGONETA = new TipoVehiculo(2, "FURGONETA", new BigDecimal("800"));
    public static final Modalidad ESTANDAR = new Modalidad(3, "ESTANDAR", 3);
    public static final Destinatario LUIS = new Destinatario(1L, TipoDocumento.CC, "52000111", "Luis Pérez", "3153334444", null);

    private Ejemplos() {
    }

    public static Cliente cliente(EstadoActivo estado) {
        return new Cliente(1L, "900123456", "Cliente", TipoCliente.DROGUERIA, "3001", "a@example.com", LocalDate.of(2026, 1, 10), estado);
    }

    public static Vehiculo vehiculo(TipoVehiculo tipo, EstadoVehiculo estado) {
        return new Vehiculo(1L, 1, tipo, "ABC123", "Honda", "CB125", new BigDecimal("40"), false, estado);
    }

    public static Mensajero mensajero(TipoVehiculo tipo, EstadoEmpleado estado) {
        return new Mensajero(7L, 1, "1040777007", "Andrea", "Salazar", "Mensajero", "3201", null, LocalDate.of(2025, 9, 1), null,
                null, estado, 1L, tipo);
    }

    public static Envio envioNuevo(boolean fragil, boolean altoValor) {
        Envio envio = Envio.nuevo(1L, LUIS, 1, ESTANDAR, "Calle 1 # 2-3", new BigDecimal("2.5"), "Libros", new BigDecimal("1000"),
                fragil, altoValor, null, 4L, AHORA);
        envio.asignarGuia("EE0000000000099");
        return envio;
    }

    public static Despacho despachoDeEntrega() {
        Despacho d = Despacho.armar(1, vehiculo(MOTO, EstadoVehiculo.DISPONIBLE), mensajero(MOTO, EstadoEmpleado.ACTIVO),
                LocalDate.of(2026, 11, 20), TipoDespacho.ENTREGA);
        d.asignarId(15);
        return d;
    }

    public static PruebaEntrega prueba(String documento) {
        return new PruebaEntrega(null, AHORA.plusHours(5), "Receptor", documento, TipoPrueba.DOCUMENTO, null);
    }

    /** Un envio clasificado y listo con un intento ya asignado en un despacho de entrega. */
    public static AsignacionDespacho intentoUno(Envio envio) {
        return despachoDeEntrega().asignar(envio);
    }
}
