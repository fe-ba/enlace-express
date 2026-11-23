// Tablero de la gerencia (U1): cumplimiento por zona (OE1), envios por estado y reclamaciones pendientes (OE2).
import { BarController, BarElement, CategoryScale, Chart, Legend, LinearScale, Tooltip } from 'chart.js';
import { api } from '../../comun/api';
import { formatoFechaHora, formatoNumero, legible } from '../../comun/formato';
import type { FilaConteo, FilaCumplimiento, FilaReclamacion } from '../../comun/tipos';
import { campoSeleccion, h, mostrarError, tabla, vaciar, zonaDeAvisos } from '../../comun/ui';

Chart.register(BarController, BarElement, CategoryScale, LinearScale, Tooltip, Legend);

let graficos: Chart[] = [];

function grafico(id: string, etiquetas: string[], valores: number[], titulo: string, maximo?: number): HTMLElement {
  const lienzo = h('canvas', { id, 'data-prueba': id, role: 'img', 'aria-label': titulo });
  queueMicrotask(() => {
    const opciones = { animation: false as const, responsive: true, maintainAspectRatio: false, plugins: { legend: { display: false } },
      scales: { y: { beginAtZero: true, ...(maximo ? { max: maximo } : {}) } } };
    graficos.push(new Chart(lienzo, {
      type: 'bar', data: { labels: etiquetas, datasets: [{ label: titulo, data: valores, backgroundColor: '#1095c1' }] }, options: opciones,
    }));
  });
  return h('div', { class: 'grafico' }, lienzo);
}

export async function vistaTablero(contenedor: HTMLElement): Promise<void> {
  graficos.forEach((g) => g.destroy());
  graficos = [];
  const avisos = zonaDeAvisos();
  const centro = campoSeleccion('centro', 'Centro de distribución', [
    { valor: '', texto: 'Todos los centros' }, { valor: '1', texto: 'Centro Norte (1)' }, { valor: '2', texto: 'Centro Sur (2)' }]);
  const zona = h('div', { id: 'zona-tablero', 'data-prueba': 'zona-tablero' });

  async function pintar(): Promise<void> {
    graficos.forEach((g) => g.destroy());
    graficos = [];
    const parametro = centro.control.value === '' ? '' : `?centro=${centro.control.value}`;
    const [cumplimiento, estados, reclamaciones] = await Promise.all([
      api.get<FilaCumplimiento[]>(`/api/tablero/cumplimiento${parametro}`),
      api.get<FilaConteo[]>(`/api/tablero/envios-por-estado${parametro}`),
      api.get<FilaReclamacion[]>('/api/tablero/reclamaciones-pendientes'),
    ]);
    vaciar(zona);
    zona.append(
      h('h2', {}, 'Cumplimiento de entregas por zona'),
      h('p', { class: 'reglas' }, 'Porcentaje de envíos entregados dentro de la fecha de compromiso (meta de calidad del servicio).'),
      grafico('grafico-cumplimiento', cumplimiento.map((f) => f.zona), cumplimiento.map((f) => f.porcentajeATiempo), '% entregado a tiempo', 100),
      tabla<FilaCumplimiento>([
        { titulo: 'Zona', valor: (f) => f.zona },
        { titulo: 'Entregados', valor: (f) => formatoNumero(f.entregados), clase: 'numero' },
        { titulo: 'A tiempo', valor: (f) => formatoNumero(f.entregadosATiempo), clase: 'numero' },
        { titulo: '% a tiempo', valor: (f) => `${formatoNumero(f.porcentajeATiempo)} %`, clase: 'numero' },
      ], cumplimiento, 'Todavía no hay entregas.', 'tabla-cumplimiento'),
      h('h2', {}, 'Envíos por estado'),
      grafico('grafico-estados', estados.map((f) => legible(f.etiqueta)), estados.map((f) => f.total), 'Envíos'),
      tabla<FilaConteo>([
        { titulo: 'Estado', valor: (f) => legible(f.etiqueta) },
        { titulo: 'Envíos', valor: (f) => formatoNumero(f.total), clase: 'numero' },
      ], estados, 'No hay envíos.', 'tabla-estados'),
      h('h2', {}, 'Reclamaciones pendientes'),
      tabla<FilaReclamacion>([
        { titulo: 'Radicada', valor: (f) => formatoFechaHora(f.fechaRadicacion) },
        { titulo: 'Cliente', valor: (f) => f.cliente },
        { titulo: 'Guía', valor: (f) => f.numeroGuia ?? 'Sin guía' },
        { titulo: 'Tipo', valor: (f) => legible(f.tipo) },
        { titulo: 'Descripción', valor: (f) => f.descripcion },
        { titulo: 'Horas', valor: (f) => formatoNumero(f.horasTranscurridas), clase: 'numero' },
      ], reclamaciones, 'No hay reclamaciones pendientes.', 'tabla-reclamaciones'),
    );
  }

  centro.control.addEventListener('change', () => void pintar().catch((e: unknown) => mostrarError(avisos, e)));
  contenedor.append(h('h1', {}, 'Tablero de la gerencia'), centro.contenedor, avisos, zona);
  await pintar();
}
