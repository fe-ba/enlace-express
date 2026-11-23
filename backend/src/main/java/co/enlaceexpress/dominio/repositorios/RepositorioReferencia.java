package co.enlaceexpress.dominio.repositorios;

import java.util.Optional;

import co.enlaceexpress.dominio.envio.Destinatario;
import co.enlaceexpress.dominio.enums.TipoDocumento;
import co.enlaceexpress.dominio.referencia.Catalogos;
import co.enlaceexpress.dominio.referencia.Cliente;
import co.enlaceexpress.dominio.referencia.Empleado;
import co.enlaceexpress.dominio.referencia.Mensajero;
import co.enlaceexpress.dominio.referencia.SedeCliente;
import co.enlaceexpress.dominio.referencia.Vehiculo;
import co.enlaceexpress.dominio.referencia.Zona;

/** Lectura de los datos de referencia y los catalogos. */
public interface RepositorioReferencia {

    Optional<Cliente> cliente(long idCliente);

    Optional<SedeCliente> sede(long idSede);

    Optional<Zona> zona(long idZona);

    Optional<Empleado> empleado(long idEmpleado);

    Optional<Mensajero> mensajero(long idMensajero);

    Optional<Vehiculo> vehiculo(long idVehiculo);

    Catalogos catalogos();

    /** Agregado a lo del diagrama: clientes ACTIVOS por razon social (formulario de solicitudes). */
    java.util.List<Cliente> clientesActivos();

    /** Agregado a lo del diagrama: todos los clientes, activos o no, por razon social (reclamaciones). */
    java.util.List<Cliente> clientes();

    /** Agregado a lo del diagrama: sedes de un cliente. */
    java.util.List<SedeCliente> sedesDeCliente(long idCliente);

    /** Agregado a lo del diagrama: todas las zonas. */
    java.util.List<Zona> zonas();

    /** Agregado a lo del diagrama: mensajeros ACTIVOS de un centro, con su zona y tipo de vehiculo. */
    java.util.List<Mensajero> mensajerosActivosDelCentro(long idCentro);

    /** Agregado a lo del diagrama (DestinatarioMapper): busca un destinatario por documento (RN04). */
    Optional<Destinatario> destinatarioPorDocumento(TipoDocumento tipo, String numero);

    Optional<Destinatario> destinatario(long idDestinatario);
}
