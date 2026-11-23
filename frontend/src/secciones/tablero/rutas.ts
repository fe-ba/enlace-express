import type { Ruta } from '../../comun/enrutador';
import { vistaTablero } from './tablero';

export const rutasTablero: Ruta[] = [
  { patron: '/tablero', roles: ['GERENCIA'], titulo: 'Tablero', vista: vistaTablero },
];
