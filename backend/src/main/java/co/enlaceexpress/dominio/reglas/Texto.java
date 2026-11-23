package co.enlaceexpress.dominio.reglas;

/** Validacion de los textos de entrada: obligatorios u opcionales, sin espacios sobrantes y con su longitud maxima. */
public final class Texto {

    private Texto() {
    }

    /** Texto obligatorio: sin espacios en los extremos, no vacio y de a lo sumo {@code maximo} caracteres. */
    public static String obligatorio(String campo, String etiqueta, String valor, int maximo) {
        String texto = valor == null ? "" : valor.strip();
        if (texto.isEmpty()) {
            throw new EntradaInvalida(campo, "El campo " + etiqueta + " es obligatorio");
        }
        return acotar(campo, etiqueta, texto, maximo);
    }

    /** Texto opcional: nulo si viene vacio. */
    public static String opcional(String campo, String etiqueta, String valor, int maximo) {
        String texto = valor == null ? "" : valor.strip();
        return texto.isEmpty() ? null : acotar(campo, etiqueta, texto, maximo);
    }

    private static String acotar(String campo, String etiqueta, String texto, int maximo) {
        if (texto.length() > maximo) {
            throw new EntradaInvalida(campo, "El campo " + etiqueta + " no puede pasar de " + maximo + " caracteres");
        }
        return texto;
    }
}
