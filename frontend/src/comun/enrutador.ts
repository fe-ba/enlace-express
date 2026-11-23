// Enrutador por hash: "#/mesa/solicitud", "#/rastreo/EE0000000000003".
import type { Rol } from './tipos';
import { usuarioActual, inicioDelRol } from './sesion';
import { h, vaciar } from './ui';

export interface Ruta {
  /** Patron con parametros: "/rastreo/:guia". */
  patron: string;
  /** Roles que pueden entrar; sin lista, es publica. */
  roles?: Rol[];
  titulo: string;
  vista: (contenedor: HTMLElement, parametros: Record<string, string>) => void | Promise<void>;
}

const rutas: Ruta[] = [];

export function registrar(ruta: Ruta): void {
  rutas.push(ruta);
}

function coincide(patron: string, ruta: string): Record<string, string> | null {
  const a = patron.split('/').filter(Boolean);
  const b = ruta.split('/').filter(Boolean);
  if (a.length !== b.length) {
    return null;
  }
  const parametros: Record<string, string> = {};
  for (let i = 0; i < a.length; i++) {
    const p = a[i]!;
    const v = b[i]!;
    if (p.startsWith(':')) {
      parametros[p.slice(1)] = decodeURIComponent(v);
    } else if (p !== v) {
      return null;
    }
  }
  return parametros;
}

export function irA(destino: string): void {
  if (window.location.hash === destino) {
    void mostrar();
  } else {
    window.location.hash = destino;
  }
}

/** Muestra la vista de la ruta actual, comprobando el rol de la sesion. */
export async function mostrar(): Promise<void> {
  const contenedor = document.getElementById('principal');
  if (!contenedor) {
    return;
  }
  const hash = window.location.hash.replace(/^#/, '') || '/rastreo';
  const usuario = usuarioActual();
  for (const ruta of rutas) {
    const parametros = coincide(ruta.patron, hash);
    if (!parametros) {
      continue;
    }
    if (ruta.roles && (!usuario || !ruta.roles.includes(usuario.rol))) {
      irA(usuario ? inicioDelRol(usuario.rol) : '#/ingreso');
      return;
    }
    document.title = `${ruta.titulo} · Enlace Express`;
    vaciar(contenedor);
    await ruta.vista(contenedor, parametros);
    marcarMenu(hash);
    contenedor.focus({ preventScroll: true });
    return;
  }
  vaciar(contenedor);
  contenedor.append(h('h1', {}, 'Página no encontrada'), h('p', {}, h('a', { href: '#/rastreo' }, 'Volver al inicio')));
}

function marcarMenu(hash: string): void {
  document.querySelectorAll<HTMLAnchorElement>('#menu a').forEach((a) => {
    const activo = hash.startsWith(a.getAttribute('href')?.replace(/^#/, '') ?? '\u0000');
    if (activo) {
      a.setAttribute('aria-current', 'page');
    } else {
      a.removeAttribute('aria-current');
    }
  });
}

export function iniciarEnrutador(): void {
  window.addEventListener('hashchange', () => void mostrar());
}
