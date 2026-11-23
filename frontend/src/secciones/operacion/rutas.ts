import type { Ruta } from '../../comun/enrutador';
import { vistaCentros } from './centros';
import { vistaDespacho } from './despacho';
import { vistaPlanilla } from './planilla';
import { vistaRecepcion } from './recepcion';

export const rutasOperacion: Ruta[] = [
  { patron: '/operacion/recepcion', roles: ['CENTRO'], titulo: 'Recepción y clasificación', vista: vistaRecepcion },
  { patron: '/operacion/despacho', roles: ['CENTRO'], titulo: 'Armar despacho', vista: vistaDespacho },
  { patron: '/operacion/centros', roles: ['CENTRO'], titulo: 'Centros y zonas', vista: vistaCentros },
  { patron: '/operacion/planilla', roles: ['CENTRO'], titulo: 'Planilla de despacho', vista: (c) => vistaPlanilla(c, null) },
  { patron: '/operacion/planilla/:id', roles: ['CENTRO'], titulo: 'Planilla de despacho', vista: (c, p) => vistaPlanilla(c, p['id'] ?? null) },
];
