// CU14 a CU19: la planilla de ruta del mensajero y sus acciones: entregar con prueba, registrar novedad o devolver (tercer intento).
// Diseno para telefono: una columna y botones grandes.
import { api } from '../../comun/api';
import { legible } from '../../comun/formato';
import type { FilaPlanilla } from '../../comun/tipos';
import { boton, campoSeleccion, campoTexto, ejecutar, h, insignia, mostrarOk, vaciar, zonaDeAvisos } from '../../comun/ui';

type Accion = 'entrega' | 'novedad' | 'devolucion';

export async function vistaPlanilla(contenedor: HTMLElement): Promise<void> {
  const avisos = zonaDeAvisos();
  const lista = h('div', { id: 'lista-planilla', 'data-prueba': 'lista-planilla' });

  async function pintar(): Promise<void> {
    const filas = await api.get<FilaPlanilla[]>('/api/mensajero/planilla');
    vaciar(lista);
    if (filas.length === 0) {
      lista.append(h('p', { class: 'vacio' }, 'No tiene envíos en sus despachos abiertos.'));
      return;
    }
    let despacho = -1;
    for (const f of filas) {
      if (f.idDespacho !== despacho) {
        despacho = f.idDespacho;
        lista.append(h('h2', {}, `Despacho ${f.idDespacho}`));
      }
      lista.append(tarjeta(f));
    }
  }

  function tarjeta(f: FilaPlanilla): HTMLElement {
    const especial = f.fragil || f.altoValor;
    const pendiente = f.resultado === 'PENDIENTE';
    const partes: Node[] = [
      h('header', {}, h('strong', {}, `${f.ordenVisita}. `, h('span', { class: 'guia' }, f.numeroGuia)),
        pendiente ? insignia(`Intento ${f.numeroIntento}`) : insignia(legible(f.resultado), f.resultado === 'ENTREGADO' ? 'ok' : 'alerta')),
      h('p', {}, h('strong', {}, f.destinatario), h('br'), f.direccion, ` (${f.zona})`, h('br'),
        h('a', { class: 'telefono', href: `tel:${f.telefono}` }, f.telefono)),
    ];
    if (especial) {
      partes.push(h('p', { class: 'nota-especial' }, [f.fragil ? 'Frágil' : '', f.altoValor ? 'Alto valor' : ''].filter(Boolean).join(' y '),
        `: solo se entrega al destinatario (${f.tipoDocumentoDestinatario} ${f.numeroDocumentoDestinatario}).`));
    }
    if (pendiente) {
      // el tercer intento solo puede ser devolucion; los dos primeros, entrega o novedad
      if (f.numeroIntento < 3) {
        partes.push(desplegable(f, 'entrega', 'Entregar'), desplegable(f, 'novedad', 'Registrar novedad'));
      } else {
        partes.push(h('p', { class: 'reglas' }, 'Tercer intento: solo puede devolverse al remitente.'), desplegable(f, 'devolucion', 'Registrar devolución'));
      }
    }
    return h('article', { class: `tarjeta-visita${especial ? ' especial' : ''}`, 'data-guia': f.numeroGuia }, ...partes);
  }

  function desplegable(f: FilaPlanilla, accion: Accion, titulo: string): HTMLElement {
    const sufijo = `${accion}-${f.idAsignacion}`;
    const aviso = zonaDeAvisos(`aviso-${sufijo}`);
    const campos: HTMLElement[] = [];
    let nombre: ReturnType<typeof campoTexto> | undefined;
    let documento: ReturnType<typeof campoTexto> | undefined;
    let tipoPrueba: ReturnType<typeof campoSeleccion> | undefined;
    let tipoNovedad: ReturnType<typeof campoSeleccion> | undefined;
    let descripcion: ReturnType<typeof campoTexto> | undefined;
    if (accion === 'novedad') {
      tipoNovedad = campoSeleccion(`tipo-novedad-${sufijo}`, 'Tipo de novedad', [
        ['DESTINATARIO_AUSENTE', 'Destinatario ausente'], ['DIRECCION_ERRADA', 'Dirección errada'], ['RECHAZADO', 'Rechazado'],
        ['PAQUETE_AVERIADO', 'Paquete averiado'], ['OTRA', 'Otra']].map(([valor, texto]) => ({ valor: valor!, texto: texto! })));
      descripcion = campoTexto(`descripcion-${sufijo}`, 'Descripción', { required: true, maxlength: 300 });
      campos.push(tipoNovedad.contenedor, descripcion.contenedor);
    } else {
      nombre = campoTexto(`nombre-receptor-${sufijo}`, accion === 'entrega' ? 'Nombre de quien recibe' : 'Nombre de quien recibe la devolución', { required: true, maxlength: 100, autocomplete: 'off' });
      documento = campoTexto(`documento-receptor-${sufijo}`, 'Documento de quien recibe', { required: true, maxlength: 15, autocomplete: 'off' });
      if (f.fragil || f.altoValor) {
        documento.control.value = accion === 'entrega' ? f.numeroDocumentoDestinatario : '';
      }
      tipoPrueba = campoSeleccion(`tipo-prueba-${sufijo}`, 'Tipo de prueba', [
        { valor: 'DOCUMENTO', texto: 'Documento' }, { valor: 'FIRMA', texto: 'Firma' }, { valor: 'FOTOGRAFIA', texto: 'Fotografía' }]);
      campos.push(nombre.contenedor, documento.contenedor, tipoPrueba.contenedor);
    }
    const enviar = boton(`confirmar-${sufijo}`, titulo, accion === 'novedad' ? { class: 'secondary' } : {});
    const formulario = h('form', {
      onsubmit: (ev: Event) => {
        ev.preventDefault();
        void ejecutar(enviar, aviso, async () => {
          const cuerpo = accion === 'novedad'
            ? { tipoNovedad: tipoNovedad!.control.value, descripcion: descripcion!.control.value.trim() }
            : { nombreReceptor: nombre!.control.value.trim(), documentoReceptor: documento!.control.value.trim(), tipoPrueba: tipoPrueba!.control.value };
          const r = await api.post<{ resultado: string; estadoEnvio: string }>(`/api/mensajero/asignaciones/${f.idAsignacion}/${accion}`, cuerpo);
          mostrarOk(avisos, `Guía ${f.numeroGuia}: ${legible(r.estadoEnvio)}.`);
          await pintar();
        });
      },
    }, ...campos, enviar, aviso);
    return h('details', { id: `detalle-${sufijo}`, 'data-prueba': `detalle-${sufijo}` },
      h('summary', { role: 'button', class: accion === 'novedad' ? 'secondary' : '' }, titulo), formulario);
  }

  contenedor.append(h('div', { class: 'movil' }, h('h1', {}, 'Mi planilla'), avisos, lista));
  await pintar();
}
