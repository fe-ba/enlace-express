// CU08 a CU11: envios por despachar, seleccion, mensajero y vehiculo disponible (C9) y armado del despacho de entrega.
import { api } from '../../comun/api';
import { formatoFecha, formatoPeso, legible } from '../../comun/formato';
import type { FilaPorDespachar, ResumenMensajero, ResumenVehiculo } from '../../comun/tipos';
import { boton, campoSeleccion, ejecutar, h, insignia, mostrarError, mostrarOk, vaciar, zonaDeAvisos } from '../../comun/ui';

export async function vistaDespacho(contenedor: HTMLElement): Promise<void> {
  const avisos = zonaDeAvisos();
  const zonaEnvios = h('div', { id: 'por-despachar', 'data-prueba': 'por-despachar' });
  const [mensajeros] = await Promise.all([api.get<ResumenMensajero[]>('/api/centro/mensajeros')]);

  const mensajero = campoSeleccion('mensajero', 'Mensajero', [{ valor: '', texto: 'Seleccione un mensajero' },
    ...mensajeros.map((m) => ({ valor: String(m.idEmpleado), texto: `${m.nombres} ${m.apellidos} (${legible(m.tipoVehiculo)})` }))], { required: true });
  const vehiculo = campoSeleccion('vehiculo', 'Vehículo disponible', [{ valor: '', texto: 'Seleccione primero el mensajero' }], { required: true, disabled: true });
  const armar = boton('armar-despacho', 'Armar despacho de entrega');

  mensajero.control.addEventListener('change', () => {
    void (async () => {
      vehiculo.control.replaceChildren(h('option', { value: '' }, 'Cargando…'));
      if (mensajero.control.value === '') {
        vehiculo.control.replaceChildren(h('option', { value: '' }, 'Seleccione primero el mensajero'));
        vehiculo.control.disabled = true;
        return;
      }
      const vehiculos = await api.get<ResumenVehiculo[]>(`/api/centro/mensajeros/${mensajero.control.value}/vehiculos`);
      vehiculo.control.replaceChildren(...(vehiculos.length === 0
        ? [h('option', { value: '' }, 'No hay vehículos disponibles de su tipo')]
        : vehiculos.map((v) => h('option', { value: String(v.idVehiculo) }, `${v.placa ?? 'sin placa'} - ${v.marca} ${v.modelo}`))));
      vehiculo.control.disabled = vehiculos.length === 0;
    })().catch((e: unknown) => mostrarError(avisos, e));
  });

  let filas: FilaPorDespachar[] = [];
  async function pintar(): Promise<void> {
    filas = await api.get<FilaPorDespachar[]>('/api/centro/por-despachar');
    vaciar(zonaEnvios);
    if (filas.length === 0) {
      zonaEnvios.append(h('p', { class: 'vacio' }, 'No hay envíos por despachar en su centro.'));
      return;
    }
    zonaEnvios.append(h('div', { class: 'tabla-ancha', role: 'region', tabindex: 0, 'aria-label': 'Envíos por despachar' }, h('table', { class: 'striped' },
      h('thead', {}, h('tr', {}, ...['', 'Guía', 'Zona', 'Modalidad', 'Compromiso', 'Peso', 'Manejo', 'Intentos previos'].map((t) => h('th', { scope: 'col' }, t)))),
      h('tbody', {}, ...filas.map((f) => h('tr', {},
        h('td', {}, h('input', { type: 'checkbox', class: 'seleccion', value: f.numeroGuia, id: `sel-${f.numeroGuia}`, 'data-prueba': `sel-${f.numeroGuia}`, 'aria-label': `Seleccionar ${f.numeroGuia}` })),
        h('td', {}, h('span', { class: 'guia' }, f.numeroGuia)),
        h('td', {}, f.zona), h('td', {}, legible(f.modalidad)), h('td', {}, formatoFecha(f.fechaCompromiso)),
        h('td', { class: 'numero' }, formatoPeso(f.pesoKg)),
        h('td', {}, f.fragil ? insignia('Frágil', 'alerta') : null, f.altoValor ? insignia('Alto valor', 'alerta') : null),
        h('td', { class: 'numero' }, String(f.intentosPrevios))))))));
  }

  const formulario = h('form', {
    id: 'formulario-despacho',
    onsubmit: (ev: Event) => {
      ev.preventDefault();
      const guias = Array.from(zonaEnvios.querySelectorAll<HTMLInputElement>('input.seleccion:checked')).map((i) => i.value);
      void ejecutar(armar, avisos, async () => {
        const r = await api.post<{ idDespacho: number; asignaciones: number }>('/api/centro/despachos', {
          idMensajero: Number(mensajero.control.value), idVehiculo: Number(vehiculo.control.value), guias,
        });
        mostrarOk(avisos, h('span', {}, 'Despacho ', h('strong', { 'data-prueba': 'id-despacho' }, String(r.idDespacho)),
          ` armado con ${r.asignaciones} envío(s) y en ruta. `, h('a', { href: `#/operacion/planilla/${r.idDespacho}` }, 'Ver la planilla'), '.'));
        await pintar();
      });
    },
  }, h('h2', {}, 'Despacho'), h('div', { class: 'rejilla' }, mensajero.contenedor, vehiculo.contenedor), armar);

  contenedor.append(h('h1', {}, 'Armar despacho de entrega'),
    h('p', {}, 'Seleccione los envíos clasificados, el mensajero y uno de los vehículos disponibles de su tipo.'),
    h('h2', {}, 'Envíos por despachar'), zonaEnvios, formulario, avisos);
  await pintar();
}
