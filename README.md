# Enlace Express: implementación del módulo M1

Prototipo funcional del módulo M1 (Operación de envíos) de
BD_ENLACE_EXPRESS, correspondiente a la sección 6.3 del proyecto final de
Fundamentos de Bases de Datos (Universidad Distrital). Autor: Ferney Eduardo
Ballesta Avila.

Incluye la base de datos en Oracle 23c Free (DDL, PL/SQL, permisos, datos de
prueba, consultas, transacciones e informes), una aplicación Spring Boot sin
JPA y un frontend en TypeScript con Pico CSS. Las decisiones del proyecto
están en `docs/decisions.md`.

## Requisitos

- Docker con Docker Compose (Oracle corre en un contenedor).
- Java 21 y Maven 3.9 o superior (backend).
- Node.js no es obligatorio: `frontend/build.sh` compila el frontend con la
  imagen Docker oficial de `node`, así que funciona aunque el sistema no
  tenga Node o lo tenga dañado.
- No hace falta tener `sqlplus` instalado: los scripts se ejecutan con el
  `sqlplus` del contenedor.

## Levantar Oracle

```bash
cp .env.example .env      # editar .env y poner contraseñas propias
docker compose up -d
docker compose ps         # esperar a que enlace-oracle esté "healthy"
```

La primera vez se descarga la imagen y se crea la base, lo que puede tardar
varios minutos. Los datos quedan en el volumen `enlace-oracle-datos`. Para
empezar de cero:

```bash
docker compose down -v
```

El contenedor usa la zona horaria `America/Bogota` (`TZ`). La carpeta `./database`
queda montada en solo lectura en `/opt/enlace/database` dentro del contenedor.

Comprobación rápida:

```bash
docker exec enlace-oracle bash -c \
  'echo "select name, open_mode from v\$pdbs;" | sqlplus -s system/"$ORACLE_PASSWORD"@//localhost/FREEPDB1'
```

## Instalar la base de datos

```bash
database/install.sh
```

El script lee `.env`, comprueba que `enlace-oracle` esté healthy y reinstala
la base desde cero cada vez (no hace falta `docker compose down -v`). Usa el
`sqlplus` del contenedor, con `NLS_LANG=.AL32UTF8` para conservar las tildes
de los comentarios, y se detiene ante el primer error. Las contraseñas viajan
por la entrada estándar de `sqlplus` como variables de sustitución; nunca
están escritas en los `.sql`.

Fases:

1. Como SYSTEM, `database/admin/`: limpieza, espacios de tablas
   (`TS_ENLACE_DATOS`, `TS_ENLACE_INDICES`), esquema `BD_ENLACE_EXPRESS`,
   5 roles y 5 cuentas de servicio.
2. Como propietario, en orden alfabético: `database/schema/` (tablas e índices),
   luego `plsql`, `grants` y `seed` a medida que existan. Al
   final se exige que no haya objetos inválidos.
3. Verificación de cifras (`database/tests/verificar_cifras.sql`): una
   fila por cifra del documento con `OK` o `FALLA`. La salida queda en
   `docs/evidence/01_verificacion_cifras.txt`. Con
   `VERIFICACION_ESTRICTA=1` el script termina con error si alguna cifra
   falla.

Para ejecutar un script suelto sin reinstalar (pruebas, consultas):
`database/run.sh propietario tests/prueba_vistas.sql`.

Pruebas con los datos cargados: `database/run.sh propietario tests/02_pruebas_reglas.sql`
(reglas de negocio) y `database/tests/test-grants.sh` (permisos de las 5 cuentas
de servicio). Las salidas quedan en `docs/evidence/`.

Para agregar scripts basta con dejar un `.sql` numerado en la carpeta que
corresponde.

## Frontend

Una sola aplicación en TypeScript con Vite, Pico CSS y Chart.js, con menú por
rol (mesa, centro, mensajero, gerencia, cliente) y rastreo público por guía.
No usa frameworks. El Node del sistema no se usa: se compila con Docker
(`node:22-alpine`) y nada queda como root.

```
frontend/build.sh           # npm ci + tsc + vite build
frontend/build.sh --limpio  # borra node_modules y compila de nuevo
```

La salida va a `backend/src/main/resources/static/` (no se versiona) y Spring
Boot la sirve en `/`; el enrutador es por hash, por eso no hace falta reenviar
rutas desconocidas a `index.html`. El caché de npm queda en `frontend/.npm/`.

Para desarrollar con recarga en caliente, con el backend en el puerto 8080:

```
cd backend && mvn -q spring-boot:run            # API en http://localhost:8080
cd frontend && npm ci && npm run dev            # interfaz en http://localhost:5173 (proxy de /api)
```

(`npm run dev` requiere un Node local funcional; si no lo hay, recompile con
`frontend/build.sh` y recargue `http://localhost:8080/`.)

## Demostración

`demo/start.sh` deja todo listo desde cero (base, frontend, backend en
segundo plano y un usuario por rol); `demo/stop.sh` la detiene. La
contraseña de los usuarios `demo_*` es la variable `DEMO_PASSWORD` de `.env`.
`demo/e2e/run.sh` recorre el flujo en un navegador sin cabeza y guarda
las capturas en `docs/evidence/10_aplicacion/`. Guion y detalles en
`demo/README.md`.

## Documentación de la API

Con la aplicación levantada (`demo/start.sh` o el jar de `backend/`):

- Swagger UI: <http://localhost:8080/swagger-ui.html>
- Documento OpenAPI (JSON): <http://localhost:8080/v3/api-docs>

Se entregan sin sesión (solo lectura). Las rutas están agrupadas por sección, indican el
rol que exigen y describen la sesión por cookie, el token CSRF (`X-XSRF-TOKEN`) y los errores
en formato Problem Details con la propiedad `codigo`. Para probar un `POST` desde Swagger UI,
inicie sesión con `POST /api/sesion` y use el botón Authorize con el valor de la cookie
`XSRF-TOKEN`. La copia del documento y una captura están en `docs/evidence/13_openapi.json`
y `docs/evidence/13_swagger_ui.png` (se regeneran con `demo/e2e/capture-openapi.sh`).

## Pruebas e integración continua

Las pruebas del backend se corren con `mvn -q verify` (carpeta `backend/`): 60
unitarias (`*Test`) y 39 de integración (`*IT`). Las de integración tienen dos
modos:

```
mvn -q verify                              # modo normal: usan el Oracle del compose (docker compose up -d)
ENLACE_TESTCONTAINERS=true mvn -q verify   # modo Testcontainers (también: mvn -q verify -Ptestcontainers)
```

En modo Testcontainers levantan un solo contenedor de Oracle
(`gvenzl/oracle-free:23-slim`) para toda la corrida, instalan el esquema con
`database/install.sh` en modo estricto y generan contraseñas al azar: no necesitan el
compose ni el `.env`. Hace falta Docker. `database/install.sh` acepta
`ENLACE_CONTENEDOR` y `ENLACE_EVIDENCIA` para usar otro contenedor y otro
archivo de evidencia, y toma las contraseñas del entorno si el `.env` no existe.

La integración continua está en `.github/workflows/ci.yml`: en cada `push` y
solicitud de integración a `main` hay dos trabajos en paralelo. El primero
compila el frontend (Node 22) y corre `mvn -B verify` en modo Testcontainers; el
segundo (`ci/verify-figures.sh`) instala el esquema en un Oracle desechable y
exige que las cifras del documento den OK. No usa secretos. Para ejecutar los
mismos pasos en el equipo, de principio a fin:

```
ci/local.sh        # frontend con Docker + verify con Testcontainers + cifras (unos 2 minutos)
```

## Despliegue

`deploy/` trae los artefactos para publicar el prototipo: el `Dockerfile` de la aplicación (multietapa, x86 y ARM),
un `docker-compose.yml` de producción (Oracle sin puerto publicado, la aplicación y Caddy con HTTPS automático), el
`Caddyfile`, `install-schema.sh` (el esquema se instala una sola vez) y `.github/workflows/cd.yml` (construye la imagen
para x86 y ARM, la publica en GitHub Container Registry y actualiza la aplicación en la máquina virtual por SSH).
`deploy/test-local.sh` los prueba en el equipo con `DOMINIO=localhost`; la salida está en
`docs/evidence/14_despliegue_local.txt`. Lo que falta (crear la máquina virtual de Oracle Cloud, el subdominio de
DuckDNS y los secretos del CD) requiere las cuentas del autor y está explicado paso a paso en `deploy/README.md`, que
también describe el respaldo con Cloudflare Tunnel.

## Estructura

```
.github/workflows/   CI y CD (GitHub Actions)
backend/             Spring Boot 4.1, Java 21, Data Mapper sin ORM
ci/                  pasos de la CI para ejecutar en el equipo
database/            base de datos Oracle
  admin/             como SYSTEM: espacios de tablas, esquema, roles, cuentas de servicio
  schema/            tablas, índices y vistas (DDL de Data Modeler completado)
  plsql/             pkg_errores, procedimiento de registro y 6 disparadores
  grants/            permisos de los 5 roles (sin DELETE)
  seed/              catálogos, datos de referencia y operación de prueba; volume/ genera el volumen
  queries/           consultas C1 a C10 del documento
  transactions/      transacciones T01 a T12 y prueba de concurrencia
  reports/           informes I01 a I07 y planes de ejecución (explain/)
  extensions/        extensiones E1 y E2 (fuera de las 19 tablas del módulo)
  tests/             verificación de cifras y pruebas de reglas, permisos y E1
  install.sh         reinstala la base desde cero
  run.sh             ejecuta un .sql suelto con la cuenta indicada
  generate-evidence.sh  regenera todas las evidencias de la base
demo/                demostración (start.sh, stop.sh) y prueba de punta a punta (e2e/)
deploy/              Dockerfile, compose de producción con Caddy y scripts
docs/
  decisions.md       decisiones del proyecto
  extensions.md      extensiones fuera del módulo
  datamodeler/       DDL exportado de Data Modeler
  diagrams/          diagramas UML (PlantUML)
  evidence/          salidas de las pruebas, consultas, transacciones e informes
  reference/         copias de los capítulos 4 a 6 usadas por las pruebas
  report/            sección 6.3 y cambios del documento en LaTeX
frontend/            TypeScript, Vite, Pico CSS, Chart.js
```

Los scripts de `database/` se ejecutan en dos fases: administración como SYSTEM
(`admin`) y objetos como propietario `BD_ENLACE_EXPRESS` (el resto). Las
contraseñas nunca se escriben en los scripts: salen de `.env`.
