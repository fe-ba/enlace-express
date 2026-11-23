import type { Ruta } from '../../comun/enrutador';
import { vistaPlanilla } from './planilla';
import { vistaRecolecciones } from './recolecciones';

export const rutasMensajero: Ruta[] = [
  { patron: '/mensajero/planilla', roles: ['MENSAJERO'], titulo: 'Mi planilla', vista: vistaPlanilla },
  { patron: '/mensajero/recolecciones', roles: ['MENSAJERO'], titulo: 'Recolecciones', vista: vistaRecolecciones },
];
