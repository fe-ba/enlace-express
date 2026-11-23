package co.enlaceexpress.presentacion;

import static org.assertj.core.api.Assertions.assertThat;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.annotation.DirtiesContext;

/**
 * La documentacion de la API (decision E3) se entrega sin sesion y trae las rutas principales de cada
 * seccion; las rutas de los roles siguen exigiendo sesion.
 */
@DirtiesContext(classMode = DirtiesContext.ClassMode.AFTER_CLASS)
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
class OpenApiIT {

    @Value("${local.server.port}")
    private int puerto;

    private HttpResponse<String> pedir(String ruta) throws Exception {
        return HttpClient.newBuilder().followRedirects(HttpClient.Redirect.NORMAL).build().send(
                HttpRequest.newBuilder(URI.create("http://localhost:" + puerto + ruta)).GET().build(),
                HttpResponse.BodyHandlers.ofString());
    }

    @Test
    void elDocumentoOpenApiSeEntregaSinSesionYTraeLasRutasPrincipales() throws Exception {
        HttpResponse<String> r = pedir("/v3/api-docs");
        assertThat(r.statusCode()).isEqualTo(200);
        assertThat(r.headers().firstValue("Content-Type")).hasValueSatisfying(t -> assertThat(t).contains("json"));
        assertThat(r.body())
                .contains("\"title\":\"API de Enlace Express - módulo M1\"")
                .contains("\"/api/mesa/envios\"")
                .contains("\"/api/centro/despachos\"")
                .contains("\"/api/mensajero/asignaciones/{id}/entrega\"")
                .contains("\"/api/publico/rastreo/{guia}\"")
                // secciones, autenticacion y formato de error
                .contains("\"name\":\"Mesa de servicio\"").contains("\"name\":\"Rastreo público\"")
                .contains("cookieDeSesion").contains("X-XSRF-TOKEN").contains("\"codigo\"");
    }

    @Test
    void swaggerUiSeEntregaSinSesion() throws Exception {
        HttpResponse<String> r = pedir("/swagger-ui.html");
        assertThat(r.statusCode()).isEqualTo(200);
        assertThat(r.body()).containsIgnoringCase("swagger");
    }

    @Test
    void documentarLaApiNoAbreLasRutasDeLosRoles() throws Exception {
        assertThat(pedir("/api/mesa/clientes").statusCode()).isEqualTo(401);
        assertThat(pedir("/api/tablero/cumplimiento").statusCode()).isEqualTo(401);
        assertThat(pedir("/api/centro/por-despachar").statusCode()).isEqualTo(401);
    }
}
