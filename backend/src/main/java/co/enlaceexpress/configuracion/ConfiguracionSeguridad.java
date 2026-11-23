package co.enlaceexpress.configuracion;

import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configurers.RequestCacheConfigurer;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.context.HttpSessionSecurityContextRepository;
import org.springframework.security.web.context.SecurityContextRepository;
import org.springframework.security.web.csrf.CookieCsrfTokenRepository;
import org.springframework.security.web.csrf.CsrfTokenRepository;
import org.springframework.security.web.csrf.CsrfTokenRequestAttributeHandler;
import org.springframework.web.servlet.HandlerExceptionResolver;

/**
 * Spring Security con sesion en el servidor (cookie JSESSIONID, sin JWT), contrasenas BCrypt y CSRF (decision
 * 12.2). La autenticacion la hace SesionController con pkg_seguridad. El rol de la sesion decide las rutas;
 * los errores 401 y 403 salen como Problem Details por el mismo manejador de errores de la API.
 */
@Configuration
public class ConfiguracionSeguridad {

    @Bean
    public PasswordEncoder codificadorDeContrasenas() {
        return new BCryptPasswordEncoder(10);
    }

    /** El token CSRF va en la cookie XSRF-TOKEN (legible por el frontend) y se devuelve en el encabezado X-XSRF-TOKEN. */
    @Bean
    public CsrfTokenRepository repositorioCsrf(@Value("${server.servlet.session.cookie.secure:false}") boolean cookieSegura) {
        CookieCsrfTokenRepository repositorio = CookieCsrfTokenRepository.withHttpOnlyFalse();
        // detras de un proxy con HTTPS la peticion llega a la aplicacion por HTTP, asi que la marca Secure se pide
        // con la misma propiedad que la de la cookie de sesion (ENLACE_COOKIE_SEGURA)
        repositorio.setCookieCustomizer(cookie -> cookie.sameSite("Lax").path("/").secure(cookieSegura));
        return repositorio;
    }

    @Bean
    public SecurityContextRepository repositorioDeContexto() {
        return new HttpSessionSecurityContextRepository();
    }

    @Bean
    public SecurityFilterChain cadenaDeSeguridad(HttpSecurity http, CsrfTokenRepository repositorioCsrf,
            SecurityContextRepository repositorioDeContexto,
            @Qualifier("handlerExceptionResolver") HandlerExceptionResolver resolvedor) throws Exception {
        http
            .csrf(csrf -> csrf.csrfTokenRepository(repositorioCsrf)
                    // el frontend manda en X-XSRF-TOKEN el mismo valor de la cookie
                    .csrfTokenRequestHandler(new CsrfTokenRequestAttributeHandler()))
            .securityContext(contexto -> contexto.securityContextRepository(repositorioDeContexto))
            .formLogin(formulario -> formulario.disable())
            .httpBasic(basica -> basica.disable())
            .logout(salida -> salida.disable())
            .requestCache(RequestCacheConfigurer::disable)
            .authorizeHttpRequests(rutas -> rutas
                .requestMatchers("/api/publico/**", "/api/salud", "/api/csrf").permitAll()
                // documentacion de la API (OpenAPI y Swagger UI): solo lectura, sin sesion; no da acceso a ninguna ruta
                .requestMatchers("/v3/api-docs", "/v3/api-docs/**", "/swagger-ui.html", "/swagger-ui/**").permitAll()
                .requestMatchers(HttpMethod.POST, "/api/sesion", "/api/registro/**").permitAll()
                .requestMatchers("/api/mesa/**").hasRole("MESA")
                .requestMatchers("/api/centro/**").hasRole("CENTRO")
                .requestMatchers("/api/mensajero/**").hasRole("MENSAJERO")
                .requestMatchers("/api/tablero/**").hasRole("GERENCIA")
                .requestMatchers("/api/cliente/**").hasRole("CLIENTE")
                .requestMatchers("/api/**").authenticated()
                .anyRequest().permitAll())   // archivos estaticos del frontend
            .exceptionHandling(errores -> errores
                .authenticationEntryPoint((peticion, respuesta, e) -> resolvedor.resolveException(peticion, respuesta, null, e))
                .accessDeniedHandler((peticion, respuesta, e) -> resolvedor.resolveException(peticion, respuesta, null, e)));
        return http.build();
    }
}
