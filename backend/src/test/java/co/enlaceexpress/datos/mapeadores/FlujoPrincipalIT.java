package co.enlaceexpress.datos.mapeadores;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.function.Function;

import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.MethodOrderer;
import org.junit.jupiter.api.Order;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.TestMethodOrder;

import co.enlaceexpress.casosdeuso.indicadores.FilaPlanilla;
import co.enlaceexpress.casosdeuso.indicadores.FilaSeguimiento;
import co.enlaceexpress.datos.ConfiguracionPruebas;
import co.enlaceexpress.datos.EntornoPruebas;
import co.enlaceexpress.datos.informes.InformesMapper;
import co.enlaceexpress.datos.infraestructura.FabricaConexiones;
import co.enlaceexpress.datos.infraestructura.UnidadDeTrabajo;
import co.enlaceexpress.dominio.despacho.AsignacionDespacho;
import co.enlaceexpress.dominio.despacho.Despacho;
import co.enlaceexpress.dominio.despacho.Novedad;
import co.enlaceexpress.dominio.despacho.PruebaEntrega;
import co.enlaceexpress.dominio.enums.EstadoEnvio;
import co.enlaceexpress.dominio.enums.FranjaHoraria;
import co.enlaceexpress.dominio.enums.ResultadoVisita;
import co.enlaceexpress.dominio.enums.Rol;
import co.enlaceexpress.dominio.enums.TipoDespacho;
import co.enlaceexpress.dominio.enums.TipoDocumento;
import co.enlaceexpress.dominio.enums.TipoNovedad;
import co.enlaceexpress.dominio.enums.TipoPrueba;
import co.enlaceexpress.dominio.envio.Destinatario;
import co.enlaceexpress.dominio.envio.Envio;
import co.enlaceexpress.dominio.envio.EventoEnvio;
import co.enlaceexpress.dominio.referencia.Catalogos;
import co.enlaceexpress.dominio.referencia.Cliente;
import co.enlaceexpress.dominio.referencia.Mensajero;
import co.enlaceexpress.dominio.referencia.SedeCliente;
import co.enlaceexpress.dominio.referencia.Vehiculo;
import co.enlaceexpress.dominio.reglas.ReglaNegocioException;
import co.enlaceexpress.dominio.solicitud.SolicitudRecoleccion;

/**
 * Recorre el flujo principal (decision B2) con los mapeadores, cada paso en su unidad de trabajo, con la
 * cuenta de su rol y confirmando. Antes de empezar reinstala la base (database/install.sh) y al terminar la
 * deja otra vez limpia, porque estas pruebas confirman datos.
 */
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
class FlujoPrincipalIT {

    // empleados de los datos fijos: 2 auxiliar de centro, 4 agente de mesa, 6 a 8 mensajeros de motocicleta
    private static final long AUXILIAR = 2;
    private static final long AGENTE = 4;
    private static final long MENSAJERO_RECOLECCION = 6;
    private static final long MENSAJERO_7 = 7;
    private static final long MENSAJERO_8 = 8;
    private static final long CLIENTE_1 = 1;

    private static FabricaConexiones fabrica;

    @BeforeAll
    static void prepararBase() throws Exception {
        instalarBase();
        fabrica = new FabricaConexiones(ConfiguracionPruebas.propiedades(1, 3));
    }

    @AfterAll
    static void dejarBaseLimpia() throws Exception {
        fabrica.close();
        instalarBase();
    }

    /** Reinstala desde cero (las pruebas confirman datos) y deja la secuencia de guias tras los datos fijos. */
    private static void instalarBase() {
        EntornoPruebas.instalarBase();
    }

    private static <T> T enUnidad(Rol rol, String usuario, Function<UnidadDeTrabajo, T> paso) {
        try (UnidadDeTrabajo uow = new UnidadDeTrabajo(fabrica)) {
            uow.iniciar(rol, usuario);
            T resultado = paso.apply(uow);
            uow.confirmar();
            return resultado;
        }
    }

    // ------------------------------------------------------------------ pasos del flujo (cada uno es un caso de uso en pequeno)

    private static long registrarSolicitud() {
        return enUnidad(Rol.MESA, "natalia.quintero", uow -> {
            ReferenciaMapper referencia = new ReferenciaMapper(uow);
            SedeCliente sede = referencia.sede(1).orElseThrow();
            Cliente cliente = referencia.cliente(sede.idCliente()).orElseThrow();
            LocalDate hoy = LocalDate.now();
            SolicitudRecoleccion solicitud = SolicitudRecoleccion.registrar(sede, cliente, hoy, hoy, FranjaHoraria.MANANA);
            return new SolicitudMapper(uow).insertar(solicitud);
        });
    }

    private static String registrarEnvio(long idSolicitud, String documento, boolean fragil) {
        return enUnidad(Rol.MESA, "natalia.quintero", uow -> {
            Catalogos catalogos = new ReferenciaMapper(uow).catalogos();
            Destinatario destinatario = new Destinatario(null, TipoDocumento.CC, documento, "Destinatario " + documento, "3000000000", null);
            Envio envio = Envio.nuevo(idSolicitud, destinatario, 1, catalogos.modalidad(3), "Calle 10 # 20-30",
                    new BigDecimal("2.5"), "Mercancia de prueba", new BigDecimal("150000"), fragil, false, null, AGENTE,
                    LocalDateTime.now());
            String guia = new EnvioMapper(uow).registrar(envio);
            assertThat(guia).matches("EE\\d{13}");
            return guia;
        });
    }

    private static void recolectar(long idSolicitud) {
        enUnidad(Rol.MENSAJERO, "carlos.pena", uow -> {
            SolicitudMapper solicitudes = new SolicitudMapper(uow);
            EnvioMapper envios = new EnvioMapper(uow);
            assertThat(solicitudes.bloquearPorId(idSolicitud)).isTrue();
            SolicitudRecoleccion solicitud = solicitudes.buscarPorId(idSolicitud).orElseThrow();
            solicitud.marcarAtendida();
            solicitudes.actualizarEstado(solicitud);
            for (String guia : envios.guiasDeSolicitud(idSolicitud)) {
                envios.bloquearPorGuia(guia);
                Envio envio = envios.buscarPorGuia(guia).orElseThrow();
                EventoEnvio evento = envio.registrarEvento(EstadoEnvio.RECOLECTADO, MENSAJERO_RECOLECCION, "Recogido en la sede", LocalDateTime.now());
                envios.agregarEvento(guia, evento);
            }
            return null;
        });
    }

    private static void recibirYClasificar(String guia) {
        enUnidad(Rol.CENTRO, "diego.ramirez", uow -> {
            EnvioMapper envios = new EnvioMapper(uow);
            envios.bloquearPorGuia(guia);
            Envio envio = envios.buscarPorGuia(guia).orElseThrow();
            LocalDateTime ahora = LocalDateTime.now();
            // dos eventos en la misma operacion: instantes distintos y crecientes (C5)
            EventoEnvio enCentro = envio.registrarEvento(EstadoEnvio.EN_CENTRO, AUXILIAR, "Recibido y pesado", ahora);
            EventoEnvio clasificado = envio.registrarEvento(EstadoEnvio.CLASIFICADO, AUXILIAR, "Clasificado por zona", ahora);
            assertThat(clasificado.fechaHora()).isAfter(enCentro.fechaHora());
            envio.clasificar(envio.pesoDeclarado().add(new BigDecimal("0.10")), new BigDecimal("9000"));
            envios.agregarEvento(guia, enCentro);
            envios.agregarEvento(guia, clasificado);
            envios.actualizarClasificacion(envio);
            return null;
        });
    }

    /** Arma un despacho de entrega con el mensajero y los envios dados; devuelve su id. Con el vehiculo que C9 ofrezca. */
    private static long armarDespacho(long idMensajero, List<String> guias) {
        return enUnidad(Rol.CENTRO, "diego.ramirez", uow -> {
            ReferenciaMapper referencia = new ReferenciaMapper(uow);
            DespachoMapper despachos = new DespachoMapper(uow);
            EnvioMapper envios = new EnvioMapper(uow);
            Mensajero mensajero = referencia.mensajero(idMensajero).orElseThrow();
            Vehiculo vehiculo = despachos.vehiculosDisponibles(idMensajero).get(0);
            Despacho despacho = Despacho.armar(mensajero.idCentro(), vehiculo, mensajero, LocalDate.now(), TipoDespacho.ENTREGA);
            despachos.insertar(despacho);
            for (String guia : guias) {
                envios.bloquearPorGuia(guia);
                Envio envio = envios.buscarPorGuia(guia).orElseThrow();
                envio.cargarIntentos(despachos.asignacionesDeGuia(guia));
                AsignacionDespacho asignacion = despacho.asignar(envio);
                despachos.guardarAsignacion(despacho, asignacion);
                envios.agregarEvento(guia, envio.registrarEvento(EstadoEnvio.EN_RUTA, idMensajero, "Sale en el despacho " + despacho.idDespacho(), LocalDateTime.now()));
            }
            despacho.salir(LocalDateTime.now());
            despachos.actualizarEstado(despacho);
            return despacho.idDespacho();
        });
    }

    /** Lo que el mensajero necesita de su asignacion: el envio con intentos y el documento del destinatario (de la planilla). */
    private static Envio cargarParaEntrega(UnidadDeTrabajo uow, long idDespacho, String guia, List<AsignacionDespacho> intentosSalida) {
        EnvioMapper envios = new EnvioMapper(uow);
        Envio envio = envios.buscarPorGuia(guia).orElseThrow();
        FilaPlanilla fila = new InformesMapper(uow).planilla(idDespacho).stream()
                .filter(f -> f.numeroGuia().equals(guia)).findFirst().orElseThrow();
        envio.asignarDestinatario(new Destinatario(null, fila.tipoDocumentoDestinatario(), fila.numeroDocumentoDestinatario(),
                fila.destinatario(), fila.telefono(), null));
        List<AsignacionDespacho> intentos = new DespachoMapper(uow).asignacionesDeGuia(guia);
        envio.cargarIntentos(intentos);
        intentosSalida.addAll(intentos);
        return envio;
    }

    private static AsignacionDespacho ultimoIntento(List<AsignacionDespacho> intentos) {
        return intentos.get(intentos.size() - 1);
    }

    private static void entregar(long idDespacho, String guia, long idMensajero, String documentoReceptor) {
        enUnidad(Rol.MENSAJERO, "andrea.salazar", uow -> {
            DespachoMapper despachos = new DespachoMapper(uow);
            List<AsignacionDespacho> intentos = new ArrayList<>();
            Envio envio = cargarParaEntrega(uow, idDespacho, guia, intentos);
            AsignacionDespacho asignacion = ultimoIntento(intentos);
            despachos.bloquearAsignacion(asignacion.idAsignacion());
            LocalDateTime ahora = LocalDateTime.now();
            asignacion.registrarEntrega(new PruebaEntrega(null, ahora, "Receptor", documentoReceptor, TipoPrueba.DOCUMENTO, null));
            despachos.guardarResultado(asignacion);
            new EnvioMapper(uow).agregarEvento(guia, envio.registrarEvento(EstadoEnvio.ENTREGADO, idMensajero, "Entregado", ahora));
            return null;
        });
    }

    private static void registrarNovedad(long idDespacho, String guia, long idMensajero) {
        enUnidad(Rol.MENSAJERO, "andrea.salazar", uow -> {
            DespachoMapper despachos = new DespachoMapper(uow);
            List<AsignacionDespacho> intentos = new ArrayList<>();
            Envio envio = cargarParaEntrega(uow, idDespacho, guia, intentos);
            AsignacionDespacho asignacion = ultimoIntento(intentos);
            despachos.bloquearAsignacion(asignacion.idAsignacion());
            asignacion.registrarNovedad(Novedad.nueva(TipoNovedad.DESTINATARIO_AUSENTE, "Nadie atendio"));
            despachos.guardarResultado(asignacion);
            new EnvioMapper(uow).agregarEvento(guia, envio.registrarEvento(EstadoEnvio.CON_NOVEDAD, idMensajero, "Novedad: destinatario ausente", LocalDateTime.now()));
            return null;
        });
    }

    private static List<String> recorrido(String guia, Long idCliente) {
        return enUnidad(Rol.CLIENTE, "portal", uow -> new InformesMapper(uow).seguimiento(guia, idCliente).stream()
                .map(FilaSeguimiento::estado).toList());
    }

    // ------------------------------------------------------------------ pruebas

    @Test
    @Order(1)
    void flujoPrincipalCompleto() {
        long solicitud = registrarSolicitud();
        String entregado = registrarEnvio(solicitud, "FLUJO-001", true);   // fragil: se entrega al destinatario (RN06)
        String conNovedad = registrarEnvio(solicitud, "FLUJO-002", false);
        assertThat(conNovedad).isGreaterThan(entregado);

        recolectar(solicitud);
        for (String guia : List.of(entregado, conNovedad)) {
            recibirYClasificar(guia);
        }

        // C4 y la vista de envios por despachar: los dos quedan listos para armar la ruta
        enUnidad(Rol.CENTRO, "diego.ramirez", uow -> {
            assertThat(new EnvioMapper(uow).clasificadosSinAsignar()).contains(entregado, conNovedad);
            assertThat(new InformesMapper(uow).enviosPorDespachar(1)).extracting("numeroGuia").contains(entregado, conNovedad);
            Envio envio = new EnvioMapper(uow).buscarPorGuia(entregado).orElseThrow();
            assertThat(envio.pesoReal()).isEqualByComparingTo("2.60");
            assertThat(envio.valorFlete()).isEqualByComparingTo("9000");
            assertThat(envio.estadoActual()).isEqualTo(EstadoEnvio.CLASIFICADO);
            return null;
        });

        long despacho = armarDespacho(MENSAJERO_7, List.of(entregado, conNovedad));
        enUnidad(Rol.CENTRO, "diego.ramirez", uow -> {
            assertThat(new EnvioMapper(uow).clasificadosSinAsignar()).doesNotContain(entregado, conNovedad);
            assertThat(new EnvioMapper(uow).estadoActual(entregado)).isEqualTo(EstadoEnvio.EN_RUTA);
            Despacho d = new DespachoMapper(uow).buscarPorId(despacho).orElseThrow();
            assertThat(d.asignaciones()).hasSize(2);
            return null;
        });

        // el documento de quien recibe un envio fragil debe ser el del destinatario: el dominio lo rechaza antes de la base
        assertThatThrownBy(() -> entregar(despacho, entregado, MENSAJERO_7, "999"))
                .isInstanceOfSatisfying(ReglaNegocioException.class, e -> assertThat(e.codigo()).isEqualTo("RN06"));
        entregar(despacho, entregado, MENSAJERO_7, "FLUJO-001");
        registrarNovedad(despacho, conNovedad, MENSAJERO_7);

        // seguimiento como CLIENTE (solo ve la vista del capitulo 4), filtrado por la empresa dueña
        assertThat(recorrido(entregado, CLIENTE_1)).containsExactly("REGISTRADO", "RECOLECTADO", "EN_CENTRO", "CLASIFICADO", "EN_RUTA", "ENTREGADO");
        assertThat(recorrido(conNovedad, CLIENTE_1)).containsExactly("REGISTRADO", "RECOLECTADO", "EN_CENTRO", "CLASIFICADO", "EN_RUTA", "CON_NOVEDAD");
        assertThat(recorrido(entregado, CLIENTE_1 + 1)).isEmpty();
        assertThat(recorrido(entregado, null)).hasSize(6);

        // el estado final en la base
        enUnidad(Rol.CENTRO, "diego.ramirez", uow -> {
            EnvioMapper envios = new EnvioMapper(uow);
            assertThat(envios.estadoActual(entregado)).isEqualTo(EstadoEnvio.ENTREGADO);
            assertThat(envios.estadoActual(conNovedad)).isEqualTo(EstadoEnvio.CON_NOVEDAD);
            return null;
        });
        enUnidad(Rol.MENSAJERO, "andrea.salazar", uow -> {
            List<FilaPlanilla> planilla = new InformesMapper(uow).planilla(despacho);
            assertThat(planilla).extracting(FilaPlanilla::resultado).containsExactly(ResultadoVisita.ENTREGADO, ResultadoVisita.NOVEDAD);
            AsignacionDespacho a = new DespachoMapper(uow).asignacionesDeGuia(entregado).get(0);
            new DespachoMapper(uow).cargarPruebaYNovedad(a);
            assertThat(a.prueba().documentoReceptor()).isEqualTo("FLUJO-001");
            return null;
        });
    }

    @Test
    @Order(2)
    void devolucionEnElTercerIntentoYTransicionNoPermitidaEnDominioYEnBase() {
        long solicitud = registrarSolicitud();
        String guia = registrarEnvio(solicitud, "FLUJO-003", false);
        recolectar(solicitud);
        recibirYClasificar(guia);

        // intentos 1 y 2: novedad; cada intento en un despacho distinto
        long d1 = armarDespacho(MENSAJERO_7, List.of(guia));
        registrarNovedad(d1, guia, MENSAJERO_7);
        long d2 = armarDespacho(MENSAJERO_8, List.of(guia));
        registrarNovedad(d2, guia, MENSAJERO_8);
        long d3 = armarDespacho(MENSAJERO_7, List.of(guia));

        // tercer intento: la entrega no existe, solo la devolucion (RN07), y el dominio lo rechaza sin tocar la base
        assertThatThrownBy(() -> entregar(d3, guia, MENSAJERO_7, "otro"))
                .isInstanceOfSatisfying(ReglaNegocioException.class, e -> assertThat(e.codigo()).isEqualTo("RN07"));
        enUnidad(Rol.MENSAJERO, "andrea.salazar", uow -> {
            DespachoMapper despachos = new DespachoMapper(uow);
            List<AsignacionDespacho> intentos = new ArrayList<>();
            Envio envio = cargarParaEntrega(uow, d3, guia, intentos);
            assertThat(intentos).hasSize(3);
            AsignacionDespacho tercero = ultimoIntento(intentos);
            assertThat(tercero.numeroIntento()).isEqualTo(3);
            despachos.bloquearAsignacion(tercero.idAsignacion());
            LocalDateTime ahora = LocalDateTime.now();
            tercero.registrarDevolucion(new PruebaEntrega(null, ahora, "Remitente", "REM-001", TipoPrueba.DOCUMENTO, null));
            despachos.guardarResultado(tercero);
            new EnvioMapper(uow).agregarEvento(guia, envio.registrarEvento(EstadoEnvio.DEVUELTO, MENSAJERO_7, "Devuelto al remitente", ahora));
            return null;
        });
        assertThat(recorrido(guia, CLIENTE_1)).containsExactly("REGISTRADO", "RECOLECTADO", "EN_CENTRO", "CLASIFICADO", "EN_RUTA",
                "CON_NOVEDAD", "EN_RUTA", "CON_NOVEDAD", "EN_RUTA", "DEVUELTO");

        // transicion no permitida (ENTREGADO despues de DEVUELTO): primero el dominio, sin tocar la base...
        ReglaNegocioException delDominio = enUnidad(Rol.CENTRO, "diego.ramirez", uow -> {
            EnvioMapper envios = new EnvioMapper(uow);
            Envio envio = envios.buscarPorGuia(guia).orElseThrow();
            assertThat(envio.estadoActual()).isEqualTo(EstadoEnvio.DEVUELTO);
            int eventosAntes = envio.historial().size();
            ReglaNegocioException e = catchRegla(() -> envio.registrarEvento(EstadoEnvio.ENTREGADO, AUXILIAR, "no", LocalDateTime.now()));
            assertThat(envio.historial()).hasSize(eventosAntes);
            return e;
        });
        assertThat(delDominio.codigo()).isEqualTo("RN12");

        // ...y despues la base, saltandose el dominio (llamando al mapeador directamente)
        try (UnidadDeTrabajo uow = new UnidadDeTrabajo(fabrica)) {
            uow.iniciar(Rol.CENTRO, "diego.ramirez");
            EventoEnvio ilegal = new EventoEnvio(null, EstadoEnvio.ENTREGADO, AUXILIAR, LocalDateTime.now().plusMinutes(5), "salto del dominio");
            ReglaNegocioException delaBase = catchRegla(() -> new EnvioMapper(uow).agregarEvento(guia, ilegal));
            assertThat(delaBase.codigo()).isEqualTo("RN12");
            assertThat(delaBase.codigoOracle()).isEqualTo(20012).isEqualTo(delDominio.codigoOracle());
            assertThat(delaBase.getMessage()).isNotBlank().doesNotContain("ORA-");
        }
        // la transaccion rechazada no dejo nada
        assertThat(recorrido(guia, CLIENTE_1)).hasSize(10);

        // un cuarto intento tampoco existe (RN07) y no toca la base
        enUnidad(Rol.CENTRO, "diego.ramirez", uow -> {
            Envio envio = new EnvioMapper(uow).buscarPorGuia(guia).orElseThrow();
            envio.cargarIntentos(new DespachoMapper(uow).asignacionesDeGuia(guia));
            assertThat(envio.intentosRealizados()).isEqualTo(3);
            Mensajero m = new ReferenciaMapper(uow).mensajero(MENSAJERO_7).orElseThrow();
            Vehiculo v = new DespachoMapper(uow).vehiculosDisponibles(MENSAJERO_7).get(0);
            Despacho despacho = Despacho.armar(1, v, m, LocalDate.now(), TipoDespacho.ENTREGA);
            assertThat(catchRegla(() -> despacho.asignar(envio)).codigo()).isEqualTo("RN07");
            return null;
        });
    }

    private static ReglaNegocioException catchRegla(Runnable accion) {
        try {
            accion.run();
        } catch (ReglaNegocioException e) {
            return e;
        }
        throw new AssertionError("Se esperaba una ReglaNegocioException");
    }
}
