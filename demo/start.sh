#!/usr/bin/env bash
# Deja la demostracion lista desde cero y sin intervencion:
#   1. reinstala la base (instalacion normal, datos fijos)
#   2. compila el frontend y empaqueta el backend
#   3. levanta la aplicacion en segundo plano (PID en demo/.app.pid, log en demo/app.log)
#   4. genera los codigos de activacion como administrador y registra por la API un usuario por rol
#
# Uso:  demo/start.sh
# Requiere: .env con las contrasenas (incluida DEMO_PASSWORD), Docker y Java 21. No usa sudo.
set -euo pipefail

RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEMO="$RAIZ/demo"
CONTENEDOR="enlace-oracle"
URL="http://localhost:8080"
cd "$RAIZ"

if [[ ! -f .env ]]; then
    echo "Falta .env (copie .env.example y complete las contrasenas)." >&2
    exit 1
fi
set -a
# shellcheck disable=SC1091
source .env
set +a
if [[ -z "${DEMO_PASSWORD:-}" || "$DEMO_PASSWORD" == "cambiar" ]]; then
    echo "Defina DEMO_PASSWORD en .env (minimo 8 caracteres, con una letra y un numero)." >&2
    exit 1
fi
if [[ ! "$DEMO_PASSWORD" =~ ^[A-Za-z0-9]{8,}$ || ! "$DEMO_PASSWORD" =~ [0-9] || ! "$DEMO_PASSWORD" =~ [A-Za-z] ]]; then
    echo "DEMO_PASSWORD debe tener minimo 8 letras y numeros, con al menos una letra y un numero." >&2
    exit 1
fi

paso() { printf '\n== %s\n' "$1"; }

paso "Oracle"
estado="$(docker inspect -f '{{.State.Health.Status}}' "$CONTENEDOR" 2>/dev/null || true)"
if [[ "$estado" != "healthy" ]]; then
    docker compose up -d
    for _ in $(seq 1 90); do
        estado="$(docker inspect -f '{{.State.Health.Status}}' "$CONTENEDOR" 2>/dev/null || true)"
        [[ "$estado" == "healthy" ]] && break
        sleep 4
    done
    [[ "$estado" == "healthy" ]] || { echo "Oracle no quedo healthy." >&2; exit 1; }
fi
echo "Oracle healthy."

paso "Deteniendo la aplicacion anterior (si existe)"
"$DEMO/stop.sh"

paso "Reinstalando la base de datos"
"$RAIZ/database/install.sh" > "$DEMO/instalacion.log" 2>&1 || { tail -20 "$DEMO/instalacion.log" >&2; exit 1; }
tail -3 "$DEMO/instalacion.log"

paso "Compilando el frontend"
"$RAIZ/frontend/build.sh" > "$DEMO/frontend.log" 2>&1 || { tail -20 "$DEMO/frontend.log" >&2; exit 1; }
tail -1 "$DEMO/frontend.log"

paso "Empaquetando el backend"
(cd "$RAIZ/backend" && mvn -q -DskipTests package) > "$DEMO/backend.log" 2>&1 || { tail -30 "$DEMO/backend.log" >&2; exit 1; }
JAR="$(ls "$RAIZ"/backend/target/enlace-express-*.jar | grep -v original | head -1)"
echo "$JAR"

paso "Levantando la aplicacion"
nohup java -Duser.timezone=America/Bogota -jar "$JAR" > "$DEMO/app.log" 2>&1 &
echo $! > "$DEMO/.app.pid"
listo=0
for _ in $(seq 1 60); do
    if [[ "$(curl -s -o /dev/null -w '%{http_code}' "$URL/api/salud" || true)" == "200" ]]; then
        listo=1
        break
    fi
    sleep 1
done
if [[ "$listo" != 1 ]]; then
    echo "La aplicacion no respondio en /api/salud; vea demo/app.log" >&2
    tail -20 "$DEMO/app.log" >&2
    exit 1
fi
echo "Aplicacion arriba (PID $(cat "$DEMO/.app.pid"))."

paso "Generando codigos de activacion y registrando los usuarios"
# Los codigos los emite el administrador de la base (pkg_codigos_activacion no tiene GRANT).
CODIGOS="$(docker exec -i "$CONTENEDOR" sqlplus -s /nolog <<SQL
CONNECT bd_enlace_express/"$PROPIETARIO_PASSWORD"@//localhost/FREEPDB1
SET SERVEROUTPUT ON FEEDBACK OFF VERIFY OFF
DECLARE
  PROCEDURE g(p_nombre VARCHAR2, p_codigo VARCHAR2) IS
  BEGIN DBMS_OUTPUT.PUT_LINE('CODIGO ' || p_nombre || ' ' || p_codigo); END;
BEGIN
  g('gerencia', pkg_codigos_activacion.generar_para_empleado('52111001', 3));
  g('centro', pkg_codigos_activacion.generar_para_empleado('80222002', 3));
  g('mesa', pkg_codigos_activacion.generar_para_empleado('1019444004', 3));
  g('mensajero', pkg_codigos_activacion.generar_para_empleado('1040777007', 3));
  g('cliente', pkg_codigos_activacion.generar_para_cliente('900345678', 3));
  COMMIT;
END;
/
SQL
)"

codigo_de() { grep "^CODIGO $1 " <<<"$CODIGOS" | awk '{print $3}'; }

# Registro por la API real: primero /api/csrf (cookie XSRF-TOKEN), luego el POST con X-XSRF-TOKEN.
registrar() {
    local tipo="$1" campo="$2" valor="$3" rol="$4" usuario="$5"
    local jar cuerpo token estado
    jar="$(mktemp)"
    curl -s -o /dev/null -c "$jar" "$URL/api/csrf"
    token="$(awk '$6 == "XSRF-TOKEN" {print $7}' "$jar")"
    cuerpo="$(printf '{"%s":"%s","codigo":"%s","usuario":"%s","contrasena":"%s"}' \
        "$campo" "$valor" "$(codigo_de "$rol")" "$usuario" "$DEMO_PASSWORD")"
    estado="$(curl -s -o "$jar.salida" -w '%{http_code}' -b "$jar" -H "X-XSRF-TOKEN: $token" \
        -H 'Content-Type: application/json' -d "$cuerpo" "$URL/api/registro/$tipo")"
    if [[ "$estado" != "201" && "$estado" != "200" ]]; then
        echo "Fallo el registro de $usuario (HTTP $estado): $(cat "$jar.salida")" >&2
        rm -f "$jar" "$jar.salida"
        exit 1
    fi
    rm -f "$jar" "$jar.salida"
    echo "  $usuario registrado"
}

registrar empleado documento 52111001 gerencia demo_gerencia
registrar empleado documento 80222002 centro demo_centro
registrar empleado documento 1019444004 mesa demo_mesa
registrar empleado documento 1040777007 mensajero demo_mensajero
registrar cliente nit 900345678 cliente demo_cliente

cat <<TEXTO

La demostracion esta lista.

  URL:  $URL

  Usuario          Rol
  demo_gerencia    Gerencia (tablero)
  demo_centro      Centro de distribucion 1 (recepcion y despachos)
  demo_mesa        Mesa de servicio (solicitudes y envios)
  demo_mensajero   Mensajero (planilla y recolecciones)
  demo_cliente     Cliente TiendaOnline Colombia S.A.S. (seguimiento)

  Contrasena: la de DEMO_PASSWORD en .env
  Detener:    demo/stop.sh
TEXTO
