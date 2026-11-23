// CU22 y CU23: la mesa radica reclamaciones de cualquier cliente (un cliente inactivo puede reclamar por envios anteriores), las responde (meta de 4 horas, RN14) y las cierra.
import { api } from '../../comun/api';
import { formatoFechaHora, formatoNumero, legible } from '../../comun/formato';
import type { FilaReclamacionMesa, ResumenCliente } from '../../comun/tipos';
import { boton, campoSeleccion, campoTexto, ejecutar, h, insignia, mostrarOk, vaciar, zonaDeAvisos } from '../../comun/ui';

export async function vistaReclamaciones(contenedor: HTMLElement): Promise<void> {
  const avisos = zonaDeAvisos();
  const clientes = await api.get<ResumenCliente[]>('/api/mesa/clientes?todos=true');

  // ---- registrar
  const cliente = campoSeleccion('reclamacion-cliente', 'Cliente', [{ valor: '', texto: 'Seleccione un cliente' },
    ...clientes.map((c) => ({ valor: String(c.idCliente), texto: `${c.razonSocial} (${c.nit})${c.estado === 'ACTIVO' ? '' : ' - inactivo'}` }))], { required: true });
  const guia = campoTexto('reclamacion-guia', 'Número de guía (opcional)', { placeholder: 'EE0000000000015', maxlength: 15, autocomplete: 'off' });
  const tipo = campoSeleccion('reclamacion-tipo', 'Tipo',
    ['ENTREGA', 'DANO', 'FACTURACION', 'OTRO'].map((t) => ({ valor: t, texto: legible(t) })));
  const descripcion = campoTexto('reclamacion-descripcion', 'Descripción', { required: true, maxlength: 500, autocomplete: 'off' });
  const registrar = boton('registrar-reclamacion', 'Registrar reclamación');

  const pendientes = h('div', { id: 'reclamaciones-pendientes', 'data-prueba': 'reclamaciones-pendientes' });
  const respondidas = h('div', { id: 'reclamaciones-respondidas', 'data-prueba': 'reclamaciones-respondidas' });

  function datos(f: FilaReclamacionMesa): HTMLElement {
    return h('p', {}, h('strong', {}, `Reclamación ${f.idReclamacion}`), ` · ${f.cliente} · ${legible(f.tipo)}`,
      f.numeroGuia ? [' · guía ', h('span', { class: 'guia' }, f.numeroGuia)] : ' · sin guía', h('br'),
      f.descripcion, h('br'), h('small', {}, `Radicada: ${formatoFechaHora(f.fechaRadicacion)}`));
  }

  function marca(f: FilaReclamacionMesa): HTMLElement {
    const texto = f.estado === 'ABIERTA' ? `${formatoNumero(f.horas)} h sin respuesta` : `Respondida en ${formatoNumero(f.horas)} h`;
    return f.superaMeta ? insignia(`${texto}: supera la meta de 4 h`, 'peligro') : insignia(`${texto}: dentro de la meta`, 'ok');
  }

  async function pintar(): Promise<void> {
    const [abiertas, resp] = await Promise.all([
      api.get<FilaReclamacionMesa[]>('/api/mesa/reclamaciones'),
      api.get<FilaReclamacionMesa[]>('/api/mesa/reclamaciones?estado=RESPONDIDA'),
    ]);
    vaciar(pendientes);
    vaciar(respondidas);
    if (abiertas.length === 0) {
      pendientes.append(h('p', { class: 'vacio' }, 'No hay reclamaciones pendientes de respuesta.'));
    }
    for (const f of abiertas) {
      const respuesta = campoTexto(`respuesta-${f.idReclamacion}`, 'Respuesta', { required: true, maxlength: 500, autocomplete: 'off' });
      const responder = boton(`responder-${f.idReclamacion}`, 'Responder');
      const formulario = h('form', {
        'data-reclamacion': String(f.idReclamacion),
        onsubmit: (ev: Event) => {
          ev.preventDefault();
          void ejecutar(responder, avisos, async () => {
            const r = await api.post<{ idReclamacion: number; horas: number; superaMeta: boolean }>(
              `/api/mesa/reclamaciones/${f.idReclamacion}/responder`, { respuesta: respuesta.control.value.trim() });
            mostrarOk(avisos, `Reclamación ${r.idReclamacion} respondida en ${formatoNumero(r.horas)} h${r.superaMeta ? ' (supera la meta de 4 h)' : ''}.`);
            await pintar();
          });
        },
      }, h('article', {}, datos(f), marca(f), respuesta.contenedor, responder));
      pendientes.append(formulario);
    }
    if (resp.length === 0) {
      respondidas.append(h('p', { class: 'vacio' }, 'No hay reclamaciones respondidas por cerrar.'));
    }
    for (const f of resp) {
      const cerrar = h('button', {
        id: `cerrar-${f.idReclamacion}`, 'data-prueba': `cerrar-${f.idReclamacion}`, type: 'button', class: 'secondary',
        onclick: () => void ejecutar(cerrar, avisos, async () => {
          await api.post(`/api/mesa/reclamaciones/${f.idReclamacion}/cerrar`);
          mostrarOk(avisos, `Reclamación ${f.idReclamacion} cerrada.`);
          await pintar();
        }),
      }, 'Cerrar reclamación');
      respondidas.append(h('article', { 'data-reclamacion': String(f.idReclamacion) }, datos(f),
        h('p', {}, h('strong', {}, 'Respuesta: '), f.respuesta ?? '', h('br'),
          h('small', {}, `Respondida: ${formatoFechaHora(f.fechaRespuesta)}`)), marca(f), cerrar));
    }
  }

  const formulario = h('form', {
    id: 'formulario-reclamacion',
    onsubmit: (ev: Event) => {
      ev.preventDefault();
      void ejecutar(registrar, avisos, async () => {
        const r = await api.post<{ idReclamacion: number }>('/api/mesa/reclamaciones', {
          idCliente: Number(cliente.control.value), numeroGuia: guia.control.value.trim() || null,
          tipo: tipo.control.value, descripcion: descripcion.control.value.trim(),
        });
        mostrarOk(avisos, h('span', {}, 'Reclamación ', h('strong', { 'data-prueba': 'id-reclamacion' }, String(r.idReclamacion)), ' registrada.'));
        guia.control.value = '';
        descripcion.control.value = '';
        await pintar();
      });
    },
  }, h('div', { class: 'rejilla' }, cliente.contenedor, guia.contenedor, tipo.contenedor, descripcion.contenedor), registrar);

  contenedor.append(h('h1', {}, 'Reclamaciones'),
    h('p', { class: 'reglas' }, 'La meta es responder en 4 horas (RN14). Se puede registrar la reclamación de cualquier cliente; si indica una guía, debe ser de un envío de ese cliente.'),
    h('h2', {}, 'Registrar reclamación'), formulario, avisos,
    h('h2', {}, 'Pendientes de respuesta'), pendientes,
    h('h2', {}, 'Respondidas por cerrar'), respondidas);
  await pintar();
}
