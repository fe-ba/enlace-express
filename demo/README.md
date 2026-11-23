# Demostración de Enlace Express (módulo M1)

Deja la aplicación funcionando con la base en el estado de la demostración
y un usuario por rol (decisión B4).

## Levantar

```
demo/start.sh     # reinstala la base, compila, levanta la app y crea los usuarios
demo/stop.sh      # detiene la aplicación (usa el PID guardado en demo/.app.pid)
```

Requisitos: Oracle del `docker compose` (el script lo levanta si hace falta),
Docker, Java 21 y Maven, y `.env` con las contraseñas. Además de las variables
de `.env.example` hace falta `DEMO_PASSWORD` (mínimo 8 letras y números, con
al menos una letra y un número): es la contraseña de los cinco usuarios y
nunca se escribe en el repositorio.

`start.sh` termina en menos de un minuto: reinstala la base (datos fijos),
compila el frontend (`frontend/build.sh`), empaqueta el backend, levanta
el jar en segundo plano (log en `demo/app.log`) y registra los
usuarios por la API real, con códigos de activación emitidos como
administrador. Al final imprime la URL y los usuarios.

La aplicación queda en <http://localhost:8080/>.

| Usuario | Rol | Qué es |
|---|---|---|
| `demo_mesa` | Mesa de servicio | Agente de mesa de servicio, centro 1 |
| `demo_mensajero` | Mensajero | Mensajero 7, centro 1, motocicleta |
| `demo_centro` | Centro | Auxiliar de centro del centro 1 |
| `demo_gerencia` | Gerencia | Gerente |
| `demo_cliente` | Cliente | TiendaOnline Colombia S.A.S. |

Contraseña de todos: la de `DEMO_PASSWORD` en `.env`.

## Guion (unos 10 minutos)

Use una ventana por usuario (por ejemplo una ventana privada por rol). Las
guías las genera el sistema; anótelas al registrarlas.

1. **Rastreo público, sin cuenta.** En `#/rastreo` escriba
   `EE0000000000003`. Debe ver el estado Entregado y la línea de tiempo con
   fecha, estado y zona, sin nombres ni direcciones. Una guía inexistente da
   un mensaje claro.
2. **Mesa registra la solicitud.** `demo_mesa` entra y queda en
   "Registrar solicitud". Elija TiendaOnline Colombia, su sede, la fecha y la
   franja, y registre. Debe aparecer el número de solicitud.
3. **Mesa registra dos envíos** (menú "Registrar envío"), con zona Norte (centro 1):
   uno marcado Frágil (documento del destinatario `DEMO-0001`) y otro normal (`DEMO-0002`). Cada registro muestra la guía y la fecha de
   compromiso calculada con la modalidad.
4. **Mensajero recolecta.** `demo_mensajero` entra desde el teléfono (o con la
   ventana angosta), abre "Recolecciones" y marca la solicitud como
   recolectada: "2 envío(s)".
5. **Centro recibe y despacha.** `demo_centro`, en "Recepción", escribe el
   peso real y el flete de cada envío y los recibe (quedan clasificados). En
   "Despachos" selecciona los dos, elige al mensajero 7 y uno de sus
   vehículos disponibles, y arma el despacho. "Ver la planilla" muestra el orden de visita.
6. **Caso de rechazo RN06.** `demo_mensajero`, en "Mi planilla", abre
   "Entregar" en el envío frágil (aparece resaltado), escribe un documento
   que no es el del destinatario y confirma. Debe verse el rechazo
   `RN06: el envío es frágil o de alto valor y solo se entrega al destinatario...`.
7. **Entrega con prueba.** Con el documento del destinatario
   (`DEMO-0001`) la entrega se acepta. En el otro envío registre una novedad ("Destinatario ausente").
8. **Seguimiento.** Vuelva al rastreo público con ambas guías: uno Entregado,
   otro Con novedad. `demo_cliente` ve los dos en "Mis envíos" y su
   recorrido completo.
9. **Gerencia.** `demo_gerencia` ve el tablero: cumplimiento por zona,
   envíos por estado y reclamaciones pendientes con las horas transcurridas.
10. **Tres intentos y devolución.** `demo_centro` cierra el despacho
    (en "Planilla", botón "Cerrar despacho"); el envío con novedad vuelve a
    "Despachos" con 1 intento previo. Se arma un despacho nuevo y el mensajero
    registra una segunda novedad; se cierra, se arma un tercero y en el
    intento 3 el mensajero ya no ve "Entregar": solo "Registrar devolución".
    El envío queda Devuelto.
11. **Caso de rechazo RN12.** `demo_mesa`, en "Consultar envío", busca la
    guía del envío entregado y pulsa "Anular envío". Debe verse
    `RN12: la guía ... ya está en un estado final (ENTREGADO) y no admite el evento ANULADO`.

12. **Novedades y reclamaciones.** `demo_mesa`, en "Novedades", ve las novedades
    abiertas con los teléfonos, elige la acción (reintento o devolución), escribe la
    solución y la cierra. En "Reclamaciones" radica la reclamación de un cliente
    (con una guía opcional que debe ser de ese cliente; con la de otro cliente
    se rechaza), la responde y la cierra; las pendientes muestran las horas y una
    marca roja si superan la meta de 4 horas (RN14).
13. **Centros y zonas.** `demo_centro`, en "Centros y zonas", crea un centro, le
    agrega una zona y lo inactiva; nada se borra (RN16) y a un centro inactivo no se le
    agregan zonas.

## Prueba automática de punta a punta

```
demo/e2e/run.sh
```

Recorre el guion anterior en un navegador sin cabeza (Playwright en Docker,
imagen `mcr.microsoft.com/playwright:v1.49.1-noble`) con los usuarios `demo_*`.
Guarda 25 capturas y `resumen.txt` en `docs/evidence/10_aplicacion/`; termina
en 0 si no hay fallas. Se puede correr varias veces seguidas: cada corrida crea
sus propias solicitudes y envíos. Para volver al estado inicial, `start.sh`.

## Identificador de cliente (decisión A2)

Con la demostración levantada:

```
database/tests/test-client-identifier.sh
```

Hace una operación como `demo_mesa` por la API y lee la auditoría unificada de
Oracle: el `CLIENT_IDENTIFIER` es `demo_mesa` aunque la conexión sea de la
cuenta `svc_mesa`. Deja la salida en `docs/evidence/11_identificador_cliente.txt`.
