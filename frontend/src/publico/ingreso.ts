import { ejecutar, boton, campoTexto, h, zonaDeAvisos } from '../comun/ui';
import { iniciarSesion, inicioDelRol } from '../comun/sesion';
import { dibujarMenu } from '../comun/menu';
import { irA } from '../comun/enrutador';

export function vistaIngreso(contenedor: HTMLElement): void {
  const avisos = zonaDeAvisos();
  const usuario = campoTexto('usuario', 'Usuario', { autocomplete: 'username', required: true, autocapitalize: 'none' });
  const contrasena = campoTexto('contrasena', 'Contraseña', { type: 'password', autocomplete: 'current-password', required: true });
  const enviar = boton('ingresar', 'Ingresar');

  const formulario = h('form', {
    id: 'formulario-ingreso',
    onsubmit: (ev: Event) => {
      ev.preventDefault();
      void ejecutar(enviar, avisos, async () => {
        const u = await iniciarSesion(usuario.control.value.trim(), contrasena.control.value);
        dibujarMenu();
        irA(inicioDelRol(u.rol));
      });
    },
  }, usuario.contenedor, contrasena.contenedor, enviar);

  contenedor.append(
    h('h1', {}, 'Ingresar'),
    formulario, avisos,
    h('p', {}, '¿Primera vez? ', h('a', { href: '#/registro' }, 'Regístrese con su código de activación'), '.'),
  );
  usuario.control.focus();
}
