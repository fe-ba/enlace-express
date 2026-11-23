// CU02, CU03 y CU04: registrar un envio con su destinatario; la guia la genera la base de datos.
import { api } from '../../comun/api';
import { formatoFecha, legible } from '../../comun/formato';
import type { EnvioRegistrado, Modalidad, Zona } from '../../comun/tipos';
import { boton, campoSeleccion, campoTexto, casilla, ejecutar, h, mostrarOk, zonaDeAvisos } from '../../comun/ui';
import { CLAVE_ULTIMA_SOLICITUD } from './solicitud';

export async function vistaEnvio(contenedor: HTMLElement): Promise<void> {
  const avisos = zonaDeAvisos();
  const [zonas, modalidades] = await Promise.all([api.get<Zona[]>('/api/mesa/zonas'), api.get<Modalidad[]>('/api/mesa/modalidades')]);

  const solicitud = campoTexto('id-solicitud', 'Número de solicitud', { type: 'number', min: 1, required: true, value: sessionStorage.getItem(CLAVE_ULTIMA_SOLICITUD) ?? '' });
  const tipoDoc = campoSeleccion('tipo-documento', 'Tipo de documento del destinatario',
    ['CC', 'CE', 'NIT', 'PAS', 'TI'].map((t) => ({ valor: t, texto: t })));
  const documento = campoTexto('numero-documento', 'Número de documento', { required: true, maxlength: 15 });
  const nombre = campoTexto('nombre-destinatario', 'Nombre del destinatario', { required: true, maxlength: 100 });
  const telefono = campoTexto('telefono-destinatario', 'Teléfono', { type: 'tel', required: true, maxlength: 20 });
  const correo = campoTexto('correo-destinatario', 'Correo (opcional)', { type: 'email', maxlength: 100 });
  const zona = campoSeleccion('zona', 'Zona de destino', zonas.map((z) => ({ valor: String(z.idZona), texto: `${z.nombre} (${z.localidades})` })));
  const modalidad = campoSeleccion('modalidad', 'Modalidad', modalidades.map((m) => ({ valor: String(m.idModalidad), texto: `${legible(m.nombre)} (${m.plazoDiasHabiles} día(s) hábil(es))` })));
  const direccion = campoTexto('direccion-destino', 'Dirección de destino', { required: true, maxlength: 150 });
  const peso = campoTexto('peso-declarado', 'Peso declarado (kg)', { type: 'number', min: 0.01, step: 0.01, required: true });
  const contenido = campoTexto('contenido', 'Contenido', { required: true, maxlength: 150 });
  const valor = campoTexto('valor-declarado', 'Valor declarado (COP)', { type: 'number', min: 0, step: 1, required: true });
  const fragil = casilla('fragil', 'Frágil');
  const altoValor = casilla('alto-valor', 'Alto valor');
  const compromiso = campoTexto('fecha-compromiso', 'Fecha de compromiso (opcional: si se deja vacía se calcula con la modalidad)', { type: 'date' });
  const enviar = boton('registrar-envio', 'Registrar envío');

  const formulario = h('form', {
    id: 'formulario-envio',
    onsubmit: (ev: Event) => {
      ev.preventDefault();
      void ejecutar(enviar, avisos, async () => {
        const r = await api.post<EnvioRegistrado>('/api/mesa/envios', {
          idSolicitud: Number(solicitud.control.value),
          destinatario: {
            tipoDocumento: tipoDoc.control.value, numeroDocumento: documento.control.value.trim(), nombre: nombre.control.value.trim(),
            telefono: telefono.control.value.trim(), correo: correo.control.value.trim() || null,
          },
          idZona: Number(zona.control.value), idModalidad: Number(modalidad.control.value),
          direccionDestino: direccion.control.value.trim(), pesoDeclarado: Number(peso.control.value), contenido: contenido.control.value.trim(),
          valorDeclarado: Number(valor.control.value), fragil: fragil.control.checked, altoValor: altoValor.control.checked,
          fechaCompromiso: compromiso.control.value || null,
        });
        mostrarOk(avisos, h('span', {}, 'Envío registrado con la guía ', h('strong', { class: 'guia', 'data-prueba': 'guia-registrada' }, r.numeroGuia),
          '. Fecha de compromiso: ', h('span', { 'data-prueba': 'fecha-compromiso-calculada' }, formatoFecha(r.fechaCompromiso)), '. ',
          h('a', { href: `#/mesa/consulta/${r.numeroGuia}` }, 'Ver el envío'), '.'));
        for (const c of [documento, nombre, telefono, correo, direccion, peso, contenido, valor, compromiso]) {
          c.control.value = '';
        }
        fragil.control.checked = false;
        altoValor.control.checked = false;
        documento.control.focus();
      });
    },
  },
  h('fieldset', {}, h('legend', {}, 'Solicitud'), solicitud.contenedor),
  h('fieldset', {}, h('legend', {}, 'Destinatario'), h('div', { class: 'rejilla' }, tipoDoc.contenedor, documento.contenedor, nombre.contenedor, telefono.contenedor, correo.contenedor)),
  h('fieldset', {}, h('legend', {}, 'Envío'), h('div', { class: 'rejilla' }, zona.contenedor, modalidad.contenedor, direccion.contenedor, peso.contenedor, contenido.contenedor, valor.contenedor, compromiso.contenedor),
    fragil.contenedor, altoValor.contenedor),
  enviar);

  contenedor.append(h('h1', {}, 'Registrar envío'),
    h('p', { class: 'reglas' }, 'Un envío frágil o de alto valor solo se entrega al destinatario (RN06).'), formulario, avisos);
}
