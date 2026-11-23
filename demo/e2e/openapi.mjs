// Captura de Swagger UI (documentacion de la API, decision E3) con Chromium sin cabeza.
import { chromium } from 'playwright-core';

const BASE = process.env.URL_APP ?? 'http://localhost:8080/';
const navegador = await chromium.launch();
const ctx = await navegador.newContext({ locale: 'es-CO', viewport: { width: 1280, height: 900 } });
const p = await ctx.newPage();
await p.goto(BASE + 'swagger-ui.html');
await p.waitForSelector('.swagger-ui .opblock-tag');
// se despliega la seccion de la mesa para que se vean sus rutas con el rol que exigen
await p.click('.opblock-tag[data-tag="Mesa de servicio"]');
await p.waitForSelector('.opblock-tag-section.is-open .opblock');
await p.evaluate(() => window.scrollTo(0, 0));
await p.waitForTimeout(500);
await p.screenshot({ path: '/salida/13_swagger_ui.png', fullPage: false });
await navegador.close();
console.log('captura guardada: 13_swagger_ui.png');
