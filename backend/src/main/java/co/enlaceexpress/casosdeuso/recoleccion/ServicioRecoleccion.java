package co.enlaceexpress.casosdeuso.recoleccion;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

import org.springframework.stereotype.Service;

import co.enlaceexpress.casosdeuso.indicadores.FilaRecoleccion;
import co.enlaceexpress.casosdeuso.seguridad.FabricaUnidadesDeTrabajo;
import co.enlaceexpress.casosdeuso.seguridad.UsuarioSesion;
import co.enlaceexpress.datos.informes.InformesMapper;
import co.enlaceexpress.datos.infraestructura.UnidadDeTrabajo;
import co.enlaceexpress.datos.mapeadores.EnvioMapper;
import co.enlaceexpress.datos.mapeadores.ReferenciaMapper;
import co.enlaceexpress.datos.mapeadores.SolicitudMapper;
import co.enlaceexpress.dominio.enums.EstadoEnvio;
import co.enlaceexpress.dominio.enums.FranjaHoraria;
import co.enlaceexpress.dominio.enums.Rol;
import co.enlaceexpress.dominio.envio.Envio;
import co.enlaceexpress.dominio.referencia.Cliente;
import co.enlaceexpress.dominio.referencia.SedeCliente;
import co.enlaceexpress.dominio.reglas.EntradaInvalida;
import co.enlaceexpress.dominio.reglas.RecursoNoEncontrado;
import co.enlaceexpress.dominio.solicitud.SolicitudRecoleccion;

/**
 * Recoleccion: la mesa de servicio registra las solicitudes (CU01) y el mensajero las atiende (CU15).
 * Cada operacion es una transaccion: abre la unidad de trabajo con el rol y el usuario de la sesion, bloquea la fila
 * que cambia de estado (C4), aplica las reglas del dominio, guarda y confirma una sola vez.
 */
@Service
public class ServicioRecoleccion {

    /** Resultado de recolectar: la solicitud y cuantos envios se marcaron RECOLECTADO. */
    public record Recoleccion(long idSolicitud, int enviosRecolectados) {
    }

    private final FabricaUnidadesDeTrabajo unidades;

    public ServicioRecoleccion(FabricaUnidadesDeTrabajo unidades) {
        this.unidades = unidades;
    }

    /** CU01 (U3): registra una solicitud de recoleccion de un cliente activo (RN15). */
    public long registrarSolicitud(UsuarioSesion usuario, Long idSede, LocalDate fechaProgramada, FranjaHoraria franja) {
        if (idSede == null) {
            throw new EntradaInvalida("idSede", "La sede es obligatoria");
        }
        if (fechaProgramada == null) {
            throw new EntradaInvalida("fechaProgramada", "La fecha programada es obligatoria");
        }
        if (franja == null) {
            throw new EntradaInvalida("franjaHoraria", "La franja horaria es obligatoria (MANANA o TARDE)");
        }
        try (UnidadDeTrabajo uow = unidades.para(usuario, Rol.MESA)) {
            ReferenciaMapper referencia = new ReferenciaMapper(uow);
            SedeCliente sede = referencia.sede(idSede).orElseThrow(() -> new EntradaInvalida("idSede", "La sede no existe"));
            Cliente cliente = referencia.cliente(sede.idCliente()).orElseThrow();
            SolicitudRecoleccion solicitud = SolicitudRecoleccion.registrar(sede, cliente, LocalDate.now(), fechaProgramada, franja);
            long id = new SolicitudMapper(uow).insertar(solicitud);
            uow.confirmar();
            return id;
        }
    }

    /** U4: solicitudes por atender, con su sede y cuantos envios tiene cada una. */
    public List<FilaRecoleccion> pendientes(UsuarioSesion usuario) {
        try (UnidadDeTrabajo uow = unidades.para(usuario, Rol.MENSAJERO)) {
            return new InformesMapper(uow).recolecciones();
        }
    }

    /**
     * CU15 (U4): la solicitud pasa a ATENDIDA y cada uno de sus envios recibe el evento RECOLECTADO, con
     * instantes distintos y crecientes (C5). Los envios anulados no se recogen. Todo o nada (RN12).
     */
    public Recoleccion recolectar(UsuarioSesion usuario, long idSolicitud) {
        try (UnidadDeTrabajo uow = unidades.para(usuario, Rol.MENSAJERO)) {
            SolicitudMapper solicitudes = new SolicitudMapper(uow);
            EnvioMapper envios = new EnvioMapper(uow);
            if (!solicitudes.bloquearPorId(idSolicitud)) {
                throw new RecursoNoEncontrado("No se encontró la solicitud " + idSolicitud);
            }
            SolicitudRecoleccion solicitud = solicitudes.buscarPorId(idSolicitud).orElseThrow();
            solicitud.marcarAtendida();
            solicitudes.actualizarEstado(solicitud);

            List<String> recolectados = new ArrayList<>();
            for (String guia : envios.guiasDeSolicitud(idSolicitud)) {
                envios.bloquearPorGuia(guia);
                Envio envio = envios.buscarPorGuia(guia).orElseThrow();
                if (envio.estadoActual() == EstadoEnvio.ANULADO) {
                    continue;
                }
                envios.agregarEvento(guia, envio.registrarEvento(EstadoEnvio.RECOLECTADO, usuario.idEmpleado(),
                        "Recogido en la sede del cliente", LocalDateTime.now()));
                recolectados.add(guia);
            }
            uow.confirmar();
            return new Recoleccion(idSolicitud, recolectados.size());
        }
    }
}
