// CU21: la mesa ve las novedades abiertas (con los datos para llamar) y decide la accion, deja la solucion y las cierra.
import { api } from '../../comun/api';
import { formatoFechaHora, legible } from '../../comun/formato';
import type { FilaNovedadAbierta } from '../../comun/tipos';
import { boton, campoSeleccion, campoTexto, ejecutar, h, insignia, mostrarOk, vaciar, zonaDeAvisos } from '../../comun/ui';

export async function vistaNovedades(contenedor: HTMLElement): Promise<void> {
  const avisos = zonaDeAvisos();
  const lista = h('div', { id: 'lista-novedades', 'data-prueba': 'lista-novedades' });

  function vacio(): void {
    lista.append(h('p', { class: 'vacio' }, 'No hay novedades abiertas.'));
  }

  async function pintar(): Promise<void> {
    const filas = await api.get<FilaNovedadAbierta[]>('/api/mesa/novedades');
    vaciar(lista);
    if (filas.length === 0) {
      vacio();
      return;
    }
    for (const f of filas) {
      const accion = campoSeleccion(`accion-${f.idNovedad}`, 'Acción', [
        { valor: 'REINTENTO', texto: 'Reintento de la entrega' }, { valor: 'DEVOLUCION', texto: 'Devolución al remitente' }]);
      const solucion = campoTexto(`solucion-${f.idNovedad}`, 'Solución', { required: true, maxlength: 300, autocomplete: 'off',
        placeholder: 'Qué se acordó con el destinatario o el cliente' });
      const gestionar = boton(`gestionar-${f.idNovedad}`, 'Gestionar y cerrar');
      const formulario = h('form', {
        class: 'gestion-novedad', 'data-novedad': String(f.idNovedad),
        onsubmit: (ev: Event) => {
          ev.preventDefault();
          void ejecutar(gestionar, avisos, async () => {
            const r = await api.post<{ idNovedad: number; accion: string; estado: string }>(
              `/api/mesa/novedades/${f.idNovedad}/gestionar`, { accion: accion.control.value, solucion: solucion.control.value.trim() });
            // solo se quita la tarjeta gestionada; lo escrito en las demas se conserva
            formulario.remove();
            mostrarOk(avisos, `Novedad ${r.idNovedad} gestionada: ${legible(r.accion)}, ${legible(r.estado)}.`);
            if (!lista.querySelector('form')) {
              vacio();
            }
          });
        },
      }, h('article', {},
        h('header', {}, h('span', { class: 'guia' }, f.numeroGuia), ' · intento ', String(f.numeroIntento), ' ', insignia(legible(f.tipoNovedad), 'alerta')),
        h('p', {}, f.descripcion),
        h('p', { class: 'reglas' }, `Visita: ${formatoFechaHora(f.horaVisita)}. Destinatario: ${f.destinatario} (`,
          h('a', { href: `tel:${f.telefonoDestinatario}` }, f.telefonoDestinatario), `). Cliente: ${f.cliente} (`,
          h('a', { href: `tel:${f.telefonoCliente}` }, f.telefonoCliente), ').'),
        h('div', { class: 'rejilla' }, accion.contenedor, solucion.contenedor), gestionar));
      lista.append(formulario);
    }
  }

  contenedor.append(h('h1', {}, 'Novedades abiertas'),
    h('p', {}, 'Problemas ocurridos en un intento de entrega. Llame al destinatario o al cliente, decida si se reintenta o se devuelve y deje la solución.'),
    avisos, lista);
  await pintar();
}
