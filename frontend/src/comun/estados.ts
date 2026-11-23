/** Clase de color de la insignia segun el estado del envio. */
export function claseDeEstado(estado: string): string {
  switch (estado) {
    case 'ENTREGADO': return 'ok';
    case 'CON_NOVEDAD':
    case 'DEVUELTO': return 'alerta';
    case 'ANULADO': return 'peligro';
    default: return '';
  }
}
