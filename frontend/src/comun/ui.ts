// Utilidades minimas para construir el DOM sin frameworks.
import { ErrorApi } from './api';

type Hijo = Node | string | number | null | undefined | false | Hijo[];
type Atributos = Record<string, string | number | boolean | EventListener | undefined | null>;

/** Crea un elemento: h('button', { class: 'secondary', onclick: fn }, 'Texto'). */
export function h<K extends keyof HTMLElementTagNameMap>(etiqueta: K, atributos: Atributos = {}, ...hijos: Hijo[]): HTMLElementTagNameMap[K] {
  const el = document.createElement(etiqueta);
  for (const [clave, valor] of Object.entries(atributos)) {
    if (valor === undefined || valor === null || valor === false) {
      continue;
    }
    if (clave.startsWith('on') && typeof valor === 'function') {
      el.addEventListener(clave.slice(2), valor as EventListener);
    } else if (clave === 'class') {
      el.className = String(valor);
    } else if (valor === true) {
      el.setAttribute(clave, '');
    } else {
      el.setAttribute(clave, String(valor));
    }
  }
  agregar(el, hijos);
  return el;
}

function agregar(el: Element, hijos: Hijo[]): void {
  for (const hijo of hijos) {
    if (hijo === null || hijo === undefined || hijo === false) {
      continue;
    }
    if (Array.isArray(hijo)) {
      agregar(el, hijo);
    } else {
      el.append(typeof hijo === 'object' ? hijo : String(hijo));
    }
  }
}

export function vaciar(el: Element): void {
  while (el.firstChild) {
    el.removeChild(el.firstChild);
  }
}

/** Campo de formulario con su etiqueta; id y data-prueba iguales para localizarlo en las pruebas. */
export interface Campo<E extends HTMLElement> {
  contenedor: HTMLLabelElement;
  control: E;
}

export function campoTexto(id: string, etiqueta: string, atributos: Atributos = {}): Campo<HTMLInputElement> {
  const control = h('input', { id, name: id, 'data-prueba': id, type: 'text', ...atributos });
  return { contenedor: h('label', { for: id }, etiqueta, control), control };
}

export function campoSeleccion(id: string, etiqueta: string, opciones: { valor: string; texto: string }[], atributos: Atributos = {}): Campo<HTMLSelectElement> {
  const control = h('select', { id, name: id, 'data-prueba': id, ...atributos },
    ...opciones.map((o) => h('option', { value: o.valor }, o.texto)));
  return { contenedor: h('label', { for: id }, etiqueta, control), control };
}

export function casilla(id: string, etiqueta: string): Campo<HTMLInputElement> {
  const control = h('input', { id, name: id, 'data-prueba': id, type: 'checkbox' });
  return { contenedor: h('label', { for: id }, control, etiqueta), control };
}

/** Un boton de envio con su id estable. */
export function boton(id: string, texto: string, atributos: Atributos = {}): HTMLButtonElement {
  return h('button', { id, 'data-prueba': id, type: 'submit', ...atributos }, texto);
}

/** Zona para mostrar avisos: el resultado o el error de la ultima operacion. */
export function zonaDeAvisos(id = 'avisos'): HTMLElement {
  return h('div', { id, 'data-prueba': id, role: 'status', 'aria-live': 'polite' });
}

export function mostrarOk(zona: HTMLElement, texto: string | Node): void {
  vaciar(zona);
  zona.append(h('article', { class: 'aviso aviso-ok' }, texto));
}

export function mostrarError(zona: HTMLElement, error: unknown): void {
  vaciar(zona);
  const texto = error instanceof ErrorApi ? error.mensaje : 'Ocurrió un error inesperado.';
  const codigo = error instanceof ErrorApi ? error.codigo : '';
  zona.append(h('article', { class: 'aviso aviso-error', role: 'alert', 'data-codigo': codigo }, texto));
}

/** Tabla con columnas definidas por funcion. */
export interface Columna<T> {
  titulo: string;
  valor: (fila: T) => Hijo;
  clase?: string;
}

export function tabla<T>(columnas: Columna<T>[], filas: T[], vacio = 'No hay datos para mostrar.', idTabla?: string): HTMLElement {
  if (filas.length === 0) {
    return h('p', { class: 'vacio' }, vacio);
  }
  const t = h('table', { class: 'striped', id: idTabla, 'data-prueba': idTabla },
    h('thead', {}, h('tr', {}, ...columnas.map((c) => h('th', { scope: 'col' }, c.titulo)))),
    h('tbody', {}, ...filas.map((f) => h('tr', {}, ...columnas.map((c) => {
      return h('td', { class: c.clase }, c.valor(f));
    })))),
  );
  return h('div', { class: 'tabla-ancha', role: 'region', tabindex: 0, 'aria-label': 'Tabla de resultados' }, t);
}

/** Etiqueta de color para un estado. */
export function insignia(texto: string, clase = ''): HTMLElement {
  return h('span', { class: `insignia ${clase}`.trim() }, texto);
}

/** Linea de tiempo de un recorrido. */
export function lineaDeTiempo(eventos: { fecha: string; estado: string; detalle?: string | null }[]): HTMLElement {
  return h('ol', { class: 'linea-tiempo', 'data-prueba': 'linea-tiempo' },
    ...eventos.map((e) => h('li', {}, h('strong', {}, e.estado), h('span', { class: 'fecha' }, e.fecha),
      e.detalle ? h('small', {}, e.detalle) : null)));
}

/** Ejecuta una accion de un boton: lo deshabilita mientras corre y muestra el error si falla. */
export async function ejecutar(boton: HTMLElement | null, zona: HTMLElement, accion: () => Promise<void>): Promise<void> {
  boton?.setAttribute('aria-busy', 'true');
  boton?.setAttribute('disabled', '');
  try {
    await accion();
  } catch (e) {
    mostrarError(zona, e);
  } finally {
    boton?.removeAttribute('aria-busy');
    boton?.removeAttribute('disabled');
  }
}

export function cargando(): HTMLElement {
  return h('p', { 'aria-busy': 'true' }, 'Cargando…');
}
