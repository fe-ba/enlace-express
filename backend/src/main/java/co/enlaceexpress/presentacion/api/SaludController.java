package co.enlaceexpress.presentacion.api;

import java.util.LinkedHashMap;
import java.util.Map;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import co.enlaceexpress.casosdeuso.administracion.ServicioSalud;
import co.enlaceexpress.datos.mapeadores.SaludMapper.EstadoBase;
import co.enlaceexpress.dominio.reglas.ErrorDeDatos;

/** Chequeo de salud: GET /api/salud. */
@RestController
@RequestMapping("/api")
public class SaludController {

    private final ServicioSalud servicio;

    public SaludController(ServicioSalud servicio) {
        this.servicio = servicio;
    }

    @GetMapping("/salud")
    public ResponseEntity<Map<String, Object>> salud() {
        Map<String, Object> respuesta = new LinkedHashMap<>();
        try {
            EstadoBase estado = servicio.estadoDeLaBase();
            respuesta.put("estado", "OK");
            respuesta.put("baseDeDatos", estado.baseDeDatos());
            respuesta.put("horaBase", estado.horaBase().toString());
            respuesta.put("esquema", estado.esquema());
            return ResponseEntity.ok(respuesta);
        } catch (ErrorDeDatos | IllegalStateException e) {
            respuesta.put("estado", "ERROR");
            respuesta.put("detalle", "No se pudo consultar la base de datos");
            return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE).body(respuesta);
        }
    }
}
