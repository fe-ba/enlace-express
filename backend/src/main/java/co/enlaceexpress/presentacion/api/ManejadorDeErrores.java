package co.enlaceexpress.presentacion.api;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.HttpStatusCode;
import org.springframework.http.ProblemDetail;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.core.AuthenticationException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.context.request.WebRequest;
import org.springframework.web.servlet.mvc.method.annotation.ResponseEntityExceptionHandler;

import co.enlaceexpress.casosdeuso.seguridad.ServicioAutenticacion;
import co.enlaceexpress.dominio.reglas.AccesoDenegado;
import co.enlaceexpress.dominio.reglas.DatoDuplicado;
import co.enlaceexpress.dominio.reglas.DatoInvalido;
import co.enlaceexpress.dominio.reglas.EntradaInvalida;
import co.enlaceexpress.dominio.reglas.ErrorDeDatos;
import co.enlaceexpress.dominio.reglas.EstadoIncorrecto;
import co.enlaceexpress.dominio.reglas.RecursoNoEncontrado;
import co.enlaceexpress.dominio.reglas.RecursoOcupado;
import co.enlaceexpress.dominio.reglas.ReferenciaInexistente;
import co.enlaceexpress.dominio.reglas.RegistroEnUso;
import co.enlaceexpress.dominio.reglas.ReglaNegocioException;

/**
 * Todos los errores de la API salen como Problem Details (RFC 9457) con la propiedad "codigo": el codigo
 * de la regla de negocio (RN07, E1, ...) o uno general. Nunca llevan pila ni SQL.
 * <ul>
 * <li>ReglaNegocioException -> 422 (codigo de la regla)</li>
 * <li>DatoInvalido, EntradaInvalida y cuerpo mal formado -> 400</li>
 * <li>DatoDuplicado, RegistroEnUso, RecursoOcupado, EstadoIncorrecto -> 409</li>
 * <li>ReferenciaInexistente -> 400: el cliente envio una referencia que no existe</li>
 * <li>AccesoDenegado, rol insuficiente o CSRF -> 403; sin sesion -> 401; no encontrado -> 404</li>
 * <li>demasiadas consultas -> 429 con Retry-After; cualquier otro error -> 500 generico</li>
 * </ul>
 */
@RestControllerAdvice
public class ManejadorDeErrores extends ResponseEntityExceptionHandler {

    private static final Logger REGISTRO = LoggerFactory.getLogger(ManejadorDeErrores.class);

    private static ResponseEntity<Object> problema(HttpStatus estado, String titulo, String codigo, String detalle) {
        ProblemDetail p = ProblemDetail.forStatusAndDetail(estado, detalle);
        p.setTitle(titulo);
        p.setProperty("codigo", codigo);
        return ResponseEntity.status(estado).body(p);
    }

    @ExceptionHandler(ReglaNegocioException.class)
    ResponseEntity<Object> reglaDeNegocio(ReglaNegocioException e) {
        return problema(HttpStatus.UNPROCESSABLE_CONTENT, "Regla de negocio incumplida", e.codigo(), e.getMessage());
    }

    @ExceptionHandler(DatoInvalido.class)
    ResponseEntity<Object> datoInvalido(DatoInvalido e) {
        ResponseEntity<Object> r = problema(HttpStatus.BAD_REQUEST, "Dato inválido", "DATO_INVALIDO", e.getMessage());
        if (e.restriccion() != null) {
            ((ProblemDetail) r.getBody()).setProperty("restriccion", e.restriccion());
        }
        return r;
    }

    @ExceptionHandler(EntradaInvalida.class)
    ResponseEntity<Object> entradaInvalida(EntradaInvalida e) {
        ResponseEntity<Object> r = problema(HttpStatus.BAD_REQUEST, "Solicitud inválida", "ENTRADA_INVALIDA", e.getMessage());
        ((ProblemDetail) r.getBody()).setProperty("campo", e.campo());
        return r;
    }

    @ExceptionHandler(DatoDuplicado.class)
    ResponseEntity<Object> datoDuplicado(DatoDuplicado e) {
        return problema(HttpStatus.CONFLICT, "Dato duplicado", "DATO_DUPLICADO", "Ya existe un registro con ese valor");
    }

    @ExceptionHandler(RegistroEnUso.class)
    ResponseEntity<Object> registroEnUso(RegistroEnUso e) {
        return problema(HttpStatus.CONFLICT, "Registro en uso", "REGISTRO_EN_USO", "El registro tiene datos que dependen de él");
    }

    @ExceptionHandler(RecursoOcupado.class)
    ResponseEntity<Object> recursoOcupado(RecursoOcupado e) {
        return problema(HttpStatus.CONFLICT, "Recurso ocupado", "RECURSO_OCUPADO", "Otra operación está usando el registro; intente de nuevo");
    }

    @ExceptionHandler(ReferenciaInexistente.class)
    ResponseEntity<Object> referenciaInexistente(ReferenciaInexistente e) {
        return problema(HttpStatus.BAD_REQUEST, "Referencia inexistente", "REFERENCIA_INEXISTENTE", "Un dato hace referencia a un registro que no existe");
    }

    @ExceptionHandler(AccesoDenegado.class)
    ResponseEntity<Object> accesoDenegadoEnLaBase(AccesoDenegado e) {
        REGISTRO.warn("La cuenta de servicio no tiene privilegio: {}", e.getMessage());
        return problema(HttpStatus.FORBIDDEN, "Acceso denegado", "ACCESO_DENEGADO", "No tiene permiso para esta operación");
    }

    @ExceptionHandler(EstadoIncorrecto.class)
    ResponseEntity<Object> estadoIncorrecto(EstadoIncorrecto e) {
        return problema(HttpStatus.CONFLICT, "Estado incorrecto", "ESTADO_INCORRECTO", e.getMessage());
    }

    @ExceptionHandler(RecursoNoEncontrado.class)
    ResponseEntity<Object> noEncontrado(RecursoNoEncontrado e) {
        return problema(HttpStatus.NOT_FOUND, "No encontrado", "NO_ENCONTRADO", e.getMessage());
    }

    @ExceptionHandler(BadCredentialsException.class)
    ResponseEntity<Object> credenciales(BadCredentialsException e) {
        return problema(HttpStatus.UNAUTHORIZED, "No autenticado", "CREDENCIALES_INCORRECTAS", ServicioAutenticacion.MENSAJE_ERROR);
    }

    @ExceptionHandler(AuthenticationException.class)
    ResponseEntity<Object> noAutenticado(AuthenticationException e) {
        return problema(HttpStatus.UNAUTHORIZED, "No autenticado", "NO_AUTENTICADO", "Debe iniciar sesión");
    }

    @ExceptionHandler(AccessDeniedException.class)
    ResponseEntity<Object> accesoDenegado(AccessDeniedException e) {
        boolean csrf = e instanceof org.springframework.security.web.csrf.CsrfException;
        return problema(HttpStatus.FORBIDDEN, csrf ? "Token CSRF ausente o inválido" : "Acceso denegado",
                csrf ? "CSRF" : "ACCESO_DENEGADO", csrf ? "Falta el token CSRF o no es válido" : "Su rol no tiene acceso a este recurso");
    }

    @ExceptionHandler(DemasiadasConsultas.class)
    ResponseEntity<Object> demasiadasConsultas(DemasiadasConsultas e) {
        ProblemDetail p = ProblemDetail.forStatusAndDetail(HttpStatus.TOO_MANY_REQUESTS, e.getMessage());
        p.setTitle("Demasiadas consultas");
        p.setProperty("codigo", "DEMASIADAS_CONSULTAS");
        p.setProperty("reintentarEnSegundos", e.reintentarEnSegundos());
        return ResponseEntity.status(HttpStatus.TOO_MANY_REQUESTS).header(HttpHeaders.RETRY_AFTER, String.valueOf(e.reintentarEnSegundos())).body(p);
    }

    @ExceptionHandler(ErrorDeDatos.class)
    ResponseEntity<Object> errorDeDatos(ErrorDeDatos e) {
        REGISTRO.error("Error de datos (ORA-{})", e.codigoOracle(), e);
        return problema(HttpStatus.INTERNAL_SERVER_ERROR, "Error interno", "ERROR_INTERNO", "No se pudo completar la operación");
    }

    @ExceptionHandler(Exception.class)
    ResponseEntity<Object> inesperado(Exception e) {
        REGISTRO.error("Error inesperado", e);
        return problema(HttpStatus.INTERNAL_SERVER_ERROR, "Error interno", "ERROR_INTERNO", "No se pudo completar la operación");
    }

    /** Los errores propios de Spring MVC (cuerpo mal formado, ruta inexistente, metodo no permitido) tambien llevan "codigo". */
    @Override
    protected ResponseEntity<Object> handleExceptionInternal(Exception e, Object cuerpo, HttpHeaders encabezados,
            HttpStatusCode estado, WebRequest peticion) {
        ResponseEntity<Object> r = super.handleExceptionInternal(e, cuerpo, encabezados, estado, peticion);
        if (r != null && r.getBody() instanceof ProblemDetail p && (p.getProperties() == null || !p.getProperties().containsKey("codigo"))) {
            p.setProperty("codigo", estado.value() == 404 ? "NO_ENCONTRADO" : estado.value() == 400 ? "SOLICITUD_INVALIDA" : "HTTP_" + estado.value());
        }
        return r;
    }
}
