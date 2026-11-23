package co.enlaceexpress.casosdeuso.indicadores;

import co.enlaceexpress.dominio.enums.ResultadoVisita;
import co.enlaceexpress.dominio.enums.TipoDocumento;

/**
 * Fila de v_planilla_despacho (informe de planilla de ruta, C3). Ademas de las columnas del diagrama trae
 * lo que el mensajero necesita para entregar: la asignacion, el intento y el documento del destinatario (RN06).
 */
public record FilaPlanilla(int ordenVisita, String numeroGuia, String destinatario, String telefono, String direccion,
        ResultadoVisita resultado, long idAsignacion, int numeroIntento, TipoDocumento tipoDocumentoDestinatario,
        String numeroDocumentoDestinatario, String zona, boolean fragil, boolean altoValor, long idDespacho,
        String estadoDespacho) {
}
