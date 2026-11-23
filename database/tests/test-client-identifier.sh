#!/usr/bin/env bash
# Evidencia de la decision A2: Oracle sabe quien hizo cada operacion aunque todas las conexiones usen la cuenta
# de servicio del rol. La aplicacion fija DBMS_SESSION.SET_IDENTIFIER(usuario) al abrir cada unidad de trabajo.
#
# Forma elegida: auditoria unificada. SYSTEM crea una politica temporal que audita las acciones de svc_mesa:
# INSERT sobre SOLICITUD_RECOLECCION y EXECUTE de PR_REGISTRAR_ENVIO (el envio se inserta dentro del procedimiento,
# de modo que se audita su ejecucion). Luego demo_mesa registra una solicitud y un envio por la API real y se
# lee UNIFIED_AUDIT_TRAIL.CLIENT_IDENTIFIER. La politica se elimina al terminar.
#
# Uso:  database/tests/test-client-identifier.sh
# Requiere: la demostracion levantada (demo/start.sh) y DEMO_PASSWORD en .env.
# Salida: docs/evidence/11_identificador_cliente.txt. Termina con error si no aparece demo_mesa.
set -euo pipefail

RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SALIDA="$RAIZ/docs/evidence/11_identificador_cliente.txt"
URL="http://localhost:8080"
POLITICA="pol_demo_identificador"
cd "$RAIZ"

set -a
# shellcheck disable=SC1091
source .env
set +a
: "${DEMO_PASSWORD:?Defina DEMO_PASSWORD en .env}"
if [[ "$(curl -s -o /dev/null -w '%{http_code}' "$URL/api/salud" || true)" != "200" ]]; then
    echo "La aplicacion no responde en $URL. Ejecute demo/start.sh primero." >&2
    exit 1
fi

sistema() {
    docker exec -i enlace-oracle sqlplus -s /nolog <<SQL
CONNECT system/"$ORACLE_PASSWORD"@//localhost/FREEPDB1
SET LINESIZE 220 PAGESIZE 100 FEEDBACK OFF VERIFY OFF TRIMSPOOL ON TAB OFF
$1
SQL
}

limpiar() {
    sistema "
BEGIN
  EXECUTE IMMEDIATE 'NOAUDIT POLICY $POLITICA BY svc_mesa';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
  EXECUTE IMMEDIATE 'DROP AUDIT POLICY $POLITICA';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/" > /dev/null 2>&1 || true
}
trap limpiar EXIT
limpiar

sistema "
CREATE AUDIT POLICY $POLITICA ACTIONS
  INSERT ON bd_enlace_express.solicitud_recoleccion,
  EXECUTE ON bd_enlace_express.pr_registrar_envio;
AUDIT POLICY $POLITICA BY svc_mesa;" > /dev/null
ANTES="$(sistema "SELECT 'MARCA ' || TO_CHAR(SYSTIMESTAMP, 'YYYY-MM-DD\"T\"HH24:MI:SS.FF3') FROM dual;" | awk '/^MARCA/ {print $2}')"

# --- operacion real: demo_mesa por la API, con CSRF
JAR="$(mktemp)"
trap 'rm -f "$JAR"; limpiar' EXIT
token() { awk '$6 == "XSRF-TOKEN" {print $7}' "$JAR"; }
publicar() {
    curl -s -b "$JAR" -c "$JAR" -H "X-XSRF-TOKEN: $(token)" -H 'Content-Type: application/json' -d "$2" "$URL$1"
}
curl -s -o /dev/null -c "$JAR" "$URL/api/csrf"
publicar /api/sesion "{\"usuario\":\"demo_mesa\",\"contrasena\":\"$DEMO_PASSWORD\"}" > /dev/null
SEDE="$(curl -s -b "$JAR" "$URL/api/mesa/clientes/3/sedes" | grep -o '"idSede":[0-9]*' | head -1 | cut -d: -f2)"
HOY="$(TZ=America/Bogota date +%F)"
RESP_SOLICITUD="$(publicar /api/mesa/solicitudes "{\"idSede\":$SEDE,\"fechaProgramada\":\"$HOY\",\"franjaHoraria\":\"TARDE\"}")"
ID_SOLICITUD="$(grep -o '"idSolicitud":[0-9]*' <<<"$RESP_SOLICITUD" | cut -d: -f2)"
[[ -n "$ID_SOLICITUD" ]] || { echo "No se pudo registrar la solicitud: $RESP_SOLICITUD" >&2; exit 1; }
RESP_ENVIO="$(publicar /api/mesa/envios "{\"idSolicitud\":$ID_SOLICITUD,\"destinatario\":{\"tipoDocumento\":\"CC\",\"numeroDocumento\":\"AUD-0001\",\"nombre\":\"Destinatario de auditoria\",\"telefono\":\"3001112233\",\"correo\":null},\"idZona\":1,\"idModalidad\":3,\"direccionDestino\":\"Calle 1 # 2-3\",\"pesoDeclarado\":1.5,\"contenido\":\"Prueba de auditoria\",\"valorDeclarado\":50000,\"fragil\":false,\"altoValor\":false,\"fechaCompromiso\":null}")"
GUIA="$(grep -o 'EE[0-9]\{13\}' <<<"$RESP_ENVIO" | head -1)"
[[ -n "$GUIA" ]] || { echo "No se pudo registrar el envio: $RESP_ENVIO" >&2; exit 1; }

# --- lectura de la auditoria como administrador
consultar_auditoria() {
    sistema "
COLUMN dbusername FORMAT A12
COLUMN client_identifier FORMAT A18
COLUMN action_name FORMAT A11
COLUMN object_name FORMAT A22
SELECT TO_CHAR(event_timestamp, 'YYYY-MM-DD HH24:MI:SS') AS instante, dbusername, client_identifier, action_name, object_name
FROM   unified_audit_trail
WHERE  unified_audit_policies = '${POLITICA^^}'
AND    event_timestamp >= TO_TIMESTAMP('$ANTES', 'YYYY-MM-DD\"T\"HH24:MI:SS.FF3')
ORDER  BY event_timestamp;"
}
# la auditoria unificada se escribe en cola: se reintenta unos segundos hasta que aparezcan las dos acciones
for _ in $(seq 1 15); do
    CONSULTA="$(consultar_auditoria)"
    grep -qi 'SOLICITUD_RECOLECCION' <<<"$CONSULTA" && grep -qi 'PR_REGISTRAR_ENVIO' <<<"$CONSULTA" && break
    sleep 1
done

{
    echo "Evidencia de la decision A2: identificador de cliente de la sesion de Oracle"
    echo "Fecha: $(TZ=America/Bogota date '+%Y-%m-%d %H:%M:%S') (America/Bogota)"
    echo
    echo "Operacion hecha por la aplicacion (API real, con sesion y CSRF) como el usuario demo_mesa:"
    echo "  - solicitud de recoleccion $ID_SOLICITUD (POST /api/mesa/solicitudes)"
    echo "  - envio $GUIA (POST /api/mesa/envios)"
    echo
    echo "Observacion: auditoria unificada de Oracle. Politica temporal $POLITICA creada por SYSTEM:"
    echo "  AUDIT POLICY ... ACTIONS INSERT ON solicitud_recoleccion, EXECUTE ON pr_registrar_envio, BY svc_mesa"
    echo "(la politica se elimina al terminar este script)."
    echo
    echo "Lectura de UNIFIED_AUDIT_TRAIL (DBUSERNAME es la cuenta de servicio con la que se conecta la"
    echo "aplicacion; CLIENT_IDENTIFIER es el usuario real que fijo DBMS_SESSION.SET_IDENTIFIER):"
    echo
    echo "$CONSULTA"
} > "$SALIDA"
cat "$SALIDA"

if grep -qiE '^[0-9-]+ [0-9:]+[[:space:]]+SVC_MESA[[:space:]]+demo_mesa[[:space:]]+INSERT[[:space:]]+SOLICITUD_RECOLECCION' <<<"$CONSULTA" \
   && grep -qiE '^[0-9-]+ [0-9:]+[[:space:]]+SVC_MESA[[:space:]]+demo_mesa[[:space:]]+EXECUTE[[:space:]]+PR_REGISTRAR_ENVIO' <<<"$CONSULTA"; then
    echo "RESULTADO: OK, Oracle registro demo_mesa como identificador de cliente de operaciones hechas con svc_mesa." | tee -a "$SALIDA"
else
    echo "RESULTADO: FALLA, no aparecio demo_mesa como identificador de cliente." | tee -a "$SALIDA"
    exit 1
fi
