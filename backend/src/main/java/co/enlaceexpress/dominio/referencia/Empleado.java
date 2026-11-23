package co.enlaceexpress.dominio.referencia;

import java.time.LocalDate;

import co.enlaceexpress.dominio.enums.EstadoEmpleado;

/** Empleado del centro; el cargo determina el rol en la aplicacion (extension E1). */
public class Empleado {

    private final Long idEmpleado;
    private final long idCentro;
    private final String documento;
    private final String nombres;
    private final String apellidos;
    private final String cargo;
    private final String telefono;
    private final String correo;
    private final LocalDate fechaIngreso;
    private final LocalDate fechaRetiro;
    private final String motivoRetiro;
    private final EstadoEmpleado estado;

    public Empleado(Long idEmpleado, long idCentro, String documento, String nombres, String apellidos, String cargo,
            String telefono, String correo, LocalDate fechaIngreso, LocalDate fechaRetiro, String motivoRetiro,
            EstadoEmpleado estado) {
        this.idEmpleado = idEmpleado;
        this.idCentro = idCentro;
        this.documento = documento;
        this.nombres = nombres;
        this.apellidos = apellidos;
        this.cargo = cargo;
        this.telefono = telefono;
        this.correo = correo;
        this.fechaIngreso = fechaIngreso;
        this.fechaRetiro = fechaRetiro;
        this.motivoRetiro = motivoRetiro;
        this.estado = estado;
    }

    public Long idEmpleado() { return idEmpleado; }
    public long idCentro() { return idCentro; }
    public String documento() { return documento; }
    public String nombres() { return nombres; }
    public String apellidos() { return apellidos; }
    public String cargo() { return cargo; }
    public String telefono() { return telefono; }
    public String correo() { return correo; }
    public LocalDate fechaIngreso() { return fechaIngreso; }
    public LocalDate fechaRetiro() { return fechaRetiro; }
    public String motivoRetiro() { return motivoRetiro; }
    public EstadoEmpleado estado() { return estado; }

    public boolean estaActivo() {
        return estado == EstadoEmpleado.ACTIVO;
    }
}
