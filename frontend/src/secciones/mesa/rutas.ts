import type { Ruta } from '../../comun/enrutador';
import { vistaConsulta } from './consulta';
import { vistaEnvio } from './envio';
import { vistaNovedades } from './novedades';
import { vistaReclamaciones } from './reclamaciones';
import { vistaSolicitud } from './solicitud';

export const rutasMesa: Ruta[] = [
  { patron: '/mesa/solicitud', roles: ['MESA'], titulo: 'Registrar solicitud', vista: vistaSolicitud },
  { patron: '/mesa/envio', roles: ['MESA'], titulo: 'Registrar envío', vista: vistaEnvio },
  { patron: '/mesa/novedades', roles: ['MESA'], titulo: 'Novedades', vista: vistaNovedades },
  { patron: '/mesa/reclamaciones', roles: ['MESA'], titulo: 'Reclamaciones', vista: vistaReclamaciones },
  { patron: '/mesa/consulta', roles: ['MESA'], titulo: 'Consultar envío', vista: (c) => vistaConsulta(c, null) },
  { patron: '/mesa/consulta/:guia', roles: ['MESA'], titulo: 'Consultar envío', vista: (c, p) => vistaConsulta(c, p['guia'] ?? null) },
];
