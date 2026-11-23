package co.enlaceexpress.casosdeuso.ruta;

import java.time.LocalDateTime;
import java.util.List;

import org.springframework.stereotype.Service;

import co.enlaceexpress.casosdeuso.indicadores.FilaPlanilla;
import co.enlaceexpress.casosdeuso.seguridad.FabricaUnidadesDeTrabajo;
import co.enlaceexpress.casosdeuso.seguridad.UsuarioSesion;
import co.enlaceexpress.datos.informes.InformesMapper;
import co.enlaceexpress.datos.infraestructura.UnidadDeTrabajo;
import co.enlaceexpress.datos.mapeadores.DespachoMapper;
import co.enlaceexpress.datos.mapeadores.EnvioMapper;
import co.enlaceexpress.dominio.despacho.AsignacionDespacho;
import co.enlaceexpress.dominio.despacho.Despacho;
import co.enlaceexpress.dominio.despacho.Novedad;
import co.enlaceexpress.dominio.despacho.PruebaEntrega;
import co.enlaceexpress.dominio.enums.EstadoEnvio;
import co.enlaceexpress.dominio.enums.Rol;
import co.enlaceexpress.dominio.enums.TipoNovedad;
import co.enlaceexpress.dominio.enums.TipoPrueba;
import co.enlaceexpress.dominio.envio.Destinatario;
import co.enlaceexpress.dominio.envio.Envio;
import co.enlaceexpress.dominio.reglas.EntradaInvalida;
import co.enlaceexpress.dominio.reglas.EstadoIncorrecto;
import co.enlaceexpress.dominio.reglas.RecursoNoEncontrado;

/**
 * Ruta del mensajero (U4): planilla (CU14), entrega con prueba (CU16 y CU19), novedad (CU17) y devolucion en el
 * tercer intento (CU18). Toda operacion sobre una asignacion comprueba que es de un despacho del mensajero de la
 * sesion; si no, responde que no existe (404), sin revelar que existe. Cada operacion bloquea el envio y la
 * asignacion (C4), aplica el dominio y confirma una sola vez.
 */
@Service
public class ServicioRuta {

    private static final String NO_ENCONTRADA = "No se encontró la asignación";

    /** Datos de la prueba de entrega que registra el mensajero. */
    public record DatosPrueba(String nombreReceptor, String documentoReceptor, TipoPrueba tipoPrueba) {
    }

    /** Datos de la novedad. */
    public record DatosNovedad(TipoNovedad tipoNovedad, String descripcion) {
    }

    /** Resultado de la operacion: la asignacion, su resultado y el estado en que quedo el envio. */
    public record ResultadoAsignacion(long idAsignacion, String numeroGuia, String resultado, String estadoEnvio) {
    }

    private final FabricaUnidadesDeTrabajo unidades;

    public ServicioRuta(FabricaUnidadesDeTrabajo unidades) {
        this.unidades = unidades;
    }

    /** CU14: asignaciones de sus despachos no cerrados, en orden de visita. */
    public List<FilaPlanilla> planilla(UsuarioSesion usuario) {
        try (UnidadDeTrabajo uow = unidades.para(usuario, Rol.MENSAJERO)) {
            return new InformesMapper(uow).planillaDelMensajero(usuario.idEmpleado());
        }
    }

    /** CU16 y CU19: prueba de entrega, resultado ENTREGADO y evento (RN05, RN06, RN08, RN12; el intento 3 solo devuelve, RN07). */
    public ResultadoAsignacion registrarEntrega(UsuarioSesion usuario, long idAsignacion, DatosPrueba datos) {
        PruebaEntrega prueba = prueba(datos);
        return operar(usuario, idAsignacion, (a, envio, ahora) -> {
            a.registrarEntrega(prueba);
            return EstadoEnvio.ENTREGADO;
        }, prueba.nombreReceptor(), "Entregado a ", prueba);
    }

    /** CU17: novedad, resultado NOVEDAD y evento CON_NOVEDAD (RN07, RN08, RN12). */
    public ResultadoAsignacion registrarNovedad(UsuarioSesion usuario, long idAsignacion, DatosNovedad datos) {
        if (datos == null || datos.tipoNovedad() == null) {
            throw new EntradaInvalida("tipoNovedad", "El tipo de novedad es obligatorio");
        }
        if (datos.descripcion() == null || datos.descripcion().isBlank()) {
            throw new EntradaInvalida("descripcion", "La descripción de la novedad es obligatoria");
        }
        Novedad novedad = Novedad.nueva(datos.tipoNovedad(), datos.descripcion().strip());
        return operar(usuario, idAsignacion, (a, envio, ahora) -> {
            a.registrarNovedad(novedad);
            return EstadoEnvio.CON_NOVEDAD;
        }, datos.tipoNovedad().name(), "Novedad: ", null);
    }

    /** CU18: devolucion en el tercer intento, con su prueba (RN05, RN07, RN12). */
    public ResultadoAsignacion registrarDevolucion(UsuarioSesion usuario, long idAsignacion, DatosPrueba datos) {
        PruebaEntrega prueba = prueba(datos);
        return operar(usuario, idAsignacion, (a, envio, ahora) -> {
            a.registrarDevolucion(prueba);
            return EstadoEnvio.DEVUELTO;
        }, prueba.nombreReceptor(), "Devuelto; recibe ", prueba);
    }

    /** Lo que cambia entre entrega, novedad y devolucion: la regla del dominio y el estado resultante. */
    private interface Accion {
        EstadoEnvio aplicar(AsignacionDespacho asignacion, Envio envio, LocalDateTime ahora);
    }

    private ResultadoAsignacion operar(UsuarioSesion usuario, long idAsignacion, Accion accion, String detalle,
            String prefijoObservacion, PruebaEntrega prueba) {
        try (UnidadDeTrabajo uow = unidades.para(usuario, Rol.MENSAJERO)) {
            DespachoMapper despachos = new DespachoMapper(uow);
            EnvioMapper envios = new EnvioMapper(uow);
            InformesMapper informes = new InformesMapper(uow);

            // 1. la asignacion debe ser de un despacho abierto del mensajero de la sesion; si no, 404
            AsignacionDespacho previa = despachos.buscarAsignacion(idAsignacion).orElseThrow(() -> new RecursoNoEncontrado(NO_ENCONTRADA));
            Despacho despacho = despachos.buscarPorId(previa.idDespacho()).orElseThrow(() -> new RecursoNoEncontrado(NO_ENCONTRADA));
            if (despacho.idMensajero() != usuario.idEmpleado()) {
                throw new RecursoNoEncontrado(NO_ENCONTRADA);
            }
            if (!despacho.estaAbierto()) {
                throw new EstadoIncorrecto("El despacho " + despacho.idDespacho() + " ya está cerrado");
            }

            // 2. bloqueos (C4): el envio y la asignacion cuyo estado cambia
            String guia = previa.numeroGuia();
            envios.bloquearPorGuia(guia);
            despachos.bloquearAsignacion(idAsignacion);

            // 3. el envio con sus intentos y el documento del destinatario (de la planilla, que el mensajero si puede leer)
            Envio envio = envios.buscarPorGuia(guia).orElseThrow();
            FilaPlanilla fila = informes.planilla(despacho.idDespacho()).stream()
                    .filter(f -> f.idAsignacion() == idAsignacion).findFirst().orElseThrow(() -> new RecursoNoEncontrado(NO_ENCONTRADA));
            envio.asignarDestinatario(new Destinatario(null, fila.tipoDocumentoDestinatario(), fila.numeroDocumentoDestinatario(),
                    fila.destinatario(), fila.telefono(), null));
            List<AsignacionDespacho> intentos = despachos.asignacionesDeGuia(guia);
            envio.cargarIntentos(intentos);
            AsignacionDespacho asignacion = intentos.stream().filter(i -> i.idAsignacion() == idAsignacion).findFirst().orElseThrow();

            // 4. reglas del dominio y persistencia
            LocalDateTime ahora = LocalDateTime.now();
            EstadoEnvio nuevoEstado = accion.aplicar(asignacion, envio, ahora);
            despachos.guardarResultado(asignacion);
            envios.agregarEvento(guia, envio.registrarEvento(nuevoEstado, usuario.idEmpleado(), prefijoObservacion + detalle, ahora));
            uow.confirmar();
            return new ResultadoAsignacion(idAsignacion, guia, asignacion.resultado().name(), envio.estadoActual().name());
        }
    }

    private static PruebaEntrega prueba(DatosPrueba datos) {
        if (datos == null || datos.nombreReceptor() == null || datos.nombreReceptor().isBlank()) {
            throw new EntradaInvalida("nombreReceptor", "El nombre de quien recibe es obligatorio");
        }
        if (datos.documentoReceptor() == null || datos.documentoReceptor().isBlank()) {
            throw new EntradaInvalida("documentoReceptor", "El documento de quien recibe es obligatorio");
        }
        if (datos.tipoPrueba() == null) {
            throw new EntradaInvalida("tipoPrueba", "El tipo de prueba es obligatorio (FIRMA, DOCUMENTO o FOTOGRAFIA)");
        }
        return new PruebaEntrega(null, LocalDateTime.now(), datos.nombreReceptor().strip(), datos.documentoReceptor().strip(),
                datos.tipoPrueba(), null);
    }
}
