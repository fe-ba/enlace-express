// CU13: el personal del centro lista, crea y modifica centros de distribucion y zonas. Nada se borra (RN16):
// un centro se inactiva, y un centro inactivo no recibe zonas nuevas.
import { api } from '../../comun/api';
import { legible } from '../../comun/formato';
import type { Centro, Zona } from '../../comun/tipos';
import { boton, campoSeleccion, campoTexto, ejecutar, h, insignia, mostrarOk, vaciar, zonaDeAvisos } from '../../comun/ui';

export async function vistaCentros(contenedor: HTMLElement): Promise<void> {
  const avisos = zonaDeAvisos();
  const listaCentros = h('div', { id: 'lista-centros', 'data-prueba': 'lista-centros' });
  const listaZonas = h('div', { id: 'lista-zonas', 'data-prueba': 'lista-zonas' });
  const formularioZona = h('div', { id: 'zona-nueva' });

  function opcionesDeCentros(centros: Centro[], soloActivos: boolean) {
    return centros.filter((c) => !soloActivos || c.estado === 'ACTIVO').map((c) => ({ valor: String(c.idCentro), texto: c.nombre }));
  }

  function tarjetaDeCentro(c: Centro): HTMLElement {
    const nombre = campoTexto(`centro-nombre-${c.idCentro}`, 'Nombre', { required: true, maxlength: 60, value: c.nombre });
    const direccion = campoTexto(`centro-direccion-${c.idCentro}`, 'Dirección', { required: true, maxlength: 120, value: c.direccion });
    const telefono = campoTexto(`centro-telefono-${c.idCentro}`, 'Teléfono', { maxlength: 20, value: c.telefono ?? '' });
    const guardar = boton(`guardar-centro-${c.idCentro}`, 'Guardar cambios');
    const nuevoEstado = c.estado === 'ACTIVO' ? 'INACTIVO' : 'ACTIVO';
    const cambiar = h('button', {
      id: `estado-centro-${c.idCentro}`, 'data-prueba': `estado-centro-${c.idCentro}`, type: 'button', class: 'secondary outline',
      onclick: () => void ejecutar(cambiar, avisos, async () => {
        await api.post(`/api/centro/centros/${c.idCentro}/estado`, { estado: nuevoEstado });
        mostrarOk(avisos, `El centro ${c.nombre} quedó ${legible(nuevoEstado)}.`);
        await pintar();
      }),
    }, c.estado === 'ACTIVO' ? 'Inactivar centro' : 'Activar centro');
    const formulario = h('form', {
      onsubmit: (ev: Event) => {
        ev.preventDefault();
        void ejecutar(guardar, avisos, async () => {
          await api.post(`/api/centro/centros/${c.idCentro}/modificar`, {
            nombre: nombre.control.value.trim(), direccion: direccion.control.value.trim(), telefono: telefono.control.value.trim() || null });
          mostrarOk(avisos, `Centro ${nombre.control.value.trim()} actualizado.`);
          await pintar();
        });
      },
    }, h('div', { class: 'rejilla' }, nombre.contenedor, direccion.contenedor, telefono.contenedor), guardar);
    return h('article', { 'data-centro': String(c.idCentro) },
      h('header', {}, h('strong', {}, c.nombre), ' ', insignia(legible(c.estado), c.estado === 'ACTIVO' ? 'ok' : 'peligro')),
      h('p', {}, `${c.direccion}${c.telefono ? ' · tel. ' + c.telefono : ''}`),
      h('details', {}, h('summary', {}, 'Editar'), formulario), cambiar);
  }

  function tarjetaDeZona(z: Zona, centros: Centro[]): HTMLElement {
    const centro = campoSeleccion(`zona-centro-${z.idZona}`, 'Centro', opcionesDeCentros(centros, false));
    centro.control.value = String(z.idCentro);
    const nombre = campoTexto(`zona-nombre-${z.idZona}`, 'Nombre', { required: true, maxlength: 60, value: z.nombre });
    const localidades = campoTexto(`zona-localidades-${z.idZona}`, 'Localidades', { required: true, maxlength: 200, value: z.localidades });
    const guardar = boton(`guardar-zona-${z.idZona}`, 'Guardar cambios');
    const formulario = h('form', {
      onsubmit: (ev: Event) => {
        ev.preventDefault();
        void ejecutar(guardar, avisos, async () => {
          await api.post(`/api/centro/zonas/${z.idZona}/modificar`, {
            idCentro: Number(centro.control.value), nombre: nombre.control.value.trim(), localidades: localidades.control.value.trim() });
          mostrarOk(avisos, `Zona ${nombre.control.value.trim()} actualizada.`);
          await pintar();
        });
      },
    }, h('div', { class: 'rejilla' }, centro.contenedor, nombre.contenedor, localidades.contenedor), guardar);
    const dueno = centros.find((c) => c.idCentro === z.idCentro)?.nombre ?? `centro ${z.idCentro}`;
    return h('article', { 'data-zona': String(z.idZona) }, h('strong', {}, z.nombre), ` · ${dueno} · ${z.localidades}`,
      h('details', {}, h('summary', {}, 'Editar'), formulario));
  }

  async function pintar(): Promise<void> {
    const [centros, zonas] = await Promise.all([api.get<Centro[]>('/api/centro/centros'), api.get<Zona[]>('/api/centro/zonas')]);
    vaciar(listaCentros);
    vaciar(listaZonas);
    vaciar(formularioZona);
    centros.forEach((c) => listaCentros.append(tarjetaDeCentro(c)));
    zonas.forEach((z) => listaZonas.append(tarjetaDeZona(z, centros)));

    const centro = campoSeleccion('zona-nueva-centro', 'Centro', opcionesDeCentros(centros, true), { required: true });
    const nombre = campoTexto('zona-nueva-nombre', 'Nombre', { required: true, maxlength: 60, autocomplete: 'off' });
    const localidades = campoTexto('zona-nueva-localidades', 'Localidades', { required: true, maxlength: 200, autocomplete: 'off' });
    const crear = boton('crear-zona', 'Crear zona');
    formularioZona.append(h('form', {
      id: 'formulario-zona',
      onsubmit: (ev: Event) => {
        ev.preventDefault();
        void ejecutar(crear, avisos, async () => {
          const z = await api.post<Zona>('/api/centro/zonas', {
            idCentro: Number(centro.control.value), nombre: nombre.control.value.trim(), localidades: localidades.control.value.trim() });
          mostrarOk(avisos, `Zona ${z.nombre} creada.`);
          await pintar();
        });
      },
    }, h('div', { class: 'rejilla' }, centro.contenedor, nombre.contenedor, localidades.contenedor), crear));
  }

  const nombre = campoTexto('centro-nuevo-nombre', 'Nombre', { required: true, maxlength: 60, autocomplete: 'off' });
  const direccion = campoTexto('centro-nuevo-direccion', 'Dirección', { required: true, maxlength: 120, autocomplete: 'off' });
  const telefono = campoTexto('centro-nuevo-telefono', 'Teléfono (opcional)', { maxlength: 20, autocomplete: 'off' });
  const crear = boton('crear-centro', 'Crear centro');
  const formulario = h('form', {
    id: 'formulario-centro',
    onsubmit: (ev: Event) => {
      ev.preventDefault();
      void ejecutar(crear, avisos, async () => {
        const c = await api.post<Centro>('/api/centro/centros', {
          nombre: nombre.control.value.trim(), direccion: direccion.control.value.trim(), telefono: telefono.control.value.trim() || null });
        mostrarOk(avisos, h('span', {}, 'Centro ', h('strong', { 'data-prueba': 'centro-creado' }, c.nombre), ' creado.'));
        nombre.control.value = '';
        direccion.control.value = '';
        telefono.control.value = '';
        await pintar();
      });
    },
  }, h('div', { class: 'rejilla' }, nombre.contenedor, direccion.contenedor, telefono.contenedor), crear);

  contenedor.append(h('h1', {}, 'Centros y zonas'),
    h('p', { class: 'reglas' }, 'Los centros no se borran: se inactivan (RN16). A un centro inactivo no se le agregan zonas.'),
    avisos, h('h2', {}, 'Centros de distribución'), listaCentros, h('h3', {}, 'Nuevo centro'), formulario,
    h('h2', {}, 'Zonas'), listaZonas, h('h3', {}, 'Nueva zona'), formularioZona);
  await pintar();
}
