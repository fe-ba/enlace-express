package co.enlaceexpress.presentacion;

import static org.assertj.core.api.Assertions.assertThat;

import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.Types;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.MethodOrderer;
import org.junit.jupiter.api.Order;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.TestMethodOrder;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.annotation.DirtiesContext;

import co.enlaceexpress.datos.ConfiguracionPruebas;
import co.enlaceexpress.datos.EntornoPruebas;
import co.enlaceexpress.presentacion.ClienteHttp.Respuesta;
import tools.jackson.databind.JsonNode;

/**
 * Flujo B2 de punta a punta por HTTP real (servidor en un puerto aleatorio, cookies y CSRF reales) con seis usuarios
 * registrados por la API con codigo: mesa, centro, dos mensajeros, gerencia y un cliente. Estas pruebas confirman datos,
 * asi que antes de empezar y al terminar reinstalan la base (database/install.sh).
 */
@DirtiesContext(classMode = DirtiesContext.ClassMode.AFTER_CLASS)
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
class FlujoApiIT {

    private static final String CLAVE = "Clave1234";

    @Value("${local.server.port}")
    private int puerto;

    private static ClienteHttp mesa;
    private static ClienteHttp centro;
    private static ClienteHttp mensajero7;
    private static ClienteHttp mensajero8;
    private static ClienteHttp gerencia;
    private static ClienteHttp cliente;

    @BeforeAll
    static void reinstalar() throws Exception {
        instalarBase();
    }

    @AfterAll
    static void dejarBaseLimpia() throws Exception {
        instalarBase();
    }

    private static void instalarBase() {
        EntornoPruebas.instalarBase();
    }

    // ------------------------------------------------------------------ ayudas

    private static String codigo(String llamada, String dato) throws Exception {
        try (Connection c = ConfiguracionPruebas.conexionPropietario(); CallableStatement cs = c.prepareCall(llamada)) {
            cs.registerOutParameter(1, Types.VARCHAR);
            cs.setString(2, dato);
            cs.execute();
            return cs.getString(1);
        }
    }

    private ClienteHttp registrarEmpleadoYEntrar(String documento, String usuario) throws Exception {
        ClienteHttp c = new ClienteHttp(puerto);
        String codigo = codigo("{? = call pkg_codigos_activacion.generar_para_empleado(?, 24)}", documento);
        Respuesta r = c.post("/api/registro/empleado", String.format(
                "{\"documento\":\"%s\",\"codigo\":\"%s\",\"usuario\":\"%s\",\"contrasena\":\"%s\"}", documento, codigo, usuario, CLAVE));
        assertThat(r.estado()).as(r.cuerpo()).isEqualTo(201);
        assertThat(c.post("/api/sesion", String.format("{\"usuario\":\"%s\",\"contrasena\":\"%s\"}", usuario, CLAVE)).estado()).isEqualTo(200);
        return c;
    }

    private static void problema(Respuesta r, int estado, String codigo) {
        assertThat(r.estado()).as(r.cuerpo()).isEqualTo(estado);
        assertThat(r.encabezado("Content-Type")).contains("application/problem+json");
        assertThat(r.json().get("codigo").asString()).as(r.cuerpo()).isEqualTo(codigo);
    }

    private static JsonNode ok(Respuesta r, int estado) {
        assertThat(r.estado()).as(r.cuerpo()).isEqualTo(estado);
        return r.json();
    }

    private static String envioJson(long idSolicitud, String documento, boolean fragil, double peso, String contenido) {
        return String.format("{\"idSolicitud\":%d,\"destinatario\":{\"tipoDocumento\":\"CC\",\"numeroDocumento\":\"%s\","
                + "\"nombre\":\"Destinatario %s\",\"telefono\":\"3000000000\"},\"idZona\":1,\"idModalidad\":3,"
                + "\"direccionDestino\":\"Calle 10 # 20-30\",\"pesoDeclarado\":%s,%s\"valorDeclarado\":150000,"
                + "\"fragil\":%s,\"altoValor\":false}", idSolicitud, documento, documento, peso,
                contenido == null ? "" : "\"contenido\":\"" + contenido + "\",", fragil).replace(",,", ",");
    }

    private long solicitud() throws Exception {
        String hoy = LocalDate.now().toString();
        return ok(mesa.post("/api/mesa/solicitudes", "{\"idSede\":1,\"fechaProgramada\":\"" + hoy + "\",\"franjaHoraria\":\"MANANA\"}"), 201)
                .get("idSolicitud").asLong();
    }

    private String registrarEnvio(long idSolicitud, String documento, boolean fragil) throws Exception {
        return ok(mesa.post("/api/mesa/envios", envioJson(idSolicitud, documento, fragil, 2.5, "Mercancia de prueba")), 201)
                .get("numeroGuia").asString();
    }

    private void recolectarYRecibir(long idSolicitud, String... guias) throws Exception {
        assertThat(ok(mensajero7.post("/api/mensajero/solicitudes/" + idSolicitud + "/recolectar", ""), 200).get("enviosRecolectados").asInt())
                .isEqualTo(guias.length);
        for (String g : guias) {
            ok(centro.post("/api/centro/envios/" + g + "/recepcion", "{\"pesoReal\":2.60,\"valorFlete\":9000}"), 200);
        }
    }

    private long armarDespacho(ClienteHttp quien, long idMensajero, String... guias) throws Exception {
        JsonNode vehiculos = ok(quien.get("/api/centro/mensajeros/" + idMensajero + "/vehiculos"), 200);
        assertThat(vehiculos).isNotEmpty();
        StringBuilder g = new StringBuilder();
        for (String guia : guias) {
            g.append(g.length() == 0 ? "" : ",").append('"').append(guia).append('"');
        }
        return ok(quien.post("/api/centro/despachos", String.format("{\"idMensajero\":%d,\"idVehiculo\":%d,\"guias\":[%s]}",
                idMensajero, vehiculos.get(0).get("idVehiculo").asLong(), g)), 201).get("idDespacho").asLong();
    }

    /** Id de la asignacion PENDIENTE de la guia en la planilla del mensajero. */
    private static long asignacionPendiente(ClienteHttp mensajero, String guia) throws Exception {
        for (JsonNode fila : ok(mensajero.get("/api/mensajero/planilla"), 200)) {
            if (fila.get("numeroGuia").asString().equals(guia) && fila.get("resultado").asString().equals("PENDIENTE")) {
                return fila.get("idAsignacion").asLong();
            }
        }
        throw new AssertionError("La planilla no tiene una asignacion pendiente de " + guia);
    }

    private static List<String> estados(Respuesta rastreo) {
        List<String> estados = new ArrayList<>();
        rastreo.json().get("eventos").forEach(e -> estados.add(e.get("estado").asString()));
        return estados;
    }

    private static final String PRUEBA = "{\"nombreReceptor\":\"Receptor\",\"documentoReceptor\":\"%s\",\"tipoPrueba\":\"DOCUMENTO\"}";
    private static final String NOVEDAD = "{\"tipoNovedad\":\"DESTINATARIO_AUSENTE\",\"descripcion\":\"Nadie atendio\"}";

    // ------------------------------------------------------------------ pruebas

    @Test
    @Order(0)
    void registrarYEntrarLosSeisUsuarios() throws Exception {
        mesa = registrarEmpleadoYEntrar("1019444004", "api_mesa");
        centro = registrarEmpleadoYEntrar("80222002", "api_centro");
        mensajero7 = registrarEmpleadoYEntrar("1040777007", "api_mensajero7");
        mensajero8 = registrarEmpleadoYEntrar("1050888008", "api_mensajero8");
        gerencia = registrarEmpleadoYEntrar("52111001", "api_gerencia");
        cliente = new ClienteHttp(puerto);
        String codigo = codigo("{? = call pkg_codigos_activacion.generar_para_cliente(?, 24)}", "900123456");
        assertThat(cliente.post("/api/registro/cliente", String.format(
                "{\"nit\":\"900123456\",\"codigo\":\"%s\",\"usuario\":\"api_cliente\",\"contrasena\":\"%s\"}", codigo, CLAVE)).estado()).isEqualTo(201);
        assertThat(cliente.post("/api/sesion", "{\"usuario\":\"api_cliente\",\"contrasena\":\"" + CLAVE + "\"}").estado()).isEqualTo(200);
    }

    @Test
    @Order(1)
    void flujoPrincipalDeLaSolicitudAlSeguimientoYAlCierreDelDespacho() throws Exception {
        // datos de los formularios de la mesa
        assertThat(ok(mesa.get("/api/mesa/clientes"), 200).toString()).contains("Droguería Nueva Salud S.A.S.");
        assertThat(ok(mesa.get("/api/mesa/clientes/1/sedes"), 200)).hasSize(2);
        assertThat(ok(mesa.get("/api/mesa/zonas"), 200)).hasSize(5);
        assertThat(ok(mesa.get("/api/mesa/modalidades"), 200)).hasSize(3);

        // solicitud: RN15 con el cliente inactivo (sede 7) y valida con la sede 1
        String hoy = LocalDate.now().toString();
        problema(mesa.post("/api/mesa/solicitudes", "{\"idSede\":7,\"fechaProgramada\":\"" + hoy + "\",\"franjaHoraria\":\"MANANA\"}"), 422, "RN15");
        long solicitud = solicitud();

        // envios: RN03 (peso 0) y RN02 (sin contenido) se rechazan; dos validos, el primero fragil
        problema(mesa.post("/api/mesa/envios", envioJson(solicitud, "API-0001", true, 0, "Cosas")), 422, "RN03");
        problema(mesa.post("/api/mesa/envios", envioJson(solicitud, "API-0001", true, 2.5, null)), 422, "RN02");
        String entregado = registrarEnvio(solicitud, "API-0001", true);
        String conNovedad = registrarEnvio(solicitud, "API-0002", false);
        assertThat(entregado).matches("EE\\d{13}");
        JsonNode detalle = ok(mesa.get("/api/mesa/envios/" + entregado), 200);
        assertThat(detalle.get("estadoActual").asString()).isEqualTo("REGISTRADO");
        assertThat(detalle.get("destinatario").get("numeroDocumento").asString()).isEqualTo("API-0001");
        assertThat(detalle.get("recorrido")).hasSize(1);

        // recoleccion (mensajero)
        JsonNode pendientes = ok(mensajero7.get("/api/mensajero/recolecciones"), 200);
        boolean estaLaSolicitud = false;
        for (JsonNode s : pendientes) {
            if (s.get("idSolicitud").asLong() == solicitud) {
                estaLaSolicitud = true;
                assertThat(s.get("envios").asInt()).isEqualTo(2);
            }
        }
        assertThat(estaLaSolicitud).isTrue();
        assertThat(ok(mensajero7.post("/api/mensajero/solicitudes/" + solicitud + "/recolectar", ""), 200).get("enviosRecolectados").asInt()).isEqualTo(2);
        problema(mensajero7.post("/api/mensajero/solicitudes/" + solicitud + "/recolectar", ""), 409, "ESTADO_INCORRECTO");

        // recepcion y clasificacion (centro)
        assertThat(ok(centro.get("/api/centro/envios/recolectados"), 200).toString()).contains(entregado).contains(conNovedad);
        problema(centro.post("/api/centro/envios/" + entregado + "/recepcion", "{\"pesoReal\":-1,\"valorFlete\":9000}"), 422, "RN03");
        for (String g : new String[] {entregado, conNovedad}) {
            assertThat(ok(centro.post("/api/centro/envios/" + g + "/recepcion", "{\"pesoReal\":2.60,\"valorFlete\":9000}"), 200)
                    .get("estadoActual").asString()).isEqualTo("CLASIFICADO");
        }
        assertThat(ok(centro.get("/api/centro/por-despachar"), 200).toString()).contains(entregado).contains(conNovedad);
        assertThat(ok(centro.get("/api/centro/mensajeros"), 200).toString()).contains("\"idEmpleado\":7");

        // despacho de entrega (centro): una asignacion por envio y evento EN_RUTA
        long despacho = armarDespacho(centro, 7, entregado, conNovedad);
        assertThat(ok(centro.get("/api/centro/despachos/" + despacho + "/planilla"), 200)).hasSize(2);
        assertThat(ok(centro.get("/api/centro/por-despachar"), 200).toString()).doesNotContain(entregado).doesNotContain(conNovedad);

        // entrega del fragil: con un documento ajeno el dominio la rechaza (RN06) y la asignacion sigue PENDIENTE; con el del destinatario, ENTREGADO
        long asignacionFragil = asignacionPendiente(mensajero7, entregado);
        problema(mensajero7.post("/api/mensajero/asignaciones/" + asignacionFragil + "/entrega", String.format(PRUEBA, "MAL-999")), 422, "RN06");
        assertThat(asignacionPendiente(mensajero7, entregado)).isEqualTo(asignacionFragil);
        JsonNode entrega = ok(mensajero7.post("/api/mensajero/asignaciones/" + asignacionFragil + "/entrega", String.format(PRUEBA, "API-0001")), 200);
        assertThat(entrega.get("resultado").asString()).isEqualTo("ENTREGADO");
        assertThat(entrega.get("estadoEnvio").asString()).isEqualTo("ENTREGADO");
        // novedad del otro
        long asignacionNovedad = asignacionPendiente(mensajero7, conNovedad);
        assertThat(ok(mensajero7.post("/api/mensajero/asignaciones/" + asignacionNovedad + "/novedad", NOVEDAD), 200)
                .get("estadoEnvio").asString()).isEqualTo("CON_NOVEDAD");

        // seguimiento: rastreo publico y portal del cliente
        ClienteHttp anonimo = new ClienteHttp(puerto);
        assertThat(estados(anonimo.get("/api/publico/rastreo/" + entregado))).containsExactly("REGISTRADO", "RECOLECTADO", "EN_CENTRO",
                "CLASIFICADO", "EN_RUTA", "ENTREGADO");
        assertThat(estados(anonimo.get("/api/publico/rastreo/" + conNovedad))).containsExactly("REGISTRADO", "RECOLECTADO", "EN_CENTRO",
                "CLASIFICADO", "EN_RUTA", "CON_NOVEDAD");
        String misEnvios = ok(cliente.get("/api/cliente/envios"), 200).toString();
        assertThat(misEnvios).contains(entregado).contains(conNovedad);
        assertThat(ok(cliente.get("/api/cliente/envios/" + entregado + "/seguimiento"), 200)).hasSize(6);
        assertThat(ok(mesa.get("/api/mesa/envios/" + entregado), 200).get("estadoActual").asString()).isEqualTo("ENTREGADO");

        // un envio entregado no se anula (RN12); el despacho se cierra una sola vez
        problema(mesa.post("/api/mesa/envios/" + entregado + "/anular", "{}"), 422, "RN12");
        assertThat(ok(centro.post("/api/centro/despachos/" + despacho + "/cerrar", ""), 200).get("estado").asString()).isEqualTo("CERRADO");
        problema(centro.post("/api/centro/despachos/" + despacho + "/cerrar", ""), 409, "ESTADO_INCORRECTO");
        problema(mensajero7.post("/api/mensajero/asignaciones/" + asignacionNovedad + "/novedad", NOVEDAD), 409, "ESTADO_INCORRECTO");

        // tablero de la gerencia
        assertThat(ok(gerencia.get("/api/tablero/cumplimiento"), 200)).isNotEmpty();
        assertThat(ok(gerencia.get("/api/tablero/cumplimiento?centro=1"), 200).toString()).contains("\"idCentro\":1");
        assertThat(ok(gerencia.get("/api/tablero/envios-por-estado"), 200).toString()).contains("ENTREGADO");
        assertThat(ok(gerencia.get("/api/tablero/reclamaciones-pendientes"), 200)).isNotEmpty();
        problema(mesa.get("/api/tablero/cumplimiento"), 403, "ACCESO_DENEGADO");
    }

    @Test
    @Order(2)
    void rechazosDevolucionEnElTercerIntentoYPropiedadDeLasAsignaciones() throws Exception {
        long solicitud = solicitud();
        String devuelto = registrarEnvio(solicitud, "API-0003", false);
        String enRuta = registrarEnvio(solicitud, "API-0004", false);
        recolectarYRecibir(solicitud, devuelto, enRuta);
        long despacho1 = armarDespacho(centro, 7, devuelto, enRuta);

        // un envio EN_RUTA no se anula (RN12) ni se asigna a otro despacho mientras su intento sigue pendiente (RN07)
        problema(mesa.post("/api/mesa/envios/" + enRuta + "/anular", "{}"), 422, "RN12");
        problema(centro.post("/api/centro/despachos", String.format("{\"idMensajero\":8,\"idVehiculo\":%d,\"guias\":[\"%s\"]}",
                ok(centro.get("/api/centro/mensajeros/8/vehiculos"), 200).get(0).get("idVehiculo").asLong(), enRuta)), 422, "RN07");
        // un vehiculo de otro tipo que el del mensajero (la furgoneta 6 con un motociclista) viola RN11
        problema(centro.post("/api/centro/despachos", String.format("{\"idMensajero\":7,\"idVehiculo\":6,\"guias\":[\"%s\"]}", devuelto)), 422, "RN11");
        // vehiculo en mantenimiento (el 3): RN10
        problema(centro.post("/api/centro/despachos", String.format("{\"idMensajero\":7,\"idVehiculo\":3,\"guias\":[\"%s\"]}", devuelto)), 422, "RN10");
        // referencias que no existen
        problema(centro.post("/api/centro/despachos", String.format("{\"idMensajero\":7,\"idVehiculo\":999,\"guias\":[\"%s\"]}", devuelto)), 400, "ENTRADA_INVALIDA");
        problema(centro.post("/api/centro/despachos", "{\"idMensajero\":7,\"idVehiculo\":1,\"guias\":[]}"), 400, "ENTRADA_INVALIDA");

        // el mensajero 8 no puede operar la asignacion del mensajero 7: 404
        long asignacion1 = asignacionPendiente(mensajero7, devuelto);
        problema(mensajero8.post("/api/mensajero/asignaciones/" + asignacion1 + "/novedad", NOVEDAD), 404, "NO_ENCONTRADO");
        problema(mensajero8.post("/api/mensajero/asignaciones/999999/novedad", NOVEDAD), 404, "NO_ENCONTRADO");
        assertThat(ok(mensajero8.get("/api/mensajero/planilla"), 200).toString()).doesNotContain(devuelto);

        // intentos 1 y 2: novedad; cada uno en un despacho nuevo del centro
        ok(mensajero7.post("/api/mensajero/asignaciones/" + asignacion1 + "/novedad", NOVEDAD), 200);
        long despacho2 = armarDespacho(centro, 8, devuelto);
        long asignacion2 = asignacionPendiente(mensajero8, devuelto);
        ok(mensajero8.post("/api/mensajero/asignaciones/" + asignacion2 + "/novedad", NOVEDAD), 200);
        long despacho3 = armarDespacho(centro, 7, devuelto);
        assertThat(despacho1).isLessThan(despacho2);
        assertThat(despacho2).isLessThan(despacho3);

        // tercer intento: la entrega no existe (RN07), la devolucion si
        long asignacion3 = asignacionPendiente(mensajero7, devuelto);
        problema(mensajero7.post("/api/mensajero/asignaciones/" + asignacion3 + "/entrega", String.format(PRUEBA, "X-1")), 422, "RN07");
        problema(mensajero7.post("/api/mensajero/asignaciones/" + asignacion3 + "/novedad", NOVEDAD), 422, "RN07");
        assertThat(asignacionPendiente(mensajero7, devuelto)).isEqualTo(asignacion3);
        JsonNode devolucion = ok(mensajero7.post("/api/mensajero/asignaciones/" + asignacion3 + "/devolucion", String.format(PRUEBA, "REM-1")), 200);
        assertThat(devolucion.get("resultado").asString()).isEqualTo("DEVUELTO");
        assertThat(estados(new ClienteHttp(puerto).get("/api/publico/rastreo/" + devuelto))).containsExactly("REGISTRADO", "RECOLECTADO",
                "EN_CENTRO", "CLASIFICADO", "EN_RUTA", "CON_NOVEDAD", "EN_RUTA", "CON_NOVEDAD", "EN_RUTA", "DEVUELTO");

        // la devolucion en un intento que no es el tercero (RN07), y un envio ya devuelto no se anula (RN12)
        long intentoUnoDelOtro = asignacionPendiente(mensajero7, enRuta);
        problema(mensajero7.post("/api/mensajero/asignaciones/" + intentoUnoDelOtro + "/devolucion", String.format(PRUEBA, "REM-2")), 422, "RN07");
        problema(mesa.post("/api/mesa/envios/" + devuelto + "/anular", "{}"), 422, "RN12");
        // una guia mal escrita o inexistente: 404
        problema(mesa.get("/api/mesa/envios/EE9999999999999"), 404, "NO_ENCONTRADO");
        problema(mesa.post("/api/mesa/envios/no-es-guia/anular", "{}"), 404, "NO_ENCONTRADO");
        // cuerpo sin los campos obligatorios: 400 (no 500)
        problema(mensajero7.post("/api/mensajero/asignaciones/" + intentoUnoDelOtro + "/entrega", "{}"), 400, "ENTRADA_INVALIDA");
        problema(mensajero7.post("/api/mensajero/asignaciones/" + intentoUnoDelOtro + "/entrega", "{\"tipoPrueba\":\"HUELLA\"}"), 400, "SOLICITUD_INVALIDA");
        // el rol equivocado: 403 (la mesa no opera la ruta)
        problema(mesa.post("/api/mensajero/asignaciones/" + intentoUnoDelOtro + "/novedad", NOVEDAD), 403, "ACCESO_DENEGADO");
    }
}
