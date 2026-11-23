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

/** Arranca la aplicacion completa (configuracion, .env, pools por rol) y llama a /api/salud. */
// cierra el contexto (y los pools) al terminar: otras pruebas reinstalan la base
@DirtiesContext(classMode = DirtiesContext.ClassMode.AFTER_CLASS)
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
class SaludIT {

    @Value("${local.server.port}")
    private int puerto;

    @Test
    void saludResponde200ConLosDatosDeLaBase() throws Exception {
        HttpResponse<String> respuesta = HttpClient.newHttpClient().send(
                HttpRequest.newBuilder(URI.create("http://localhost:" + puerto + "/api/salud")).GET().build(),
                HttpResponse.BodyHandlers.ofString());
        assertThat(respuesta.statusCode()).isEqualTo(200);
        assertThat(respuesta.body()).contains("\"estado\":\"OK\"").contains("\"baseDeDatos\":\"FREEPDB1\"")
                .contains("\"esquema\":\"BD_ENLACE_EXPRESS\"").contains("\"horaBase\":");
    }
}
