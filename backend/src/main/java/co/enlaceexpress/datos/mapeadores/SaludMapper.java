package co.enlaceexpress.datos.mapeadores;


import java.time.LocalDateTime;

import co.enlaceexpress.datos.infraestructura.ConversorTipos;
import co.enlaceexpress.datos.infraestructura.UnidadDeTrabajo;

/** Lee de Oracle los datos que muestra el chequeo de salud. */
public class SaludMapper extends MapeadorJdbc {

    private static final String SQL_ESTADO_BASE = """
            SELECT SYS_CONTEXT('USERENV', 'CON_NAME'),
                   SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA'),
                   LOCALTIMESTAMP
            FROM   dual""";

    /** Estado de la base: PDB, esquema actual de la sesion y hora de la base. */
    public record EstadoBase(String baseDeDatos, String esquema, LocalDateTime horaBase) {
    }

    public SaludMapper(UnidadDeTrabajo uow) {
        super(uow);
    }

    public EstadoBase estado() {
        return consultarUno(SQL_ESTADO_BASE, new Object[0], fila -> new EstadoBase(
                fila.getString(1), fila.getString(2),
                ConversorTipos.aInstante(fila.getTimestamp(3))))
                .orElseThrow();
    }
}
