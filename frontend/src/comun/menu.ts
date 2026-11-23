import type { Rol } from './tipos';
import { cerrarSesion, usuarioActual } from './sesion';
import { irA } from './enrutador';
import { h, vaciar } from './ui';

interface Entrada {
  texto: string;
  destino: string;
  id: string;
}

const publico: Entrada[] = [
  { texto: 'Rastrear envío', destino: '#/rastreo', id: 'menu-rastreo' },
];

const porRol: Record<Rol, Entrada[]> = {
  MESA: [
    { texto: 'Solicitud', destino: '#/mesa/solicitud', id: 'menu-solicitud' },
    { texto: 'Registrar envío', destino: '#/mesa/envio', id: 'menu-envio' },
    { texto: 'Consultar envío', destino: '#/mesa/consulta', id: 'menu-consulta' },
    { texto: 'Novedades', destino: '#/mesa/novedades', id: 'menu-novedades' },
    { texto: 'Reclamaciones', destino: '#/mesa/reclamaciones', id: 'menu-reclamaciones' },
  ],
  CENTRO: [
    { texto: 'Recepción', destino: '#/operacion/recepcion', id: 'menu-recepcion' },
    { texto: 'Despachos', destino: '#/operacion/despacho', id: 'menu-despacho' },
    { texto: 'Planilla', destino: '#/operacion/planilla', id: 'menu-planilla-centro' },
    { texto: 'Centros y zonas', destino: '#/operacion/centros', id: 'menu-centros' },
  ],
  MENSAJERO: [
    { texto: 'Mi planilla', destino: '#/mensajero/planilla', id: 'menu-planilla' },
    { texto: 'Recolecciones', destino: '#/mensajero/recolecciones', id: 'menu-recolecciones' },
  ],
  GERENCIA: [
    { texto: 'Tablero', destino: '#/tablero', id: 'menu-tablero' },
  ],
  CLIENTE: [
    { texto: 'Mis envíos', destino: '#/seguimiento', id: 'menu-seguimiento' },
  ],
};

/** Dibuja el menu segun el rol de la sesion; sin sesion, las paginas publicas. */
export function dibujarMenu(): void {
  const lista = document.getElementById('menu');
  if (!lista) {
    return;
  }
  vaciar(lista);
  const usuario = usuarioActual();
  const entradas = usuario ? [...porRol[usuario.rol], ...publico] : [...publico,
    { texto: 'Ingresar', destino: '#/ingreso', id: 'menu-ingreso' },
    { texto: 'Registrarse', destino: '#/registro', id: 'menu-registro' }];
  for (const e of entradas) {
    lista.append(h('li', {}, h('a', { href: e.destino, id: e.id, 'data-prueba': e.id }, e.texto)));
  }
  if (usuario) {
    lista.append(
      h('li', { class: 'usuario' }, h('small', { 'data-prueba': 'usuario-actual' }, `${usuario.usuario} (${usuario.rol.toLowerCase()})`)),
      h('li', {}, h('a', {
        href: '#/ingreso', id: 'menu-salir', 'data-prueba': 'menu-salir', role: 'button', class: 'secondary outline',
        onclick: (ev: Event) => {
          ev.preventDefault();
          void cerrarSesion().finally(() => {
            dibujarMenu();
            irA('#/ingreso');
          });
        },
      }, 'Salir')),
    );
  }
}
