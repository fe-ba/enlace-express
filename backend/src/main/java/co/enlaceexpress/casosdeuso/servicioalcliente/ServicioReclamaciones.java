package co.enlaceexpress.casosdeuso.servicioalcliente;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

import org.springframework.stereotype.Service;

import co.enlaceexpress.casosdeuso.indicadores.FilaReclamacion;
import co.enlaceexpress.casosdeuso.seguridad.FabricaUnidadesDeTrabajo;
import co.enlaceexpress.casosdeuso.seguridad.UsuarioSesion;
import co.enlaceexpress.datos.informes.InformesMapper;
import co.enlaceexpress.datos.infraestructura.UnidadDeTrabajo;
import co.enlaceexpress.datos.mapeadores.ReclamacionMapper;
import co.enlaceexpress.datos.mapeadores.ReferenciaMapper;
import co.enlaceexpress.dominio.enums.EstadoReclamacion;
import co.enlaceexpress.dominio.enums.Rol;
import co.enlaceexpress.dominio.enums.TipoReclamacion;
import co.enlaceexpress.dominio.envio.Envio;
import co.enlaceexpress.dominio.reclamacion.Reclamacion;
import co.enlaceexpress.dominio.reglas.EntradaInvalida;
import co.enlaceexpress.dominio.reglas.RecursoNoEncontrado;

/**
 * CU22 Registrar reclamacion y CU23 Responder reclamacion (U3, T11). La mesa de servicio radica la reclamacion de un
 * cliente (activo o no: un cliente inactivo puede tener reclamos sobre envios anteriores), con una guia opcional que debe ser de un envio de ese cliente, la responde (RN14) y la cierra.
 * Responder y cerrar son transacciones con SELECT ... FOR UPDATE de la reclamacion.
 */
@Service
public class ServicioReclamaciones {

    public record Radicada(long idReclamacion, LocalDateTime fechaRadicacion) {
    }

    public record Respondida(long idReclamacion, String estado, LocalDateTime fechaRespuesta, BigDecimal horas, boolean superaMeta) {
    }

    public record Cerrada(long idReclamacion, String estado) {
    }

    private final FabricaUnidadesDeTrabajo unidades;

    public ServicioReclamaciones(FabricaUnidadesDeTrabajo unidades) {
        this.unidades = unidades;
    }

    /** CU22: radica la reclamacion con la fecha y hora actuales. */
    public Radicada registrar(UsuarioSesion usuario, Long idCliente, String numeroGuia, TipoReclamacion tipo, String descripcion) {
        if (idCliente == null) {
            throw new EntradaInvalida("idCliente", "El cliente es obligatorio");
        }
        try (UnidadDeTrabajo uow = unidades.para(usuario, Rol.MESA)) {
            new ReferenciaMapper(uow).cliente(idCliente)
                    .orElseThrow(() -> new EntradaInvalida("idCliente", "El cliente no existe"));
            Reclamacion reclamacion = Reclamacion.radicar(idCliente, numeroGuia, tipo, descripcion, LocalDateTime.now());
            ReclamacionMapper reclamaciones = new ReclamacionMapper(uow);
            if (reclamacion.numeroGuia() != null) {
                // la mesa puede leer ENVIO, SOLICITUD_RECOLECCION y SEDE_CLIENTE, asi que la guia se verifica antes de guardar
                if (!Envio.formatoDeGuiaValido(reclamacion.numeroGuia())
                        || !reclamaciones.guiaEsDelCliente(reclamacion.numeroGuia(), idCliente)) {
                    throw new EntradaInvalida("numeroGuia", "La guía no existe o no es de un envío de ese cliente");
                }
            }
            reclamaciones.insertar(reclamacion);
            uow.confirmar();
            return new Radicada(reclamacion.idReclamacion(), reclamacion.fechaRadicacion());
        }
    }

    /**
     * Lista para la mesa: las ABIERTAS (v_reclamaciones_pendientes, con las horas desde la radicacion) o las
     * RESPONDIDAS que faltan por cerrar. Con otro estado no hay lista (400).
     */
    public List<FilaReclamacionMesa> listar(UsuarioSesion usuario, EstadoReclamacion estado) {
        EstadoReclamacion buscado = estado == null ? EstadoReclamacion.ABIERTA : estado;
        if (buscado == EstadoReclamacion.CERRADA) {
            throw new EntradaInvalida("estado", "La lista es de reclamaciones ABIERTA o RESPONDIDA");
        }
        try (UnidadDeTrabajo uow = unidades.para(usuario, Rol.MESA)) {
            if (buscado == EstadoReclamacion.RESPONDIDA) {
                return new ReclamacionMapper(uow).respondidas();
            }
            return new InformesMapper(uow).reclamacionesPendientes().stream().map(ServicioReclamaciones::deLaVista).toList();
        }
    }

    private static FilaReclamacionMesa deLaVista(FilaReclamacion f) {
        return new FilaReclamacionMesa(f.idReclamacion(), f.fechaRadicacion(), f.idCliente(), f.cliente(), f.numeroGuia(), f.tipo(),
                f.descripcion(), EstadoReclamacion.ABIERTA.name(), null, null, f.horasTranscurridas(),
                f.horasTranscurridas().doubleValue() > Reclamacion.META_HORAS);
    }

    /** CU23: responde una reclamacion ABIERTA; la fecha de respuesta es la actual y debe seguir a la radicacion (RN14). */
    public Respondida responder(UsuarioSesion usuario, long idReclamacion, String respuesta) {
        try (UnidadDeTrabajo uow = unidades.para(usuario, Rol.MESA)) {
            ReclamacionMapper reclamaciones = new ReclamacionMapper(uow);
            Reclamacion reclamacion = bloquearYCargar(reclamaciones, idReclamacion);
            LocalDateTime ahora = LocalDateTime.now();
            reclamacion.responder(respuesta, ahora);
            reclamaciones.actualizarRespuesta(reclamacion);
            uow.confirmar();
            double horas = reclamacion.horasDeRespuesta(ahora);
            return new Respondida(idReclamacion, reclamacion.estado().name(), reclamacion.fechaRespuesta(),
                    BigDecimal.valueOf(horas).setScale(1, java.math.RoundingMode.HALF_UP), reclamacion.superaLaMeta(ahora));
        }
    }

    /** Cierra una reclamacion RESPONDIDA. */
    public Cerrada cerrar(UsuarioSesion usuario, long idReclamacion) {
        try (UnidadDeTrabajo uow = unidades.para(usuario, Rol.MESA)) {
            ReclamacionMapper reclamaciones = new ReclamacionMapper(uow);
            Reclamacion reclamacion = bloquearYCargar(reclamaciones, idReclamacion);
            reclamacion.cerrar();
            reclamaciones.actualizarRespuesta(reclamacion);
            uow.confirmar();
            return new Cerrada(idReclamacion, reclamacion.estado().name());
        }
    }

    private static Reclamacion bloquearYCargar(ReclamacionMapper reclamaciones, long idReclamacion) {
        if (!reclamaciones.bloquearPorId(idReclamacion)) {
            throw new RecursoNoEncontrado("No se encontró la reclamación " + idReclamacion);
        }
        return reclamaciones.buscarPorId(idReclamacion).orElseThrow();
    }
}
