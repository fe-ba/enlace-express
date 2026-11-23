import type { Ruta } from '../comun/enrutador';
import { vistaIngreso } from './ingreso';
import { vistaRastreo } from './rastreo';
import { vistaRegistro } from './registro';

export const rutasPublicas: Ruta[] = [
  { patron: '/rastreo', titulo: 'Rastrear envío', vista: (c) => vistaRastreo(c, null) },
  { patron: '/rastreo/:guia', titulo: 'Rastrear envío', vista: (c, p) => vistaRastreo(c, p['guia'] ?? null) },
  { patron: '/ingreso', titulo: 'Ingresar', vista: vistaIngreso },
  { patron: '/registro', titulo: 'Registrarse', vista: vistaRegistro },
];
