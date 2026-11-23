// CU06 y CU07: recibir los envios recolectados, registrar su peso real y su flete y clasificarlos.
import { api } from '../../comun/api';
import { formatoFecha, legible } from '../../comun/formato';
import type { FilaEnvioEstado } from '../../comun/tipos';
import { boton, campoTexto, ejecutar, h, mostrarOk, vaciar, zonaDeAvisos } from '../../comun/ui';

export async function vistaRecepcion(contenedor: HTMLElement): Promise<void> {
  const avisos = zonaDeAvisos();
  const lista = h('div', { id: 'lista-recepcion', 'data-prueba': 'lista-recepcion' });

  async function pintar(): Promise<void> {
    const filas = await api.get<FilaEnvioEstado[]>('/api/centro/envios/recolectados');
    vaciar(lista);
    if (filas.length === 0) {
      lista.append(h('p', { class: 'vacio' }, 'No hay envíos recolectados por recibir en su centro.'));
      return;
    }
    for (const f of filas) {
      const peso = campoTexto(`peso-real-${f.numeroGuia}`, 'Peso real (kg)', { type: 'number', min: 0.01, step: 0.01, required: true });
      const flete = campoTexto(`flete-${f.numeroGuia}`, 'Flete (COP)', { type: 'number', min: 1, step: 1, required: true });
      const recibir = boton(`recibir-${f.numeroGuia}`, 'Recibir y clasificar');
      const formulario = h('form', {
        class: 'recepcion', 'data-guia': f.numeroGuia,
        onsubmit: (ev: Event) => {
          ev.preventDefault();
          void ejecutar(recibir, avisos, async () => {
            await api.post(`/api/centro/envios/${f.numeroGuia}/recepcion`, { pesoReal: Number(peso.control.value), valorFlete: Number(flete.control.value) });
            mostrarOk(avisos, `El envío ${f.numeroGuia} quedó clasificado y listo para despachar.`);
            // solo se quita la tarjeta recibida: lo escrito en las demas se conserva
            formulario.remove();
            if (!lista.querySelector('form')) {
              lista.append(h('p', { class: 'vacio' }, 'No hay envíos recolectados por recibir en su centro.'));
            }
          });
        },
      }, h('article', {},
        h('header', {}, h('span', { class: 'guia' }, f.numeroGuia), ' · ', f.razonSocial),
        h('p', {}, `${legible(f.modalidad)} · zona ${f.zona} · compromiso ${formatoFecha(f.fechaCompromiso)}`),
        h('div', { class: 'rejilla' }, peso.contenedor, flete.contenedor), recibir));
      lista.append(formulario);
    }
  }

  contenedor.append(h('h1', {}, 'Recepción y clasificación'),
    h('p', {}, 'Envíos recolectados que llegaron al centro. Al recibirlos quedan EN_CENTRO y CLASIFICADO.'), avisos, lista);
  await pintar();
}
