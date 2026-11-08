<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport"
          content="width=device-width, initial-scale=1.0">

    <title><?= htmlspecialchars($titulo ?? 'OceanConta') ?></title>

    <link rel="stylesheet" href="/css/estilo.css">
</head>

<body>

<header class="header-principal">

    <div class="header-contenido">

        <div class="header-marca">
            <h1>Ocean</h1>
            <p>
                Sistema de Gestión Contable - Ocean Express
            </p>
        </div>

        <?php if ($pagina !== 'inicio'): ?>

            <nav class="menu-navegacion">

                <a href="/index.php"
                   class="<?= $pagina === 'inicio' ? 'activo' : '' ?>">
                    Inicio
                </a>

                <a href="/index.php?pagina=contabilidad"
                   class="<?= $pagina === 'contabilidad' ? 'activo' : '' ?>">
                    Contabilidad
                </a>

                <a href="/index.php?pagina=costos"
                   class="<?= $pagina === 'costos' ? 'activo' : '' ?>">
                    Costos
                </a>

                <a href="/index.php?pagina=verificacion"
                   class="<?= $pagina === 'verificacion' ? 'activo' : '' ?>">
                    Verificación
                </a>

            </nav>

        <?php endif; ?>

    </div>

</header>

<main>