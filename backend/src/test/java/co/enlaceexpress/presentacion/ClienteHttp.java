package co.enlaceexpress.presentacion;

import java.net.CookieManager;
import java.net.HttpCookie;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpHeaders;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;

import tools.jackson.databind.JsonNode;
import tools.jackson.databind.json.JsonMapper;

/** Cliente HTTP real con cookies (como un navegador) que maneja el token CSRF de la aplicacion. */
class ClienteHttp {

    record Respuesta(int estado, String cuerpo, HttpHeaders encabezados) {
        JsonNode json() {
            return JsonMapper.builder().build().readTree(cuerpo);
        }

        String encabezado(String nombre) {
            return encabezados.firstValue(nombre).orElse(null);
        }
    }

    private final String base;
    private final CookieManager cookies = new CookieManager();
    private final HttpClient http = HttpClient.newBuilder().cookieHandler(cookies).build();

    ClienteHttp(int puerto) {
        this.base = "http://localhost:" + puerto;
    }

    Respuesta get(String ruta) throws Exception {
        return enviar(HttpRequest.newBuilder(URI.create(base + ruta)).GET().build());
    }

    /** POST con el token CSRF (el de la cookie XSRF-TOKEN) en X-XSRF-TOKEN. */
    Respuesta post(String ruta, String json) throws Exception {
        return enviar(construirPost(ruta, json, token()));
    }

    /** POST sin el encabezado CSRF. */
    Respuesta postSinCsrf(String ruta, String json) throws Exception {
        return enviar(construirPost(ruta, json, null));
    }

    String cookie(String nombre) {
        return cookies.getCookieStore().getCookies().stream().filter(c -> c.getName().equals(nombre))
                .map(HttpCookie::getValue).findFirst().orElse(null);
    }

    private String token() throws Exception {
        if (cookie("XSRF-TOKEN") == null) {
            get("/api/csrf");
        }
        return cookie("XSRF-TOKEN");
    }

    private HttpRequest construirPost(String ruta, String json, String token) {
        HttpRequest.Builder b = HttpRequest.newBuilder(URI.create(base + ruta))
                .header("Content-Type", "application/json")
                .POST(HttpRequest.BodyPublishers.ofString(json == null ? "" : json, StandardCharsets.UTF_8));
        if (token != null) {
            b.header("X-XSRF-TOKEN", token);
        }
        return b.build();
    }

    private Respuesta enviar(HttpRequest peticion) throws Exception {
        HttpResponse<String> r = http.send(peticion, HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
        return new Respuesta(r.statusCode(), r.body(), r.headers());
    }

    /** Peticion GET con una cookie de sesion escrita a mano, sin pasar por el almacen de cookies. */
    static Respuesta getConCookie(int puerto, String ruta, String cookie) throws Exception {
        HttpResponse<String> r = HttpClient.newHttpClient().send(
                HttpRequest.newBuilder(URI.create("http://localhost:" + puerto + ruta)).header("Cookie", cookie).GET().build(),
                HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
        return new Respuesta(r.statusCode(), r.body(), r.headers());
    }
}
