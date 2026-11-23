package co.enlaceexpress.datos.mapeadores;

import java.sql.ResultSet;
import java.sql.SQLException;

/** Convierte la fila actual de un ResultSet en un objeto del dominio. */
@FunctionalInterface
public interface MapeadorFila<T> {

    T mapear(ResultSet fila) throws SQLException;
}
