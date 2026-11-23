# Decisiones del proyecto final - BD_ENLACE_EXPRESS

Proyecto final de Fundamentos de Bases de Datos (Universidad Distrital).
Documento: "Diseño e implementación de una base de datos relacional para una
empresa de mensajería y paquetería urbana" - Enlace Express S.A.S.
Autor: Ferney Eduardo Ballesta Avila (20231020141).

Estado: capítulos 1 a 6 terminados según la plantilla del curso, salvo la
sección 6.3 (prototipo funcional), que solo tiene definida su arquitectura
(6.3.1). La versión final del documento es el "Avance 14" (117 páginas).
Las decisiones del prototipo quedaron cerradas (secciones 12 y 13).
Entrega: lunes 23 de noviembre de 2026, 8:00 p. m.

## Archivos de este proyecto

| Ruta | Contenido |
|---|---|
| `proyecto-final/decisiones.md` | Este archivo: decisiones, cifras clave y pendientes |
| `proyecto-final/latex/main.tex` | Documento LaTeX principal (preámbulo, orden de capítulos y anexos) |
| `proyecto-final/latex/01..06-*.tex` | Capítulos 1 a 6 (contenido completo del documento) |
| `proyecto-final/latex/A..E-*.tex` | Anexos A a E |
| `proyecto-final/diagramas/*.puml` | Diagramas UML en PlantUML (casos de uso, componentes, clases del dominio, mapeadores) |
| `proyecto-final/scripts/ddl_datamodeler_modulo_envios.sql` | DDL del módulo exportado de Data Modeler (2026-11-21); ver sección 14 |

El PDF final y las imágenes PNG de los diagramas no se pueden guardar como
documentos de texto del proyecto; se suben aparte como archivos.

## 1. Alcance: un solo módulo

- El análisis (capítulo 2) dio cuatro módulos: M1 Operación de envíos,
  M2 Comercial y facturación, M3 Flota, M4 Talento humano.
- Por tiempo se desarrolla a fondo solo uno. Los otros quedan analizados en
  los anexos (A, B y C) para integrarse después.
- Se eligió **M1 Operación de envíos** con una matriz de 7 criterios (1 a 3
  puntos cada uno): relación con la misión, volumen de datos, problemas que
  resuelve, aporte a las metas, número de usuarios, necesidad desde el primer
  día, módulos que dependen de él. Resultado: M1 = 21, M2 = 14, M3 = 8, M4 = 8.
- Argumento central: sin M1 la empresa no puede recibir ni entregar envíos;
  M2 depende de M1 para facturar. Orden siguiente: M2, luego M3 y M4.
- Límites del módulo: 12 entidades propias, 7 de referencia (cliente, sede,
  modalidad, tipo de vehículo, vehículo, empleado, mensajero) mantenidas por
  otros módulos, 9 fuera del módulo.
- Datos de referencia: mientras se integran M2 a M4, los carga y actualiza el
  administrador de la base de datos, a solicitud de las áreas dueñas.

## 2. Usuarios del módulo

| Código | Usuario | Papel en el módulo |
|---|---|---|
| U1 | Gerente | Consulta indicadores |
| U2 | Personal del centro de distribución | Registra (recepción, clasificación, despachos) |
| U3 | Mesa de servicio | Registra (solicitudes, envíos, novedades, reclamaciones) |
| U4 | Mensajero | Registra (recolección, entrega, novedad, devolución) |
| U9 | Cliente | Consulta seguimiento por guía |

## 3. Diseño conceptual (capítulo 3)

- Notación del curso (diapositivas): rectángulos para entidades, rombos para
  relaciones, cardinalidad 1:1, 1:N, N:M. El documento usa además la pareja
  (mín,máx); la tabla de relaciones tiene una columna "Tipo" con 1:1/1:N/N:M.
- Prediseño del módulo (figura 7): 14 entidades, 20 relaciones (Chen, draw.io).
- Seis ajustes justificados; los principales: destinatario como entidad
  propia; la relación N:M "se asigna" (envío-despacho) pasa a la entidad
  ASIGNACION_DESPACHO (con número de intento, para controlar intentos);
  mensajero como especialización parcial de empleado; catálogo de estados;
  catálogo de tipos de vehículo; relación "conduce".
- Modelo final: 19 entidades, 26 relaciones + especialización (figura 8, en
  Data Modeler). En Data Modeler aparecen 27 relaciones porque la
  especialización se dibuja como relación 1:1 identificadora.
- Se eliminó la antigua sección 3.6 (herramienta CASE); la figura 8 va justo
  después de la figura 7.

## 4. Diseño lógico (capítulo 4)

- Conversión con las 3 reglas del curso (entidad -> tabla, 1:N -> clave
  foránea, N:M -> tabla intermedia) más 1:1 -> clave foránea única y
  especialización -> tabla con la misma clave.
- Cifras: 19 tablas, 130 columnas, 110 NOT NULL, 19 PK, 13 UNIQUE, 27 FK,
  33 CHECK, 12 DEFAULT. 16 reglas de negocio (RN01-RN16).
- Decisión clave de optimización: el estado actual del envío no se guarda en
  ENVIO; se obtiene del último evento (evita datos que se contradigan).
- Normalización desde una relación "GUÍA" sin normalizar hasta FNBC.
- 7 vistas de usuario: v_seguimiento_envio, v_estado_actual_envio,
  v_planilla_despacho, v_envios_por_despachar, v_novedades_abiertas,
  v_reclamaciones_pendientes, v_cumplimiento_entregas.
- Diccionario de datos completo (130 columnas), verificado contra el reporte
  de Data Modeler (anexo D).

## 5. Diseño físico (capítulo 5)

- Motor: **Oracle** (Oracle AI Database Free en la primera fase; Standard
  Edition 2 si se superan sus límites). Razones: el modelo se hizo en Data
  Modeler; Oracle aplica todas las restricciones y permite disparadores; el
  syllabus lista Oracle 23c o superior.
- Límites de la edición gratuita: 2 núcleos, 2 GB de memoria, 12 GB de datos.
- Supuesto de volumen (declarado en el documento, no es dato de la empresa):
  900 envíos por día hábil (25 mensajeros x 36 visitas), 300 días hábiles al
  año, crecimiento del 25 % anual. Resultado: ~0,7 GB el primer año y
  ~2,7 GB a los tres años, incluidos índices.
- 59 índices: 32 automáticos (PK y UNIQUE), 22 sobre claves foráneas, 5
  adicionales (entre ellos uno único sobre evento_envio(numero_guia,
  fecha_hora), que resuelve el estado actual).
- Ciclo de vida del envío (transiciones permitidas): REGISTRADO ->
  RECOLECTADO -> EN_CENTRO -> CLASIFICADO -> EN_RUTA -> ENTREGADO /
  CON_NOVEDAD / DEVUELTO; CON_NOVEDAD -> EN_RUTA; ANULADO solo antes de
  EN_RUTA; DEVUELTO solo en el tercer intento. Estados finales: ENTREGADO,
  DEVUELTO, ANULADO.
- 6 disparadores + 1 procedimiento de registro del envío (genera la guía
  "EE" + 13 dígitos, inserta envío y evento REGISTRADO, crea el destinatario
  si no existe). Reglas cubiertas: RN05, RN06, RN07, RN10, RN11, RN12, RN15.
- 5 roles (rol_gerencia, rol_centro, rol_mesa, rol_mensajero, rol_cliente),
  ninguno puede borrar (RN16). Esquema propietario BD_ENLACE_EXPRESS.
- 2 espacios de tablas: TS_ENLACE_DATOS y TS_ENLACE_INDICES.
- Almacenamiento y procesamiento centralizados; tres niveles físicos
  (clientes, servidor de aplicaciones, servidor de base de datos).
- El servidor de aplicaciones es una aplicación propia con acceso por JDBC
  (no ORDS; ver sección 7 de este archivo).

## 6. Desarrollo (capítulo 6)

- 6.1: 10 consultas (C1-C10) en álgebra relacional y SQL estándar (válido en
  MySQL y Oracle). Notación del texto guía del syllabus (Silberschatz, Korth y
  Sudarshan): sigma, Pi mayúscula, reunión natural y theta, unión, diferencia,
  división, agregación con G caligráfica, renombre rho, asignación. Las
  expresiones se escriben por pasos; donde dos relaciones comparten un
  atributo que no es la clave foránea (nombre, estado, id_zona) se renombra o
  se proyecta antes de reunir.
- 6.2: especificación sin resultados: tablas (tipo y quién registra),
  relaciones (comportamiento al insertar/modificar/borrar), catálogo de
  consultas, 12 transacciones (todo o nada) y diseño de 7 informes.
- Decisión: **no se muestran resultados de consultas en 6.2**; los resultados
  se producen con el prototipo (6.3).
- 6.3.1: arquitectura del prototipo definida; el resto de 6.3 está pendiente.

## 7. Arquitectura del prototipo

Cuatro capas lógicas, cada una usa solo la de abajo:

1. **Presentación**: app web de operación (U2), app web de mesa (U3),
   tablero de indicadores (U1), app móvil del mensajero (U4, funciona sin
   conexión), portal de seguimiento (U9), consola de administración.
2. **Casos de uso**: servicios de recolección, centro, ruta, servicio al
   cliente, indicadores y administración, más seguridad (autenticación y
   roles). Abren y cierran la transacción.
3. **Modelo de dominio**: agregados Envío y Despacho, solicitud y
   reclamación, datos de referencia, reglas (RN01-RN16, ciclo de vida).
   Define las interfaces de repositorio.
4. **Datos**: mapeadores JDBC que implementan los repositorios y la base de
   datos Oracle.

Reglas de negocio en dos niveles: el dominio las valida primero (mensaje claro
al usuario) y la base de datos (restricciones y disparadores) es la garantía
final.

**Se descartó ORDS** (Oracle REST Data Services) como capa de servicios porque
las aplicaciones hablarían directamente con la base de datos y se saltarían
las capas de casos de uso y dominio. Problemas: transacciones incompletas
(varias llamadas REST sueltas), reglas repetidas en cada aplicación,
aplicaciones atadas a la estructura de las tablas, control de acceso por tabla
y no por caso de uso, mayor superficie expuesta. ORDS podría usarse más
adelante solo para consultas de lectura.

## 8. Diagramas UML (carpeta diagramas)

- **Casos de uso**: 6 actores (U1, U2, U3, U4, U9, administrador), 28 casos de
  uso en 6 grupos. Include: registrar envío -> generar número de guía; armar
  despacho -> asignar envíos y validar vehículo y mensajero; registrar entrega
  y registrar devolución -> registrar prueba de entrega. Extend: registrar
  destinatario -> registrar envío (si es nuevo). "Iniciar sesión" va como
  nota, no como caso de uso.
- **Componentes**: las cuatro capas, API REST (JSON sobre HTTPS), servicios,
  agregados, interfaces de repositorio, repositorios JDBC, consultas e
  informes, conexión y transacciones, Oracle, almacenamiento de archivos
  (fotos y firmas).
- **Clases del dominio**: 19 clases con estereotipo «Persistente» (una por
  tabla), sin claves foráneas como atributos (se usan asociaciones).
  Composición: Envío-eventos, Despacho-asignaciones, Asignación-prueba y
  novedad, Cliente-sedes. Herencia Empleado <- Mensajero. 16 enumeraciones
  (valores CHECK, no son tablas) y el servicio de dominio CicloDeVidaEnvio.
- **Mapeadores**: patrón Data Mapper **sin ORM**: cada método ejecuta una
  sentencia SQL fija (constante) con PreparedStatement y variables de enlace.
  10 mapeadores heredan de MapeadorJdbc. Infraestructura: UnidadDeTrabajo
  (una conexión por transacción, autocommit desactivado, abierta con el rol
  del usuario), FabricaConexiones (una cuenta de servicio por rol),
  TraductorErroresOracle, ConversorTipos. Detalles Oracle: claves de
  identidad con getGeneratedKeys indicando el nombre de la columna;
  procedimiento de registro con CallableStatement; errores ORA-00001,
  ORA-02290, ORA-02291, ORA-02292 y ORA-20000 a ORA-20999 (disparadores).
  Los informes devuelven filas (DTO), no entidades.

## 9. Herramienta CASE (Oracle SQL Developer Data Modeler)

- En el cuerpo del documento van los diagramas de Data Modeler (notación
  Barker); las versiones en Chen hechas en draw.io van en el anexo E.
- Diagramas del cuerpo que solo existen en Chen: vistas recortadas M_U2 y
  M_U3, y el prediseño del módulo (figura 7). Opcional: crear en Data Modeler
  una subvista del prediseño global con las 14 entidades del módulo.
- Las 7 vistas se quitaron de los diagramas de Data Modeler (aparecían como
  cajas sueltas porque no tienen claves foráneas).
- Al importar DDL, Data Modeler a veces crea tablas duplicadas con sufijo
  "v1"/"v2": las buenas son las que no tienen sufijo (tienen los
  comentarios); se borran las copias antes de generar reportes.

## 10. Reglas de redacción del documento

- Sin emojis.
- No mencionar que los diagramas o modelos se generaron a partir de scripts;
  decir que se construyeron en Data Modeler.
- No incluir código SQL salvo donde es explícitamente necesario (capítulo 6,
  consultas). Los tipos de Oracle y los nombres de restricciones sí van.
- Fuera del capítulo 6 no hay listados de código.
- Excepción en la sección 6.3 (aprobada el 2026-11-19): ahí los scripts son
  la implementación, así que se permiten extractos cortos de código y
  nombrar los archivos. Los diagramas del modelo se siguen presentando como
  construidos en Data Modeler.

## 11. Pendientes

- **Entrega final: lunes 23 de noviembre de 2026, 8:00 p. m.** Plan de
  trabajo y prioridades en la sección 13.
- **Sección 6.3 (prototipo)**: decisiones cerradas (secciones 12 y 13) y
  estructura de carpetas definida (12.8). Falta toda la implementación.
  El DDL ya se exportó de Data Modeler (2026-11-21) y cuadra con el
  documento; lo que le falta está en la sección 14. La implementación la
  hacen dos agentes de Claude Code (sección 14.3). Los esqueletos con código
  que se generaron antes del cierre de decisiones quedan descartados.
- **Cambios al documento (decisiones A1 y A2)**: corregir en el capítulo 3
  ("Alcances") la frase que dice que no se desarrollan aplicaciones, y en el
  capítulo 5 el párrafo que dice que cada usuario interno tiene una cuenta
  propia de base de datos.
- Crear `docs/extensiones.md` y, en el documento, un apartado de
  extensiones dentro de la 6.3.
- Los diagramas UML aún no están incluidos en el documento (se incluirán en
  6.3 cuando se desarrolle).
- Opcional: subvista del prediseño del módulo en Data Modeler.

## 12. Prototipo: decisiones de implementación (cerradas el 2026-11-18)

Fase de decisiones cerrada. Estas decisiones concretan cómo se construye la
sección 6.3. Los únicos cambios a capítulos anteriores son A1 (capítulo 3)
y A2 (capítulo 5), de la sección 13.

### 12.1 Base de datos
- **Oracle Database 23c**, edición Free. Es la línea de versiones 23.x que
  Oracle renombró a 23ai (2024) y luego a Oracle AI Database 26ai (2025);
  coincide con el capítulo 5 y con el syllabus. Se descartan MySQL y
  PostgreSQL. PDB de trabajo `FREEPDB1`.
- Esquema propietario `BD_ENLACE_EXPRESS`, 5 roles sin DELETE y 2 espacios
  de tablas, según el capítulo 5.
- Una cuenta de servicio por rol (svc_gerencia, svc_centro, svc_mesa,
  svc_mensajero, svc_cliente). La aplicación fija
  `CURRENT_SCHEMA = BD_ENLACE_EXPRESS` al conectarse, para que el SQL sea
  el mismo de la 6.1.
- Códigos de error de los disparadores: -20000 menos el número de la regla
  (RN02 -20002, RN05 -20005, RN06 -20006, RN07 -20007, RN08 -20008,
  RN10 -20010, RN11 -20011, RN12 -20012, RN15 -20015), en el paquete
  `pkg_errores`.
- Se mantiene CHAR(1) con CHECK para los indicadores sí/no (no el tipo
  BOOLEAN de 23c), porque así está en el diccionario de datos.
- Scripts numerados en dos fases: administración como SYSTEM (espacios de
  tablas, esquema, roles, cuentas) y objetos como propietario (DDL, PL/SQL,
  permisos, datos). Contraseñas como variables de sustitución y en `.env`,
  nunca en los scripts.

### 12.2 Backend
- Java 21, Maven, **Spring Boot 4.1 sin JPA ni Spring Data**. Spring Boot
  se usa para la API REST, la configuración y la seguridad.
- Cuatro capas del capítulo 6.3.1; acceso a datos con mapeadores JDBC
  (Data Mapper, SQL fijo con PreparedStatement), según el diagrama de
  mapeadores.
- **Transacciones con `UnidadDeTrabajo` propia**, no con @Transactional de
  Spring: una conexión por transacción, abierta con la cuenta de servicio
  del rol del usuario; una fuente de conexiones por rol
  (`FabricaConexiones`).
- **Autenticación con Spring Security y sesión en el servidor** (cookie),
  contraseñas con BCrypt y protección CSRF. Se descarta JWT porque el
  frontend se sirve desde el mismo servidor, la sesión permite cerrar o
  desactivar cuentas de inmediato y el rol de la sesión elige la cuenta de
  servicio de Oracle (usuario -> rol de la aplicación -> cuenta de
  servicio -> rol de la base de datos).

### 12.3 Acceso de usuarios (ajustado por D1 y D2 el 2026-11-19)
- **Rastreo público**: cualquier persona consulta un envío con el número de
  guía, sin cuenta. Muestra solo estados, fechas y zona: sin nombres,
  direcciones ni teléfonos. Límite de consultas por dirección IP, porque
  las guías son consecutivas y se pueden recorrer.
- **Registro con código de activación**: el administrador genera un código
  de un solo uso y con vencimiento para cada empleado y para cada empresa
  cliente. Validar solo con la cédula o el NIT no basta (son datos que
  otros conocen).
- **Clientes (U9)**: se registran con el NIT y el código de su empresa;
  solo ven los envíos de su empresa.
- **Empleados (U1 a U4)**: se registran con su número de documento (debe
  existir en EMPLEADO y estar activo) y su código. No eligen el rol: se
  deriva de su cargo y, para el mensajero, de que exista en MENSAJERO.
- **Usuarios de demostración** precargados, uno por rol (decisión B4).

### 12.4 Frontend (ajustado por B3, F1 y F2 el 2026-11-19)
- HTML, CSS y TypeScript. **Vite** como herramienta de compilación: servidor
  de desarrollo con recarga y reenvío de la API a Spring Boot; para
  producción genera HTML, CSS y JS planos en
  `backend/src/main/resources/static/`.
- Spring Boot sirve el frontend desde el mismo servidor (mismo origen, sin
  CORS).
- **Una sola aplicación web con menú según el rol**, en lugar de cinco
  aplicaciones separadas. Las aplicaciones del documento son secciones:
  operación (U2), mesa (U3), mensajero (U4, adaptable al teléfono, sin modo
  sin conexión), tablero (U1) y seguimiento (U9). Parte pública aparte:
  inicio de sesión, registro y rastreo por guía.
- Estilos base con **Pico CSS**; gráficos del tablero con **Chart.js**.

### 12.5 Alcance y extensiones
- El prototipo es el **módulo M1 funcionando**.
- Se permite extender fuera del módulo solo para probar un caso de uso
  completo o hacer una prueba real del sistema, limitada al módulo.
- Cada extensión se registra en `docs/extensiones.md` (qué agrega, qué caso
  de uso permite probar, por qué no está en el módulo), va en una carpeta
  de scripts aparte para que las 19 tablas del módulo sigan
  identificables, y tendrá un apartado propio en la 6.3 del documento.
- **E1. Usuarios de la aplicación**: tabla con cuenta, hash de contraseña,
  rol y vínculo con EMPLEADO o CLIENTE, más los códigos de activación (un
  solo uso, con vencimiento). Motivo: sin ella no se puede probar ningún
  caso de uso con inicio de sesión; el módulo no tiene credenciales.
- Posibles, no decididas: almacenamiento local de fotos y firmas de las
  pruebas de entrega. Una consola de administración de datos de referencia
  no hace falta (el administrador los carga con scripts, como dice el
  documento).

### 12.6 Entorno, CI/CD y despliegue
- Repositorio único en **GitHub**: `docs/`, `db/`, `backend/`, `frontend/`.
- **Docker** para Oracle en desarrollo (imagen `gvenzl/oracle-free:23-slim`,
  multiarquitectura) con docker compose. Razones: instalación aislada,
  reinicio limpio de la base, mismo entorno en cualquier equipo, base para
  CI.
- **CI con GitHub Actions**: en cada cambio compila el backend y el
  frontend, instala el esquema en un Oracle de contenedor y corre las
  pruebas.
- **Despliegue: máquina virtual gratuita de Oracle Cloud (Always Free,
  Ampere A1, ARM)**, con el mismo docker compose (Oracle 23c Free + Spring
  Boot). Límite gratuito desde junio de 2026: 2 OCPU y 12 GB en total.
  Requiere tarjeta para verificación (el autor la tiene); las cuentas
  inactivas más de 30 días pueden ser suspendidas.
- **CD con GitHub Actions**: si la rama principal pasa la CI, se actualizan
  los contenedores en la máquina virtual.
- HTTPS con un proxy inverso que obtiene el certificado automáticamente
  (por ejemplo Caddy) y un nombre de dominio o subdominio gratuito; se
  define al desplegar.
- **Respaldo**: si no se consigue la máquina virtual, presentar desde el
  equipo propio con Docker y Cloudflare Tunnel (HTTPS gratuito, sin CD).
- Descartados: Vercel (no aloja Oracle y su modelo de funciones no encaja
  con la sesión en el servidor), Render gratuito (512 MB, se apaga tras 15
  minutos sin tráfico, sin Oracle) y Autonomous Database gratuita (no
  permite crear espacios de tablas, contradice el capítulo 5).

### 12.7 Orden de trabajo
Reemplazado por el plan por niveles y días de la sección 13.

### 12.8 Estructura del repositorio `enlace-express`

Cada carpeta hoja lleva un `.gitkeep` (55 en total, tras agregar
`db/09_verificacion/` y reorganizar `frontend/src/` el 2026-11-19). El autor crea la
estructura con comandos bash y hace él mismo los commits (con su identidad
de GitHub). Primer commit: "chore: estructura inicial de carpetas".
Desde el 2026-11-21 el repositorio se llama `ImplementacionProyectoDB` y
los commits los hace el agente orquestador (sección 14.3).

```
enlace-express/
├── .github/workflows/          CI y CD (GitHub Actions)
├── backend/src/
│   ├── main/java/co/enlaceexpress/
│   │   ├── configuracion/      Spring (seguridad, fuentes de conexión por rol)
│   │   ├── presentacion/api/   API REST
│   │   ├── casosdeuso/         administracion, centro, indicadores,
│   │   │                       recoleccion, ruta, seguridad, servicioalcliente
│   │   ├── dominio/            despacho, enums, envio, reclamacion,
│   │   │                       referencia, reglas, repositorios, solicitud
│   │   └── datos/              informes, infraestructura, mapeadores
│   ├── main/resources/
│   └── test/java/co/enlaceexpress/{datos,dominio}, test/resources/
├── db/
│   ├── 00_admin/               como SYSTEM: espacios de tablas, esquema,
│   │                           roles, cuentas de servicio
│   ├── 01_ddl/                 tablas, FK, índices, vistas, comentarios
│   ├── 02_plsql/               pkg_errores, procedimiento, 6 disparadores
│   ├── 03_permisos/
│   ├── 04_datos/               catálogos, referencia, operación de prueba
│   ├── 05_consultas/           C1 a C10
│   ├── 06_transacciones/       T01 a T12 (casos válidos y que fallan)
│   ├── 07_informes/            I01 a I07
│   ├── 08_extensiones/         objetos fuera del módulo (E1, ...)
│   └── 09_verificacion/        comprobación de cifras contra el documento
├── despliegue/                 compose y proxy para Oracle Cloud
├── docs/{datamodeler,diagramas,evidencias,latex}/
├── frontend/src/
│   ├── comun/                  diseño, cliente de la API, sesión
│   ├── publico/                inicio de sesión, registro, rastreo por guía
│   └── secciones/{operacion,mesa,mensajero,tablero,seguimiento}/
├── .gitattributes
└── .gitignore
```

- `frontend/src/publico/`: inicio de sesión, registro y rastreo público.
- `frontend/src/secciones/`: una sección por grupo de usuarios dentro de la
  única aplicación web.
- La salida compilada del frontend va a `backend/src/main/resources/static/`
  y no se versiona.
- `.gitignore`: `.env` (se versiona `.env.example`), `backend/target/`,
  `node_modules/`, salida del frontend, `*.dmp`, `*.log`, auxiliares de
  LaTeX, carpetas de editores y archivos del sistema operativo.
- `.gitattributes`: texto en LF (`* text=auto eol=lf`), `.bat/.cmd/.ps1`
  en CRLF, imágenes, PDF, JAR, ZIP y DMP como binarios, `docs/**` como
  documentación para las estadísticas de GitHub.
- Pendiente de crear al programar: `docker-compose.yml`, `.env.example`,
  `README.md`, `docs/decisiones.md` (copia de este archivo) y
  `docs/extensiones.md`.

### 12.9 Entorno de desarrollo del autor
- Equipo principal con **Arch Linux**: los comandos se dan en bash; no
  aplican instrucciones de Windows.
- Paquetes: `git jdk21-openjdk maven nodejs npm docker docker-compose
  docker-buildx` (pacman). Arch puede tener un JDK más nuevo como
  predeterminado: fijar Java 21 con `archlinux-java set java-21-openjdk`.
- Docker nativo (sin WSL2), servicio activo con systemd y usuario en el
  grupo `docker` (equivale a permisos de root; alternativa: Podman sin
  root, compatible con la imagen de Oracle).
- SQL Developer, Data Modeler y SQLcl: zip de Oracle o AUR.

## 13. Revisión final antes de programar (aprobada el 2026-11-19)

Todas las propuestas de la revisión fueron aprobadas. Las que ajustan
decisiones anteriores ya están reflejadas en la sección 12 (12.3, 12.4,
12.5, 12.8) y en la regla de redacción de la sección 10.

### 13.1 Decisiones aprobadas

**A. Contradicciones con el documento**
- A1. Corregir el capítulo 3 ("Alcances"): el prototipo incluye una
  aplicación web mínima que demuestra los casos de uso del módulo; las
  aplicaciones completas (móvil sin conexión, etc.) quedan fuera. Apoyo en
  el syllabus: integrar la base de datos a una aplicación con ODBC/JDBC y
  diseñar una aplicación soportada en un motor relacional.
- A2. Corregir el capítulo 5: cuentas de servicio por rol (no una cuenta de
  base de datos por usuario) y cada conexión fija el identificador de
  cliente de la sesión con el usuario real, para que Oracle sepa quién hizo
  cada operación.

**B. Alcance y estrategia**
- B1. Entrega por niveles, cada uno completo por sí mismo:
  - Nivel 1 (obligatorio): base de datos completa, datos de prueba y
    resultados de C1-C10, de las 12 transacciones y de los 7 informes, con
    capturas.
  - Nivel 2: aplicación con el flujo principal de punta a punta.
  - Nivel 3: resto de casos de uso, CI/CD y despliegue en Oracle Cloud.
- B2. Flujo principal primero: registrar envío -> recolectar -> recibir y
  clasificar -> armar despacho -> entregar con prueba -> seguimiento
  público. Luego un caso de rechazo: devolución en el tercer intento y una
  transición no permitida bloqueada por el disparador.
- B3. Una sola aplicación web con menú por rol (ver 12.4).
- B4. Usuarios de demostración (uno por rol) y un script que deja la base
  en el estado de la demostración.

**C. Base de datos**
- C1. Generar el DDL desde Data Modeler (tiene las 19 tablas, restricciones
  y comentarios verificados contra el anexo D) y ordenarlo en los scripts
  numerados, en lugar de escribirlo a mano.
- C2. Script de verificación en `db/09_verificacion/`: comprueba contra el
  catálogo de Oracle 19 tablas, 130 columnas, 110 NOT NULL, 19 PK,
  13 UNIQUE, 27 FK, 33 CHECK, 12 DEFAULT y 59 índices. Evidencia para la
  6.3 y paso de la CI.
- C3. Disparadores compuestos (compound triggers) para ASIGNACION_DESPACHO
  y EVENTO_ENVIO, que consultan su propia tabla: evitan el error de tabla
  mutante (ORA-04091).
- C4. Bloqueo pesimista: toda transacción que cambia el estado de un envío
  o un despacho bloquea primero esa fila con SELECT ... FOR UPDATE.
  Material para la 6.3 (concurrencia).
- C5. TIMESTAMP con microsegundos y horas distintas asignadas por la
  aplicación cuando una transacción inserta varios eventos del mismo envío
  (índice único numero_guia, fecha_hora).
- C6. Zona horaria America/Bogota en el contenedor de Oracle, la JVM y la
  máquina de despliegue.
- C7. Dos conjuntos de datos: uno pequeño y fijo para las pruebas, y uno de
  volumen generado con PL/SQL para los informes y para mostrar con
  EXPLAIN PLAN el uso de los índices del capítulo 5.

**D. Seguridad**
- D1. Códigos de activación de un solo uso y con vencimiento (ver 12.3).
- D2. Rastreo público sin datos personales y con límite de consultas por IP.

**E. Backend**
- E1. Errores de la API en formato Problem Details (incluido en Spring) con
  el código de la regla incumplida (por ejemplo RN07).
- E2. Pruebas de integración con Testcontainers y la misma imagen de Oracle
  23c, en el equipo y en la CI.
- E3. Documentación de la API con OpenAPI y Swagger UI, si la librería es
  compatible con Spring Boot 4.1 (verificar al empezar).
- Se mantienen Java 21 (el controlador JDBC está certificado hasta 21) y la
  UnidadDeTrabajo propia.

**F. Frontend**
- F1. Vite (ver 12.4).
- F2. Pico CSS y Chart.js (ver 12.4).

**G. Despliegue**
- G1. Imágenes construidas en GitHub Actions para x86 y ARM y publicadas en
  GitHub Container Registry; la máquina de Oracle Cloud solo descarga y
  reinicia.
- G2. El esquema se instala una vez; el CD actualiza solo la aplicación.
  Cambios de esquema: reinstalar con el script.
- G3. Subdominio gratuito con DuckDNS y HTTPS con Caddy.

**H. Documento**
- H1. Estructura de la 6.3: 6.3.1 arquitectura (existe), implementación de
  la base de datos y verificación de cifras, datos de prueba, resultados de
  C1-C10, transacciones y reglas (aceptadas y rechazadas), informes,
  aplicación (flujo principal y diagramas UML), extensiones, concurrencia,
  despliegue y CI/CD.
- H2. Regla de redacción ajustada para la 6.3 (ver sección 10).

### 13.2 Plan hasta la entrega (lunes 23 de noviembre, 8:00 p. m.)

Con cuatro días, el compromiso es terminar los niveles 1 y 2. El nivel 3
queda como opcional y puede seguir después si la presentación es posterior
a la entrega.

| Día | Trabajo | Resultado |
|---|---|---|
| Jue 19 | Oracle en Docker (C6); DDL desde Data Modeler en `00_admin` y `01_ddl` (C1); verificación de cifras (C2) | Esquema creado y cifras comprobadas |
| Vie 20 | `02_plsql` (pkg_errores, procedimiento, disparadores compuestos C3, bloqueos C4, C5); `03_permisos`; datos fijos y de volumen (C7); `05` a `07` con capturas y EXPLAIN PLAN | **Nivel 1 terminado** |
| Sáb 21 | Backend: FabricaConexiones, UnidadDeTrabajo, TraductorErroresOracle, mapeadores del flujo principal, E1 (usuarios y códigos), Spring Security, API del flujo principal con Problem Details | API del flujo principal |
| Dom 22 | Frontend con Vite y Pico: parte pública (login, registro, rastreo D2) y secciones del flujo principal; usuarios y script de demostración (B4); CI básica si alcanza | **Nivel 2 terminado** |
| Lun 23 | Documento: A1, A2 y sección 6.3 según H1 con las evidencias; compilar el PDF; margen para imprevistos. Entregar antes de las 8:00 p. m. | Entrega |

Fuera del compromiso para el lunes (nivel 3, en este orden si sobra
tiempo): CI completa con Testcontainers (E2), OpenAPI (E3), Chart.js en el
tablero, resto de casos de uso, despliegue en Oracle Cloud con GHCR,
DuckDNS y Caddy (G1-G3) y CD. Si hay que mostrar la aplicación en vivo
antes de tener Oracle Cloud: equipo propio con Cloudflare Tunnel.

## 14. DDL de Data Modeler y ejecución con agentes (2026-11-21)

### 14.1 DDL exportado
- Exportado de Data Modeler 24.3 el 2026-11-21 (destino declarado
  "Oracle Database 21c"; es compatible con 23c). Guardado en
  `proyecto-final/scripts/ddl_datamodeler_modulo_envios.sql` y en el
  repositorio en `docs/datamodeler/modulo_envios_datamodeler.ddl`.
- Verificado contra el documento: 19 tablas, 130 columnas, 110 NOT NULL,
  12 DEFAULT, 19 PK, 13 UNIQUE, 27 FK y 33 CHECK. Coincide.

### 14.2 Lo que el DDL no trae y se completa desde el capítulo 5
- Semántica de longitud en caracteres (`NLS_LENGTH_SEMANTICS = CHAR`), como
  dice el capítulo 5.
- Columnas de identidad en las 14 tablas con clave sustituta generada (todas
  menos ENVIO, MENSAJERO, ESTADO_ENVIO, MODALIDAD y TIPO_VEHICULO).
- Cláusulas de espacio de tablas (TS_ENLACE_DATOS para tablas,
  TS_ENLACE_INDICES para índices).
- Los 27 índices que no son de PK ni UNIQUE (22 sobre FK y 5 adicionales).
- Vistas, PL/SQL, roles, permisos y cuentas de servicio.
- Al verificar en el catálogo: excluir los NOT NULL de las restricciones
  CHECK y las columnas de identidad de los DEFAULT.

### 14.3 Implementación con dos agentes de Claude Code
- La implementación la hacen dos agentes en un equipo de Claude Code, en
  un repositorio nuevo llamado **`ImplementacionProyectoDB`** (reemplaza
  el nombre `enlace-express` de la 12.8; la estructura interna es la
  misma):
  - **orquestador**: Opus 5.5 con esfuerzo alto. Ordena, verifica, hace
    los commits y lleva la bitácora.
  - **constructor**: Sonnet 5.5 con esfuerzo alto. Escribe el código,
    los scripts y los textos LaTeX.
- Trabajan sin aprobaciones (modo `auto`) y con libertad total dentro del
  repositorio: archivos, commits en `main`, ramas y push si hay remoto.
  Esto reemplaza la regla de la 12.8 de que el autor hace los commits.
- Prioridades: nivel 1, nivel 2, documento (6.3 completa y párrafos A1 y
  A2 en `docs/documento/`), nivel 3. Desde las 12:00 m. del lunes 23 solo
  se trabaja en el documento si no está terminado.
- Solo se usa el plan de suscripción: sin créditos de uso. Si se alcanza
  el límite, se espera al reinicio; el script `vigilar-limite.sh` pide
  continuar cuando el límite se libera.
- Configuración en el repositorio: `CLAUDE.md`, `.claude/settings.json`,
  `.claude/agents/orquestador.md`, `.claude/agents/constructor.md`,
  `iniciar-equipo.sh` y `vigilar-limite.sh`.
- Registro de su trabajo en `docs/bitacora-agentes.md`; las decisiones que
  tomen sin el autor llevan la etiqueta `PARA FERNEY`.
- Al terminar (2026-11-22) se quitaron del repositorio la configuración de
  los agentes y su bitácora; las decisiones que tomaron sin el autor quedan
  en la sección 15 y la reorganización de carpetas en la sección 16.

## 15. Decisiones tomadas durante la implementación (2026-11-21 y 22)

Durante la implementación con agentes, las decisiones que no estaban
definidas se tomaron con la opción más cercana al documento y se anotaron
para el autor. Se conservan aquí (las rutas ya están con los nombres de la
sección 16). Las más importantes: el plazo de las modalidades cuenta el día
del registro como el primero (MISMO_DIA 1, DIA_SIGUIENTE 2, ESTANDAR 3,
porque el CHECK exige plazo > 0); tres permisos de lectura agregados para
que cada rol pueda ejecutar sus consultas; la parte pública de la
aplicación usa `svc_cliente`; la extensión E2 (vista de rastreo público);
y `v_envios_por_despachar` incluye los envíos CON_NOVEDAD.

**2026-11-21 01:54 - Revisión del entorno**

- **Node.js del sistema roto.** `node -v` falla con `error while loading shared libraries:
libsimdjson.so.36` (el sistema tiene `libsimdjson.so.34`; parece una
actualizacion parcial de Arch). No se instala nada con pacman. Decision:
el frontend se compila con la imagen oficial de Docker `node` (version
LTS fija) montando `frontend/`, mediante un script del repositorio. La
salida sigue yendo a `backend/src/main/resources/static/`. Para
arreglarlo en el equipo: `sudo pacman -Syu` (actualiza simdjson y
nodejs juntos).

**2026-11-21 01:57 - T01 Estructura del repositorio y Oracle en Docker**

- la 12.8 habla de 55 `.gitkeep`; la lista de carpetas del
  árbol de 12.8 da 45 carpetas hoja vacías. Se crearon esas 45.
- con `TZ=America/Bogota` la sesión queda en -05:00, pero
  `DBTIMEZONE` es +00:00 (valor de la imagen). Como las columnas son
  TIMESTAMP y DATE sin zona, no afecta los datos; los scripts y la
  aplicación fijan `TIME_ZONE = 'America/Bogota'` en cada sesión.

**2026-11-21 02:04 - T02 Administración, DDL, índices y verificación de cifras**

- la verificación de cifras corre como SYSTEM (vistas
  `DBA_*` filtradas por el esquema y la lista de las 19 tablas), porque
  los roles solo se ven en `DBA_ROLES`.
- los índices sobre FK se nombran `<nombre de la FK>_IX` y
  los adicionales `DESPACHO_FECHA_IX`, `ENVIO_FECHA_REGISTRO_IX`,
  `EVENTO_GUIA_FECHA_UX` (índice único, no restricción, para no alterar
  las 13 UNIQUE), `NOVEDAD_ESTADO_IX` y `RECLAMACION_ESTADO_IX`; el
  documento no les da nombre.

**2026-11-21 02:07 - T03 Vistas de usuario**

- `v_envios_por_despachar` incluye envíos con estado actual
  CLASIFICADO o CON_NOVEDAD que no están en un despacho de entrega
  abierto (ARMADO o EN_RUTA). El documento dice "clasificados", pero el
  ciclo de vida permite CON_NOVEDAD -> EN_RUTA en un despacho nuevo, y la
  condición "que todavía no están en un despacho de entrega abierto" solo
  tiene sentido para envíos que ya estuvieron en uno.
- "a tiempo" en `v_cumplimiento_entregas` es que el día del
  evento ENTREGADO sea menor o igual a la fecha de compromiso; la zona es
  la de destino del envío y el centro el de esa zona.

**2026-11-21 02:13 - T04 PL/SQL: pkg_errores, procedimiento y 6 disparadores**

- el procedimiento se llama `pr_registrar_envio` y los
  disparadores `trg_solicitud_cliente_activo`,
  `trg_despacho_vehiculo_mensajero`, `trg_asignacion_intento`,
  `trg_asignacion_resultado`, `trg_prueba_documento` y
  `trg_evento_transicion` (el documento no les da nombre).
- además de lo que dice `tab:disparadores`, una asignación
  no puede nacer con resultado ENTREGADO, DEVUELTO o NOVEDAD (RN05 y
  RN08): si no, un INSERT se saltaría el disparador de resultado.
- el disparador de resultado es de fila simple, porque no
  consulta su propia tabla; la decisión C3 se cumple en los dos que sí lo
  hacen (inserción de asignaciones y eventos).

**2026-11-21 02:24 - T05 Permisos, datos fijos y plazo de las modalidades**

- el CHECK `MODALIDAD_PLAZO_CK` exige plazo > 0, así que
  MISMO_DIA no puede tener plazo 0. Se tomó que el día del registro
  cuenta como día 1: MISMO_DIA 1, DIA_SIGUIENTE 2, ESTANDAR 3, días
  hábiles de lunes a sábado (si el registro cae en domingo, el día 1 es
  el lunes). Lo implementa `pkg_calendario.fecha_compromiso`.
- además de los privilegios de `tab:roles`, cada rol tiene
  SELECT sobre las tablas que inserta o actualiza (lo exigen UPDATE con
  WHERE, SELECT ... FOR UPDATE y leer lo guardado), y rol_centro y
  rol_mesa tienen SELECT sobre `v_estado_actual_envio`, porque
  `tab:vistas` la asigna a U2 y U3.
- cargos exactos de los empleados (la extensión E1 deriva
  el rol de ellos): `Gerente`, `Auxiliar de centro`, `Agente de mesa de
  servicio`, `Mensajero`.

**2026-11-21 02:28 - T06 Consultas C1 a C10 con evidencias**

- se agregaron tres privilegios de lectura que exigen las
  consultas del capítulo 6 para el usuario que las usa: `empleado` y
  `asignacion_despacho` a rol_mesa (C2 y C7) y `destinatario` a
  rol_centro (C3). rol_mensajero no recibe `destinatario`: U4 ve la
  planilla por `v_planilla_despacho` (comprobado con un caso de rechazo).
  Permisos: 41 OK, 0 FALLA.

**2026-11-21 02:36 - T07 Transacciones T01 a T12 y concurrencia**

- para llevar el envío C al tercer intento (T08), el
  propietario prepara dos despachos previos (`T08_preparacion.sql`),
  porque el mensajero no arma despachos y los datos fijos no traían un
  envío con dos novedades listo para devolver.
- en T05 el despacho nace EN_RUTA con hora de salida, porque
  la transacción del documento inserta en la misma unidad el evento
  EN_RUTA de cada envío.

**2026-11-21 02:57 - T09 Extensión E1: usuarios de la aplicación y códigos de activación**

- la parte pública de la aplicación (inicio de sesión,
  registro y rastreo) usa la cuenta `svc_cliente`, que recibe EXECUTE
  sobre `pkg_seguridad`; no se creó una sexta cuenta de servicio.
- los códigos se generan con `DBMS_CRYPTO.RANDOMBYTES`. Ese
  paquete no está concedido a PUBLIC en la imagen y SYSTEM no puede
  concederlo, así que `admin/05_privilegios_extensiones.sql` se
  conecta como SYS (misma contraseña de `.env`) solo para ese GRANT. Es
  la única excepción a "administración como SYSTEM" de la 12.1.

**2026-11-21 03:02 - T10 Backend: proyecto e infraestructura JDBC**

- la aplicación lee las contraseñas de las cuentas de
  servicio del `.env` de la raíz (`spring.config.import`) o de variables
  de entorno con los mismos nombres.

**2026-11-21 12:11 - T11 Dominio y mapeadores del flujo principal**

- como rol_mensajero no lee ESTADO_ENVIO ni EMPLEADO, los
  mapeadores del flujo leen los eventos sin esas uniones (el nombre del
  estado sale del catálogo fijo del dominio) y la planilla trae el
  documento del destinatario (RN06) desde `v_planilla_despacho`.

**2026-11-21 12:25 - T12 Seguridad, registro, rastreo público y Problem Details**

- extensión E2, vista de rastreo público (ver
  `docs/extensions.md`). Sin ella D2 no se podía cumplir sin modificar
  una vista del módulo o ampliar permisos de rol_cliente.

**2026-11-21 16:30 - T13 Casos de uso y API REST del flujo principal**

- asignar a un despacho un envío que ya está en otro
  despacho abierto se rechaza con RN07 (el intento anterior sigue
  PENDIENTE), el mismo código que daría el disparador.

**2026-11-21 16:42 - T14 Frontend con Vite, TypeScript y Pico CSS**

- el filtro de centro del tablero tiene los dos centros de
  los datos de prueba fijos, porque la API no expone un listado de
  centros.

**2026-11-21 16:55 - T15 Demostración, usuarios de demostración y prueba de punta a punta (nivel 2 terminado)**

- para volver a despachar un envío con novedad, el despacho
  anterior debe estar CERRADO (`v_envios_por_despachar` excluye los que
  están en un despacho abierto); el guion de la demostración lo cierra
  antes de armar el siguiente.

**2026-11-21 16:58 - T16 Documento: cambios A1 y A2**

- el preámbulo de prueba reconstruye `L{}`, `\pk`, `\fk` y
  el estilo `sqlpro` a partir de su uso en los capítulos; el documento
  real usa el preámbulo de `main.tex`.

**2026-11-21 20:59 - T20 Documento: 6.3.7, 6.3.10, figuras y revisión final (documento terminado)**

- los diagramas de clases son densos; en papel se leen con
  dificultad (en el PDF se pueden ampliar). Si se quieren más legibles
  hay que partirlos en el PlantUML original, que no se tocó.
- el texto de 6.3.7 cita las guías EE0000000000030 y 031 y
  los despachos 27 a 29 de las capturas; si se regeneran las capturas sin
  reinstalar la base, cambian.

## 16. Reorganización del repositorio (2026-11-22)

Al terminar se renombraron carpetas y scripts a nombres en inglés, más
comunes en un repositorio. No cambian los objetos de la base de datos
(tablas, vistas, roles, paquetes), los archivos `.sql` (sus nombres siguen
los códigos del documento: C01, T01, I01...), el código Java ni el
frontend. Las salidas de `docs/evidence/` se conservan tal como se
generaron, así que algunas mencionan las rutas anteriores.

| Antes | Ahora |
|---|---|
| `db/` | `database/` |
| `db/00_admin/` | `database/admin/` |
| `db/01_ddl/` | `database/schema/` |
| `db/02_plsql/` | `database/plsql/` |
| `db/03_permisos/` | `database/grants/` |
| `db/04_datos/ (volumen/)` | `database/seed/ (volume/)` |
| `db/05_consultas/` | `database/queries/` |
| `db/06_transacciones/` | `database/transactions/` |
| `db/07_informes/` | `database/reports/` |
| `db/08_extensiones/` | `database/extensions/` |
| `db/09_verificacion/` | `database/tests/` |
| `db/instalar.sh` | `database/install.sh` |
| `db/ejecutar.sh` | `database/run.sh` |
| `db/generar_evidencias.sh` | `database/generate-evidence.sh` |
| `demostracion/ (preparar.sh, detener.sh)` | `demo/ (start.sh, stop.sh)` |
| `despliegue/` | `deploy/` |
| `docs/evidencias/` | `docs/evidence/` |
| `docs/documento/` | `docs/report/` |
| `docs/latex/` | `docs/reference/` |
| `docs/diagramas/` | `docs/diagrams/` |
| `docs/decisiones.md, docs/extensiones.md` | `docs/decisions.md, docs/extensions.md` |
| `frontend/compilar.sh` | `frontend/build.sh` |
| `LEEME.md` | `README.md` |
| `demostracion/e2e/ejecutar.sh` | `demo/e2e/run.sh` |
| `despliegue/instalar_esquema.sh`, `probar_local.sh` | `deploy/install-schema.sh`, `test-local.sh` |
| `ci/verificar_cifras.sh` | `ci/verify-figures.sh` |

