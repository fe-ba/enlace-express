package co.enlaceexpress.presentacion;

import static org.assertj.core.api.Assertions.assertThat;

import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;
import java.sql.Timestamp;
import java.sql.Types;

import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.MethodOrderer;
import org.junit.jupiter.api.Order;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.TestMethodOrder;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.test.annotation.DirtiesContext;

import co.enlaceexpress.casosdeuso.seguridad.FabricaUnidadesDeTrabajo;
import co.enlaceexpress.casosdeuso.seguridad.UsuarioSesion;
import co.enlaceexpress.datos.ConfiguracionPruebas;
import co.enlaceexpress.datos.infraestructura.UnidadDeTrabajo;
import co.enlaceexpress.dominio.enums.Rol;
import co.enlaceexpress.presentacion.ClienteHttp.Respuesta;
import tools.jackson.databind.JsonNode;

/**
 * Integracion por HTTP real (servidor en un puerto aleatorio, cookies y CSRF reales) contra Oracle con los
 * datos fijos. El propietario genera los codigos de activacion como el administrador. Al final borra lo que
 * las pruebas crearon en las tablas de la extension E1 (la base queda como estaba).
 */
@DirtiesContext(classMode = DirtiesContext.ClassMode.AFTER_CLASS)
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT,
        properties = "enlace.rastreo.limite-por-minuto=30")
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
class SeguridadIT {

    private static final String CLAVE = "Clave1234";
    private static final String GUIA = "EE0000000000003";

    @Value("${local.server.port}")
    private int puerto;

    @Autowired
    private FabricaUnidadesDeTrabajo unidades;

    private static Timestamp inicio;
    private static int consultasDeRastreo;

    @BeforeAll
    static void marcarInicio() throws Exception {
        try (Connection c = ConfiguracionPruebas.conexionPropietario(); Statement st = c.createStatement();
                ResultSet rs = st.executeQuery("SELECT LOCALTIMESTAMP FROM dual")) {
            rs.next();
            inicio = rs.getTimestamp(1);
        }
    }

    @AfterAll
    static void limpiar() throws Exception {
        try (Connection c = ConfiguracionPruebas.conexionPropietario()) {
            try (PreparedStatement ps = c.prepareStatement("DELETE FROM codigo_activacion WHERE fecha_generacion >= ?")) {
                ps.setTimestamp(1, inicio);
                ps.executeUpdate();
            }
            try (Statement st = c.createStatement()) {
                st.executeUpdate("DELETE FROM usuario_aplicacion WHERE nombre_usuario LIKE 'it\\_%' ESCAPE '\\'");
            }
        }
    }

    // ------------------------------------------------------------------ ayudas

    /** El administrador (propietario) genera un codigo de activacion. */
    private static String codigoDeEmpleado(String documento) throws Exception {
        return generar("{? = call pkg_codigos_activacion.generar_para_empleado(?, 24)}", documento);
    }

    private static String codigoDeCliente(String nit) throws Exception {
        return generar("{? = call pkg_codigos_activacion.generar_para_cliente(?, 24)}", nit);
    }

    private static String generar(String llamada, String dato) throws Exception {
        try (Connection c = ConfiguracionPruebas.conexionPropietario(); CallableStatement cs = c.prepareCall(llamada)) {
            cs.registerOutParameter(1, Types.VARCHAR);
            cs.setString(2, dato);
            cs.execute();
            return cs.getString(1);
        }
    }

    private static String json(String... paresClaveValor) {
        StringBuilder sb = new StringBuilder("{");
        for (int i = 0; i < paresClaveValor.length; i += 2) {
            sb.append(i > 0 ? "," : "").append('"').append(paresClaveValor[i]).append("\":\"")
                    .append(paresClaveValor[i + 1].replace("\"", "\\\"")).append('"');
        }
        return sb.append('}').toString();
    }

    private static String consultaUnica(String sql, String parametro) throws Exception {
        try (Connection c = ConfiguracionPruebas.conexionPropietario(); PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, parametro);
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return rs.getString(1);
            }
        }
    }

    private Respuesta registrarEmpleado(ClienteHttp cliente, String documento, String codigo, String usuario, String clave) throws Exception {
        return cliente.post("/api/registro/empleado", json("documento", documento, "codigo", codigo, "usuario", usuario, "contrasena", clave));
    }

    private Respuesta iniciar(ClienteHttp cliente, String usuario, String clave) throws Exception {
        return cliente.post("/api/sesion", json("usuario", usuario, "contrasena", clave));
    }

    private Respuesta rastreo(ClienteHttp cliente, String guia) throws Exception {
        consultasDeRastreo++;
        return cliente.get("/api/publico/rastreo/" + guia);
    }

    // ------------------------------------------------------------------ registro

    @Test
    @Order(1)
    void registroDeEmpleadosYClientesConCodigoYElRolSeDerivaDelCargo() throws Exception {
        ClienteHttp c = new ClienteHttp(puerto);
        // documento de la agente de mesa (4), del mensajero 7 y NIT de dos clientes de los datos fijos
        Respuesta mesa = registrarEmpleado(c, "1019444004", codigoDeEmpleado("1019444004"), "it_mesa", CLAVE);
        assertThat(mesa.estado()).isEqualTo(201);
        assertThat(mesa.json().get("rol").asString()).isEqualTo("MESA");
        assertThat(mesa.json().get("usuario").asString()).isEqualTo("it_mesa");

        Respuesta mensajero = registrarEmpleado(c, "1040777007", codigoDeEmpleado("1040777007"), "it_mensajero", CLAVE);
        assertThat(mensajero.estado()).isEqualTo(201);
        assertThat(mensajero.json().get("rol").asString()).isEqualTo("MENSAJERO");

        Respuesta cliente1 = c.post("/api/registro/cliente", json("nit", "900123456", "codigo", codigoDeCliente("900123456"),
                "usuario", "it_cliente1", "contrasena", CLAVE));
        assertThat(cliente1.estado()).isEqualTo(201);
        assertThat(cliente1.json().get("rol").asString()).isEqualTo("CLIENTE");
        Respuesta cliente2 = c.post("/api/registro/cliente", json("nit", "900234567", "codigo", codigoDeCliente("900234567"),
                "usuario", "it_cliente2", "contrasena", CLAVE));
        assertThat(cliente2.estado()).isEqualTo(201);
        // el hash BCrypt lo calcula la aplicacion: la base nunca ve la contrasena
        String hash = consultaUnica("SELECT hash_contrasena FROM usuario_aplicacion WHERE nombre_usuario = ?", "it_mesa");
        assertThat(hash).startsWith("$2").hasSize(60).doesNotContain(CLAVE);
    }

    @Test
    @Order(2)
    void errorDeRegistroSalenComoProblemDetailsConSuCodigo() throws Exception {
        ClienteHttp c = new ClienteHttp(puerto);
        // el codigo de it_mesa ya se uso; otro intento con un codigo nuevo de otro empleado: ya tiene cuenta
        String codigo = codigoDeEmpleado("1019444004");
        Respuesta cuentaRepetida = registrarEmpleado(c, "1019444004", codigo, "it_mesa_bis", CLAVE);
        assertThat(cuentaRepetida.estado()).isEqualTo(422);
        assertThat(cuentaRepetida.encabezado("Content-Type")).contains("application/problem+json");
        assertThat(cuentaRepetida.json().get("codigo").asString()).isEqualTo("E1");

        // codigo ajeno, documento inexistente: el mismo mensaje
        Respuesta ajeno = registrarEmpleado(c, "1030666006", codigo, "it_otro", CLAVE);
        Respuesta inexistente = registrarEmpleado(c, "000", codigo, "it_otro", CLAVE);
        assertThat(ajeno.estado()).isEqualTo(422);
        assertThat(ajeno.json().get("codigo").asString()).isEqualTo("E1");
        assertThat(ajeno.json().get("detail").asString()).isEqualTo(inexistente.json().get("detail").asString())
                .isEqualTo("los datos de registro o el código no son válidos");

        // usuario repetido
        Respuesta usuarioRepetido = registrarEmpleado(c, "1030666006", codigoDeEmpleado("1030666006"), "it_mesa", CLAVE);
        assertThat(usuarioRepetido.estado()).isEqualTo(422);
        assertThat(usuarioRepetido.json().get("detail").asString()).contains("nombre de usuario");

        // cargo sin acceso (hay uno con cargo valido, asi que se prueba el codigo ya usado de un cliente)
        Respuesta usado = c.post("/api/registro/cliente", json("nit", "900123456", "codigo", "AAAA-AAAA-AAAA", "usuario", "it_x1", "contrasena", CLAVE));
        assertThat(usado.estado()).isEqualTo(422);
    }

    @Test
    @Order(3)
    void contrasenaDebilOCamposFaltantesDan400() throws Exception {
        ClienteHttp c = new ClienteHttp(puerto);
        String codigo = "XXXX-XXXX-XXXX";
        for (String debil : new String[] {"corta1", "sololetrasaqui", "123456789"}) {
            Respuesta r = registrarEmpleado(c, "1030666006", codigo, "it_debil", debil);
            assertThat(r.estado()).as(debil).isEqualTo(400);
            assertThat(r.json().get("codigo").asString()).isEqualTo("ENTRADA_INVALIDA");
            assertThat(r.json().get("campo").asString()).isEqualTo("contrasena");
        }
        assertThat(c.post("/api/registro/empleado", json("documento", "1030666006", "codigo", codigo, "usuario", "a b", "contrasena", CLAVE)).estado()).isEqualTo(400);
        assertThat(c.post("/api/registro/empleado", "{}").estado()).isEqualTo(400);
        assertThat(c.post("/api/registro/empleado", "esto no es json").estado()).isEqualTo(400);
    }

    // ------------------------------------------------------------------ sesion

    @Test
    @Order(4)
    void inicioDeSesionConCookieYErroresIguales() throws Exception {
        ClienteHttp c = new ClienteHttp(puerto);
        assertThat(c.get("/api/sesion").estado()).isEqualTo(401);

        Respuesta ok = iniciar(c, "it_mesa", CLAVE);
        assertThat(ok.estado()).isEqualTo(200);
        assertThat(ok.json().get("rol").asString()).isEqualTo("MESA");
        assertThat(ok.json().get("idEmpleado").asLong()).isEqualTo(4L);
        assertThat(ok.json().get("idCliente").isNull()).isTrue();
        String setCookie = String.join(";", ok.encabezados().allValues("Set-Cookie"));
        assertThat(setCookie).contains("JSESSIONID").contains("HttpOnly").containsIgnoringCase("SameSite=Lax");
        assertThat(c.cookie("JSESSIONID")).isNotBlank();
        Respuesta actual = c.get("/api/sesion");
        assertThat(actual.estado()).isEqualTo(200);
        assertThat(actual.json().get("usuario").asString()).isEqualTo("it_mesa");
        // el ultimo ingreso queda anotado por pkg_seguridad.registrar_ingreso
        assertThat(consultaUnica("SELECT COUNT(*) FROM usuario_aplicacion WHERE nombre_usuario = ? AND ultimo_ingreso IS NOT NULL", "it_mesa")).isEqualTo("1");

        // contraseña errada, usuario inexistente y cuenta INACTIVA: el mismo 401 con el mismo mensaje
        Respuesta errada = iniciar(new ClienteHttp(puerto), "it_mesa", "Otra12345");
        Respuesta inexistente = iniciar(new ClienteHttp(puerto), "it_no_existe", CLAVE);
        try (Connection con = ConfiguracionPruebas.conexionPropietario(); Statement st = con.createStatement()) {
            st.executeUpdate("UPDATE usuario_aplicacion SET estado = 'INACTIVO' WHERE nombre_usuario = 'it_mensajero'");
        }
        Respuesta inactiva = iniciar(new ClienteHttp(puerto), "it_mensajero", CLAVE);
        try (Connection con = ConfiguracionPruebas.conexionPropietario(); Statement st = con.createStatement()) {
            st.executeUpdate("UPDATE usuario_aplicacion SET estado = 'ACTIVO' WHERE nombre_usuario = 'it_mensajero'");
        }
        for (Respuesta r : new Respuesta[] {errada, inexistente, inactiva}) {
            assertThat(r.estado()).isEqualTo(401);
            assertThat(r.json().get("detail").asString()).isEqualTo("Usuario o contraseña incorrectos");
            assertThat(r.json().get("codigo").asString()).isEqualTo("CREDENCIALES_INCORRECTAS");
            assertThat(r.encabezado("WWW-Authenticate")).isNull();
        }
        assertThat(errada.cuerpo()).isEqualTo(inexistente.cuerpo()).isEqualTo(inactiva.cuerpo());
    }

    @Test
    @Order(5)
    void sinTokenCsrfElPostSeRechaza() throws Exception {
        ClienteHttp c = new ClienteHttp(puerto);
        Respuesta r = c.postSinCsrf("/api/sesion", json("usuario", "it_mesa", "contrasena", CLAVE));
        assertThat(r.estado()).isEqualTo(403);
        assertThat(r.json().get("codigo").asString()).isEqualTo("CSRF");
        // con el token de la cookie la misma operacion llega al controlador (cuerpo vacio: 400, no 403)
        ClienteHttp d = new ClienteHttp(puerto);
        assertThat(d.post("/api/registro/empleado", "{}").estado()).isEqualTo(400);
    }

    @Test
    @Order(6)
    void elRolDeLaSesionDecideLasRutas() throws Exception {
        ClienteHttp c = new ClienteHttp(puerto);
        // sin sesion: 401 en las rutas protegidas
        assertThat(c.get("/api/mesa/prueba").estado()).isEqualTo(401);
        assertThat(c.get("/api/mesa/prueba").json().get("codigo").asString()).isEqualTo("NO_AUTENTICADO");
        assertThat(iniciar(c, "it_mesa", CLAVE).estado()).isEqualTo(200);
        Respuesta enCentro = c.get("/api/centro/prueba");
        assertThat(enCentro.estado()).isEqualTo(403);
        assertThat(enCentro.json().get("codigo").asString()).isEqualTo("ACCESO_DENEGADO");
        assertThat(enCentro.encabezado("Content-Type")).contains("application/problem+json");
        assertThat(c.get("/api/mensajero/prueba").estado()).isEqualTo(403);
        assertThat(c.get("/api/tablero/prueba").estado()).isEqualTo(403);
        assertThat(c.get("/api/cliente/envios/" + GUIA + "/seguimiento").estado()).isEqualTo(403);
        // su propia ruta pasa la autorizacion (la ruta aun no existe: 404)
        assertThat(c.get("/api/mesa/prueba").estado()).isEqualTo(404);
        // las rutas publicas no piden sesion
        assertThat(new ClienteHttp(puerto).get("/api/salud").estado()).isEqualTo(200);
    }

    @Test
    @Order(7)
    void cerrarLaSesionInvalidaLaCookie() throws Exception {
        ClienteHttp c = new ClienteHttp(puerto);
        assertThat(iniciar(c, "it_mesa", CLAVE).estado()).isEqualTo(200);
        String cookie = "JSESSIONID=" + c.cookie("JSESSIONID");
        assertThat(ClienteHttp.getConCookie(puerto, "/api/sesion", cookie).estado()).isEqualTo(200);
        assertThat(c.post("/api/sesion/cerrar", "").estado()).isEqualTo(204);
        assertThat(c.get("/api/sesion").estado()).isEqualTo(401);
        assertThat(ClienteHttp.getConCookie(puerto, "/api/sesion", cookie).estado()).isEqualTo(401);
    }

    @Test
    @Order(8)
    void elIdentificadorDeClienteDeOracleEsElUsuarioDeLaSesionDuranteLaOperacion() throws Exception {
        UsuarioSesion mesa = new UsuarioSesion("it_mesa", Rol.MESA, 4L, null);
        SecurityContextHolder.getContext().setAuthentication(UsernamePasswordAuthenticationToken.authenticated(mesa, null,
                java.util.List.of(new SimpleGrantedAuthority("ROLE_MESA"))));
        try (UnidadDeTrabajo uow = unidades.delUsuarioActual(); Statement st = uow.conexion().createStatement();
                ResultSet rs = st.executeQuery("SELECT SYS_CONTEXT('USERENV', 'CLIENT_IDENTIFIER') || '|' || SYS_CONTEXT('USERENV', 'SESSION_USER') FROM dual")) {
            rs.next();
            assertThat(rs.getString(1)).isEqualTo("it_mesa|SVC_MESA");
        } finally {
            SecurityContextHolder.clearContext();
        }
        try (UnidadDeTrabajo uow = unidades.publica(); Statement st = uow.conexion().createStatement();
                ResultSet rs = st.executeQuery("SELECT SYS_CONTEXT('USERENV', 'CLIENT_IDENTIFIER') || '|' || SYS_CONTEXT('USERENV', 'SESSION_USER') FROM dual")) {
            rs.next();
            assertThat(rs.getString(1)).isEqualTo("publico|SVC_CLIENTE");
        }
    }

    // ------------------------------------------------------------------ rastreo

    @Test
    @Order(9)
    void rastreoPublicoSoloMuestraFechaEstadoYZonaSinDatosPersonales() throws Exception {
        ClienteHttp c = new ClienteHttp(puerto);
        Respuesta r = rastreo(c, GUIA);
        assertThat(r.estado()).isEqualTo(200);
        assertThat(r.encabezados().allValues("Set-Cookie")).as("el rastreo no abre sesion").isEmpty();
        JsonNode j = r.json();
        assertThat(j.get("guia").asString()).isEqualTo(GUIA);
        assertThat(j.get("estadoActual").asString()).isEqualTo("ENTREGADO");
        assertThat(j.propertyNames()).containsExactlyInAnyOrder("guia", "estadoActual", "eventos");
        JsonNode eventos = j.get("eventos");
        assertThat(eventos).hasSize(8);
        assertThat(eventos.get(0).get("estado").asString()).isEqualTo("REGISTRADO");
        assertThat(eventos.get(7).get("estado").asString()).isEqualTo("ENTREGADO");
        for (JsonNode e : eventos) {
            assertThat(e.propertyNames()).containsExactlyInAnyOrder("fechaHora", "estado", "zona");
            assertThat(e.get("fechaHora").asString()).matches("\\d{4}-\\d{2}-\\d{2}T.*");
            assertThat(e.get("zona").asString()).isEqualTo("Sur");
        }
        // ningun dato personal: ni nombre ni telefono ni direccion del destinatario, ni nombres de empleados ni observaciones
        String destinatario = consultaUnica("SELECT d.nombre FROM envio e JOIN destinatario d ON d.id_destinatario = e.id_destinatario WHERE e.numero_guia = ?", GUIA);
        String telefono = consultaUnica("SELECT d.telefono FROM envio e JOIN destinatario d ON d.id_destinatario = e.id_destinatario WHERE e.numero_guia = ?", GUIA);
        String direccion = consultaUnica("SELECT direccion_destino FROM envio WHERE numero_guia = ?", GUIA);
        assertThat(destinatario).isNotBlank();
        assertThat(direccion).isNotBlank();
        assertThat(r.cuerpo()).doesNotContain(destinatario).doesNotContain(telefono).doesNotContain(direccion)
                .doesNotContain("Recepción").doesNotContain("Carlos").doesNotContain("Natalia").doesNotContain("Julián")
                .doesNotContain("observacion").doesNotContain("responsable");
    }

    @Test
    @Order(10)
    void guiaInexistenteOMalEscritaDa404ConElMismoMensaje() throws Exception {
        ClienteHttp c = new ClienteHttp(puerto);
        Respuesta inexistente = rastreo(c, "EE9999999999999");
        Respuesta malEscrita = rastreo(c, "no-es-una-guia");
        Respuesta corta = rastreo(c, "EE123");
        for (Respuesta r : new Respuesta[] {inexistente, malEscrita, corta}) {
            assertThat(r.estado()).isEqualTo(404);
            assertThat(r.json().get("codigo").asString()).isEqualTo("NO_ENCONTRADO");
            assertThat(r.json().get("detail").asString()).isEqualTo("No se encontró un envío con ese número de guía");
        }
    }

    @Test
    @Order(11)
    void seguimientoDelClienteSoloDeLosEnviosDeSuEmpresa() throws Exception {
        // la guia 3 es de la empresa 1 (Drogueria Nueva Salud)
        ClienteHttp uno = new ClienteHttp(puerto);
        assertThat(uno.get("/api/cliente/envios/" + GUIA + "/seguimiento").estado()).isEqualTo(401);
        assertThat(iniciar(uno, "it_cliente1", CLAVE).estado()).isEqualTo(200);
        Respuesta propio = uno.get("/api/cliente/envios/" + GUIA + "/seguimiento");
        assertThat(propio.estado()).isEqualTo(200);
        JsonNode filas = propio.json();
        assertThat(filas).hasSize(8);
        assertThat(filas.get(0).propertyNames()).contains("fechaHora", "estado", "observacion", "responsable");

        ClienteHttp dos = new ClienteHttp(puerto);
        assertThat(iniciar(dos, "it_cliente2", CLAVE).estado()).isEqualTo(200);
        Respuesta ajeno = dos.get("/api/cliente/envios/" + GUIA + "/seguimiento");
        assertThat(ajeno.estado()).isEqualTo(404);
        assertThat(ajeno.json().get("detail").asString()).isEqualTo("No se encontró un envío con ese número de guía");
        assertThat(dos.get("/api/cliente/envios/EE9999999999999/seguimiento").estado()).isEqualTo(404);
    }

    @Test
    @Order(99)
    void laConsultaTreintaYUnoDentroDelMinutoDa429() throws Exception {
        ClienteHttp c = new ClienteHttp(puerto);
        Respuesta ultima = null;
        int hasta = 0;
        while (hasta++ < 40) {
            ultima = rastreo(c, GUIA);
            if (ultima.estado() == 429) {
                break;
            }
        }
        assertThat(ultima.estado()).isEqualTo(429);
        assertThat(consultasDeRastreo - 1).as("consultas permitidas antes del bloqueo").isEqualTo(30);
        assertThat(ultima.encabezado("Retry-After")).matches("\\d+");
        assertThat(Long.parseLong(ultima.encabezado("Retry-After"))).isBetween(1L, 60L);
        assertThat(ultima.json().get("codigo").asString()).isEqualTo("DEMASIADAS_CONSULTAS");
        assertThat(ultima.encabezado("Content-Type")).contains("application/problem+json");
    }
}
