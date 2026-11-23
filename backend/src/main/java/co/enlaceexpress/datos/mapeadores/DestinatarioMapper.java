package co.enlaceexpress.datos.mapeadores;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Optional;

import co.enlaceexpress.datos.infraestructura.UnidadDeTrabajo;
import co.enlaceexpress.dominio.enums.TipoDocumento;
import co.enlaceexpress.dominio.envio.Destinatario;

/** Lee destinatarios. Se crean al registrar el envio, dentro de pr_registrar_envio (RN04). */
public class DestinatarioMapper extends MapeadorJdbc {

    private static final String COLUMNAS = "SELECT id_destinatario, tipo_documento, numero_documento, nombre, telefono, correo FROM destinatario ";
    private static final String SQL_POR_ID = COLUMNAS + "WHERE id_destinatario = ?";
    private static final String SQL_POR_DOCUMENTO = COLUMNAS + "WHERE tipo_documento = ? AND numero_documento = ?";

    public DestinatarioMapper(UnidadDeTrabajo uow) {
        super(uow);
    }

    public Optional<Destinatario> buscarPorId(long id) {
        return consultarUno(SQL_POR_ID, new Object[] {id}, DestinatarioMapper::aDestinatario);
    }

    public Optional<Destinatario> buscarPorDocumento(TipoDocumento tipo, String numero) {
        return consultarUno(SQL_POR_DOCUMENTO, new Object[] {tipo, numero}, DestinatarioMapper::aDestinatario);
    }

    private static Destinatario aDestinatario(ResultSet fila) throws SQLException {
        return new Destinatario(fila.getLong(1), TipoDocumento.valueOf(fila.getString(2)), fila.getString(3),
                fila.getString(4), fila.getString(5), fila.getString(6));
    }
}
