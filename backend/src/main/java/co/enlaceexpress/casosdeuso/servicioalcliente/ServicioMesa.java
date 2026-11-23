package co.enlaceexpress.casosdeuso.servicioalcliente;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

import org.springframework.stereotype.Service;

import co.enlaceexpress.casosdeuso.indicadores.FilaSeguimiento;
import co.enlaceexpress.casosdeuso.seguridad.FabricaUnidadesDeTrabajo;
import co.enlaceexpress.casosdeuso.seguridad.UsuarioSesion;
import co.enlaceexpress.datos.informes.InformesMapper;
import co.enlaceexpress.datos.infraestructura.UnidadDeTrabajo;
import co.enlaceexpress.datos.mapeadores.DestinatarioMapper;
import co.enlaceexpress.datos.mapeadores.EnvioMapper;
import co.enlaceexpress.datos.mapeadores.ReferenciaMapper;
import co.enlaceexpress.datos.mapeadores.SolicitudMapper;
import co.enlaceexpress.dominio.enums.EstadoEnvio;
import co.enlaceexpress.dominio.enums.Rol;
import co.enlaceexpress.dominio.enums.TipoDocumento;
import co.enlaceexpress.dominio.envio.Destinatario;
import co.enlaceexpress.dominio.envio.Envio;
import co.enlaceexpress.dominio.referencia.Catalogos;
import co.enlaceexpress.dominio.referencia.Cliente;
import co.enlaceexpress.dominio.referencia.Modalidad;
import co.enlaceexpress.dominio.referencia.SedeCliente;
import co.enlaceexpress.dominio.referencia.Zona;
import co.enlaceexpress.dominio.reglas.RecursoNoEncontrado;
import co.enlaceexpress.dominio.reglas.ReglasDeNegocio;

/**
 * Mesa de servicio (U3): datos de los formularios, registro de envios (CU02, CU03 y CU04), consulta del envio (C1 y
 * C2) y anulacion (CU05). Cada operacion es una transaccion con el rol y el usuario de la sesion.
 */
@Service
public class ServicioMesa {

    public static final String NO_ENCONTRADO = ServicioRastreo.NO_ENCONTRADO;

    /** Datos del destinatario que escribe la mesa al registrar un envio. */
    public record DatosDestinatario(TipoDocumento tipoDocumento, String numeroDocumento, String nombre, String telefono, String correo) {
    }

    /** Datos del envio nuevo. */
    public record DatosEnvio(Long idSolicitud, DatosDestinatario destinatario, Long idZona, Integer idModalidad,
            String direccionDestino, BigDecimal pesoDeclarado, String contenido, BigDecimal valorDeclarado,
            boolean fragil, boolean altoValor, LocalDate fechaCompromiso) {
    }

    public record EnvioRegistrado(String numeroGuia, LocalDate fechaCompromiso) {
    }

    /** Resumen de un cliente para el formulario de solicitudes. */
    public record ResumenCliente(Long idCliente, String nit, String razonSocial, String tipoCliente, String estado) {
    }

    /** C1 y C2: datos del envio, su destinatario y su recorrido. */
    public record DetalleEnvio(String numeroGuia, long idSolicitud, LocalDate fechaRegistro, LocalDate fechaCompromiso,
            String estadoActual, String direccionDestino, BigDecimal pesoDeclarado, BigDecimal pesoReal, String contenido,
            BigDecimal valorDeclarado, boolean fragil, boolean altoValor, BigDecimal valorFlete, long idZona, int idModalidad,
            Destinatario destinatario, List<FilaSeguimiento> recorrido) {
    }

    public record EnvioAnulado(String numeroGuia, String estadoActual) {
    }

    private final FabricaUnidadesDeTrabajo unidades;

    public ServicioMesa(FabricaUnidadesDeTrabajo unidades) {
        this.unidades = unidades;
    }

    /** Los clientes ACTIVOS (solicitudes, RN15) o, con {@code todos}, tambien los inactivos (reclamaciones). */
    public List<ResumenCliente> clientes(UsuarioSesion usuario, boolean todos) {
        try (UnidadDeTrabajo uow = unidades.para(usuario, Rol.MESA)) {
            ReferenciaMapper referencia = new ReferenciaMapper(uow);
            return (todos ? referencia.clientes() : referencia.clientesActivos()).stream()
                    .map((Cliente c) -> new ResumenCliente(c.idCliente(), c.nit(), c.razonSocial(), c.tipoCliente().name(), c.estado().name())).toList();
        }
    }

    public List<SedeCliente> sedes(UsuarioSesion usuario, long idCliente) {
        try (UnidadDeTrabajo uow = unidades.para(usuario, Rol.MESA)) {
            return new ReferenciaMapper(uow).sedesDeCliente(idCliente);
        }
    }

    public List<Zona> zonas(UsuarioSesion usuario) {
        try (UnidadDeTrabajo uow = unidades.para(usuario, Rol.MESA)) {
            return new ReferenciaMapper(uow).zonas();
        }
    }

    public List<Modalidad> modalidades(UsuarioSesion usuario) {
        try (UnidadDeTrabajo uow = unidades.para(usuario, Rol.MESA)) {
            return new ReferenciaMapper(uow).catalogos().modalidades();
        }
    }

    /**
     * CU02 (con CU03 y CU04): valida los datos (RN02, RN03), bloquea la solicitud y registra el envio con el
     * procedimiento de la base (destinatario nuevo o existente, guia, envio y evento REGISTRADO).
     */
    public EnvioRegistrado registrarEnvio(UsuarioSesion usuario, DatosEnvio datos) {
        ReglasDeNegocio.exigir(datos.idSolicitud() != null, "la solicitud de recoleccion");
        ReglasDeNegocio.exigir(datos.idZona() != null, "la zona");
        try (UnidadDeTrabajo uow = unidades.para(usuario, Rol.MESA)) {
            if (!new SolicitudMapper(uow).bloquearPorId(datos.idSolicitud())) {
                throw new RecursoNoEncontrado("No se encontró la solicitud " + datos.idSolicitud());
            }
            Catalogos catalogos = new ReferenciaMapper(uow).catalogos();
            Modalidad modalidad = datos.idModalidad() == null ? null : catalogos.modalidades().stream()
                    .filter(m -> m.idModalidad() == datos.idModalidad()).findFirst().orElse(null);
            DatosDestinatario d = datos.destinatario();
            Destinatario destinatario = d == null ? null
                    : new Destinatario(null, d.tipoDocumento(), vacioANulo(d.numeroDocumento()), vacioANulo(d.nombre()),
                            vacioANulo(d.telefono()), vacioANulo(d.correo()));
            Envio envio = Envio.nuevo(datos.idSolicitud(), destinatario, datos.idZona(), modalidad, datos.direccionDestino(),
                    datos.pesoDeclarado(), datos.contenido(), datos.valorDeclarado(), datos.fragil(), datos.altoValor(),
                    datos.fechaCompromiso(), usuario.idEmpleado(), LocalDateTime.now());
            String guia = new EnvioMapper(uow).registrar(envio);
            uow.confirmar();
            return new EnvioRegistrado(guia, envio.fechaCompromiso());
        }
    }

    /** C1 y C2: el envio, su destinatario y su recorrido. */
    public DetalleEnvio consultar(UsuarioSesion usuario, String guia) {
        exigirFormato(guia);
        try (UnidadDeTrabajo uow = unidades.para(usuario, Rol.MESA)) {
            Envio e = new EnvioMapper(uow).buscarPorGuia(guia).orElseThrow(() -> new RecursoNoEncontrado(NO_ENCONTRADO));
            Destinatario destinatario = new DestinatarioMapper(uow).buscarPorId(e.idDestinatario()).orElse(null);
            List<FilaSeguimiento> recorrido = new InformesMapper(uow).seguimiento(guia, null);
            return new DetalleEnvio(e.numeroGuia(), e.idSolicitud(), e.fechaRegistro(), e.fechaCompromiso(),
                    e.estadoActual() == null ? null : e.estadoActual().name(), e.direccionDestino(), e.pesoDeclarado(),
                    e.pesoReal(), e.contenido(), e.valorDeclarado(), e.fragil(), e.altoValor(), e.valorFlete(), e.idZona(),
                    e.idModalidad(), destinatario, recorrido);
        }
    }

    /** CU05: evento ANULADO; solo antes de salir a ruta (RN12). */
    public EnvioAnulado anular(UsuarioSesion usuario, String guia, String observacion) {
        exigirFormato(guia);
        try (UnidadDeTrabajo uow = unidades.para(usuario, Rol.MESA)) {
            EnvioMapper envios = new EnvioMapper(uow);
            if (!envios.bloquearPorGuia(guia)) {
                throw new RecursoNoEncontrado(NO_ENCONTRADO);
            }
            Envio envio = envios.buscarPorGuia(guia).orElseThrow();
            String texto = observacion == null || observacion.isBlank() ? "Anulado" : observacion.strip();
            envios.agregarEvento(guia, envio.registrarEvento(EstadoEnvio.ANULADO, usuario.idEmpleado(), texto, LocalDateTime.now()));
            uow.confirmar();
            return new EnvioAnulado(guia, envio.estadoActual().name());
        }
    }

    private static void exigirFormato(String guia) {
        if (!Envio.formatoDeGuiaValido(guia)) {
            throw new RecursoNoEncontrado(NO_ENCONTRADO);
        }
    }

    private static String vacioANulo(String texto) {
        return texto == null || texto.isBlank() ? null : texto.strip();
    }
}
