import '@picocss/pico/css/pico.min.css';
import './comun/estilos.css';

import { EVENTO_SESION_EXPIRADA } from './comun/api';
import { dibujarMenu } from './comun/menu';
import { irA, iniciarEnrutador, mostrar, registrar } from './comun/enrutador';
import { cargarSesion, inicioDelRol, olvidarSesion, usuarioActual } from './comun/sesion';
import { rutasPublicas } from './publico/rutas';
import { rutasMesa } from './secciones/mesa/rutas';
import { rutasOperacion } from './secciones/operacion/rutas';
import { rutasMensajero } from './secciones/mensajero/rutas';
import { rutasTablero } from './secciones/tablero/rutas';
import { rutasSeguimiento } from './secciones/seguimiento/rutas';

[...rutasPublicas, ...rutasMesa, ...rutasOperacion, ...rutasMensajero, ...rutasTablero, ...rutasSeguimiento].forEach(registrar);

async function arrancar(): Promise<void> {
  try {
    await cargarSesion();
  } catch {
    // sin conexion con el servidor: se muestra la parte publica y la vista informa el error
  }
  dibujarMenu();
  iniciarEnrutador();
  // si el servidor cierra la sesion (por ejemplo vencio), se vuelve al ingreso
  window.addEventListener(EVENTO_SESION_EXPIRADA, () => {
    olvidarSesion();
    dibujarMenu();
    irA('#/ingreso');
  });
  if (!window.location.hash) {
    const usuario = usuarioActual();
    window.location.hash = usuario ? inicioDelRol(usuario.rol) : '#/rastreo';
  }
  await mostrar();
}

void arrancar();
