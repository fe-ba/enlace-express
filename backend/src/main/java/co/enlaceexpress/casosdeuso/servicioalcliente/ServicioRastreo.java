package co.enlaceexpress.casosdeuso.servicioalcliente;

import java.util.List;
import java.util.regex.Pattern;

import org.springframework.stereotype.Service;

import co.enlaceexpress.casosdeuso.indicadores.FilaSeguimiento;
import co.enlaceexpress.casosdeuso.seguridad.FabricaUnidadesDeTrabajo;
import co.enlaceexpress.casosdeuso.seguridad.UsuarioSesion;
import co.enlaceexpress.datos.informes.InformesMapper;
import co.enlaceexpress.datos.informes.RastreoMapper;
import co.enlaceexpress.datos.infraestructura.UnidadDeTrabajo;
import co.enlaceexpress.dominio.reglas.RecursoNoEncontrado;

/**
 * Consulta de seguimiento (CU20): el rastreo publico por numero de guia, sin cuenta y sin datos personales
 * (D2), y el seguimiento completo de un cliente con sesion, solo de los envios de su empresa.
 */
@Service
public class ServicioRastreo {

    private static final Pattern FORMATO_GUIA = Pattern.compile("EE\\d{13}");
    /** El mismo mensaje para una guia mal escrita, inexistente o de otra empresa: no revela cual de las tres es. */
    public static final String NO_ENCONTRADO = "No se encontró un envío con ese número de guía";

    private final FabricaUnidadesDeTrabajo unidades;

    public ServicioRastreo(FabricaUnidadesDeTrabajo unidades) {
        this.unidades = unidades;
    }

    public Rastreo rastreoPublico(String guia) {
        exigirFormato(guia);
        try (UnidadDeTrabajo uow = unidades.publica()) {
            List<EventoRastreo> eventos = new RastreoMapper(uow).porGuia(guia);
            if (eventos.isEmpty()) {
                throw new RecursoNoEncontrado(NO_ENCONTRADO);
            }
            return new Rastreo(guia, eventos.get(eventos.size() - 1).estado(), eventos);
        }
    }

    /** Recorrido completo (con observacion y responsable) de un envio de la empresa del cliente de la sesion. */
    public List<FilaSeguimiento> seguimientoDeCliente(UsuarioSesion cliente, String guia) {
        exigirFormato(guia);
        try (UnidadDeTrabajo uow = unidades.para(cliente)) {
            List<FilaSeguimiento> filas = new InformesMapper(uow).seguimiento(guia, cliente.idCliente());
            if (filas.isEmpty()) {
                throw new RecursoNoEncontrado(NO_ENCONTRADO);
            }
            return filas;
        }
    }

    private static void exigirFormato(String guia) {
        if (guia == null || !FORMATO_GUIA.matcher(guia).matches()) {
            throw new RecursoNoEncontrado(NO_ENCONTRADO);
        }
    }
}
