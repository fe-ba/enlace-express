// C1 y C2: consultar un envio y su recorrido; CU05: anularlo antes de salir a ruta.
import { api } from '../../comun/api';
import { claseDeEstado } from '../../comun/estados';
import { formatoFecha, formatoFechaHora, formatoMoneda, formatoPeso, legible } from '../../comun/formato';
import type { DetalleEnvio } from '../../comun/tipos';
import { boton, campoTexto, ejecutar, h, insignia, lineaDeTiempo, mostrarError, mostrarOk, vaciar, zonaDeAvisos } from '../../comun/ui';

export function vistaConsulta(contenedor: HTMLElement, guiaInicial: string | null): void {
  const avisos = zonaDeAvisos();
  const resultado = h('section', { id: 'detalle-envio', 'data-prueba': 'detalle-envio' });
  const guia = campoTexto('guia-consulta', 'Número de guía', { placeholder: 'EE0000000000003', maxlength: 15, required: true, autocomplete: 'off' });
  const buscar = boton('consultar-envio', 'Consultar');

  async function consultar(numero: string): Promise<void> {
    vaciar(resultado);
    vaciar(avisos);
    const d = await api.get<DetalleEnvio>(`/api/mesa/envios/${encodeURIComponent(numero)}`);
    const observacion = campoTexto('observacion-anulacion', 'Motivo de la anulación', { maxlength: 200, placeholder: 'Anulado a solicitud del cliente' });
    const anular = h('button', {
      id: 'anular-envio', 'data-prueba': 'anular-envio', type: 'button', class: 'secondary',
      onclick: () => {
        if (!window.confirm(`¿Anular el envío ${d.numeroGuia}? Solo es posible antes de salir a ruta.`)) {
          return;
        }
        void ejecutar(anular, avisos, async () => {
          const r = await api.post<{ numeroGuia: string; estadoActual: string }>(`/api/mesa/envios/${d.numeroGuia}/anular`, { observacion: observacion.control.value.trim() });
          mostrarOk(avisos, `El envío ${r.numeroGuia} quedó ${legible(r.estadoActual)}.`);
          await consultar(r.numeroGuia);
        });
      },
    }, 'Anular envío');
    const dest = d.destinatario;
    resultado.append(
      h('h2', {}, 'Guía ', h('span', { class: 'guia' }, d.numeroGuia), ' ', insignia(legible(d.estadoActual ?? 'REGISTRADO'), claseDeEstado(d.estadoActual ?? ''))),
      h('dl', { class: 'datos' },
        h('dt', {}, 'Registro'), h('dd', {}, formatoFecha(d.fechaRegistro)),
        h('dt', {}, 'Compromiso'), h('dd', {}, formatoFecha(d.fechaCompromiso)),
        h('dt', {}, 'Destinatario'), h('dd', {}, dest ? `${dest.nombre} (${dest.tipoDocumento} ${dest.numeroDocumento}), tel. ${dest.telefono}` : ''),
        h('dt', {}, 'Dirección'), h('dd', {}, d.direccionDestino),
        h('dt', {}, 'Contenido'), h('dd', {}, d.contenido),
        h('dt', {}, 'Peso'), h('dd', {}, `${formatoPeso(d.pesoDeclarado)} declarado${d.pesoReal !== null ? `, ${formatoPeso(d.pesoReal)} real` : ''}`),
        h('dt', {}, 'Valor declarado'), h('dd', {}, formatoMoneda(d.valorDeclarado)),
        h('dt', {}, 'Flete'), h('dd', {}, d.valorFlete !== null ? formatoMoneda(d.valorFlete) : 'Sin calcular'),
        h('dt', {}, 'Manejo'), h('dd', {}, [d.fragil ? 'Frágil' : '', d.altoValor ? 'Alto valor' : ''].filter(Boolean).join(', ') || 'Normal')),
      h('h3', {}, 'Recorrido'),
      lineaDeTiempo(d.recorrido.map((e) => ({ fecha: formatoFechaHora(e.fechaHora), estado: legible(e.estado), detalle: [e.observacion, e.responsable].filter(Boolean).join(' · ') }))),
      h('h3', {}, 'Anular'), observacion.contenedor, anular);
  }

  const formulario = h('form', {
    id: 'formulario-consulta',
    onsubmit: (ev: Event) => {
      ev.preventDefault();
      void ejecutar(buscar, avisos, () => consultar(guia.control.value.trim().toUpperCase()));
    },
  }, guia.contenedor, buscar);

  contenedor.append(h('h1', {}, 'Consultar envío'), formulario, avisos, resultado);
  if (guiaInicial) {
    guia.control.value = guiaInicial;
    consultar(guiaInicial).catch((e: unknown) => mostrarError(avisos, e));
  }
}
