import type { Ruta } from '../../comun/enrutador';
import { vistaDetalle, vistaLista } from './seguimiento';

export const rutasSeguimiento: Ruta[] = [
  { patron: '/seguimiento', roles: ['CLIENTE'], titulo: 'Mis envíos', vista: vistaLista },
  { patron: '/seguimiento/:guia', roles: ['CLIENTE'], titulo: 'Seguimiento del envío', vista: (c, p) => vistaDetalle(c, p['guia'] ?? '') },
];
