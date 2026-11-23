// CU15: recolecciones pendientes; el mensajero las marca como recogidas.
import { api } from '../../comun/api';
import { formatoFecha, legible } from '../../comun/formato';
import type { FilaRecoleccion } from '../../comun/tipos';
import { ejecutar, h, mostrarOk, vaciar, zonaDeAvisos } from '../../comun/ui';

export async function vistaRecolecciones(contenedor: HTMLElement): Promise<void> {
  const avisos = zonaDeAvisos();
  const lista = h('div', { id: 'lista-recolecciones', 'data-prueba': 'lista-recolecciones' });

  async function pintar(): Promise<void> {
    const filas = await api.get<FilaRecoleccion[]>('/api/mensajero/recolecciones');
    vaciar(lista);
    if (filas.length === 0) {
      lista.append(h('p', { class: 'vacio' }, 'No hay recolecciones pendientes.'));
      return;
    }
    for (const f of filas) {
      const recolectar = h('button', {
        id: `recolectar-${f.idSolicitud}`, 'data-prueba': `recolectar-${f.idSolicitud}`, type: 'button',
        onclick: () => void ejecutar(recolectar, avisos, async () => {
          const r = await api.post<{ enviosRecolectados: number }>(`/api/mensajero/solicitudes/${f.idSolicitud}/recolectar`);
          mostrarOk(avisos, `Solicitud ${f.idSolicitud} recolectada: ${r.enviosRecolectados} envío(s).`);
          await pintar();
        }),
      }, 'Marcar como recolectada');
      lista.append(h('article', { class: 'tarjeta-visita' },
        h('header', {}, h('strong', {}, `Solicitud ${f.idSolicitud}`), h('span', {}, `${formatoFecha(f.fechaProgramada)} · ${legible(f.franjaHoraria)}`)),
        h('p', {}, h('strong', {}, f.sede), h('br'), f.direccion, h('br'), `Contacto: ${f.contacto} · `,
          h('a', { class: 'telefono', href: `tel:${f.telefono}` }, f.telefono)),
        h('p', {}, `${f.envios} envío(s) registrado(s)`), recolectar));
    }
  }

  contenedor.append(h('div', { class: 'movil' }, h('h1', {}, 'Recolecciones pendientes'), avisos, lista));
  await pintar();
}
