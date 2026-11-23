package co.enlaceexpress.datos.mapeadores;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

import co.enlaceexpress.datos.infraestructura.UnidadDeTrabajo;

/** Mapeador de prueba: ejercita los metodos de MapeadorJdbc con SQL fijo y variables de enlace. */
class MapeadorDePruebas extends MapeadorJdbc {

    private static final String SQL_INSERTAR_DESTINATARIO =
            "INSERT INTO destinatario (tipo_documento, numero_documento, nombre, telefono) VALUES (?, ?, ?, ?)";
    private static final String SQL_CONTAR_DESTINATARIOS = "SELECT COUNT(*) FROM destinatario";
    private static final String SQL_NOMBRE_POR_DOCUMENTO = "SELECT nombre FROM destinatario WHERE numero_documento = ?";
    private static final String SQL_NOMBRES_POR_TIPO = "SELECT nombre FROM destinatario WHERE tipo_documento = ? ORDER BY nombre";
    private static final String SQL_INSERTAR_SOLICITUD =
            "INSERT INTO solicitud_recoleccion (id_sede, fecha_solicitud, fecha_programada, franja_horaria) VALUES (?, ?, ?, ?)";
    private static final String SQL_BORRAR_ENVIO = "DELETE FROM envio WHERE numero_guia = ?";
    private static final String SQL_PRIMERA_SOLICITUD = "SELECT MIN(id_solicitud) FROM solicitud_recoleccion";
    private static final String LLAMADA_REGISTRAR_ENVIO =
            "{call pr_registrar_envio(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)}";

    MapeadorDePruebas(UnidadDeTrabajo uow) {
        super(uow);
    }

    long insertarDestinatario(String tipo, String numero, String nombre) {
        return insertarConClave(SQL_INSERTAR_DESTINATARIO, new Object[] {tipo, numero, nombre, "3000000000"}, "ID_DESTINATARIO");
    }

    int contarDestinatarios() {
        return consultarUno(SQL_CONTAR_DESTINATARIOS, new Object[0], f -> f.getInt(1)).orElseThrow();
    }

    Optional<String> nombrePorDocumento(String numero) {
        return consultarUno(SQL_NOMBRE_POR_DOCUMENTO, new Object[] {numero}, f -> f.getString(1));
    }

    List<String> nombresPorTipo(String tipo) {
        return consultar(SQL_NOMBRES_POR_TIPO, new Object[] {tipo}, f -> f.getString(1));
    }

    int insertarSolicitud(long idSede) {
        LocalDate hoy = LocalDate.now();
        return ejecutar(SQL_INSERTAR_SOLICITUD, new Object[] {idSede, hoy, hoy, "MANANA"});
    }

    int borrarEnvio(String guia) {
        return ejecutar(SQL_BORRAR_ENVIO, new Object[] {guia});
    }

    long primeraSolicitud() {
        return consultarUno(SQL_PRIMERA_SOLICITUD, new Object[0], f -> f.getLong(1)).orElseThrow();
    }

    String registrarEnvio(long idSolicitud, String documento) {
        Object[] entradas = {idSolicitud, "CC", documento, "Destinatario IT", "3000000000", null, 1L, 3L, "Calle 1 # 2-3",
            new BigDecimal("1.5"), "Libros", new BigDecimal("1000"), "N", "N", null, 4L};
        return (String) llamarProcedimiento(LLAMADA_REGISTRAR_ENVIO, entradas);
    }
}
