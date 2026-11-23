// Rastreo publico por guia (CU20, D2): sin sesion; solo fecha, estado y zona de cada evento.
import { api, ErrorApi } from '../comun/api';
import { formatoFechaHora, legible } from '../comun/formato';
import { boton, campoTexto, h, lineaDeTiempo, mostrarError, vaciar, zonaDeAvisos, insignia } from '../comun/ui';
import type { Rastreo } from '../comun/tipos';
import { claseDeEstado } from '../comun/estados';

export function vistaRastreo(contenedor: HTMLElement, guiaInicial: string | null): void {
  const avisos = zonaDeAvisos();
  const resultado = h('section', { id: 'resultado-rastreo', 'data-prueba': 'resultado-rastreo', 'aria-live': 'polite' });
  const guia = campoTexto('guia', 'Número de guía', {
    placeholder: 'EE0000000000003', maxlength: 15, autocomplete: 'off', inputmode: 'text', required: true,
  });
  const enviar = boton('rastrear', 'Rastrear');

  async function consultar(numero: string): Promise<void> {
    vaciar(resultado);
    vaciar(avisos);
    const limpio = numero.trim().toUpperCase();
    if (limpio === '') {
      return;
    }
    enviar.setAttribute('aria-busy', 'true');
    try {
      const r = await api.get<Rastreo>(`/api/publico/rastreo/${encodeURIComponent(limpio)}`);
      resultado.append(
        h('h2', {}, 'Guía ', h('span', { class: 'guia' }, r.guia)),
        h('p', {}, 'Estado actual: ', insignia(legible(r.estadoActual), claseDeEstado(r.estadoActual))),
        lineaDeTiempo(r.eventos.map((e) => ({ fecha: formatoFechaHora(e.fechaHora), estado: legible(e.estado), detalle: `Zona ${e.zona}` }))),
      );
    } catch (e) {
      if (e instanceof ErrorApi && e.estado === 404) {
        mostrarError(avisos, new ErrorApi(404, e.codigo, 'No encontramos un envío con ese número de guía. Revise que empiece con EE y tenga 13 dígitos.'));
      } else if (e instanceof ErrorApi && e.estado === 429) {
        const espera = typeof e.propiedades['reintentarEnSegundos'] === 'number' ? e.propiedades['reintentarEnSegundos'] : 60;
        mostrarError(avisos, new ErrorApi(429, e.codigo, `Hizo demasiadas consultas seguidas. Intente de nuevo en ${espera} segundos.`));
      } else {
        mostrarError(avisos, e);
      }
    } finally {
      enviar.removeAttribute('aria-busy');
    }
  }

  const formulario = h('form', {
    id: 'formulario-rastreo',
    onsubmit: (ev: Event) => {
      ev.preventDefault();
      window.location.hash = `#/rastreo/${encodeURIComponent(guia.control.value.trim().toUpperCase())}`;
    },
  }, guia.contenedor, enviar);

  contenedor.append(
    h('h1', {}, 'Rastree su envío'),
    h('p', {}, 'Escriba el número de guía para ver el estado de su envío. No necesita una cuenta.'),
    formulario, avisos, resultado,
  );
  if (guiaInicial) {
    guia.control.value = guiaInicial;
    void consultar(guiaInicial);
  }
}
