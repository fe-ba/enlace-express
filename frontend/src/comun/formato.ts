// Formato de fechas, moneda y pesos en es-CO. La API entrega fechas sin zona (hora de Bogota): se muestran
// tal cual, sin convertirlas a la zona del navegador.

const fecha = new Intl.DateTimeFormat('es-CO', { day: '2-digit', month: 'short', year: 'numeric', timeZone: 'UTC' });
const fechaHora = new Intl.DateTimeFormat('es-CO', {
  day: '2-digit', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit', hour12: true, timeZone: 'UTC',
});
const moneda = new Intl.NumberFormat('es-CO', { style: 'currency', currency: 'COP', maximumFractionDigits: 0 });
const decimal = new Intl.NumberFormat('es-CO', { maximumFractionDigits: 2 });

/** Interpreta "2026-11-03" o "2026-11-03T08:33:00" como hora de pared de Bogota. */
function comoUtc(texto: string): Date {
  const m = /^(\d{4})-(\d{2})-(\d{2})(?:T(\d{2}):(\d{2})(?::(\d{2}))?)?/.exec(texto);
  if (!m) {
    return new Date(NaN);
  }
  return new Date(Date.UTC(+m[1]!, +m[2]! - 1, +m[3]!, +(m[4] ?? 0), +(m[5] ?? 0), +(m[6] ?? 0)));
}

export function formatoFecha(texto: string | null | undefined): string {
  if (!texto) {
    return '';
  }
  const d = comoUtc(texto);
  return Number.isNaN(d.getTime()) ? texto : fecha.format(d);
}

export function formatoFechaHora(texto: string | null | undefined): string {
  if (!texto) {
    return '';
  }
  const d = comoUtc(texto);
  return Number.isNaN(d.getTime()) ? texto : fechaHora.format(d);
}

export function formatoMoneda(valor: number | null | undefined): string {
  return valor === null || valor === undefined ? '' : moneda.format(valor);
}

export function formatoPeso(kg: number | null | undefined): string {
  return kg === null || kg === undefined ? '' : `${decimal.format(kg)} kg`;
}

export function formatoNumero(valor: number): string {
  return decimal.format(valor);
}

/** La fecha de hoy en Bogota como "AAAA-MM-DD", para los campos de fecha. */
export function hoy(): string {
  const partes = new Intl.DateTimeFormat('en-CA', { timeZone: 'America/Bogota', year: 'numeric', month: '2-digit', day: '2-digit' })
    .format(new Date());
  return partes;
}

/** Valores de los dominios que en la base van sin tilde o abreviados; en pantalla se escriben bien. */
const ROTULOS: Record<string, string> = {
  DANO: 'Daño',
  FACTURACION: 'Facturación',
  MANANA: 'Mañana',
  MISMO_DIA: 'Mismo día',
  DIA_SIGUIENTE: 'Día siguiente',
  BICICLETA_ELECTRICA: 'Bicicleta eléctrica',
  DEVOLUCION: 'Devolución',
  DIRECCION_ERRADA: 'Dirección errada',
  FOTOGRAFIA: 'Fotografía',
  TIENDA_LINEA: 'Tienda en línea',
  DROGUERIA: 'Droguería',
  RECOLECCION: 'Recolección',
  EN_MANTENIMIENTO: 'En mantenimiento',
  CON_NOVEDAD: 'Con novedad',
  NOVEDAD: 'Novedad',
  OTRO: 'Otro',
  OTRA: 'Otra',
};

/** "ENTREGADO" -> "Entregado"; "CON_NOVEDAD" -> "Con novedad"; "DANO" -> "Daño". */
export function legible(codigo: string): string {
  const conocido = ROTULOS[codigo];
  if (conocido) {
    return conocido;
  }
  const texto = codigo.toLowerCase().replaceAll('_', ' ');
  return texto.charAt(0).toUpperCase() + texto.slice(1);
}
