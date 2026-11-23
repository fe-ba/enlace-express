-- Pruebas de las reglas de negocio: para cada regla, un caso valido y casos
-- que deben fallar con el codigo esperado. Se ejecuta como BD_ENLACE_EXPRESS
-- sobre una base recien instalada y termina con ROLLBACK (no deja datos).
-- Uso: database/run.sh propietario tests/02_pruebas_reglas.sql
-- Cada linea es "OK" o "FALLA"; al final se imprime el total.
-- Las guias de prueba usan el prefijo ZZ para no chocar con la secuencia (EE...).
WHENEVER SQLERROR EXIT FAILURE
SET DEFINE OFF
SET LINESIZE 250
SET SERVEROUTPUT ON SIZE UNLIMITED FORMAT TRUNCATED

-- La secuencia de guias no se revierte con ROLLBACK: se guarda su valor y se restaura al final.
VARIABLE v_sec NUMBER
BEGIN
    :v_sec := seq_numero_guia.NEXTVAL;
END;
/

DECLARE
    v_ok      PLS_INTEGER := 0;
    v_falla   PLS_INTEGER := 0;
    v_t       PLS_INTEGER := 0;    -- minutos acumulados para fechas de eventos distintas
    v_guia    VARCHAR2(15);
    v_n1      NUMBER;
    v_n2      NUMBER;
    v_n3      NUMBER;
    v_fecha   DATE;

    FUNCTION g(p_n IN NUMBER) RETURN VARCHAR2 IS
    BEGIN
        RETURN 'ZZ' || LPAD(p_n, 13, '0');
    END g;

    PROCEDURE registrar(p_ok IN BOOLEAN, p_linea IN VARCHAR2) IS
    BEGIN
        IF p_ok THEN
            v_ok := v_ok + 1;
            DBMS_OUTPUT.PUT_LINE('OK   ' || p_linea);
        ELSE
            v_falla := v_falla + 1;
            DBMS_OUTPUT.PUT_LINE('FALLA ' || p_linea);
        END IF;
    END registrar;

    -- p_esperado: 0 = debe pasar; otro valor = SQLCODE esperado
    PROCEDURE caso(p_regla IN VARCHAR2, p_desc IN VARCHAR2, p_esperado IN NUMBER, p_sql IN VARCHAR2) IS
        v_cod NUMBER := 0;
        v_msg VARCHAR2(500);
        v_bien BOOLEAN;
        v_prefijo VARCHAR2(40);
    BEGIN
        BEGIN
            EXECUTE IMMEDIATE p_sql;
        EXCEPTION
            WHEN OTHERS THEN
                v_cod := SQLCODE;
                v_msg := SUBSTR(SQLERRM, 1, 160);
        END;
        v_bien := (v_cod = p_esperado);
        IF v_bien AND p_esperado BETWEEN -20099 AND -20000 THEN
            -- el mensaje debe empezar con el codigo de la regla
            v_prefijo := 'ORA-' || TO_CHAR(ABS(p_esperado)) || ': RN' || TO_CHAR(ABS(p_esperado) - 20000, 'FM00');
            v_bien := INSTR(v_msg, v_prefijo) = 1;
        END IF;
        registrar(v_bien,
            RPAD(p_regla, 5) || p_desc || ' -> '
            || CASE WHEN v_cod = 0 THEN 'sin error'
                    ELSE 'ORA' || TO_CHAR(v_cod, 'FM00000') || CASE WHEN v_bien THEN '' ELSE ' (esperado ' || p_esperado || '): ' || v_msg END END);
    END caso;

    PROCEDURE cal(p_desc IN VARCHAR2, p_registro IN DATE, p_plazo IN NUMBER, p_esperado IN DATE) IS
        v_obt DATE := pkg_calendario.fecha_compromiso(p_registro, p_plazo);
    BEGIN
        registrar(v_obt = p_esperado, 'RN02 ' || p_desc || ' (' || TO_CHAR(p_registro, 'YYYY-MM-DD') || ' -> '
                  || TO_CHAR(v_obt, 'YYYY-MM-DD') || ')');
    END cal;

    PROCEDURE ejecutar(p_sql IN VARCHAR2) IS
    BEGIN
        EXECUTE IMMEDIATE p_sql;
    END ejecutar;

    PROCEDURE envio_nuevo(p_n IN NUMBER, p_fragil IN VARCHAR2 DEFAULT 'N',
                          p_alto IN VARCHAR2 DEFAULT 'N') IS
        v_g    VARCHAR2(15) := g(p_n);
        v_dest destinatario.id_destinatario%TYPE;
    BEGIN
        SELECT id_destinatario INTO v_dest FROM destinatario WHERE numero_documento = '1000';
        INSERT INTO envio (numero_guia, id_solicitud, id_destinatario, id_zona, id_modalidad,
                           fecha_registro, direccion_destino, peso_declarado, contenido,
                           valor_declarado, fragil, alto_valor, fecha_compromiso)
        VALUES (v_g, 9001, v_dest, 9001, 3, TRUNC(SYSDATE), 'Calle ' || p_n, 1, 'Prueba', 1000,
                p_fragil, p_alto, TRUNC(SYSDATE) + 3);
    END envio_nuevo;

    -- INSERT de un evento con un instante nuevo (siempre creciente)
    FUNCTION ev(p_n IN NUMBER, p_estado IN VARCHAR2) RETURN VARCHAR2 IS
    BEGIN
        v_t := v_t + 1;
        RETURN 'INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora) VALUES ('''
            || g(p_n) || ''', (SELECT id_estado FROM estado_envio WHERE nombre = ''' || p_estado
            || '''), 9003, TIMESTAMP ''2026-01-01 00:00:00'' + NUMTODSINTERVAL(' || v_t || ', ''MINUTE''))';
    END ev;

    FUNCTION asig(p_id IN NUMBER, p_n IN NUMBER, p_despacho IN NUMBER, p_intento IN NUMBER,
                  p_resultado IN VARCHAR2 DEFAULT 'PENDIENTE') RETURN VARCHAR2 IS
    BEGIN
        RETURN 'INSERT INTO asignacion_despacho (id_asignacion, numero_guia, id_despacho, numero_intento, orden_visita, resultado) VALUES ('
            || (9000 + p_id) || ', ''' || g(p_n) || ''', ' || (9000 + p_despacho) || ', ' || p_intento || ', ' || p_id || ', ''' || p_resultado || ''')';
    END asig;

    FUNCTION prueba(p_asig IN NUMBER, p_doc IN VARCHAR2) RETURN VARCHAR2 IS
    BEGIN
        RETURN 'INSERT INTO prueba_entrega (id_asignacion, fecha_hora, nombre_receptor, documento_receptor, tipo_prueba) VALUES ('
            || (9000 + p_asig) || ', LOCALTIMESTAMP, ''Receptor'', ''' || p_doc || ''', ''DOCUMENTO'')';
    END prueba;

    FUNCTION novedad(p_id IN NUMBER, p_asig IN NUMBER) RETURN VARCHAR2 IS
    BEGIN
        RETURN 'INSERT INTO novedad (id_novedad, id_asignacion, tipo_novedad, descripcion) VALUES ('
            || (9000 + p_id) || ', ' || (9000 + p_asig) || ', ''DESTINATARIO_AUSENTE'', ''Nadie atendio'')';
    END novedad;

    FUNCTION resultado(p_asig IN NUMBER, p_res IN VARCHAR2) RETURN VARCHAR2 IS
    BEGIN
        RETURN 'UPDATE asignacion_despacho SET resultado = ''' || p_res || ''' WHERE id_asignacion = ' || (9000 + p_asig);
    END resultado;
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Datos base (claves 9001 en adelante; catalogos de seed) ---');
    INSERT INTO centro_distribucion (id_centro, nombre, direccion) VALUES (9001, 'Centro de pruebas', 'Calle 100');
    INSERT INTO zona (id_zona, id_centro, nombre, localidades) VALUES (9001, 9001, 'Zona de pruebas', 'Suba');
    INSERT INTO cliente (id_cliente, nit, razon_social, tipo_cliente, telefono, correo, fecha_vinculacion, estado)
        VALUES (9001, '9009001', 'Cliente Activo', 'DROGUERIA', '3001', 'a@example.com', DATE '2026-01-10', 'ACTIVO');
    INSERT INTO cliente (id_cliente, nit, razon_social, tipo_cliente, telefono, correo, fecha_vinculacion, estado)
        VALUES (9002, '9009002', 'Cliente Inactivo', 'OFICINA', '3002', 'b@example.com', DATE '2026-01-10', 'INACTIVO');
    INSERT INTO sede_cliente (id_sede, id_cliente, id_zona, nombre, direccion, contacto, telefono)
        VALUES (9001, 9001, 9001, 'Sede activo', 'Carrera 7', 'Marta', '3001');
    INSERT INTO sede_cliente (id_sede, id_cliente, id_zona, nombre, direccion, contacto, telefono)
        VALUES (9002, 9002, 9001, 'Sede inactivo', 'Carrera 8', 'Pedro', '3002');
    -- vehiculos: tipo 1 (motocicleta) y 2 (furgoneta) del catalogo
    INSERT INTO vehiculo (id_vehiculo, id_centro, id_tipo_vehiculo, placa, marca, modelo, capacidad_kg, electrico, estado)
        VALUES (9001, 9001, 1, 'PRB001', 'Honda', 'CB125', 30, 'N', 'DISPONIBLE');
    INSERT INTO vehiculo (id_vehiculo, id_centro, id_tipo_vehiculo, placa, marca, modelo, capacidad_kg, electrico, estado)
        VALUES (9002, 9001, 1, 'PRB002', 'Honda', 'CB125', 30, 'N', 'EN_MANTENIMIENTO');
    INSERT INTO vehiculo (id_vehiculo, id_centro, id_tipo_vehiculo, placa, marca, modelo, capacidad_kg, electrico, estado)
        VALUES (9003, 9001, 2, 'PRB003', 'Renault', 'Kangoo', 600, 'N', 'DISPONIBLE');
    INSERT INTO empleado (id_empleado, id_centro, documento, nombres, apellidos, cargo, telefono, fecha_ingreso, estado)
        VALUES (9001, 9001, '90010', 'Carlos', 'Peña', 'Mensajero', '3101', DATE '2026-01-05', 'ACTIVO');
    INSERT INTO empleado (id_empleado, id_centro, documento, nombres, apellidos, cargo, telefono, fecha_ingreso, estado)
        VALUES (9002, 9001, '90020', 'Luis', 'Ríos', 'Mensajero', '3102', DATE '2026-01-05', 'RETIRADO');
    INSERT INTO empleado (id_empleado, id_centro, documento, nombres, apellidos, cargo, telefono, fecha_ingreso, estado)
        VALUES (9003, 9001, '90030', 'Ana', 'Gómez', 'Operaria', '3103', DATE '2026-01-05', 'ACTIVO');
    INSERT INTO mensajero (id_empleado, id_zona, id_tipo_vehiculo) VALUES (9001, 9001, 1);
    INSERT INTO mensajero (id_empleado, id_zona, id_tipo_vehiculo) VALUES (9002, 9001, 1);
    -- sin id: la identidad lo genera (el procedimiento de registro tambien la usa)
    INSERT INTO destinatario (tipo_documento, numero_documento, nombre, telefono)
        VALUES ('CC', '1000', 'Luis Pérez', '3153334444');

    DBMS_OUTPUT.PUT_LINE('--- RN15: solicitud de cliente activo ---');
    caso('RN15', 'solicitud de cliente ACTIVO', 0, q'~INSERT INTO solicitud_recoleccion (id_solicitud, id_sede, fecha_solicitud, fecha_programada, franja_horaria) VALUES (9001, 9001, TRUNC(SYSDATE), TRUNC(SYSDATE), 'MANANA')~');
    caso('RN15', 'solicitud de cliente INACTIVO', -20015, q'~INSERT INTO solicitud_recoleccion (id_solicitud, id_sede, fecha_solicitud, fecha_programada, franja_horaria) VALUES (9002, 9002, TRUNC(SYSDATE), TRUNC(SYSDATE), 'MANANA')~');

    DBMS_OUTPUT.PUT_LINE('--- RN10 y RN11: despacho ---');
    caso('RN10', 'despacho con vehiculo DISPONIBLE y mensajero ACTIVO', 0, q'~INSERT INTO despacho (id_despacho, id_centro, id_vehiculo, id_mensajero, fecha, tipo) VALUES (9001, 9001, 9001, 9001, TRUNC(SYSDATE), 'ENTREGA')~');
    caso('RN10', 'vehiculo EN_MANTENIMIENTO', -20010, q'~INSERT INTO despacho (id_despacho, id_centro, id_vehiculo, id_mensajero, fecha, tipo) VALUES (9090, 9001, 9002, 9001, TRUNC(SYSDATE), 'ENTREGA')~');
    caso('RN10', 'mensajero RETIRADO', -20010, q'~INSERT INTO despacho (id_despacho, id_centro, id_vehiculo, id_mensajero, fecha, tipo) VALUES (9091, 9001, 9001, 9002, TRUNC(SYSDATE), 'ENTREGA')~');
    caso('RN10', 'UPDATE a vehiculo EN_MANTENIMIENTO', -20010, 'UPDATE despacho SET id_vehiculo = 9002 WHERE id_despacho = 9001');
    caso('RN11', 'vehiculo de otro tipo que el del mensajero', -20011, q'~INSERT INTO despacho (id_despacho, id_centro, id_vehiculo, id_mensajero, fecha, tipo) VALUES (9092, 9001, 9003, 9001, TRUNC(SYSDATE), 'ENTREGA')~');
    caso('RN11', 'UPDATE a vehiculo de otro tipo', -20011, 'UPDATE despacho SET id_vehiculo = 9003 WHERE id_despacho = 9001');
    ejecutar(q'~INSERT INTO despacho (id_despacho, id_centro, id_vehiculo, id_mensajero, fecha, tipo, estado) VALUES (9002, 9001, 9001, 9001, TRUNC(SYSDATE), 'ENTREGA', 'CERRADO')~');
    ejecutar(q'~INSERT INTO despacho (id_despacho, id_centro, id_vehiculo, id_mensajero, fecha, tipo) VALUES (9003, 9001, 9001, 9001, TRUNC(SYSDATE), 'RECOLECCION')~');
    ejecutar(q'~INSERT INTO despacho (id_despacho, id_centro, id_vehiculo, id_mensajero, fecha, tipo) VALUES (9004, 9001, 9001, 9001, TRUNC(SYSDATE), 'ENTREGA')~');
    ejecutar(q'~INSERT INTO despacho (id_despacho, id_centro, id_vehiculo, id_mensajero, fecha, tipo) VALUES (9005, 9001, 9001, 9001, TRUNC(SYSDATE), 'ENTREGA')~');

    DBMS_OUTPUT.PUT_LINE('--- RN02 y RN04: procedimiento de registro ---');
    caso('RN02', 'registro sin nombre del destinatario', -20002,
         q'~DECLARE v VARCHAR2(15); BEGIN pr_registrar_envio(9001,'CC','3000',NULL,'300',NULL,9001,3,'Calle 5',1.5,'Libros',100,NULL,NULL,NULL,9003,v); END;~');
    caso('RN02', 'registro sin peso', -20002,
         q'~DECLARE v VARCHAR2(15); BEGIN pr_registrar_envio(9001,'CC','3000','Nuevo','300',NULL,9001,3,'Calle 5',NULL,'Libros',100,NULL,NULL,NULL,9003,v); END;~');
    caso('RN02', 'registro sin direccion de destino', -20002,
         q'~DECLARE v VARCHAR2(15); BEGIN pr_registrar_envio(9001,'CC','3000','Nuevo','300',NULL,9001,3,NULL,1.5,'Libros',100,NULL,NULL,NULL,9003,v); END;~');
    SELECT COUNT(*) INTO v_n1 FROM destinatario;
    pr_registrar_envio(9001, 'CC', '3000', 'Nuevo', '300', NULL, 9001, 3, 'Calle 5', 1.5, 'Libros', 100, NULL, NULL, NULL, 9003, v_guia);
    registrar(REGEXP_LIKE(v_guia, '^EE[0-9]{13}$'), 'RN02 registro valido devuelve guia EE + 13 digitos -> ' || v_guia);
    SELECT COUNT(*) INTO v_n2 FROM evento_envio ev JOIN estado_envio es ON es.id_estado = ev.id_estado
     WHERE ev.numero_guia = v_guia AND es.nombre = 'REGISTRADO';
    registrar(v_n2 = 1, 'RN12 el registro crea el evento REGISTRADO (eventos: ' || v_n2 || ')');
    SELECT fecha_compromiso INTO v_fecha FROM envio WHERE numero_guia = v_guia;
    registrar(v_fecha BETWEEN TRUNC(SYSDATE) + 3 AND TRUNC(SYSDATE) + 4 AND v_fecha - TRUNC(v_fecha, 'IW') <> 6,
              'RN02 fecha de compromiso calculada con 3 dias habiles (lunes a sabado) -> ' || TO_CHAR(v_fecha, 'YYYY-MM-DD'));
    SELECT COUNT(*) INTO v_n2 FROM destinatario;
    registrar(v_n2 = v_n1 + 1, 'RN04 destinatario nuevo se crea (' || v_n1 || ' -> ' || v_n2 || ')');
    pr_registrar_envio(9001, 'CC', '3000', 'Otro nombre', '999', NULL, 9001, 3, 'Calle 6', 2, 'Ropa', 200, NULL, NULL, NULL, 9003, v_guia);
    SELECT COUNT(*) INTO v_n1 FROM destinatario;
    SELECT COUNT(*) INTO v_n3 FROM destinatario WHERE numero_documento = '3000' AND nombre = 'Nuevo' AND telefono = '300';
    registrar(v_n1 = v_n2 AND v_n3 = 1,
              'RN04 segundo registro con el mismo documento reutiliza el destinatario sin tocar sus datos (total ' || v_n1 || ')');

    DBMS_OUTPUT.PUT_LINE('--- RN02: fecha de compromiso (el dia del registro es el dia 1; lunes a sabado) ---');
    cal('MISMO_DIA registrado un sabado -> ese sabado', DATE '2026-11-07', 1, DATE '2026-11-07');
    cal('DIA_SIGUIENTE registrado un sabado -> el lunes', DATE '2026-11-07', 2, DATE '2026-11-09');
    cal('ESTANDAR registrado un viernes -> el lunes', DATE '2026-11-06', 3, DATE '2026-11-09');
    cal('MISMO_DIA registrado un domingo -> el lunes', DATE '2026-11-08', 1, DATE '2026-11-09');
    cal('DIA_SIGUIENTE registrado un domingo -> el martes', DATE '2026-11-08', 2, DATE '2026-11-10');
    cal('ESTANDAR registrado un martes -> el jueves', DATE '2026-11-03', 3, DATE '2026-11-05');
    cal('ESTANDAR registrado un sabado -> el martes', DATE '2026-11-07', 3, DATE '2026-11-10');

    DBMS_OUTPUT.PUT_LINE('--- RN07, RN08, RN05, RN12: guia 1, de la solicitud a la devolucion ---');
    envio_nuevo(1);
    ejecutar(ev(1, 'REGISTRADO'));
    ejecutar(ev(1, 'RECOLECTADO'));
    v_t := v_t + 10;
    caso('RN12', 'INSERT ... SELECT con EN_CENTRO y CLASIFICADO (instantes distintos)', 0,
         'INSERT INTO evento_envio (numero_guia, id_estado, id_empleado, fecha_hora) SELECT ''' || g(1)
         || ''', id_estado, 9003, TIMESTAMP ''2026-01-01 00:00:00'' + NUMTODSINTERVAL(' || v_t || ' + id_estado, ''MINUTE'') FROM estado_envio WHERE nombre IN (''EN_CENTRO'', ''CLASIFICADO'')');
    v_t := v_t + 10;
    caso('RN12', 'CLASIFICADO -> EN_RUTA', 0, ev(1, 'EN_RUTA'));
    caso('RN07', 'intento 1 con despacho de ENTREGA abierto', 0, asig(1, 1, 1, 1));
    caso('RN07', 'intento 2 sin que el 1 termine en NOVEDAD (PENDIENTE)', -20007, asig(2, 1, 4, 2));
    caso('RN08', 'resultado NOVEDAD sin novedad registrada', -20008, resultado(1, 'NOVEDAD'));
    ejecutar(novedad(1, 1));
    caso('RN08', 'resultado NOVEDAD con novedad registrada', 0, resultado(1, 'NOVEDAD'));
    caso('RN08', 'segunda novedad del mismo intento (UNIQUE)', -1, novedad(2, 1));
    caso('RN12', 'EN_RUTA -> CON_NOVEDAD', 0, ev(1, 'CON_NOVEDAD'));
    caso('RN12', 'CON_NOVEDAD -> EN_RUTA (reintento)', 0, ev(1, 'EN_RUTA'));
    caso('RN07', 'intento 2 tras NOVEDAD en el 1', 0, asig(2, 1, 4, 2));
    caso('RN07', 'intento 3 sin que el 2 termine en NOVEDAD', -20007, asig(3, 1, 5, 3));
    ejecutar(novedad(2, 2));
    ejecutar(resultado(2, 'NOVEDAD'));
    ejecutar(ev(1, 'CON_NOVEDAD'));
    ejecutar(ev(1, 'EN_RUTA'));
    caso('RN07', 'intento 3 tras dos NOVEDAD (devolucion)', 0, asig(3, 1, 5, 3));
    caso('RN07', 'ENTREGADO en el intento 3', -20007, resultado(3, 'ENTREGADO'));
    caso('RN07', 'NOVEDAD en el intento 3', -20007, resultado(3, 'NOVEDAD'));
    caso('RN05', 'DEVUELTO en el intento 3 sin prueba', -20005, resultado(3, 'DEVUELTO'));
    ejecutar(prueba(3, '5555'));
    caso('RN07', 'DEVUELTO en el intento 3 con prueba', 0, resultado(3, 'DEVUELTO'));
    caso('RN12', 'EN_RUTA -> DEVUELTO tras el tercer intento (flujo completo)', 0, ev(1, 'DEVUELTO'));
    caso('RN12', 'evento despues de DEVUELTO (estado final)', -20012, ev(1, 'EN_RUTA'));

    DBMS_OUTPUT.PUT_LINE('--- RN07: despachos y resultados ---');
    envio_nuevo(2);
    caso('RN07', 'intento 1 en despacho CERRADO', -20007, asig(5, 2, 2, 1));
    caso('RN07', 'intento 1 en despacho de RECOLECCION', -20007, asig(6, 2, 3, 1));
    caso('RN07', 'intento 3 sin intentos anteriores', -20007, asig(4, 2, 5, 3));
    caso('RN05', 'asignacion que nace ENTREGADO', -20005, asig(13, 2, 1, 1, 'ENTREGADO'));
    caso('RN08', 'asignacion que nace NOVEDAD', -20008, asig(14, 2, 1, 1, 'NOVEDAD'));
    ejecutar(asig(7, 2, 1, 1));
    caso('RN07', 'DEVUELTO en el intento 1', -20007, resultado(7, 'DEVUELTO'));

    DBMS_OUTPUT.PUT_LINE('--- RN05: entrega con prueba ---');
    envio_nuevo(3);
    ejecutar(asig(8, 3, 1, 1));
    caso('RN05', 'resultado ENTREGADO sin prueba de entrega', -20005, resultado(8, 'ENTREGADO'));
    caso('RN05', 'prueba de entrega de envio normal', 0, prueba(8, '7777'));
    caso('RN05', 'resultado ENTREGADO con prueba', 0, resultado(8, 'ENTREGADO'));
    caso('RN08', 'segunda prueba del mismo intento (UNIQUE)', -1, prueba(8, '8888'));

    DBMS_OUTPUT.PUT_LINE('--- RN06: documento de quien recibe ---');
    envio_nuevo(4, 'S', 'N');
    envio_nuevo(5, 'N', 'S');
    envio_nuevo(6, 'N', 'N');
    ejecutar(asig(10, 4, 1, 1));
    ejecutar(asig(11, 5, 1, 1));
    ejecutar(asig(12, 6, 1, 1));
    caso('RN06', 'envio fragil con documento distinto al del destinatario', -20006, prueba(10, '9999'));
    caso('RN06', 'envio fragil con el documento del destinatario', 0, prueba(10, '1000'));
    caso('RN06', 'envio de alto valor con documento distinto', -20006, prueba(11, '9999'));
    caso('RN06', 'envio normal con otro documento', 0, prueba(12, '9999'));

    DBMS_OUTPUT.PUT_LINE('--- RN05 y RN12: eventos ---');
    envio_nuevo(7);
    ejecutar(ev(7, 'REGISTRADO'));
    ejecutar(ev(7, 'RECOLECTADO'));
    ejecutar(ev(7, 'EN_CENTRO'));
    ejecutar(ev(7, 'CLASIFICADO'));
    ejecutar(ev(7, 'EN_RUTA'));
    caso('RN05', 'evento ENTREGADO sin asignacion ENTREGADO', -20005, ev(7, 'ENTREGADO'));
    ejecutar(asig(20, 7, 1, 1));
    ejecutar(prueba(20, '4444'));
    ejecutar(resultado(20, 'ENTREGADO'));
    caso('RN05', 'evento ENTREGADO con asignacion ENTREGADO', 0, ev(7, 'ENTREGADO'));
    caso('RN12', 'evento despues de ENTREGADO', -20012, ev(7, 'CON_NOVEDAD'));
    envio_nuevo(8);
    caso('RN12', 'primer evento distinto de REGISTRADO', -20012, ev(8, 'EN_CENTRO'));
    caso('RN12', 'primer evento REGISTRADO', 0, ev(8, 'REGISTRADO'));
    caso('RN12', 'REGISTRADO -> ENTREGADO', -20012, ev(8, 'ENTREGADO'));
    caso('RN12', 'REGISTRADO -> REGISTRADO', -20012, ev(8, 'REGISTRADO'));
    caso('RN12', 'REGISTRADO -> ANULADO', 0, ev(8, 'ANULADO'));
    envio_nuevo(9);
    ejecutar(ev(9, 'REGISTRADO'));
    ejecutar(ev(9, 'RECOLECTADO'));
    ejecutar(ev(9, 'EN_CENTRO'));
    ejecutar(ev(9, 'CLASIFICADO'));
    ejecutar(ev(9, 'EN_RUTA'));
    caso('RN12', 'ANULADO desde EN_RUTA', -20012, ev(9, 'ANULADO'));
    caso('RN12', 'EN_RUTA -> CLASIFICADO (retroceso)', -20012, ev(9, 'CLASIFICADO'));

    DBMS_OUTPUT.PUT_LINE('--- Total ---');
    DBMS_OUTPUT.PUT_LINE(v_ok || ' OK, ' || v_falla || ' FALLA');
END;
/

ROLLBACK;
BEGIN
    EXECUTE IMMEDIATE 'ALTER SEQUENCE seq_numero_guia RESTART START WITH ' || :v_sec;
END;
/
PROMPT Prueba terminada: ROLLBACK ejecutado, sin datos persistentes.
