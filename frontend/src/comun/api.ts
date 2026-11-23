// Cliente de la API: mismo origen, cookie de sesion, token CSRF y errores Problem Details.

/** Error de la API: lleva el estado HTTP, el codigo de la regla (RN07, E1, ...) y el detalle legible. */
export class ErrorApi extends Error {
  constructor(
    readonly estado: number,
    readonly codigo: string,
    readonly detalle: string,
    readonly propiedades: Record<string, unknown> = {},
  ) {
    super(detalle);
  }

  /** Texto para el usuario, con el codigo de la regla si es una regla de negocio ("RN06: ..."). */
  get mensaje(): string {
    return /^(RN\d{2}|E\d+)$/.test(this.codigo) ? `${this.codigo}: ${this.detalle}` : this.detalle;
  }
}

/** Se emite cuando una respuesta 401 indica que la sesion ya no es valida. */
export const EVENTO_SESION_EXPIRADA = 'sesion-expirada';

function cookie(nombre: string): string | null {
  for (const parte of document.cookie.split(';')) {
    const [clave, ...valor] = parte.trim().split('=');
    if (clave === nombre) {
      return decodeURIComponent(valor.join('='));
    }
  }
  return null;
}

/** El token CSRF vive en la cookie XSRF-TOKEN; si todavia no existe se pide a /api/csrf. */
async function tokenCsrf(): Promise<string> {
  let token = cookie('XSRF-TOKEN');
  if (token === null) {
    await fetch('/api/csrf', { credentials: 'same-origin' });
    token = cookie('XSRF-TOKEN');
  }
  if (token === null) {
    throw new ErrorApi(0, 'SIN_CSRF', 'No se pudo obtener el token de seguridad; recargue la página.');
  }
  return token;
}

async function leerError(respuesta: Response): Promise<ErrorApi> {
  const tipo = respuesta.headers.get('Content-Type') ?? '';
  if (tipo.includes('json')) {
    try {
      const p = (await respuesta.json()) as Record<string, unknown>;
      return new ErrorApi(
        respuesta.status,
        typeof p['codigo'] === 'string' ? p['codigo'] : `HTTP_${respuesta.status}`,
        typeof p['detail'] === 'string' ? p['detail'] : 'No se pudo completar la operación.',
        p,
      );
    } catch {
      // cuerpo ilegible: se informa solo el estado
    }
  }
  return new ErrorApi(respuesta.status, `HTTP_${respuesta.status}`, 'No se pudo completar la operación.');
}

async function pedir<T>(metodo: 'GET' | 'POST', ruta: string, cuerpo?: unknown): Promise<T> {
  const encabezados: Record<string, string> = { Accept: 'application/json, application/problem+json' };
  const opciones: RequestInit = { method: metodo, credentials: 'same-origin', headers: encabezados };
  if (metodo === 'POST') {
    encabezados['Content-Type'] = 'application/json';
    encabezados['X-XSRF-TOKEN'] = await tokenCsrf();
    opciones.body = JSON.stringify(cuerpo ?? {});
  }
  let respuesta: Response;
  try {
    respuesta = await fetch(ruta, opciones);
  } catch {
    throw new ErrorApi(0, 'SIN_CONEXION', 'No hay conexión con el servidor. Intente de nuevo.');
  }
  if (!respuesta.ok) {
    const error = await leerError(respuesta);
    if (respuesta.status === 401 && ruta !== '/api/sesion') {
      window.dispatchEvent(new Event(EVENTO_SESION_EXPIRADA));
    }
    throw error;
  }
  if (respuesta.status === 204) {
    return undefined as T;
  }
  return (await respuesta.json()) as T;
}

export const api = {
  get: <T>(ruta: string): Promise<T> => pedir<T>('GET', ruta),
  post: <T>(ruta: string, cuerpo?: unknown): Promise<T> => pedir<T>('POST', ruta, cuerpo),
};
