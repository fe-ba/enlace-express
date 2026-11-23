# Extensiones fuera del módulo M1

El prototipo es el módulo M1 funcionando (decisión 12.5). Se permite
extender fuera del módulo solo para probar un caso de uso completo o
hacer una prueba real del sistema. Cada extensión se registra aquí, va en
`database/extensions/` y no modifica las 19 tablas del módulo: la
verificación de cifras (`database/tests/verificar_cifras.sql`) las
cuenta por una lista explícita y sigue dando 19 tablas, 59 índices,
6 disparadores y 1 procedimiento con las extensiones instaladas.

## E1. Usuarios de la aplicación y códigos de activación

**Qué agrega.**

| Objeto | Tipo | Qué es |
|---|---|---|
| `USUARIO_APLICACION` | Tabla | Cuenta de acceso a la aplicación: nombre de usuario único, hash BCrypt de la contraseña (la base nunca ve la contraseña), rol de la aplicación (GERENCIA, CENTRO, MESA, MENSAJERO o CLIENTE), vínculo con un empleado (una cuenta por empleado) o con un cliente (varias cuentas por empresa), estado y fechas de creación y de último ingreso. |
| `CODIGO_ACTIVACION` | Tabla | Código de un solo uso y con vencimiento, emitido para un empleado o para un cliente. Solo se guarda su hash SHA-256; el código en claro se muestra una vez al generarlo. Registra cuándo se usó y qué cuenta lo usó. |
| 4 índices sobre claves foráneas | Índices | `USUARIO_CLIENTE_FK_IX`, `CODIGO_EMPLEADO_FK_IX`, `CODIGO_CLIENTE_FK_IX`, `CODIGO_USUARIO_FK_IX`, en `TS_ENLACE_INDICES` como el resto. |
| `pkg_codigos_activacion` | Paquete | Uso exclusivo del administrador de la base de datos (sin GRANT): genera el código de un empleado activo (por documento) o de un cliente activo (por NIT), con vigencia de 72 horas por defecto. Código de 12 caracteres (`XXXX-XXXX-XXXX`) generado con `DBMS_CRYPTO.RANDOMBYTES`. |
| `pkg_seguridad` | Paquete | Lo usa la aplicación: registro de empleados y de clientes con su código, datos para el inicio de sesión y registro del último ingreso. Deriva el rol del cargo del empleado; nunca lo elige el usuario. |
| `GRANT EXECUTE ON pkg_seguridad TO rol_cliente` | Permiso | Única puerta a las tablas E1, que no se conceden a ningún rol. |

**Reglas que aplica (decisiones 12.3 y D1).**

- El código es de un solo uso y vence; se bloquea con `SELECT ... FOR UPDATE`
  al usarlo, para que dos registros simultáneos no lo usen dos veces.
- El empleado debe existir y estar ACTIVO; el cliente debe estar ACTIVO.
- El rol se deriva del cargo: `Gerente` -> GERENCIA, `Auxiliar de centro`
  -> CENTRO, `Agente de mesa de servicio` -> MESA, `Mensajero` (con fila
  en MENSAJERO) -> MENSAJERO. Otro cargo no tiene acceso.
- Un documento inexistente, un código ajeno, usado o vencido dan el mismo
  mensaje, para no revelar cuál dato falló.
- Una cuenta cuyo empleado se retira o cuyo cliente se inactiva queda
  INACTIVA de inmediato en el inicio de sesión.
- Errores en el rango -20101 a -20112, con mensajes que empiezan por `E1:`
  (fuera del rango de las reglas RN del módulo).

**Qué caso de uso permite probar.** Todos los que requieren inicio de
sesión (U1 a U4 y el seguimiento de U9 con cuenta) y el caso CU28
"Gestionar usuarios y roles" en su parte de alta de cuentas. Sin E1 no
se puede probar ningún caso de uso con usuario, porque el módulo no
tiene credenciales.

**Por qué no está en el módulo.** Las cuentas de usuario y la
autenticación no son parte de la operación de envíos: el análisis las
ubica en la administración del sistema, y en una empresa real vendrían
del directorio de usuarios. Se agregan solo para que el prototipo pueda
probar los casos de uso con el rol de cada usuario.

**Cuenta de la base de datos que la usa.** La parte pública de la
aplicación (inicio de sesión, registro y rastreo por guía) trabaja antes
de saber quién es el usuario y usa la cuenta de servicio de menor
privilegio, `svc_cliente`, que solo puede ejecutar `pkg_seguridad` y leer
`v_seguimiento_envio` y `v_rastreo_publico` (E2).

**Pruebas.** `database/tests/test-e1.sh`: 74 casos, 0 fallas
(evidencia en `docs/evidence/09_extension_e1.txt`).

## E2. Vista de rastreo público

**Qué agrega.** La vista `v_rastreo_publico` (`database/extensions/E2_01_vista_rastreo.sql`):
número de guía, identificador del evento (solo para ordenar), fecha y
hora, estado y zona de destino de cada evento del envío. Es de solo
lectura y se concede únicamente a `rol_cliente`. No incluye la
observación del evento, el responsable ni ningún dato del destinatario
o del cliente.

**Qué caso de uso permite probar.** CU20 "Consultar seguimiento del
envío" en su forma pública, sin cuenta (decisión D2): cualquier persona
con el número de guía ve estados, fechas y zona, sin nombres,
direcciones ni teléfonos. La aplicación limita además las consultas por
dirección IP (30 por minuto por defecto), porque las guías son
consecutivas y se podrían recorrer.

**Por qué no está en el módulo.** El documento define el seguimiento con
`v_seguimiento_envio` para la mesa de servicio y para el cliente con
cuenta (filtrada por su empresa), y esa vista trae la observación y el
responsable, que pueden contener nombres (por ejemplo "Entregado a
Recepción del edificio"). La decisión D2, tomada al diseñar el
prototipo, pide además la zona, que la cuenta `svc_cliente` no puede leer
(no tiene permiso sobre ENVIO ni ZONA). En lugar de cambiar una de las 7
vistas del módulo o ampliar los permisos de `rol_cliente`, se agrega una
vista aparte con solo los datos públicos. La verificación de cifras sigue
contando 7 vistas del módulo y cuenta esta en una fila aparte.
