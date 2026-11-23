# Despliegue de Enlace Express

Artefactos para publicar el prototipo (decisiones 12.6, G1, G2 y G3): una máquina virtual
gratuita de Oracle Cloud (Always Free, Ampere A1, ARM) con Oracle 23c Free, la aplicación y
Caddy como proxy inverso con HTTPS automático, y un flujo de despliegue continuo con GitHub
Actions. Todo está probado en el equipo con el dominio `localhost` (`deploy/test-local.sh`,
salida en `docs/evidence/14_despliegue_local.txt`). Lo que falta lo hace el autor, porque
necesita sus cuentas: crear la máquina virtual y el dominio y cargar los secretos del CD.

| Archivo | Para qué sirve |
|---|---|
| `Dockerfile` | Imagen de la aplicación: compila el frontend (Node 22) y el backend (Maven y JDK 21) y deja un JRE 21 sin privilegios, con zona horaria America/Bogota y healthcheck. Sirve para x86 y ARM. |
| `docker-compose.yml` | Oracle (sin puerto publicado), la aplicación y Caddy. Contraseñas y dominio desde `.env`. |
| `Caddyfile` | HTTPS automático para `DOMINIO`; reenvía a la aplicación con la IP real del cliente. |
| `install-schema.sh` | Instala el esquema una sola vez (G2); no hace nada si ya existe, salvo `--reinstalar`. |
| `test-local.sh` | Prueba todo lo anterior en el equipo con HTTPS de Caddy y `localhost`. |
| `../.github/workflows/cd.yml` | Construye la imagen para x86 y ARM, la publica en GitHub Container Registry y actualiza la aplicación en la máquina virtual por SSH. |

## Pasos para publicar (una sola vez)

1. **Máquina virtual.** En Oracle Cloud, crear una instancia Always Free con la forma
   `VM.Standard.A1.Flex` (Ampere A1, ARM; hasta 2 OCPU y 12 GB según el límite vigente), con
   Ubuntu, y abrir en su lista de seguridad los puertos 22, 80 y 443. Las cuentas inactivas
   por más de 30 días pueden ser suspendidas.
2. **Docker.** En la máquina: instalar Docker Engine con el plugin de Compose
   (<https://docs.docker.com/engine/install/ubuntu/>) y agregar el usuario al grupo `docker`.
   Si el firewall del sistema (iptables o ufw) está activo, abrir también 80 y 443.
3. **Dominio.** Crear un subdominio gratuito en <https://www.duckdns.org> (por ejemplo
   `enlace.duckdns.org`) apuntando a la IP pública de la máquina.
4. **Código y `.env`.** En la máquina:
   ```
   git clone <repositorio> ImplementacionProyectoDB && cd ImplementacionProyectoDB
   cp .env.example .env     # editar: contraseñas propias y DOMINIO=enlace.duckdns.org
   ```
   El `.env` necesita las siete contraseñas de `.env.example` y estas variables del despliegue:
   `DOMINIO` (el nombre público) e `IMAGEN_APP` (por ejemplo
   `ghcr.io/<usuario>/implementacionproyectodb:latest`, en minúsculas). Nunca se versiona.
5. **Primer arranque.** El esquema debe existir antes de que la aplicación esté sana, así que
   se levanta Oracle, se instala el esquema y después el resto:
   ```
   docker compose --env-file .env -f deploy/docker-compose.yml up -d oracle
   deploy/install-schema.sh
   docker compose --env-file .env -f deploy/docker-compose.yml up -d
   ```
   Si la imagen aún no está en GHCR, se construye en la máquina:
   `docker compose --env-file .env -f deploy/docker-compose.yml build app`.
   Caddy obtiene el certificado de Let's Encrypt solo; hace falta que el dominio ya resuelva
   a la máquina y que los puertos 80 y 443 estén abiertos.
6. **Usuarios.** Los usuarios de la aplicación se crean con códigos de activación que genera el
   administrador (`pkg_codigos_activacion`, ver `docs/extensions.md`). Para una demostración
   inmediata se puede usar el registro por la API como lo hace `demo/start.sh`.
7. **Despliegue continuo.** En GitHub, en *Settings > Secrets and variables > Actions*, crear los
   secretos que usa `.github/workflows/cd.yml` (sin ellos el flujo solo publica la imagen):

   | Secreto | Contenido |
   |---|---|
   | `DESPLIEGUE_HOST` | nombre o IP de la máquina virtual |
   | `DESPLIEGUE_USUARIO` | usuario SSH (por ejemplo `ubuntu`) |
   | `DESPLIEGUE_LLAVE_SSH` | llave privada SSH completa, cuya pública está en `~/.ssh/authorized_keys` del servidor |
   | `DESPLIEGUE_HOST_KEY` | línea de `known_hosts` del servidor: `ssh-keyscan -t ed25519 <host>` |
   | `DESPLIEGUE_RUTA` | carpeta del repositorio en el servidor (por defecto `~/ImplementacionProyectoDB`) |
   | `DESPLIEGUE_PUERTO` | puerto SSH (por defecto 22) |

   El paquete de la imagen en GHCR debe poder descargarse desde la máquina: hacerlo público o
   iniciar sesión una vez con `docker login ghcr.io` (usuario y token con permiso `read:packages`).
   Desde entonces, cada cambio que pase la CI en `main` publica la imagen y actualiza solo la
   aplicación (`docker compose pull app && up -d app`); el esquema no se toca.

## Operación

- Actualizar a mano la aplicación: `docker compose --env-file .env -f deploy/docker-compose.yml pull app && docker compose --env-file .env -f deploy/docker-compose.yml up -d app`.
- Cambió el esquema: `deploy/install-schema.sh --reinstalar` (borra y recrea la base).
- Ver registros: `docker compose --env-file .env -f deploy/docker-compose.yml logs -f app`.
- Los datos de Oracle están en el volumen `enlace-prod_oradata`; los certificados, en `enlace-prod_caddy-datos`.

## Respaldo: presentar desde el equipo propio con Cloudflare Tunnel

Si no se consigue la máquina virtual, se presenta desde el equipo con el compose de desarrollo y
un túnel de Cloudflare, que da HTTPS gratuito sin abrir puertos ni usar dominio (no hay despliegue
continuo):

```
docker compose up -d                         # Oracle de desarrollo
database/install.sh                               # esquema y datos
demo/start.sh                     # aplicación en http://localhost:8080 y usuarios demo
cloudflared tunnel --url http://localhost:8080
```

`cloudflared` imprime una dirección `https://<nombre-al-azar>.trycloudflare.com`. Como entre el túnel
y la aplicación el tráfico es HTTP local, el túnel agrega la cabecera `X-Forwarded-For` con la IP del
visitante; para que el límite del rastreo público cuente esa IP, arrancar la aplicación con
`ENLACE_RASTREO_CONFIAR_EN_PROXY=true` (y `ENLACE_COOKIE_SEGURA=true`, porque el navegador usa HTTPS).

## Probar el despliegue en el equipo

```
deploy/test-local.sh
```

Construye la imagen, levanta el compose de producción con `DOMINIO=localhost` en los puertos 18443 y
18081 (`PUERTO_HTTPS` y `PUERTO_HTTP` los cambian), instala el esquema, comprueba con curl la salud, el
rastreo público, las rutas protegidas, las cookies `Secure` y el límite por IP, y al terminar baja el
compose y borra sus volúmenes. Dura unos minutos, casi todo la construcción de la imagen.
