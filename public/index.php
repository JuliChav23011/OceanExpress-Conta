<?php
declare(strict_types=1);

$pagina = $_GET['pagina'] ?? 'inicio';
$accion = $_GET['accion'] ?? 'index';

$paginas = [
    'inicio' => null,
    'contabilidad' => __DIR__ . '/../app/views/contabilidad/index.php',
    'costos' => __DIR__ . '/../app/views/costos/index.php',
    'verificacion' => __DIR__ . '/../app/views/verificacion/index.php'
];

if (!array_key_exists($pagina, $paginas)) {
    http_response_code(404);
    $pagina = 'error';
}

$contabilidadController = null;
if ($pagina === 'contabilidad') {
    require_once __DIR__ . '/../app/controllers/contabilidad/ContabilidadController.php';
    $contabilidadController = new ContabilidadController();

    $accionesPost = ['guardarAsiento', 'guardarCuenta', 'editarCuenta', 'eliminarCuenta'];
    if ($_SERVER['REQUEST_METHOD'] === 'POST' && in_array($accion, $accionesPost, true)) {
        $contabilidadController->$accion();
        exit;
    }
}

$titulo = ucfirst($pagina) . ' - OceanConta';

require_once __DIR__ . '/../app/views/layouts/header.php';

if ($pagina === 'inicio') {
?>

<section class="panel-modulos">

    <div class="titulo-seccion">
        <h2>Bienvenidos a Ocean-Express</h2>
        <p>Selecciona el módulo que deseas utilizar.</p>
    </div>

    <div class="contenedor-tarjetas">

        <a href="/index.php?pagina=contabilidad"
            class="tarjeta-modulo">

            <div class="icono-modulo">📒</div>

            <h3>Contabilidad</h3>

            <p>
                Gestiona el libro diario, cuentas T,
                ajustes y estados financieros.
            </p>

            <span class="boton-ingresar">
                Ingresar al módulo &rarr;
            </span>
        </a>

        <a href="/index.php?pagina=costos"
            class="tarjeta-modulo">

            <div class="icono-modulo">📊</div>

            <h3>Sistema de Costos</h3>

            <p>
                Registra, clasifica y calcula
                los costos de los servicios.
            </p>

            <span class="boton-ingresar">
                Ingresar al módulo &rarr;
            </span>
        </a>

        <a href="/index.php?pagina=verificacion"
            class="tarjeta-modulo">

            <div class="icono-modulo">✅</div>

            <h3>Verificación</h3>

            <p>
                Compara los resultados manuales
                con los calculados por el sistema.
            </p>

            <span class="boton-ingresar">
                Ingresar al módulo &rarr;
            </span>
        </a>

    </div>
</section>

<?php
} elseif ($pagina === 'error') {
    echo '<h2>Página no encontrada</h2>';
} elseif ($pagina === 'contabilidad' && $contabilidadController != null) {
    $contabilidadController->index();
}
else {
    require $paginas[$pagina];
}

require_once __DIR__ . '/../app/views/layouts/footer.php';
?>