package co.enlaceexpress.datos;

import org.junit.jupiter.api.extension.BeforeAllCallback;
import org.junit.jupiter.api.extension.ExtensionContext;

/**
 * Se registra sola (ServiceLoader) y, antes de cualquier clase de integracion (*IT), prepara el
 * entorno: en modo Testcontainers levanta el Oracle de la corrida antes de que Spring cree su
 * contexto. Las pruebas unitarias (*Test) no lo usan.
 */
public class ExtensionEntornoPruebas implements BeforeAllCallback {

    @Override
    public void beforeAll(ExtensionContext contexto) {
        if (contexto.getRequiredTestClass().getSimpleName().endsWith("IT")) {
            EntornoPruebas.asegurar();
        }
    }
}
