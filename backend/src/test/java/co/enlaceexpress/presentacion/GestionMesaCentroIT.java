package co.enlaceexpress.presentacion;

import static org.assertj.core.api.Assertions.assertThat;

import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.Types;

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
 * CU21 (gestionar novedad), CU22 y CU23 (reclamaciones) de la mesa y CU13 (centros y zonas) del centro, por HTTP real, cada
 * uno con su caso valido y sus rechazos. Confirman datos, asi que antes y despues reinstalan la base (database/install.sh).
 */
@DirtiesContext(classMode = DirtiesContext.ClassMode.AFTER_CLASS)
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
class GestionMesaCentroIT {

    private static final String CLAVE = "Clave1234";

    @Value("${local.server.port}")
    private int puerto;

    private static ClienteHttp mesa;
    private static ClienteHttp centro;

    @BeforeAll
    static void reinstalar() {
        EntornoPruebas.instalarBase();
    }

    @AfterAll
    static void dejarBaseLimpia() {
        EntornoPruebas.instalarBase();
    }

    private ClienteHttp registrarEmpleadoYEntrar(String documento, String usuario) throws Exception {
        ClienteHttp c = new ClienteHttp(puerto);
        String codigo;
        try (Connection con = ConfiguracionPruebas.conexionPropietario();
                CallableStatement cs = con.prepareCall("{? = call pkg_codigos_activacion.generar_para_empleado(?, 24)}")) {
            cs.registerOutParameter(1, Types.VARCHAR);
            cs.setString(2, documento);
            cs.execute();
            codigo = cs.getString(1);
        }
        assertThat(c.post("/api/registro/empleado", String.format(
                "{\"documento\":\"%s\",\"codigo\":\"%s\",\"usuario\":\"%s\",\"contrasena\":\"%s\"}", documento, codigo, usuario, CLAVE))
                .estado()).isEqualTo(201);
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

    @Test
    @Order(1)
    void registrarMesaYCentro() throws Exception {
        mesa = registrarEmpleadoYEntrar("1019444004", "gestion_mesa");
        centro = registrarEmpleadoYEntrar("80222002", "gestion_centro");
    }

    // ------------------------------------------------------------------ CU21 Gestionar novedad

    @Test
    @Order(2)
    void cu21LaMesaGestionaYCierraUnaNovedadAbierta() throws Exception {
        JsonNode abiertas = ok(mesa.get("/api/mesa/novedades"), 200);
        assertThat(abiertas.size()).isGreaterThanOrEqualTo(2);
        JsonNode primera = abiertas.get(0);
        assertThat(primera.get("numeroGuia").asString()).startsWith("EE");
        assertThat(primera.has("telefonoDestinatario")).isTrue();
        long id = primera.get("idNovedad").asLong();

        JsonNode r = ok(mesa.post("/api/mesa/novedades/" + id + "/gestionar",
                "{\"accion\":\"REINTENTO\",\"solucion\":\"Se reprograma la entrega con el destinatario\"}"), 200);
        assertThat(r.get("accion").asString()).isEqualTo("REINTENTO");
        assertThat(r.get("estado").asString()).isEqualTo("CERRADA");
        assertThat(ok(mesa.get("/api/mesa/novedades"), 200).size()).isEqualTo(abiertas.size() - 1);

        // rechazos: ya cerrada (409), accion invalida o ausente y solucion vacia (400), inexistente (404), otro rol (403)
        problema(mesa.post("/api/mesa/novedades/" + id + "/gestionar", "{\"accion\":\"DEVOLUCION\",\"solucion\":\"Otra\"}"), 409, "ESTADO_INCORRECTO");
        long otra = abiertas.get(1).get("idNovedad").asLong();
        problema(mesa.post("/api/mesa/novedades/" + otra + "/gestionar", "{\"accion\":\"CANCELAR\",\"solucion\":\"x\"}"), 400, "SOLICITUD_INVALIDA");
        problema(mesa.post("/api/mesa/novedades/" + otra + "/gestionar", "{\"solucion\":\"x\"}"), 400, "ENTRADA_INVALIDA");
        problema(mesa.post("/api/mesa/novedades/" + otra + "/gestionar", "{\"accion\":\"REINTENTO\",\"solucion\":\"  \"}"), 400, "ENTRADA_INVALIDA");
        problema(mesa.post("/api/mesa/novedades/999999/gestionar", "{\"accion\":\"REINTENTO\",\"solucion\":\"x\"}"), 404, "NO_ENCONTRADO");
        problema(centro.post("/api/mesa/novedades/" + otra + "/gestionar", "{\"accion\":\"REINTENTO\",\"solucion\":\"x\"}"), 403, "ACCESO_DENEGADO");
        // la novedad rechazada sigue abierta
        assertThat(ok(mesa.get("/api/mesa/novedades"), 200).size()).isEqualTo(abiertas.size() - 1);
    }

    // ------------------------------------------------------------------ CU22 y CU23 Reclamaciones

    private long radicar(String cuerpo) throws Exception {
        return ok(mesa.post("/api/mesa/reclamaciones", cuerpo), 201).get("idReclamacion").asLong();
    }

    @Test
    @Order(3)
    void cu22LaMesaRadicaUnaReclamacionDeCualquierCliente() throws Exception {
        JsonNode r = ok(mesa.post("/api/mesa/reclamaciones",
                "{\"idCliente\":1,\"numeroGuia\":\"EE0000000000015\",\"tipo\":\"ENTREGA\",\"descripcion\":\"El paquete llego tarde\"}"), 201);
        assertThat(r.get("idReclamacion").asLong()).isPositive();
        assertThat(r.get("fechaRadicacion").asString()).isNotBlank();
        // sin guia tambien se radica
        radicar("{\"idCliente\":3,\"tipo\":\"FACTURACION\",\"descripcion\":\"Cobro duplicado\"}");

        // un cliente inactivo tambien puede reclamar (por envios anteriores); RN15 solo aplica a las solicitudes
        radicar("{\"idCliente\":4,\"tipo\":\"OTRO\",\"descripcion\":\"Reclamo de un cliente inactivo\"}");
        assertThat(ok(mesa.get("/api/mesa/clientes"), 200).toString()).doesNotContain("\"idCliente\":4");
        assertThat(ok(mesa.get("/api/mesa/clientes?todos=true"), 200).toString()).contains("\"idCliente\":4").contains("INACTIVO");

        // rechazos: guia de otro cliente o inexistente, cliente inexistente, datos incompletos
        problema(mesa.post("/api/mesa/reclamaciones",
                "{\"idCliente\":2,\"numeroGuia\":\"EE0000000000015\",\"tipo\":\"ENTREGA\",\"descripcion\":\"x\"}"), 400, "ENTRADA_INVALIDA");
        problema(mesa.post("/api/mesa/reclamaciones",
                "{\"idCliente\":1,\"numeroGuia\":\"EE0000000999999\",\"tipo\":\"ENTREGA\",\"descripcion\":\"x\"}"), 400, "ENTRADA_INVALIDA");
        problema(mesa.post("/api/mesa/reclamaciones", "{\"idCliente\":999,\"tipo\":\"OTRO\",\"descripcion\":\"x\"}"), 400, "ENTRADA_INVALIDA");
        problema(mesa.post("/api/mesa/reclamaciones", "{\"idCliente\":1,\"tipo\":\"OTRO\"}"), 400, "ENTRADA_INVALIDA");
        problema(mesa.post("/api/mesa/reclamaciones", "{\"idCliente\":1,\"descripcion\":\"x\"}"), 400, "ENTRADA_INVALIDA");
        problema(mesa.post("/api/mesa/reclamaciones", "{\"idCliente\":1,\"tipo\":\"CHISME\",\"descripcion\":\"x\"}"), 400, "SOLICITUD_INVALIDA");
        problema(centro.post("/api/mesa/reclamaciones", "{\"idCliente\":1,\"tipo\":\"OTRO\",\"descripcion\":\"x\"}"), 403, "ACCESO_DENEGADO");
    }

    @Test
    @Order(4)
    void cu23LaMesaRespondeYCierraConLaMetaDeCuatroHoras() throws Exception {
        long id = radicar("{\"idCliente\":1,\"tipo\":\"DANO\",\"descripcion\":\"El empaque llego roto\"}");
        JsonNode pendientes = ok(mesa.get("/api/mesa/reclamaciones"), 200);
        JsonNode propia = null;
        boolean fuera = false;
        for (JsonNode f : pendientes) {
            if (f.get("idReclamacion").asLong() == id) {
                propia = f;
            }
            fuera |= f.get("superaMeta").asBoolean();
        }
        assertThat(propia).isNotNull();
        assertThat(propia.get("superaMeta").asBoolean()).isFalse();
        assertThat(propia.get("estado").asString()).isEqualTo("ABIERTA");
        assertThat(fuera).as("los datos fijos traen reclamaciones abiertas de hace mas de 4 horas").isTrue();

        JsonNode r = ok(mesa.post("/api/mesa/reclamaciones/" + id + "/responder", "{\"respuesta\":\"Se repone el envio\"}"), 200);
        assertThat(r.get("estado").asString()).isEqualTo("RESPONDIDA");
        assertThat(r.get("fechaRespuesta").asString()).isNotBlank();
        assertThat(r.get("superaMeta").asBoolean()).isFalse();
        // sale de las pendientes y entra a las respondidas
        for (JsonNode f : ok(mesa.get("/api/mesa/reclamaciones"), 200)) {
            assertThat(f.get("idReclamacion").asLong()).isNotEqualTo(id);
        }
        boolean respondida = false;
        for (JsonNode f : ok(mesa.get("/api/mesa/reclamaciones?estado=RESPONDIDA"), 200)) {
            if (f.get("idReclamacion").asLong() == id) {
                respondida = f.get("respuesta").asString().equals("Se repone el envio");
            }
        }
        assertThat(respondida).isTrue();

        // rechazos: responder de nuevo (409), cerrar una abierta (409), respuesta vacia (400), inexistente (404)
        problema(mesa.post("/api/mesa/reclamaciones/" + id + "/responder", "{\"respuesta\":\"Otra\"}"), 409, "ESTADO_INCORRECTO");
        long abierta = radicar("{\"idCliente\":1,\"tipo\":\"OTRO\",\"descripcion\":\"Otra reclamacion\"}");
        problema(mesa.post("/api/mesa/reclamaciones/" + abierta + "/cerrar", ""), 409, "ESTADO_INCORRECTO");
        problema(mesa.post("/api/mesa/reclamaciones/" + abierta + "/responder", "{\"respuesta\":\" \"}"), 400, "ENTRADA_INVALIDA");
        problema(mesa.post("/api/mesa/reclamaciones/999999/responder", "{\"respuesta\":\"x\"}"), 404, "NO_ENCONTRADO");
        problema(mesa.post("/api/mesa/reclamaciones/999999/cerrar", ""), 404, "NO_ENCONTRADO");
        problema(centro.post("/api/mesa/reclamaciones/" + id + "/cerrar", ""), 403, "ACCESO_DENEGADO");
        problema(mesa.post("/api/mesa/reclamaciones", "{\"idCliente\":1,\"tipo\":\"OTRO\",\"descripcion\":\"" + "x".repeat(501) + "\"}"), 400, "ENTRADA_INVALIDA");

        // cerrar la respondida
        assertThat(ok(mesa.post("/api/mesa/reclamaciones/" + id + "/cerrar", ""), 200).get("estado").asString()).isEqualTo("CERRADA");
        problema(mesa.post("/api/mesa/reclamaciones/" + id + "/cerrar", ""), 409, "ESTADO_INCORRECTO");
        problema(mesa.get("/api/mesa/reclamaciones?estado=CERRADA"), 400, "ENTRADA_INVALIDA");
    }

    // ------------------------------------------------------------------ CU13 Centros y zonas

    @Test
    @Order(5)
    void cu13ElCentroCreaModificaEInactivaCentros() throws Exception {
        JsonNode centros = ok(centro.get("/api/centro/centros"), 200);
        assertThat(centros.size()).isGreaterThanOrEqualTo(2);

        JsonNode nuevo = ok(centro.post("/api/centro/centros",
                "{\"nombre\":\"Centro Oriente\",\"direccion\":\"Calle 80 # 10-20\",\"telefono\":\"6012000003\"}"), 201);
        long id = nuevo.get("idCentro").asLong();
        assertThat(nuevo.get("estado").asString()).isEqualTo("ACTIVO");

        JsonNode modificado = ok(centro.post("/api/centro/centros/" + id + "/modificar",
                "{\"nombre\":\"Centro Oriente\",\"direccion\":\"Carrera 15 # 85-10\",\"telefono\":\"6012000004\"}"), 200);
        assertThat(modificado.get("direccion").asString()).isEqualTo("Carrera 15 # 85-10");
        assertThat(modificado.get("estado").asString()).isEqualTo("ACTIVO");

        // una zona en el centro activo; despues el centro se inactiva y ya no admite zonas (nada se borra, RN16)
        JsonNode zona = ok(centro.post("/api/centro/zonas",
                "{\"idCentro\":" + id + ",\"nombre\":\"Oriente\",\"localidades\":\"Santa Fe, La Candelaria\"}"), 201);
        long idZona = zona.get("idZona").asLong();
        assertThat(ok(centro.post("/api/centro/zonas/" + idZona + "/modificar",
                "{\"idCentro\":" + id + ",\"nombre\":\"Oriente\",\"localidades\":\"Santa Fe, La Candelaria, Los Mártires\"}"), 200)
                .get("localidades").asString()).contains("Los Mártires");
        assertThat(ok(centro.post("/api/centro/centros/" + id + "/estado", "{\"estado\":\"INACTIVO\"}"), 200).get("estado").asString())
                .isEqualTo("INACTIVO");
        assertThat(ok(centro.get("/api/centro/centros"), 200).size()).isEqualTo(centros.size() + 1);

        // rechazos de centros
        problema(centro.post("/api/centro/centros/" + id + "/estado", "{\"estado\":\"INACTIVO\"}"), 409, "ESTADO_INCORRECTO");
        problema(centro.post("/api/centro/centros", "{\"nombre\":\"Centro Oriente\",\"direccion\":\"Otra\"}"), 409, "DATO_DUPLICADO");
        problema(centro.post("/api/centro/centros", "{\"nombre\":\" \",\"direccion\":\"Otra\"}"), 400, "ENTRADA_INVALIDA");
        problema(centro.post("/api/centro/centros", "{\"nombre\":\"" + "x".repeat(61) + "\",\"direccion\":\"Otra\"}"), 400, "ENTRADA_INVALIDA");
        problema(centro.post("/api/centro/centros/" + id + "/estado", "{\"estado\":\"BORRADO\"}"), 400, "SOLICITUD_INVALIDA");
        problema(centro.post("/api/centro/centros/999/modificar", "{\"nombre\":\"X\",\"direccion\":\"Y\"}"), 404, "NO_ENCONTRADO");
        problema(mesa.get("/api/centro/centros"), 403, "ACCESO_DENEGADO");

        // rechazos de zonas: centro inactivo (409), nombre repetido (409), centro inexistente o datos vacios (400), zona inexistente (404)
        problema(centro.post("/api/centro/zonas", "{\"idCentro\":" + id + ",\"nombre\":\"Otra zona\",\"localidades\":\"X\"}"), 409, "ESTADO_INCORRECTO");
        problema(centro.post("/api/centro/zonas", "{\"idCentro\":1,\"nombre\":\"Norte\",\"localidades\":\"X\"}"), 409, "DATO_DUPLICADO");
        problema(centro.post("/api/centro/zonas", "{\"idCentro\":999,\"nombre\":\"Z\",\"localidades\":\"X\"}"), 400, "ENTRADA_INVALIDA");
        problema(centro.post("/api/centro/zonas", "{\"idCentro\":1,\"nombre\":\"\",\"localidades\":\"X\"}"), 400, "ENTRADA_INVALIDA");
        problema(centro.post("/api/centro/zonas/9999/modificar", "{\"idCentro\":1,\"nombre\":\"Z\",\"localidades\":\"X\"}"), 404, "NO_ENCONTRADO");
        problema(centro.post("/api/centro/zonas/" + idZona + "/modificar", "{\"idCentro\":1,\"nombre\":\"Norte\",\"localidades\":\"X\"}"), 409, "DATO_DUPLICADO");

        // se reactiva y vuelve a admitir zonas
        assertThat(ok(centro.post("/api/centro/centros/" + id + "/estado", "{\"estado\":\"ACTIVO\"}"), 200).get("estado").asString()).isEqualTo("ACTIVO");
        ok(centro.post("/api/centro/zonas", "{\"idCentro\":" + id + ",\"nombre\":\"Oriente alto\",\"localidades\":\"Usaquen\"}"), 201);
        assertThat(ok(centro.get("/api/centro/zonas"), 200).size()).isGreaterThanOrEqualTo(7);
    }
}
