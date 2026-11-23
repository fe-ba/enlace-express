package co.enlaceexpress.casosdeuso.centro;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.TreeSet;

import org.springframework.stereotype.Service;

import co.enlaceexpress.casosdeuso.indicadores.FilaEnvioEstado;
import co.enlaceexpress.casosdeuso.indicadores.FilaPlanilla;
import co.enlaceexpress.casosdeuso.indicadores.FilaPorDespachar;
import co.enlaceexpress.casosdeuso.seguridad.FabricaUnidadesDeTrabajo;
import co.enlaceexpress.casosdeuso.seguridad.UsuarioSesion;
import co.enlaceexpress.datos.informes.InformesMapper;
import co.enlaceexpress.datos.infraestructura.UnidadDeTrabajo;
import co.enlaceexpress.datos.mapeadores.DespachoMapper;
import co.enlaceexpress.datos.mapeadores.EnvioMapper;
import co.enlaceexpress.datos.mapeadores.ReferenciaMapper;
import co.enlaceexpress.dominio.despacho.AsignacionDespacho;
import co.enlaceexpress.dominio.despacho.Despacho;
import co.enlaceexpress.dominio.enums.EstadoEnvio;
import co.enlaceexpress.dominio.enums.Rol;
import co.enlaceexpress.dominio.enums.TipoDespacho;
import co.enlaceexpress.dominio.envio.Envio;
import co.enlaceexpress.dominio.referencia.Mensajero;
import co.enlaceexpress.dominio.referencia.Vehiculo;
import co.enlaceexpress.dominio.reglas.EntradaInvalida;
import co.enlaceexpress.dominio.reglas.RecursoNoEncontrado;

/**
 * Centro de distribucion (U2): recibir y clasificar (CU06 y CU07), consultar los envios por despachar (CU08),
 * armar el despacho de entrega con sus asignaciones y validaciones (CU09, CU10 y CU11) y cerrarlo (CU12). Cada
 * operacion es una transaccion: bloquea las filas que cambian de estado (C4), aplica el dominio y confirma una vez.
 */
@Service
public class ServicioCentro {

    private static final String GUIA_NO_ENCONTRADA = "No se encontró un envío con ese número de guía";

    /** Un mensajero activo del centro con su zona y el tipo de vehiculo que conduce. */
    public record ResumenMensajero(long idEmpleado, String nombres, String apellidos, Long idZona, int idTipoVehiculo, String tipoVehiculo) {
    }

    /** Un vehiculo disponible para el mensajero. */
    public record ResumenVehiculo(long idVehiculo, String placa, String marca, String modelo) {
    }

    public record DespachoArmado(long idDespacho, int asignaciones) {
    }

    public record DespachoCerrado(long idDespacho, String estado, LocalDateTime horaCierre) {
    }

    public record EnvioRecibido(String numeroGuia, String estadoActual) {
    }

    private final FabricaUnidadesDeTrabajo unidades;

    public ServicioCentro(FabricaUnidadesDeTrabajo unidades) {
        this.unidades = unidades;
    }

    /** El centro del empleado de la sesion. */
    private static long centroDe(UnidadDeTrabajo uow, UsuarioSesion usuario) {
        return new ReferenciaMapper(uow).empleado(usuario.idEmpleado()).orElseThrow().idCentro();
    }

    /** Envios RECOLECTADOS de su centro, por recibir (v_estado_actual_envio). */
    public List<FilaEnvioEstado> porRecibir(UsuarioSesion usuario) {
        try (UnidadDeTrabajo uow = unidades.para(usuario, Rol.CENTRO)) {
            return new InformesMapper(uow).enviosEnEstado(centroDe(uow, usuario), EstadoEnvio.RECOLECTADO);
        }
    }

    /** CU06 y CU07: EN_CENTRO y CLASIFICADO (instantes distintos, C5), peso real y flete (RN03, RN12). */
    public EnvioRecibido recibirYClasificar(UsuarioSesion usuario, String guia, BigDecimal pesoReal, BigDecimal valorFlete) {
        exigirFormato(guia);
        try (UnidadDeTrabajo uow = unidades.para(usuario, Rol.CENTRO)) {
            EnvioMapper envios = new EnvioMapper(uow);
            if (!envios.bloquearPorGuia(guia)) {
                throw new RecursoNoEncontrado(GUIA_NO_ENCONTRADA);
            }
            Envio envio = envios.buscarPorGuia(guia).orElseThrow();
            envio.clasificar(pesoReal, valorFlete);
            LocalDateTime ahora = LocalDateTime.now();
            envios.agregarEvento(guia, envio.registrarEvento(EstadoEnvio.EN_CENTRO, usuario.idEmpleado(), "Recibido y pesado en el centro", ahora));
            envios.agregarEvento(guia, envio.registrarEvento(EstadoEnvio.CLASIFICADO, usuario.idEmpleado(), "Clasificado por zona de destino", ahora));
            envios.actualizarClasificacion(envio);
            uow.confirmar();
            return new EnvioRecibido(guia, envio.estadoActual().name());
        }
    }

    /** CU08: envios clasificados que todavia no estan en un despacho de entrega abierto, en su centro. */
    public List<FilaPorDespachar> porDespachar(UsuarioSesion usuario) {
        try (UnidadDeTrabajo uow = unidades.para(usuario, Rol.CENTRO)) {
            return new InformesMapper(uow).enviosPorDespachar(centroDe(uow, usuario));
        }
    }

    public List<ResumenMensajero> mensajeros(UsuarioSesion usuario) {
        try (UnidadDeTrabajo uow = unidades.para(usuario, Rol.CENTRO)) {
            return new ReferenciaMapper(uow).mensajerosActivosDelCentro(centroDe(uow, usuario)).stream()
                    .map(m -> new ResumenMensajero(m.idEmpleado(), m.nombres(), m.apellidos(), m.idZona(),
                            m.tipoVehiculo().idTipoVehiculo(), m.tipoVehiculo().nombre())).toList();
        }
    }

    /** C9: vehiculos disponibles del tipo que conduce el mensajero. */
    public List<ResumenVehiculo> vehiculosDisponibles(UsuarioSesion usuario, long idMensajero) {
        try (UnidadDeTrabajo uow = unidades.para(usuario, Rol.CENTRO)) {
            return new DespachoMapper(uow).vehiculosDisponibles(idMensajero).stream()
                    .map((Vehiculo v) -> new ResumenVehiculo(v.idVehiculo(), v.placa(), v.marca(), v.modelo())).toList();
        }
    }

    /**
     * CU09, CU10 y CU11 (T05): valida vehiculo y mensajero (RN10, RN11), crea el despacho, una asignacion por envio con
     * su numero de intento (RN07) y orden de visita, y el evento EN_RUTA de cada uno (RN12). El centro del despacho es
     * el del empleado de la sesion. Todo o nada.
     */
    public DespachoArmado armarDespacho(UsuarioSesion usuario, Long idMensajero, Long idVehiculo, List<String> guias) {
        if (idMensajero == null) {
            throw new EntradaInvalida("idMensajero", "El mensajero es obligatorio");
        }
        if (idVehiculo == null) {
            throw new EntradaInvalida("idVehiculo", "El vehículo es obligatorio");
        }
        if (guias == null || guias.isEmpty()) {
            throw new EntradaInvalida("guias", "El despacho necesita al menos un envío");
        }
        // sin repetidos y en un orden fijo, para que dos despachos simultaneos bloqueen en el mismo orden
        List<String> ordenadas = List.copyOf(new TreeSet<>(guias));
        ordenadas.forEach(ServicioCentro::exigirFormato);
        try (UnidadDeTrabajo uow = unidades.para(usuario, Rol.CENTRO)) {
            ReferenciaMapper referencia = new ReferenciaMapper(uow);
            DespachoMapper despachos = new DespachoMapper(uow);
            EnvioMapper envios = new EnvioMapper(uow);
            Mensajero mensajero = referencia.mensajero(idMensajero)
                    .orElseThrow(() -> new EntradaInvalida("idMensajero", "El mensajero no existe"));
            Vehiculo vehiculo = referencia.vehiculo(idVehiculo)
                    .orElseThrow(() -> new EntradaInvalida("idVehiculo", "El vehículo no existe"));
            Despacho despacho = Despacho.armar(centroDe(uow, usuario), vehiculo, mensajero, LocalDate.now(), TipoDespacho.ENTREGA);
            despachos.insertar(despacho);
            LocalDateTime ahora = LocalDateTime.now();
            for (String guia : ordenadas) {
                if (!envios.bloquearPorGuia(guia)) {
                    throw new RecursoNoEncontrado(GUIA_NO_ENCONTRADA);
                }
                Envio envio = envios.buscarPorGuia(guia).orElseThrow();
                envio.cargarIntentos(despachos.asignacionesDeGuia(guia));
                AsignacionDespacho asignacion = despacho.asignar(envio);
                despachos.guardarAsignacion(despacho, asignacion);
                envios.agregarEvento(guia, envio.registrarEvento(EstadoEnvio.EN_RUTA, usuario.idEmpleado(),
                        "Sale en el despacho " + despacho.idDespacho() + " (intento " + asignacion.numeroIntento() + ")", ahora));
            }
            despacho.salir(LocalDateTime.now());
            despachos.actualizarEstado(despacho);
            uow.confirmar();
            return new DespachoArmado(despacho.idDespacho(), ordenadas.size());
        }
    }

    /** C3: planilla del despacho (v_planilla_despacho). */
    public List<FilaPlanilla> planilla(UsuarioSesion usuario, long idDespacho) {
        try (UnidadDeTrabajo uow = unidades.para(usuario, Rol.CENTRO)) {
            List<FilaPlanilla> filas = new InformesMapper(uow).planilla(idDespacho);
            if (filas.isEmpty() && new DespachoMapper(uow).buscarPorId(idDespacho).isEmpty()) {
                throw new RecursoNoEncontrado("No se encontró el despacho " + idDespacho);
            }
            return filas;
        }
    }

    /** CU12: hora de cierre y estado CERRADO. */
    public DespachoCerrado cerrar(UsuarioSesion usuario, long idDespacho) {
        try (UnidadDeTrabajo uow = unidades.para(usuario, Rol.CENTRO)) {
            DespachoMapper despachos = new DespachoMapper(uow);
            if (!despachos.bloquearPorId(idDespacho)) {
                throw new RecursoNoEncontrado("No se encontró el despacho " + idDespacho);
            }
            Despacho despacho = despachos.buscarPorId(idDespacho).orElseThrow();
            despacho.cerrar(LocalDateTime.now());
            despachos.actualizarEstado(despacho);
            uow.confirmar();
            return new DespachoCerrado(idDespacho, despacho.estado().name(), despacho.horaCierre());
        }
    }

    private static void exigirFormato(String guia) {
        if (!Envio.formatoDeGuiaValido(guia)) {
            throw new RecursoNoEncontrado(GUIA_NO_ENCONTRADA);
        }
    }
}
