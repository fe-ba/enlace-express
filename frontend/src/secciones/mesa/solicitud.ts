// CU01: registrar una solicitud de recoleccion (cliente -> sede, fecha y franja). RN15: solo clientes activos.
import { api } from '../../comun/api';
import { hoy } from '../../comun/formato';
import type { ResumenCliente, SedeCliente } from '../../comun/tipos';
import { boton, campoSeleccion, campoTexto, ejecutar, h, mostrarError, mostrarOk, zonaDeAvisos } from '../../comun/ui';

/** La ultima solicitud registrada se recuerda para el formulario de envios. */
export const CLAVE_ULTIMA_SOLICITUD = 'enlace.ultimaSolicitud';

export async function vistaSolicitud(contenedor: HTMLElement): Promise<void> {
  const avisos = zonaDeAvisos();
  const clientes = await api.get<ResumenCliente[]>('/api/mesa/clientes');
  const cliente = campoSeleccion('cliente', 'Cliente', [{ valor: '', texto: 'Seleccione un cliente' },
    ...clientes.map((c) => ({ valor: String(c.idCliente), texto: `${c.razonSocial} (${c.nit})` }))], { required: true });
  const sede = campoSeleccion('sede', 'Sede donde se recoge', [{ valor: '', texto: 'Seleccione primero el cliente' }], { required: true, disabled: true });
  const fecha = campoTexto('fecha-programada', 'Fecha programada', { type: 'date', value: hoy(), min: hoy(), required: true });
  const franja = campoSeleccion('franja', 'Franja horaria', [{ valor: 'MANANA', texto: 'Mañana' }, { valor: 'TARDE', texto: 'Tarde' }]);
  const enviar = boton('registrar-solicitud', 'Registrar solicitud');

  cliente.control.addEventListener('change', () => {
    void (async () => {
      sede.control.replaceChildren(h('option', { value: '' }, 'Cargando sedes…'));
      if (cliente.control.value === '') {
        sede.control.replaceChildren(h('option', { value: '' }, 'Seleccione primero el cliente'));
        sede.control.disabled = true;
        return;
      }
      const sedes = await api.get<SedeCliente[]>(`/api/mesa/clientes/${cliente.control.value}/sedes`);
      sede.control.replaceChildren(...sedes.map((s) => h('option', { value: String(s.idSede) }, `${s.nombre} - ${s.direccion}`)));
      sede.control.disabled = false;
    })().catch((e: unknown) => mostrarError(avisos, e));
  });

  const formulario = h('form', {
    id: 'formulario-solicitud',
    onsubmit: (ev: Event) => {
      ev.preventDefault();
      void ejecutar(enviar, avisos, async () => {
        const r = await api.post<{ idSolicitud: number }>('/api/mesa/solicitudes', {
          idSede: Number(sede.control.value), fechaProgramada: fecha.control.value, franjaHoraria: franja.control.value,
        });
        sessionStorage.setItem(CLAVE_ULTIMA_SOLICITUD, String(r.idSolicitud));
        mostrarOk(avisos, h('span', {}, 'Solicitud ', h('strong', { 'data-prueba': 'id-solicitud' }, String(r.idSolicitud)),
          ' registrada. ', h('a', { href: '#/mesa/envio' }, 'Registrar los envíos de esta solicitud'), '.'));
      });
    },
  }, h('div', { class: 'rejilla' }, cliente.contenedor, sede.contenedor, fecha.contenedor, franja.contenedor), enviar);

  contenedor.append(h('h1', {}, 'Registrar solicitud de recolección'), formulario, avisos);
}
