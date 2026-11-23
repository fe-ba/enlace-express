import { api, ErrorApi } from './api';
import type { Rol, UsuarioSesion } from './tipos';

let actual: UsuarioSesion | null = null;

export function usuarioActual(): UsuarioSesion | null {
  return actual;
}

/** Consulta la sesion del servidor (GET /api/sesion); sin sesion el usuario queda en nulo. */
export async function cargarSesion(): Promise<UsuarioSesion | null> {
  try {
    actual = await api.get<UsuarioSesion>('/api/sesion');
  } catch (e) {
    if (e instanceof ErrorApi && e.estado === 401) {
      actual = null;
    } else {
      throw e;
    }
  }
  return actual;
}

export async function iniciarSesion(usuario: string, contrasena: string): Promise<UsuarioSesion> {
  actual = await api.post<UsuarioSesion>('/api/sesion', { usuario, contrasena });
  return actual;
}

export async function cerrarSesion(): Promise<void> {
  try {
    await api.post<void>('/api/sesion/cerrar');
  } finally {
    actual = null;
  }
}

export function olvidarSesion(): void {
  actual = null;
}

/** Pagina de inicio de cada rol. */
export function inicioDelRol(rol: Rol): string {
  switch (rol) {
    case 'MESA': return '#/mesa/solicitud';
    case 'CENTRO': return '#/operacion/recepcion';
    case 'MENSAJERO': return '#/mensajero/planilla';
    case 'GERENCIA': return '#/tablero';
    case 'CLIENTE': return '#/seguimiento';
  }
}
