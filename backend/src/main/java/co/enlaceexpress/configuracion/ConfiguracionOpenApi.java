package co.enlaceexpress.configuracion;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import org.springdoc.core.customizers.OpenApiCustomizer;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import io.swagger.v3.oas.models.Components;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.Operation;
import io.swagger.v3.oas.models.PathItem;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.media.Content;
import io.swagger.v3.oas.models.media.MediaType;
import io.swagger.v3.oas.models.media.ObjectSchema;
import io.swagger.v3.oas.models.media.Schema;
import io.swagger.v3.oas.models.media.StringSchema;
import io.swagger.v3.oas.models.responses.ApiResponse;
import io.swagger.v3.oas.models.security.SecurityRequirement;
import io.swagger.v3.oas.models.security.SecurityScheme;
import io.swagger.v3.oas.models.tags.Tag;

/**
 * Documentacion de la API con OpenAPI 3 y Swagger UI (decision E3). springdoc infiere las rutas y los
 * esquemas de los controladores; aqui solo se agrega lo que no puede inferir: la informacion de la API,
 * las secciones (etiquetas por prefijo de ruta), el rol que exige cada ruta, la autenticacion por cookie
 * de sesion con token CSRF y el formato de los errores (Problem Details con la propiedad "codigo").
 */
@Configuration
public class ConfiguracionOpenApi {

    static final String SESION = "cookieDeSesion";
    static final String CSRF = "tokenCsrf";

    /** Seccion de la documentacion: prefijo de ruta, nombre de la etiqueta, descripcion y rol que exige. */
    private record Seccion(String prefijo, String etiqueta, String descripcion, String rol) {
    }

    private static final List<Seccion> SECCIONES = List.of(
        new Seccion("/api/mesa/", "Mesa de servicio", "Solicitudes de recolección, registro, consulta y anulación de envíos.", "MESA"),
        new Seccion("/api/centro/", "Centro de distribución", "Recepción y clasificación, envíos por despachar, armado, planilla y cierre de despachos.", "CENTRO"),
        new Seccion("/api/mensajero/", "Mensajero", "Recolecciones, planilla de ruta, entrega con prueba, novedad y devolución.", "MENSAJERO"),
        new Seccion("/api/tablero/", "Tablero de gerencia", "Cumplimiento de entregas por zona, envíos por estado y reclamaciones pendientes.", "GERENCIA"),
        new Seccion("/api/cliente/", "Portal del cliente", "Envíos y seguimiento de la empresa del cliente que inició sesión.", "CLIENTE"),
        new Seccion("/api/publico/", "Rastreo público", "Consulta de un envío por su número de guía, sin cuenta y sin datos personales; limitada por dirección IP.", null),
        new Seccion("/api/sesion", "Sesión y registro", "Inicio y cierre de sesión, token CSRF y registro con código de activación.", null),
        new Seccion("/api/csrf", "Sesión y registro", "Inicio y cierre de sesión, token CSRF y registro con código de activación.", null),
        new Seccion("/api/registro/", "Sesión y registro", "Inicio y cierre de sesión, token CSRF y registro con código de activación.", null),
        new Seccion("/api/salud", "Salud", "Chequeo de que la aplicación y la base de datos responden.", null));

    @Bean
    public OpenAPI informacionDeLaApi() {
        Components componentes = new Components()
                .addSecuritySchemes(SESION, new SecurityScheme().type(SecurityScheme.Type.APIKEY)
                        .in(SecurityScheme.In.COOKIE).name("JSESSIONID")
                        .description("Sesión en el servidor: la cookie JSESSIONID la entrega POST /api/sesion con usuario y contraseña."))
                .addSecuritySchemes(CSRF, new SecurityScheme().type(SecurityScheme.Type.APIKEY)
                        .in(SecurityScheme.In.HEADER).name("X-XSRF-TOKEN")
                        .description("Token contra falsificación de peticiones (CSRF), obligatorio en los POST. Se obtiene con GET /api/csrf: "
                                + "el valor de la cookie XSRF-TOKEN se envía en este encabezado."));
        return new OpenAPI()
                .info(new Info()
                        .title("API de Enlace Express - módulo M1")
                        .version("0.1.0")
                        .description("""
                                API REST del prototipo del módulo M1 (operación de envíos) de BD_ENLACE_EXPRESS.

                                **Autenticación.** Sesión en el servidor: `POST /api/sesion` entrega la cookie `JSESSIONID`. \
                                Cada ruta exige el rol que indica su sección. Los `POST` también exigen el token CSRF en el \
                                encabezado `X-XSRF-TOKEN` (valor de la cookie `XSRF-TOKEN`, que entrega `GET /api/csrf`). \
                                El rastreo público y el registro no necesitan sesión.

                                **Errores.** Todos salen como Problem Details (RFC 9457) con la propiedad `codigo`: \
                                422 para las reglas de negocio (`RN01` a `RN16`, `E1`), 400 para datos inválidos, 401 sin sesión, \
                                403 sin permiso, 404 si no existe, 409 por conflictos y 429 por demasiadas consultas.\
                                """))
                .components(componentes);
    }

    /** Esquema de los errores de la API (Problem Details con la propiedad "codigo"). */
    private static Schema<?> esquemaDelProblema() {
        return new ObjectSchema()
                .description("Error de la API en formato Problem Details (RFC 9457), con la propiedad adicional \"codigo\".")
                .addProperty("type", new StringSchema().example("about:blank"))
                .addProperty("title", new StringSchema().example("Regla de negocio incumplida"))
                .addProperty("status", new Schema<Integer>().type("integer").example(422))
                .addProperty("detail", new StringSchema().example("la guía EE0000000000030 ya está en un estado final (ENTREGADO) y no admite el evento ANULADO"))
                .addProperty("codigo", new StringSchema().description(
                        "Código de la regla de negocio (RN01 a RN16, E1) o uno general: DATO_INVALIDO, DATO_DUPLICADO, "
                        + "REFERENCIA_INEXISTENTE, RECURSO_OCUPADO, ACCESO_DENEGADO, NO_AUTENTICADO, CSRF, NO_ENCONTRADO, "
                        + "DEMASIADAS_CONSULTAS, ERROR_INTERNO.").example("RN12"));
    }

    /** Etiqueta cada ruta por su sección y le agrega el rol y la autenticacion que exige. */
    @Bean
    public OpenApiCustomizer seccionesDeLaApi() {
        return openApi -> {
            Map<String, Tag> etiquetas = new LinkedHashMap<>();
            for (Seccion s : SECCIONES) {
                etiquetas.putIfAbsent(s.etiqueta(), new Tag().name(s.etiqueta()).description(s.descripcion()));
            }
            openApi.setTags(new ArrayList<>(etiquetas.values()));
            // el esquema se agrega aqui porque springdoc reemplaza los esquemas del bean al armar el documento
            openApi.getComponents().addSchemas("Problema", esquemaDelProblema());
            if (openApi.getPaths() == null) {
                return;
            }
            openApi.getPaths().forEach((ruta, item) -> {
                Seccion seccion = SECCIONES.stream().filter(s -> ruta.startsWith(s.prefijo())).findFirst().orElse(null);
                if (seccion == null) {
                    return;
                }
                item.readOperationsMap().forEach((metodo, operacion) -> describir(metodo, operacion, seccion));
            });
        };
    }

    private static void describir(PathItem.HttpMethod metodo, Operation operacion, Seccion seccion) {
        operacion.setTags(List.of(seccion.etiqueta()));
        // cualquier otra respuesta es un error en formato Problem Details
        if (operacion.getResponses() != null && !operacion.getResponses().containsKey("default")) {
            operacion.getResponses().addApiResponse("default", new ApiResponse()
                    .description("Error: formato Problem Details con el código de la regla o del error en la propiedad \"codigo\".")
                    .content(new Content().addMediaType("application/problem+json",
                            new MediaType().schema(new Schema<>().$ref("#/components/schemas/Problema")))));
        }
        if (seccion.rol() != null) {
            String aviso = "Rol requerido: " + seccion.rol() + ".";
            operacion.setDescription(operacion.getDescription() == null ? aviso : aviso + " " + operacion.getDescription());
            operacion.addSecurityItem(new SecurityRequirement().addList(SESION));
        }
        if (metodo == PathItem.HttpMethod.POST && !"/api/csrf".equals(seccion.prefijo())) {
            operacion.addSecurityItem(new SecurityRequirement().addList(CSRF));
        }
    }
}
