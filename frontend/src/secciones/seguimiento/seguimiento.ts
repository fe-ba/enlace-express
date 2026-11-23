// Portal del cliente (U9, CU20): sus envios con el estado actual y el recorrido completo de cada uno.
import { api } from '../../comun/api';
import { claseDeEstado } from '../../comun/estados';
import { formatoFechaHora, legible } from '../../comun/formato';
import type { FilaEnvioCliente, FilaSeguimiento } from '../../comun/tipos';
import { h, insignia, lineaDeTiempo, tabla, zonaDeAvisos } from '../../comun/ui';

export async function vistaLista(contenedor: HTMLElement): Promise<void> {
  const avisos = zonaDeAvisos();
  const filas = await api.get<FilaEnvioCliente[]>('/api/cliente/envios');
  contenedor.append(h('h1', {}, 'Mis envíos'),
    h('p', {}, 'Los envíos de su empresa, del movimiento más reciente al más antiguo.'),
    tabla<FilaEnvioCliente>([
      { titulo: 'Guía', valor: (f) => h('a', { class: 'guia', href: `#/seguimiento/${f.numeroGuia}`, 'data-prueba': `ver-${f.numeroGuia}` }, f.numeroGuia) },
      { titulo: 'Estado', valor: (f) => insignia(legible(f.estadoActual), claseDeEstado(f.estadoActual)) },
      { titulo: 'Último movimiento', valor: (f) => formatoFechaHora(f.fechaHora) },
    ], filas, 'Su empresa todavía no tiene envíos.', 'tabla-mis-envios'), avisos);
}

export async function vistaDetalle(contenedor: HTMLElement, guia: string): Promise<void> {
  const filas = await api.get<FilaSeguimiento[]>(`/api/cliente/envios/${encodeURIComponent(guia)}/seguimiento`);
  const ultimo = filas[filas.length - 1];
  contenedor.append(h('p', {}, h('a', { href: '#/seguimiento' }, '← Mis envíos')),
    h('h1', {}, 'Guía ', h('span', { class: 'guia' }, guia)),
    h('p', {}, ultimo ? ['Estado actual: ', insignia(legible(ultimo.estado), claseDeEstado(ultimo.estado))] : []),
    lineaDeTiempo(filas.map((f) => ({ fecha: formatoFechaHora(f.fechaHora), estado: legible(f.estado), detalle: [f.observacion, f.responsable].filter(Boolean).join(' · ') }))));
}
