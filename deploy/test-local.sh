#!/usr/bin/env bash
# Prueba en el equipo el compose de produccion (deploy/docker-compose.yml) con HTTPS de Caddy y el dominio
# localhost (certificado interno de Caddy): construye la imagen, levanta Oracle, instala el esquema, levanta la
# aplicacion y el proxy, y comprueba con curl lo que importa del despliegue. Guarda la salida en
# docs/evidence/14_despliegue_local.txt y, al terminar, baja el compose y borra sus volumenes.
#
# Uso:  deploy/test-local.sh [--conservar]
#   --conservar   no baja el compose al terminar (para mirarlo a mano; luego: deploy/test-local.sh --limpiar)
#   --limpiar     solo baja el compose de produccion y borra sus volumenes
# Variables: PUERTO_HTTPS (18443) y PUERTO_HTTP (18081), para no chocar con otros servicios del equipo.
# Requiere Docker y el .env de la raiz (las mismas contrasenas que usa el compose). No usa sudo.
set -uo pipefail

RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SALIDA="$RAIZ/docs/evidence/14_despliegue_local.txt"
export DOMINIO=localhost
export PUERTO_HTTPS="${PUERTO_HTTPS:-18443}"
export PUERTO_HTTP="${PUERTO_HTTP:-18081}"
compose() { docker compose --env-file "$RAIZ/.env" -f "$RAIZ/deploy/docker-compose.yml" "$@"; }

if [[ "${1:-}" == "--limpiar" ]]; then
    compose down -v
    exit 0
fi
CONSERVAR=0
[[ "${1:-}" == "--conservar" ]] && CONSERVAR=1

[[ -f "$RAIZ/.env" ]] || { echo "Falta $RAIZ/.env" >&2; exit 1; }
set -a
# shellcheck disable=SC1091
source "$RAIZ/.env"
set +a

FALLAS=0
TOTAL=0
comprobar() { # comprobar "descripcion" codigo_de_salida
    TOTAL=$((TOTAL + 1))
    if [[ "$2" == "0" ]]; then echo "OK     $1"; else echo "FALLA  $1"; FALLAS=$((FALLAS + 1)); fi
}
titulo() { printf '\n--- %s\n' "$1"; }
oculta() { sed -E 's/(JSESSIONID|XSRF-TOKEN)=[^;]+/\1=<valor>/'; }

BASE="https://localhost:$PUERTO_HTTPS"
JAR="$(mktemp)"
limpiar() {
    rm -f "$JAR"
    if [[ "$CONSERVAR" == "0" ]]; then
        echo
        echo "Bajando el compose de produccion y borrando sus volumenes..."
        compose down -v 2>&1 | tail -8
    fi
}
trap limpiar EXIT

{
echo "Prueba local del despliegue (compose de produccion con Caddy, DOMINIO=localhost)"
echo "Fecha: $(date '+%Y-%m-%d %H:%M:%S %Z')"
echo "Puertos de Caddy en el equipo: HTTPS $PUERTO_HTTPS, HTTP $PUERTO_HTTP"

titulo "1. Construccion de la imagen de la aplicacion (deploy/Dockerfile)"
t0=$SECONDS
compose build app > /tmp/enlace-build.log 2>&1
comprobar "docker compose build app ($((SECONDS - t0)) s)" $?
docker image inspect enlace-express:local --format 'imagen: {{.Id}} arquitectura={{.Architecture}} tamano={{.Size}} bytes usuario={{.Config.User}}' 2>&1
echo "Plataformas disponibles en buildx: $(docker buildx ls 2>/dev/null | awk 'NR>1 && /linux/ {print}' | tr -s ' ' | head -1)"

titulo "2. Oracle (sin puerto publicado) y esquema (deploy/install-schema.sh)"
compose up -d oracle 2>&1 | tail -3
for _ in $(seq 1 90); do
    [[ "$(docker inspect -f '{{.State.Health.Status}}' enlace-prod-oracle 2>/dev/null)" == "healthy" ]] && break
    sleep 5
done
[[ "$(docker inspect -f '{{.State.Health.Status}}' enlace-prod-oracle)" == "healthy" ]]
comprobar "Oracle de produccion healthy" $?
puertos="$(docker port enlace-prod-oracle 2>&1 || true)"
[[ -z "$puertos" ]]
comprobar "Oracle no publica ningun puerto hacia afuera (docker port: '${puertos:-ninguno}')" $?
"$RAIZ/deploy/install-schema.sh" 2>&1 | grep -E "Cifras con FALLA|Esquema instalado|ya esta instalado"
comprobar "esquema instalado con las cifras del documento en modo estricto" "${PIPESTATUS[0]}"
"$RAIZ/deploy/install-schema.sh" 2>&1 | grep -q "ya esta instalado"
comprobar "una segunda ejecucion no reinstala (el esquema se instala una sola vez, G2)" $?

titulo "3. Aplicacion y Caddy"
compose up -d 2>&1 | tail -5
listo=1
for _ in $(seq 1 60); do
    if [[ "$(curl -sk -o /dev/null -w '%{http_code}' "$BASE/api/salud")" == "200" ]]; then listo=0; break; fi
    sleep 2
done
comprobar "https://localhost:$PUERTO_HTTPS/api/salud responde 200 a traves de Caddy" $listo
echo "Respuesta: $(curl -sk "$BASE/api/salud")"
compose ps --format 'table {{.Service}}\t{{.Status}}\t{{.Ports}}'
echo "Usuario del proceso de la aplicacion: $(docker exec enlace-prod-app id)"
docker exec enlace-prod-app id -u | grep -vq '^0$'
comprobar "la aplicacion corre sin privilegios (no es root)" $?
echo "Hora y zona en la aplicacion: $(docker exec enlace-prod-app date '+%Y-%m-%d %H:%M:%S %Z')"
docker exec enlace-prod-app date +%z | grep -q -- '-0500'
comprobar "zona horaria America/Bogota (-0500) en la aplicacion" $?
curl -s -o /dev/null --max-time 3 "http://localhost:8080/api/salud"
[[ $? -ne 0 ]]
comprobar "la aplicacion no es alcanzable directamente en el puerto 8080 del equipo (solo por Caddy)" $?

titulo "4. HTTPS, rastreo publico y rutas protegidas (curl -k por el certificado interno de Caddy)"
curl -skI "http://localhost:$PUERTO_HTTP/api/salud" | head -4 | tr -d '\r'
curl -skI "http://localhost:$PUERTO_HTTP/api/salud" | head -1 | grep -qE ' (301|302|307|308) '
comprobar "HTTP en el puerto $PUERTO_HTTP redirige a HTTPS" $?
curl -skI "$BASE/api/salud" | grep -i '^strict-transport-security' | tr -d '\r'
curl -skI "$BASE/api/salud" | grep -qi '^strict-transport-security'
comprobar "Caddy agrega Strict-Transport-Security" $?
cuerpo="$(curl -sk "$BASE/api/publico/rastreo/EE0000000000003")"
echo "Rastreo publico de EE0000000000003: $(echo "$cuerpo" | cut -c1-160)..."
echo "$cuerpo" | grep -q 'ENTREGADO'
comprobar "rastreo publico de EE0000000000003 sin sesion: trae el estado ENTREGADO" $?
estado="$(curl -sk -o /dev/null -w '%{http_code}' "$BASE/api/mesa/clientes")"
echo "GET /api/mesa/clientes sin sesion -> $estado"
[[ "$estado" == "401" ]]
comprobar "/api/mesa/clientes sin sesion da 401" $?
estado="$(curl -sk -o /dev/null -w '%{http_code}' "$BASE/")"
[[ "$estado" == "200" ]]
comprobar "la aplicacion web (index.html) se sirve por HTTPS: $estado" $?

titulo "5. Cookies Secure (CSRF y sesion)"
curl -sk -c "$JAR" -D - -o /dev/null "$BASE/api/csrf" | grep -i '^set-cookie' | oculta | tr -d '\r'
grep -q 'XSRF-TOKEN' "$JAR" && curl -sk -D - -o /dev/null "$BASE/api/csrf" | grep -i '^set-cookie: XSRF-TOKEN' | grep -qi 'secure'
comprobar "la cookie XSRF-TOKEN sale con Secure" $?
token="$(awk '$6 == "XSRF-TOKEN" {print $7}' "$JAR")"
codigo="$(docker exec -i enlace-prod-oracle sqlplus -s /nolog <<SQL | grep -Eo '^CODIGO [A-Z0-9-]+' | cut -d' ' -f2
CONNECT bd_enlace_express/"$PROPIETARIO_PASSWORD"@//localhost/FREEPDB1
SET SERVEROUTPUT ON FEEDBACK OFF
BEGIN DBMS_OUTPUT.PUT_LINE('CODIGO ' || pkg_codigos_activacion.generar_para_empleado('1019444004', 3)); COMMIT; END;
/
SQL
)"
clave="Ee$(openssl rand -hex 8)7"
estado="$(curl -sk -b "$JAR" -c "$JAR" -o /dev/null -w '%{http_code}' -H "X-XSRF-TOKEN: $token" -H 'Content-Type: application/json' \
    -d "{\"documento\":\"1019444004\",\"codigo\":\"$codigo\",\"usuario\":\"prueba_despliegue\",\"contrasena\":\"$clave\"}" "$BASE/api/registro/empleado")"
echo "Registro con codigo de activacion -> $estado"
token="$(awk '$6 == "XSRF-TOKEN" {print $7}' "$JAR")"
curl -sk -b "$JAR" -c "$JAR" -D /tmp/enlace-login.txt -o /dev/null -H "X-XSRF-TOKEN: $token" -H 'Content-Type: application/json' \
    -d "{\"usuario\":\"prueba_despliegue\",\"contrasena\":\"$clave\"}" "$BASE/api/sesion"
head -1 /tmp/enlace-login.txt | tr -d '\r'
grep -i '^set-cookie' /tmp/enlace-login.txt | oculta | tr -d '\r'
grep -i '^set-cookie: JSESSIONID' /tmp/enlace-login.txt | grep -qi 'secure'
comprobar "la cookie de sesion JSESSIONID sale con Secure" $?
grep -i '^set-cookie: JSESSIONID' /tmp/enlace-login.txt | grep -qi 'httponly'
comprobar "la cookie de sesion sale con HttpOnly" $?
estado="$(curl -sk -b "$JAR" -o /dev/null -w '%{http_code}' "$BASE/api/mesa/clientes")"
echo "GET /api/mesa/clientes con la sesion de mesa -> $estado"
[[ "$estado" == "200" ]]
comprobar "con la sesion de mesa, /api/mesa/clientes da 200 (el flujo completo funciona a traves del proxy)" $?
rm -f /tmp/enlace-login.txt

titulo "6. Limite de consultas por IP: cuenta la IP real del cliente, no la de Caddy"
# la ventana del limite es de un minuto y el rastreo de la seccion 4 ya conto una consulta de esta misma IP:
# se espera a que salga de la ventana para contar exactamente 30
echo "Esperando 61 s a que las consultas anteriores salgan de la ventana de un minuto..."
sleep 61
codigos=""
for i in $(seq 1 32); do
    codigos="$codigos $(curl -sk -o /dev/null -w '%{http_code}' "$BASE/api/publico/rastreo/EE0000000000003")"
done
echo "32 consultas seguidas desde el equipo (el limite es 30 por minuto):$codigos"
echo "$codigos" | awk '{ok=0; for (i=1;i<=30;i++) if ($i==200) ok++; exit !(ok==30 && $31==429 && $32==429)}'
comprobar "las primeras 30 consultas dan 200 y la 31 y la 32 dan 429" $?
estado="$(curl -sk -o /dev/null -w '%{http_code}' -H 'X-XSRF-TOKEN: x' "$BASE/api/publico/rastreo/EE0000000000003" -H 'X-Forwarded-For: 203.0.113.77')"
echo "Con un X-Forwarded-For falso (203.0.113.77) la misma IP sigue limitada -> $estado"
[[ "$estado" == "429" ]]
comprobar "un X-Forwarded-For falso no evade el limite (Caddy lo reemplaza por la IP real)" $?
estado="$(docker run --rm --network enlace-prod_default curlimages/curl:8.10.1 -sk -o /dev/null -w '%{http_code}' \
    --connect-to localhost:443:caddy:443 "https://localhost/api/publico/rastreo/EE0000000000003")"
echo "Otro cliente (otro contenedor de la red, otra IP) mientras el primero esta limitado -> $estado"
[[ "$estado" == "200" ]]
comprobar "otro cliente con otra IP no queda limitado (el limite no se comparte por la IP de Caddy)" $?

echo
echo "Resultado: $((TOTAL - FALLAS)) de $TOTAL comprobaciones OK, $FALLAS FALLA."
[[ "$FALLAS" == "0" ]]
} 2>&1 | tee "$SALIDA"
exit "${PIPESTATUS[0]}"
