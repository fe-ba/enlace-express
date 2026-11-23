package co.enlaceexpress.casosdeuso.centro;

import java.util.List;

import org.springframework.stereotype.Service;

import co.enlaceexpress.casosdeuso.seguridad.FabricaUnidadesDeTrabajo;
import co.enlaceexpress.casosdeuso.seguridad.UsuarioSesion;
import co.enlaceexpress.datos.infraestructura.UnidadDeTrabajo;
import co.enlaceexpress.datos.mapeadores.CentroZonaMapper;
import co.enlaceexpress.dominio.enums.EstadoActivo;
import co.enlaceexpress.dominio.enums.Rol;
import co.enlaceexpress.dominio.referencia.CentroDistribucion;
import co.enlaceexpress.dominio.referencia.Zona;
import co.enlaceexpress.dominio.reglas.EntradaInvalida;
import co.enlaceexpress.dominio.reglas.EstadoIncorrecto;
import co.enlaceexpress.dominio.reglas.RecursoNoEncontrado;

/**
 * CU13 Gestionar centros y zonas (U2): el personal del centro lista, crea y modifica centros de distribucion y zonas.
 * No se borra nada (RN16): un centro se inactiva por estado, y no se le asignan zonas nuevas mientras lo esta. Cada
 * cambio es una transaccion con SELECT ... FOR UPDATE de la fila que cambia.
 */
@Service
public class ServicioCentros {

    private final FabricaUnidadesDeTrabajo unidades;

    public ServicioCentros(FabricaUnidadesDeTrabajo unidades) {
        this.unidades = unidades;
    }

    public List<CentroDistribucion> centros(UsuarioSesion usuario) {
        try (UnidadDeTrabajo uow = unidades.para(usuario, Rol.CENTRO)) {
            return new CentroZonaMapper(uow).centros();
        }
    }

    public List<Zona> zonas(UsuarioSesion usuario) {
        try (UnidadDeTrabajo uow = unidades.para(usuario, Rol.CENTRO)) {
            return new CentroZonaMapper(uow).zonas();
        }
    }

    /** Crea un centro ACTIVO; un nombre repetido lo rechaza la base (409). */
    public CentroDistribucion crearCentro(UsuarioSesion usuario, String nombre, String direccion, String telefono) {
        CentroDistribucion nuevo = CentroDistribucion.nuevo(nombre, direccion, telefono);
        try (UnidadDeTrabajo uow = unidades.para(usuario, Rol.CENTRO)) {
            CentroZonaMapper centros = new CentroZonaMapper(uow);
            long id = centros.insertarCentro(nuevo);
            uow.confirmar();
            return new CentroDistribucion(id, nuevo.nombre(), nuevo.direccion(), nuevo.telefono(), nuevo.estado());
        }
    }

    public CentroDistribucion modificarCentro(UsuarioSesion usuario, long idCentro, String nombre, String direccion, String telefono) {
        try (UnidadDeTrabajo uow = unidades.para(usuario, Rol.CENTRO)) {
            CentroZonaMapper centros = new CentroZonaMapper(uow);
            CentroDistribucion modificado = cargarBloqueado(centros, idCentro).modificar(nombre, direccion, telefono);
            centros.actualizarCentro(modificado);
            uow.confirmar();
            return modificado;
        }
    }

    /** Activa o inactiva el centro; pedir el estado que ya tiene es un conflicto (409). */
    public CentroDistribucion cambiarEstado(UsuarioSesion usuario, long idCentro, EstadoActivo estado) {
        if (estado == null) {
            throw new EntradaInvalida("estado", "El estado es obligatorio (ACTIVO o INACTIVO)");
        }
        try (UnidadDeTrabajo uow = unidades.para(usuario, Rol.CENTRO)) {
            CentroZonaMapper centros = new CentroZonaMapper(uow);
            CentroDistribucion actual = cargarBloqueado(centros, idCentro);
            if (actual.estado() == estado) {
                throw new EstadoIncorrecto("El centro " + idCentro + " ya está " + estado);
            }
            CentroDistribucion cambiado = actual.conEstado(estado);
            centros.actualizarCentro(cambiado);
            uow.confirmar();
            return cambiado;
        }
    }

    /** Crea una zona en un centro ACTIVO. */
    public Zona crearZona(UsuarioSesion usuario, Long idCentro, String nombre, String localidades) {
        if (idCentro == null) {
            throw new EntradaInvalida("idCentro", "El centro es obligatorio");
        }
        try (UnidadDeTrabajo uow = unidades.para(usuario, Rol.CENTRO)) {
            CentroZonaMapper centros = new CentroZonaMapper(uow);
            // se bloquea el centro para que no se inactive mientras se le agrega la zona
            Zona nueva = Zona.nueva(centroDestino(centros, idCentro), nombre, localidades);
            long id = centros.insertarZona(nueva);
            uow.confirmar();
            return new Zona(id, nueva.idCentro(), nueva.nombre(), nueva.localidades());
        }
    }

    public Zona modificarZona(UsuarioSesion usuario, long idZona, Long idCentro, String nombre, String localidades) {
        try (UnidadDeTrabajo uow = unidades.para(usuario, Rol.CENTRO)) {
            CentroZonaMapper centros = new CentroZonaMapper(uow);
            if (!centros.bloquearZona(idZona)) {
                throw new RecursoNoEncontrado("No se encontró la zona " + idZona);
            }
            Zona actual = centros.zona(idZona).orElseThrow();
            CentroDistribucion destino = centroDestino(centros, idCentro == null ? actual.idCentro() : idCentro);
            Zona modificada = actual.modificar(destino, nombre, localidades);
            centros.actualizarZona(modificada);
            uow.confirmar();
            return modificada;
        }
    }

    private static CentroDistribucion cargarBloqueado(CentroZonaMapper centros, long idCentro) {
        if (!centros.bloquearCentro(idCentro)) {
            throw new RecursoNoEncontrado("No se encontró el centro " + idCentro);
        }
        return centros.centro(idCentro).orElseThrow();
    }

    private static CentroDistribucion centroDestino(CentroZonaMapper centros, long idCentro) {
        if (!centros.bloquearCentro(idCentro)) {
            throw new EntradaInvalida("idCentro", "El centro no existe");
        }
        return centros.centro(idCentro).orElseThrow();
    }
}
