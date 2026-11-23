-- Datos de volumen (decision C7): operacion de agosto a octubre de 2026 generada
-- con PL/SQL para los informes y el EXPLAIN PLAN. NO lo ejecuta install.sh por
-- defecto: database/install.sh --volumen. Se ejecuta como BD_ENLACE_EXPRESS, despues
-- de seed, con los disparadores activos (no se deshabilitan).
-- Parametro: la variable de sustitucion envios_dia (envios por dia habil; el
-- capitulo 5 supone 900). La define install.sh (VOLUMEN_ENVIOS_DIA, por defecto 900).
--
-- Proporciones del capitulo 5: ~6,2 eventos, ~1,1 asignaciones, ~1 prueba y 0,12
-- novedades por envio; 60 % de destinatarios nuevos; 6 envios por solicitud;
-- 36 despachos de entrega y 8 de recoleccion por lote diario (lunes a sabado).
-- Resultado de cada envio (escenario, por mil): 88,0 % entregado en el primer
-- intento; 8,0 % novedad y entrega en el segundo; 1,5 % dos novedades y devolucion
-- en el tercero; 1,5 % anulado; 1,0 % con novedad abierta. Lotes del 1 de agosto
-- al 24 de octubre (el ultimo reintento cae antes del 31 de octubre, asi que
-- noviembre, periodo de C5 y C6, no se toca).
-- Tablas temporales de sesion (plan_volumen, dias_volumen): se crean y se borran aqui.
WHENEVER SQLERROR EXIT FAILURE
SET DEFINE ON
SET SERVEROUTPUT ON SIZE UNLIMITED
SET FEEDBACK OFF
ALTER SESSION SET NLS_LENGTH_SEMANTICS = CHAR;

CREATE GLOBAL TEMPORARY TABLE plan_volumen (
    n               NUMBER       NOT NULL,
    guia            VARCHAR2(15) NOT NULL,
    id_solicitud    NUMBER       NOT NULL,
    id_destinatario NUMBER       NOT NULL,
    id_zona         NUMBER       NOT NULL,
    id_modalidad    NUMBER       NOT NULL,
    escenario       NUMBER(1)    NOT NULL,
    off1            NUMBER(1)    NOT NULL,
    fragil          CHAR(1)      NOT NULL,
    alto            CHAR(1)      NOT NULL,
    peso            NUMBER(6,2)  NOT NULL
) ON COMMIT PRESERVE ROWS;

CREATE GLOBAL TEMPORARY TABLE dias_volumen (
    o NUMBER NOT NULL,
    f DATE   NOT NULL
) ON COMMIT PRESERVE ROWS;

DECLARE
    c_envios_dia CONSTANT NUMBER := &envios_dia;
    c_inicio     CONSTANT DATE := DATE '2026-08-01';
    c_fin        CONSTANT DATE := DATE '2026-10-24';
    c_mens       CONSTANT NUMBER := 25;

    v_inicio_total TIMESTAMP := SYSTIMESTAMP;
    v_inicio_lote  TIMESTAMP;
    v_dia     DATE;
    v_lotes   NUMBER := 0;
    v_lote    NUMBER := 0;
    v_total   NUMBER;
    v_k       NUMBER := 0;      -- envios generados hasta ahora
    v_guia0   NUMBER;           -- ultimo numero de guia usado
    v_c0 NUMBER; v_s0 NUMBER; v_emp0 NUMBER; v_veh0 NUMBER; v_dest0 NUMBER; v_pool NUMBER;
    v_sol NUMBER; v_d1 NUMBER; v_d2 NUMBER; v_a NUMBER; v_nov NUMBER; v_pru NUMBER; v_rec NUMBER;
    v_a_ini NUMBER;
    v_nsol  NUMBER;
    v_seg   NUMBER;

    FUNCTION segundos(p_desde IN TIMESTAMP) RETURN NUMBER IS
        v_i INTERVAL DAY TO SECOND := SYSTIMESTAMP - p_desde;
    BEGIN
        RETURN ROUND(EXTRACT(DAY FROM v_i) * 86400 + EXTRACT(HOUR FROM v_i) * 3600
                   + EXTRACT(MINUTE FROM v_i) * 60 + EXTRACT(SECOND FROM v_i), 1);
    END segundos;

    -- Asignaciones del intento p_int para los escenarios p_desde a p_hasta (nunca el 4, anulado)
    PROCEDURE asignar(p_int IN NUMBER, p_desde IN NUMBER, p_hasta IN NUMBER) IS
    BEGIN
        v_a_ini := v_a;
        INSERT INTO asignacion_despacho (id_asignacion, numero_guia, id_despacho, numero_intento, orden_visita, hora_visita, resultado)
        SELECT v_a + ROW_NUMBER() OVER (ORDER BY q.n) - 1, q.guia, q.desp, p_int, q.orden,
               CAST(q.f AS TIMESTAMP) + NUMTODSINTERVAL(CASE WHEN q.off = 0 THEN 810 ELSE 510 END + 90 + 3 * q.orden, 'MINUTE'),
               'PENDIENTE'
        FROM (SELECT p.n, p.guia, p.off1 + p_int - 1 AS off, dv.f,
                     v_d2 + (p.off1 + p_int - 1) * 6 + MOD(p.n, 6) AS desp,
                     ROW_NUMBER() OVER (PARTITION BY p.off1 + p_int - 1, MOD(p.n, 6) ORDER BY p.n) AS orden
              FROM   plan_volumen p
              JOIN   dias_volumen dv ON dv.o = p.off1 + p_int - 1
              WHERE  p.escenario BETWEEN p_desde AND p_hasta AND p.escenario <> 4) q;
        v_a := v_a + SQL%ROWCOUNT;
    END asignar;

    -- Evento EN_RUTA de las asignaciones recien creadas
    PROCEDURE en_ruta IS
    BEGIN
        INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion)
        SELECT a.numero_guia, 5, d.id_mensajero,
               a.hora_visita - NUMTODSINTERVAL(75 + MOD(p.n, 10), 'MINUTE'),
               'Sale en el despacho ' || a.id_despacho
        FROM   asignacion_despacho a
        JOIN   plan_volumen p ON p.guia = a.numero_guia
        JOIN   despacho d     ON d.id_despacho = a.id_despacho
        WHERE  a.id_asignacion >= v_a_ini AND a.id_asignacion < v_a;
    END en_ruta;

    -- Prueba de entrega, resultado final (ENTREGADO o DEVUELTO) y su evento
    PROCEDURE cerrar_con_prueba(p_int IN NUMBER, p_esc IN NUMBER, p_resultado IN VARCHAR2, p_estado IN NUMBER) IS
    BEGIN
        INSERT INTO prueba_entrega (id_prueba, id_asignacion, fecha_hora, nombre_receptor, documento_receptor, tipo_prueba, archivo_soporte)
        SELECT v_pru + ROW_NUMBER() OVER (ORDER BY a.id_asignacion), a.id_asignacion, a.hora_visita,
               'Receptor ' || p.n,
               CASE WHEN p.fragil = 'S' OR p.alto = 'S' THEN dd.numero_documento ELSE 'R' || p.n END,   -- RN06
               CASE MOD(p.n, 3) WHEN 0 THEN 'DOCUMENTO' WHEN 1 THEN 'FIRMA' ELSE 'FOTOGRAFIA' END,
               CASE WHEN MOD(p.n, 3) = 0 THEN NULL ELSE 'soportes/' || p.guia || '_' || p_int || '.png' END
        FROM   asignacion_despacho a
        JOIN   plan_volumen p ON p.guia = a.numero_guia
        JOIN   destinatario dd ON dd.id_destinatario = p.id_destinatario
        WHERE  a.id_asignacion >= v_a_ini AND a.id_asignacion < v_a AND p.escenario = p_esc;
        v_pru := v_pru + SQL%ROWCOUNT;

        UPDATE asignacion_despacho a SET resultado = p_resultado
        WHERE  a.id_asignacion >= v_a_ini AND a.id_asignacion < v_a
        AND    a.numero_guia IN (SELECT guia FROM plan_volumen WHERE escenario = p_esc);

        INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion)
        SELECT a.numero_guia, p_estado, d.id_mensajero, a.hora_visita + INTERVAL '1' MINUTE,
               CASE p_resultado WHEN 'ENTREGADO' THEN 'Entregado al destinatario' ELSE 'Devuelto a la sede del cliente' END
        FROM   asignacion_despacho a
        JOIN   plan_volumen p ON p.guia = a.numero_guia
        JOIN   despacho d     ON d.id_despacho = a.id_despacho
        WHERE  a.id_asignacion >= v_a_ini AND a.id_asignacion < v_a AND p.escenario = p_esc;
    END cerrar_con_prueba;

    -- Novedad, resultado NOVEDAD y evento CON_NOVEDAD para los escenarios dados
    PROCEDURE registrar_novedad(p_int IN NUMBER, p_e1 IN NUMBER, p_e2 IN NUMBER, p_e3 IN NUMBER) IS
    BEGIN
        INSERT INTO novedad (id_novedad, id_asignacion, tipo_novedad, descripcion, accion, solucion, estado)
        SELECT v_nov + ROW_NUMBER() OVER (ORDER BY a.id_asignacion), a.id_asignacion,
               CASE MOD(p.n, 5) WHEN 0 THEN 'DESTINATARIO_AUSENTE' WHEN 1 THEN 'DIRECCION_ERRADA' WHEN 2 THEN 'RECHAZADO'
                                WHEN 3 THEN 'PAQUETE_AVERIADO' ELSE 'OTRA' END,
               'Novedad en el intento ' || p_int || ' de la guia ' || p.guia,
               CASE WHEN p.escenario = 5 THEN NULL WHEN p_int = 2 THEN 'DEVOLUCION' ELSE 'REINTENTO' END,
               CASE WHEN p.escenario = 5 THEN NULL ELSE 'Resuelta con la mesa de servicio' END,
               CASE WHEN p.escenario = 5 THEN 'ABIERTA' ELSE 'CERRADA' END
        FROM   asignacion_despacho a
        JOIN   plan_volumen p ON p.guia = a.numero_guia
        WHERE  a.id_asignacion >= v_a_ini AND a.id_asignacion < v_a AND p.escenario IN (p_e1, p_e2, p_e3);
        v_nov := v_nov + SQL%ROWCOUNT;

        UPDATE asignacion_despacho a SET resultado = 'NOVEDAD'
        WHERE  a.id_asignacion >= v_a_ini AND a.id_asignacion < v_a
        AND    a.numero_guia IN (SELECT guia FROM plan_volumen WHERE escenario IN (p_e1, p_e2, p_e3));

        INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion)
        SELECT a.numero_guia, 7, d.id_mensajero, a.hora_visita + INTERVAL '1' MINUTE, 'Novedad en el intento ' || p_int
        FROM   asignacion_despacho a
        JOIN   plan_volumen p ON p.guia = a.numero_guia
        JOIN   despacho d     ON d.id_despacho = a.id_despacho
        WHERE  a.id_asignacion >= v_a_ini AND a.id_asignacion < v_a AND p.escenario IN (p_e1, p_e2, p_e3);
    END registrar_novedad;
BEGIN
    DBMS_RANDOM.SEED(2026);

    -- numero de lotes (dias habiles, lunes a sabado)
    v_dia := c_inicio;
    WHILE v_dia <= c_fin LOOP
        IF v_dia - TRUNC(v_dia, 'IW') <> 6 THEN v_lotes := v_lotes + 1; END IF;
        v_dia := v_dia + 1;
    END LOOP;
    v_total := v_lotes * c_envios_dia;
    DBMS_OUTPUT.PUT_LINE('VOLUMEN|lotes|' || v_lotes);
    DBMS_OUTPUT.PUT_LINE('VOLUMEN|envios_por_dia|' || c_envios_dia);

    -- bases de las claves explicitas
    SELECT NVL(MAX(TO_NUMBER(SUBSTR(numero_guia, 3))), 0) INTO v_guia0 FROM envio WHERE REGEXP_LIKE(numero_guia, '^EE[0-9]{13}$');
    SELECT NVL(MAX(id_cliente), 0) + 1 INTO v_c0 FROM cliente;
    SELECT NVL(MAX(id_sede), 0) + 1 INTO v_s0 FROM sede_cliente;
    SELECT NVL(MAX(id_empleado), 0) + 1 INTO v_emp0 FROM empleado;
    SELECT NVL(MAX(id_vehiculo), 0) + 1 INTO v_veh0 FROM vehiculo;
    SELECT NVL(MAX(id_destinatario), 0) + 1 INTO v_dest0 FROM destinatario;
    SELECT NVL(MAX(id_solicitud), 0) + 1 INTO v_sol FROM solicitud_recoleccion;
    SELECT NVL(MAX(id_despacho), 0) + 1 INTO v_d1 FROM despacho;
    SELECT NVL(MAX(id_asignacion), 0) + 1 INTO v_a FROM asignacion_despacho;
    SELECT NVL(MAX(id_novedad), 0) + 1 INTO v_nov FROM novedad;
    SELECT NVL(MAX(id_prueba), 0) + 1 INTO v_pru FROM prueba_entrega;
    SELECT NVL(MAX(id_reclamacion), 0) + 1 INTO v_rec FROM reclamacion;

    -- referencia de volumen: 30 clientes con 2 sedes, 25 mensajeros con su vehiculo
    INSERT INTO cliente (id_cliente, nit, razon_social, tipo_cliente, telefono, correo, fecha_vinculacion, estado)
    SELECT v_c0 + LEVEL - 1, '8' || LPAD(v_c0 + LEVEL - 1, 8, '0'), 'Cliente de volumen ' || LEVEL,
           CASE MOD(LEVEL, 3) WHEN 0 THEN 'DROGUERIA' WHEN 1 THEN 'OFICINA' ELSE 'TIENDA_LINEA' END,
           '601' || LPAD(5560000 + LEVEL, 7, '0'), 'cliente' || LEVEL || '@volumen.example.com', DATE '2026-02-01', 'ACTIVO'
    FROM dual CONNECT BY LEVEL <= 30;
    INSERT INTO sede_cliente (id_sede, id_cliente, id_zona, nombre, direccion, contacto, telefono)
    SELECT v_s0 + LEVEL - 1, v_c0 + CEIL(LEVEL / 2) - 1, 1 + MOD(LEVEL, 5), 'Sede ' || LEVEL,
           'Calle ' || (10 + LEVEL) || ' # ' || (5 + LEVEL) || '-20', 'Contacto ' || LEVEL, '310' || LPAD(1000000 + LEVEL, 7, '0')
    FROM dual CONNECT BY LEVEL <= 60;
    INSERT INTO empleado (id_empleado, id_centro, documento, nombres, apellidos, cargo, telefono, fecha_ingreso, estado)
    SELECT v_emp0 + LEVEL - 1, 1 + MOD(LEVEL, 2), '7' || LPAD(v_emp0 + LEVEL - 1, 9, '0'), 'Mensajero' || LEVEL, 'De volumen',
           'Mensajero', '320' || LPAD(2000000 + LEVEL, 7, '0'), DATE '2026-01-05', 'ACTIVO'
    FROM dual CONNECT BY LEVEL <= c_mens;
    INSERT INTO mensajero (id_empleado, id_zona, id_tipo_vehiculo)
    SELECT v_emp0 + LEVEL - 1, 1 + MOD(LEVEL, 5), CASE WHEN LEVEL <= 22 THEN 1 ELSE 2 END
    FROM dual CONNECT BY LEVEL <= c_mens;
    INSERT INTO vehiculo (id_vehiculo, id_centro, id_tipo_vehiculo, placa, marca, modelo, capacidad_kg, electrico, estado)
    SELECT v_veh0 + LEVEL - 1, 1 + MOD(LEVEL, 2), CASE WHEN LEVEL <= 22 THEN 1 ELSE 2 END, 'V' || LPAD(LEVEL, 5, '0'),
           CASE WHEN LEVEL <= 22 THEN 'Honda' ELSE 'Renault' END, CASE WHEN LEVEL <= 22 THEN 'CB 125F' ELSE 'Kangoo' END,
           CASE WHEN LEVEL <= 22 THEN 40 ELSE 650 END, 'N', 'DISPONIBLE'
    FROM dual CONNECT BY LEVEL <= c_mens;

    -- reserva de destinatarios: 60 % nuevos (3 de cada 5 envios) y el resto reutiliza uno existente
    v_pool := 3 * CEIL(v_total / 5) + 10;
    INSERT INTO destinatario (id_destinatario, tipo_documento, numero_documento, nombre, telefono, correo)
    SELECT v_dest0 + LEVEL - 1, 'CC', 'V' || LPAD(v_dest0 + LEVEL - 1, 10, '0'), 'Destinatario ' || (v_dest0 + LEVEL - 1),
           '315' || LPAD(MOD(v_dest0 + LEVEL - 1, 10000000), 7, '0'), NULL
    FROM dual CONNECT BY LEVEL <= v_pool;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('VOLUMEN|destinatarios_reservados|' || v_pool);

    v_dia := c_inicio;
    WHILE v_dia <= c_fin LOOP
        IF v_dia - TRUNC(v_dia, 'IW') <> 6 THEN
            v_lote := v_lote + 1;
            v_inicio_lote := SYSTIMESTAMP;
            v_nsol := CEIL(c_envios_dia / 6);
            v_d2 := v_d1 + 8;                       -- 8 despachos de recoleccion, luego 36 de entrega

            -- dias del lote: o = 0 a 5 dias habiles despues del registro
            DELETE FROM dias_volumen;
            INSERT INTO dias_volumen (o, f)
            SELECT LEVEL - 1, pkg_calendario.fecha_compromiso(v_dia, LEVEL) FROM dual CONNECT BY LEVEL <= 6;

            -- despachos de recoleccion (cerrados) y de entrega (armados; se cierran al final)
            INSERT INTO despacho (id_despacho, id_centro, id_vehiculo, id_mensajero, fecha, tipo, hora_salida, hora_cierre, estado)
            SELECT v_d1 + LEVEL - 1, 1, v_veh0 + MOD(LEVEL + v_lote, c_mens), v_emp0 + MOD(LEVEL + v_lote, c_mens), v_dia, 'RECOLECCION',
                   CAST(v_dia AS TIMESTAMP) + INTERVAL '7' HOUR + INTERVAL '30' MINUTE,
                   CAST(v_dia AS TIMESTAMP) + INTERVAL '12' HOUR, 'CERRADO'
            FROM dual CONNECT BY LEVEL <= 8;
            INSERT INTO despacho (id_despacho, id_centro, id_vehiculo, id_mensajero, fecha, tipo, hora_salida, estado)
            SELECT v_d2 + x.idx, 1, v_veh0 + MOD(x.idx * 5 + v_lote, c_mens), v_emp0 + MOD(x.idx * 5 + v_lote, c_mens),
                   dv.f, 'ENTREGA',
                   CAST(dv.f AS TIMESTAMP) + CASE WHEN dv.o = 0 THEN INTERVAL '13' HOUR + INTERVAL '30' MINUTE
                                                  ELSE INTERVAL '8' HOUR + INTERVAL '30' MINUTE END,
                   'ARMADO'
            FROM (SELECT LEVEL - 1 AS idx FROM dual CONNECT BY LEVEL <= 36) x
            JOIN dias_volumen dv ON dv.o = FLOOR(x.idx / 6);

            -- solicitudes del lote
            INSERT INTO solicitud_recoleccion (id_solicitud, id_sede, id_despacho, fecha_solicitud, fecha_programada, franja_horaria, estado)
            SELECT v_sol + LEVEL - 1, v_s0 + MOD(LEVEL * 7 + v_lote, 60), v_d1 + MOD(LEVEL - 1, 8), v_dia, v_dia,
                   CASE WHEN MOD(LEVEL, 2) = 0 THEN 'MANANA' ELSE 'TARDE' END, 'ATENDIDA'
            FROM dual CONNECT BY LEVEL <= v_nsol;

            -- plan del lote: una fila por envio con su escenario y destino
            DELETE FROM plan_volumen;
            INSERT INTO plan_volumen (n, guia, id_solicitud, id_destinatario, id_zona, id_modalidad, escenario, off1, fragil, alto, peso)
            SELECT k, 'EE' || LPAD(v_guia0 + lv, 13, '0'), v_sol + FLOOR((lv - 1) / 6),
                   v_dest0 + CASE WHEN MOD(k, 5) < 3 THEN 3 * FLOOR(k / 5) + MOD(k, 5)
                                  ELSE MOD(k * 7919, 3 * FLOOR(k / 5) + 3) END,
                   TRUNC(DBMS_RANDOM.VALUE(1, 6)),
                   m,
                   CASE WHEN u < 880 THEN 1 WHEN u < 960 THEN 2 WHEN u < 975 THEN 3 WHEN u < 990 THEN 4 ELSE 5 END,
                   CASE m WHEN 1 THEN CASE WHEN h < 900 THEN 0 ELSE 1 END
                          WHEN 2 THEN CASE WHEN h < 920 THEN 1 ELSE 2 END
                          ELSE CASE WHEN h < 600 THEN 1 WHEN h < 950 THEN 2 ELSE 3 END END,
                   CASE WHEN MOD(k * 17, 100) < 8 THEN 'S' ELSE 'N' END,
                   CASE WHEN MOD(k * 29, 100) < 5 THEN 'S' ELSE 'N' END,
                   ROUND(DBMS_RANDOM.VALUE(0.5, 12), 2)
            FROM (SELECT lv, k, u, h, CASE WHEN r < 0.2 THEN 1 WHEN r < 0.5 THEN 2 ELSE 3 END AS m
                  FROM (SELECT LEVEL AS lv, v_k + LEVEL AS k, MOD((v_k + LEVEL) * 6007 + 13, 1000) AS u,
                               MOD((v_k + LEVEL) * 13007 + 5, 1000) AS h, DBMS_RANDOM.VALUE AS r
                        FROM dual CONNECT BY LEVEL <= c_envios_dia));

            -- envios
            INSERT INTO envio (numero_guia, id_solicitud, id_destinatario, id_zona, id_modalidad, fecha_registro, direccion_destino,
                               peso_declarado, peso_real, contenido, valor_declarado, fragil, alto_valor, valor_flete, fecha_compromiso)
            SELECT p.guia, p.id_solicitud, p.id_destinatario, p.id_zona, p.id_modalidad, v_dia,
                   'Carrera ' || (1 + MOD(p.n, 150)) || ' # ' || (1 + MOD(p.n * 3, 99)) || '-' || (1 + MOD(p.n * 7, 90)),
                   p.peso, CASE WHEN p.escenario = 4 THEN NULL ELSE p.peso + 0.1 END,
                   CASE MOD(p.n, 6) WHEN 0 THEN 'Documentos' WHEN 1 THEN 'Medicamentos' WHEN 2 THEN 'Ropa'
                                    WHEN 3 THEN 'Electronicos' WHEN 4 THEN 'Libros' ELSE 'Repuestos' END,
                   CASE WHEN p.alto = 'S' THEN ROUND(DBMS_RANDOM.VALUE(3000000, 8000000), 2) ELSE ROUND(DBMS_RANDOM.VALUE(10000, 400000), 2) END,
                   p.fragil, p.alto,
                   CASE WHEN p.escenario = 4 THEN NULL ELSE ROUND(4500 + 1800 * p.peso, 2) END,
                   (SELECT dv.f FROM dias_volumen dv WHERE dv.o = p.id_modalidad - 1)
            FROM plan_volumen p;

            -- eventos hasta CLASIFICADO (y REGISTRADO y ANULADO para los anulados)
            INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora, observacion)
            SELECT p.guia,
                   CASE ph.fase WHEN 1 THEN 1 WHEN 2 THEN 2 WHEN 3 THEN 3 WHEN 4 THEN 4 ELSE 9 END,
                   CASE ph.fase WHEN 1 THEN 4 + MOD(p.n, 2) WHEN 2 THEN v_emp0 + MOD(p.n, c_mens) WHEN 5 THEN 4 + MOD(p.n, 2)
                                ELSE 2 + MOD(p.n, 2) END,
                   CAST(v_dia AS TIMESTAMP) + NUMTODSINTERVAL(
                       CASE WHEN p.id_modalidad = 1 THEN 420 + MOD(p.n * 7, 60) ELSE 480 + MOD(p.n * 7, 240) END
                       + CASE ph.fase WHEN 1 THEN 0
                                      WHEN 2 THEN CASE WHEN p.id_modalidad = 1 THEN 30 ELSE 60 END
                                      WHEN 3 THEN CASE WHEN p.id_modalidad = 1 THEN 120 ELSE 240 END
                                      WHEN 4 THEN CASE WHEN p.id_modalidad = 1 THEN 180 ELSE 300 END
                                      ELSE 45 END, 'MINUTE'),
                   CASE ph.fase WHEN 1 THEN 'Envio registrado' WHEN 2 THEN 'Recogido en la sede del cliente'
                                WHEN 3 THEN 'Recibido en el centro' WHEN 4 THEN 'Clasificado por zona'
                                ELSE 'Anulado a solicitud del cliente' END
            FROM plan_volumen p
            CROSS JOIN (SELECT LEVEL AS fase FROM dual CONNECT BY LEVEL <= 5) ph
            WHERE (p.escenario <> 4 AND ph.fase <= 4) OR (p.escenario = 4 AND ph.fase IN (1, 5));

            -- intento 1: todos menos los anulados
            asignar(1, 1, 5);
            en_ruta;
            cerrar_con_prueba(1, 1, 'ENTREGADO', 6);
            registrar_novedad(1, 2, 3, 5);
            -- intento 2: escenarios 2 (entrega) y 3 (otra novedad)
            asignar(2, 2, 3);
            en_ruta;
            cerrar_con_prueba(2, 2, 'ENTREGADO', 6);
            registrar_novedad(2, 3, NULL, NULL);
            -- intento 3: devolucion (escenario 3)
            asignar(3, 3, 3);
            en_ruta;
            cerrar_con_prueba(3, 3, 'DEVUELTO', 8);

            -- reclamaciones (~1 % de los envios no anulados): 60 % respondidas, 30 % cerradas, 10 % abiertas
            INSERT INTO reclamacion (id_reclamacion, id_cliente, numero_guia, fecha_radicacion, tipo, descripcion, respuesta, fecha_respuesta, estado)
            SELECT v_rec + ROW_NUMBER() OVER (ORDER BY p.n), sd.id_cliente, p.guia,
                   CAST(dv.f AS TIMESTAMP) + NUMTODSINTERVAL(900 + MOD(p.n, 120), 'MINUTE'),
                   CASE MOD(FLOOR(p.n / 100), 4) WHEN 0 THEN 'DANO' WHEN 1 THEN 'ENTREGA' WHEN 2 THEN 'FACTURACION' ELSE 'OTRO' END,
                   'Reclamacion de la guia ' || p.guia,
                   CASE WHEN MOD(FLOOR(p.n / 100), 10) < 9 THEN 'Respuesta de la mesa de servicio' END,
                   CASE WHEN MOD(FLOOR(p.n / 100), 10) < 6 THEN CAST(dv.f AS TIMESTAMP) + NUMTODSINTERVAL(900 + MOD(p.n, 120) + 60 * (1 + MOD(p.n, 9)), 'MINUTE')
                        WHEN MOD(FLOOR(p.n / 100), 10) < 9 THEN CAST(dv.f AS TIMESTAMP) + NUMTODSINTERVAL(900 + MOD(p.n, 120) + 60 * 30, 'MINUTE') END,
                   CASE WHEN MOD(FLOOR(p.n / 100), 10) < 6 THEN 'RESPONDIDA' WHEN MOD(FLOOR(p.n / 100), 10) < 9 THEN 'CERRADA' ELSE 'ABIERTA' END
            FROM   plan_volumen p
            JOIN   dias_volumen dv          ON dv.o = p.off1
            JOIN   solicitud_recoleccion sr ON sr.id_solicitud = p.id_solicitud
            JOIN   sede_cliente sd          ON sd.id_sede = sr.id_sede
            WHERE  p.escenario <> 4 AND MOD(p.n, 100) = 7;
            v_rec := v_rec + SQL%ROWCOUNT;

            -- cierre de los despachos de entrega del lote
            UPDATE despacho SET estado = 'CERRADO', hora_cierre = hora_salida + INTERVAL '9' HOUR
            WHERE  id_despacho BETWEEN v_d2 AND v_d2 + 35;

            COMMIT;
            v_sol := v_sol + v_nsol;
            v_d1  := v_d2 + 36;
            v_guia0 := v_guia0 + c_envios_dia;
            v_k := v_k + c_envios_dia;
            IF MOD(v_lote, 10) = 0 OR v_lote = v_lotes THEN
                DBMS_OUTPUT.PUT_LINE('VOLUMEN|lote ' || v_lote || ' de ' || v_lotes || ' (' || TO_CHAR(v_dia, 'YYYY-MM-DD')
                    || ')|' || segundos(v_inicio_lote) || ' s el lote, ' || segundos(v_inicio_total) || ' s acumulados');
            END IF;
        END IF;
        v_dia := v_dia + 1;
    END LOOP;

    DBMS_OUTPUT.PUT_LINE('VOLUMEN|envios_generados|' || v_k);
    DBMS_OUTPUT.PUT_LINE('VOLUMEN|tiempo_carga_segundos|' || segundos(v_inicio_total));
    v_seg := segundos(v_inicio_total);
END;
/

TRUNCATE TABLE plan_volumen;
TRUNCATE TABLE dias_volumen;
DROP TABLE plan_volumen;
DROP TABLE dias_volumen;

-- estadisticas del esquema para el optimizador
BEGIN
    DBMS_STATS.GATHER_SCHEMA_STATS(ownname => USER, cascade => TRUE);
END;
/
PROMPT VOLUMEN|estadisticas_recogidas|ok
SET FEEDBACK ON
