package co.enlaceexpress.presentacion.api;

import java.time.Clock;
import java.util.ArrayDeque;
import java.util.Deque;
import java.util.HashMap;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import co.enlaceexpress.configuracion.PropiedadesRastreo;

/**
 * Limite de consultas por direccion IP en una ventana deslizante de un minuto, en memoria (las guias son
 * consecutivas y se podrian recorrer, decision D2). Una sola instancia de la aplicacion: si hubiera varias
 * habria que moverlo a un almacen compartido.
 */
@Component
public class LimitadorDeConsultas {

    private static final long VENTANA_MS = 60_000;
    private static final int LIMITE_DE_IPS = 50_000;

    private final int limite;
    private final Clock reloj;
    private final Map<String, Deque<Long>> consultas = new HashMap<>();

    @Autowired
    public LimitadorDeConsultas(PropiedadesRastreo propiedades) {
        this(propiedades.limitePorMinuto(), Clock.systemUTC());
    }

    LimitadorDeConsultas(int limite, Clock reloj) {
        this.limite = limite;
        this.reloj = reloj;
    }

    /** Anota la consulta y devuelve 0 si se permite; si no, los segundos que faltan para poder consultar de nuevo. */
    public synchronized long intentar(String ip) {
        long ahora = reloj.millis();
        if (consultas.size() > LIMITE_DE_IPS) {
            consultas.values().removeIf(d -> d.isEmpty() || ahora - d.peekLast() >= VENTANA_MS);
        }
        Deque<Long> instantes = consultas.computeIfAbsent(ip, k -> new ArrayDeque<>());
        while (!instantes.isEmpty() && ahora - instantes.peekFirst() >= VENTANA_MS) {
            instantes.pollFirst();
        }
        if (instantes.size() >= limite) {
            long espera = VENTANA_MS - (ahora - instantes.peekFirst());
            return Math.max(1, (espera + 999) / 1000);
        }
        instantes.addLast(ahora);
        return 0;
    }
}
