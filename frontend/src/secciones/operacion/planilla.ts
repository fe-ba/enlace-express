// C3 y CU12: planilla de un despacho y cierre.
import { api } from '../../comun/api';
import { legible } from '../../comun/formato';
import type { FilaPlanilla } from '../../comun/tipos';
import { boton, campoTexto, ejecutar, h, insignia, mostrarOk, tabla, vaciar, zonaDeAvisos } from '../../comun/ui';

export function vistaPlanilla(contenedor: HTMLElement, idInicial: string | null): void {
  const avisos = zonaDeAvisos();
  const resultado = h('section', { id: 'planilla-despacho', 'data-prueba': 'planilla-despacho' });
  const id = campoTexto('id-despacho', 'Número de despacho', { type: 'number', min: 1, required: true });
  const buscar = boton('ver-planilla', 'Ver planilla');

  async function mostrar(numero: string): Promise<void> {
    vaciar(resultado);
    const filas = await api.get<FilaPlanilla[]>(`/api/centro/despachos/${numero}/planilla`);
    const cerrar = h('button', {
      id: 'cerrar-despacho', 'data-prueba': 'cerrar-despacho', type: 'button', class: 'secondary',
      onclick: () => {
        if (!window.confirm(`¿Cerrar el despacho ${numero}?`)) {
          return;
        }
        void ejecutar(cerrar, avisos, async () => {
          await api.post(`/api/centro/despachos/${numero}/cerrar`);
          mostrarOk(avisos, `El despacho ${numero} quedó cerrado.`);
          await mostrar(numero);
        });
      },
    }, 'Cerrar despacho');
    resultado.append(h('h2', {}, `Despacho ${numero}`), tabla<FilaPlanilla>([
      { titulo: 'Orden', valor: (f) => String(f.ordenVisita), clase: 'numero' },
      { titulo: 'Guía', valor: (f) => h('span', { class: 'guia' }, f.numeroGuia) },
      { titulo: 'Destinatario', valor: (f) => f.destinatario },
      { titulo: 'Teléfono', valor: (f) => f.telefono },
      { titulo: 'Dirección', valor: (f) => f.direccion },
      { titulo: 'Zona', valor: (f) => f.zona },
      { titulo: 'Manejo', valor: (f) => [f.fragil ? insignia('Frágil', 'alerta') : null, f.altoValor ? insignia('Alto valor', 'alerta') : null] },
      { titulo: 'Intento', valor: (f) => String(f.numeroIntento), clase: 'numero' },
      { titulo: 'Resultado', valor: (f) => insignia(legible(f.resultado), f.resultado === 'ENTREGADO' ? 'ok' : f.resultado === 'PENDIENTE' ? '' : 'alerta') },
    ], filas, 'El despacho no tiene envíos.', 'tabla-planilla'), cerrar);
  }

  const formulario = h('form', {
    id: 'formulario-planilla',
    onsubmit: (ev: Event) => {
      ev.preventDefault();
      vaciar(avisos);
      window.location.hash = `#/operacion/planilla/${id.control.value.trim()}`;
    },
  }, id.contenedor, buscar);

  contenedor.append(h('h1', {}, 'Planilla de despacho'), formulario, avisos, resultado);
  if (idInicial) {
    id.control.value = idInicial;
    void ejecutar(buscar, avisos, () => mostrar(idInicial));
  }
}
