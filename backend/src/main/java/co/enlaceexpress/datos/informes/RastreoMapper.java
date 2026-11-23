package co.enlaceexpress.datos.informes;

import static co.enlaceexpress.datos.infraestructura.ConversorTipos.aInstante;

import java.util.List;

import co.enlaceexpress.casosdeuso.servicioalcliente.EventoRastreo;
import co.enlaceexpress.datos.infraestructura.UnidadDeTrabajo;
import co.enlaceexpress.datos.mapeadores.MapeadorJdbc;

/** Rastreo publico: lee la vista v_rastreo_publico de la extension E2 (sin datos personales). */
public class RastreoMapper extends MapeadorJdbc {

    private static final String SQL_RASTREO = """
            SELECT fecha_hora, estado, zona
            FROM   v_rastreo_publico
            WHERE  numero_guia = ?
            ORDER  BY fecha_hora, id_evento""";

    public RastreoMapper(UnidadDeTrabajo uow) {
        super(uow);
    }

    public List<EventoRastreo> porGuia(String numeroGuia) {
        return consultar(SQL_RASTREO, new Object[] {numeroGuia},
                f -> new EventoRastreo(aInstante(f.getTimestamp(1)), f.getString(2), f.getString(3)));
    }
}
