<link rel="stylesheet" href="assets/css/contabilidad.css">

<div class="conta-module">
    <div class="conta-topbar">
        <div>
            <strong>Módulo de Contabilidad</strong>
            <span class="text-muted">· Ocean Express</span>
        </div>
        <nav class="nav-tabs">
            <a href="/index.php?pagina=contabilidad&tab=catalogo" class="nav-tab <?= $tab === 'catalogo' ? 'active' : '' ?>">1. Catálogo de Cuentas</a>
            <a href="/index.php?pagina=contabilidad&tab=diario" class="nav-tab <?= $tab === 'diario' ? 'active' : '' ?>">2. Libro Diario</a>
            <a href="/index.php?pagina=contabilidad&tab=mayor" class="nav-tab <?= $tab === 'mayor' ? 'active' : '' ?>">3. Libro Mayor</a>
            <a href="/index.php?pagina=contabilidad&tab=balanza" class="nav-tab <?= $tab === 'balanza' ? 'active' : '' ?>">4. Balanza</a>
            <a href="/index.php?pagina=contabilidad&tab=hoja_trabajo" class="nav-tab <?= $tab === 'hoja_trabajo' ? 'active' : '' ?>">5. Hoja de Trabajo</a>
            <a href="/index.php?pagina=contabilidad&tab=estados" class="nav-tab <?= $tab === 'estados' ? 'active' : '' ?>">6. Estados Financieros</a>
        </nav>
    </div>

    <?php if (!empty($flashExito)): ?>
        <div class="alert alert-ok" id="alertaFlash">
            <span><?= htmlspecialchars($flashExito) ?></span>
            <button type="button" class="alert-close" onclick="this.parentElement.remove()">&times;</button>
        </div>
    <?php endif; ?>
    <?php if (!empty($flashError)): ?>
        <div class="alert alert-err" id="alertaFlash">
            <span><?= htmlspecialchars($flashError) ?></span>
            <button type="button" class="alert-close" onclick="this.parentElement.remove()">&times;</button>
        </div>
    <?php endif; ?>

    <?php if ($tab === 'catalogo'): ?>
    <div class="grid-2-asymmetric">
        <section class="card">
            <h2 class="card-title" id="tituloFormCuenta">Nueva cuenta contable</h2>
            <p class="card-sub">Registro y edición en el catálogo de Ocean Express</p>

            <form method="POST" action="/index.php?pagina=contabilidad&accion=guardarCuenta" id="formCuenta">
                <input type="hidden" name="id_cuenta" id="editIdCuenta" value="">

                <div class="form-group">
                    <label for="cuentaCodigo">Código contable *</label>
                    <input type="text" name="codigo" id="cuentaCodigo" placeholder="Ej. 5102-01" required>
                </div>

                <div class="form-group">
                    <label for="cuentaNombre">Nombre de la cuenta *</label>
                    <input type="text" name="nombre" id="cuentaNombre" placeholder="Ej. Energía eléctrica" required>
                </div>

                <div class="form-group">
                    <label for="cuentaTipo">Clasificación *</label>
                    <select name="tipo" id="cuentaTipo" required>
                        <option value="activo">Activo</option>
                        <option value="pasivo">Pasivo</option>
                        <option value="patrimonio">Patrimonio</option>
                        <option value="ingreso">Ingreso</option>
                        <option value="costo">Costo</option>
                        <option value="gasto">Gasto</option>
                    </select>
                </div>

                <div class="form-group">
                    <label for="cuentaTipo">Clasificación *</label>
                    <select name="tipo" id="cuentaTipo" required>
                        <option value="activo">Activo</option>
                        <option value="pasivo">Pasivo</option>
                        <option value="patrimonio">Patrimonio</option>
                        <option value="ingreso">Ingreso</option>
                        <option value="costo">Costo</option>
                        <option value="gasto">Gasto</option>
                    </select>
                </div>

                <div class="form-group">
                    <label for="cuentaPadre">Cuenta padre (Jerarquía)</label>
                    <select name="id_cuenta_padre" id="cuentaPadre">
                        <option value="">Ninguna (Cuenta raíz / Rubro principal)</option>
                        <?php foreach ($catalogoCuentas as $padre): ?>
                            <?php if (!$padre['acepta_movimientos']): ?>
                                <option value="<?= $padre['id_cuenta'] ?>" data-codigo="<?= htmlspecialchars($padre['codigo']) ?>" data-tipo="<?= htmlspecialchars($padre['tipo']) ?>">
                                    <?= htmlspecialchars($padre['codigo'] . ' - ' . $padre['nombre']) ?>
                                </option>
                            <?php endif; ?>
                        <?php endforeach; ?>
                    </select>
                </div>

                <div class="form-group checkbox-row">
                    <input type="checkbox" name="acepta_movimientos" id="cuentaAcepta" checked>
                    <label for="cuentaAcepta" class="no-margin">Acepta movimientos en Libro Diario (Subcuenta)</label>
                </div>

                <button type="submit" class="btn btn-primary" id="btnGuardarCuenta">Guardar cuenta</button>
                <button type="button" class="btn btn-secondary" id="btnCancelarEdicion" style="display:none;">Cancelar edición</button>
            </form>
        </section>

        <section class="card">
            <h2 class="card-title">Catálogo de Cuentas (<?= count($catalogoCuentas) ?>)</h2>
            <p class="card-sub">Las cuentas agrupadoras organizan los rubros; las operativas reciben partidas</p>
            <table class="tabla-paginada" data-por-pagina="10">
                <thead>
                    <tr>
                        <th>Código</th>
                        <th>Nombre</th>
                        <th>Tipo</th>
                        <th class="center">Nivel</th>
                        <th class="center">Acciones</th>
                    </tr>
                </thead>
                <tbody>
                    <?php foreach ($catalogoCuentas as $c): ?>
                    <tr class="<?= !$c['acepta_movimientos'] ? 'row-padre' : '' ?>">
                        <td><?= htmlspecialchars($c['codigo']) ?></td>
                        <td class="<?= $c['acepta_movimientos'] ? 'indent-subcuenta' : '' ?>">
                            <?= htmlspecialchars($c['nombre']) ?>
                        </td>
                        <td><span class="tag"><?= htmlspecialchars($c['tipo']) ?></span></td>
                        <td class="center"><?= $c['acepta_movimientos'] ? 'Operativa' : 'Agrupadora' ?></td>
                        <td class="center nowrap">
                            <button type="button" class="btn-edit-sm"
                                onclick='cargarEdicionCuenta(<?= json_encode($c) ?>)'>Editar</button>
                            <?php if ((int)$c['total_movimientos'] === 0): ?>
                            <form method="POST" action="/index.php?pagina=contabilidad&accion=eliminarCuenta" class="inline-form" onsubmit="return confirm('¿Eliminar esta cuenta del catálogo?');">
                                <input type="hidden" name="id_cuenta" value="<?= $c['id_cuenta'] ?>">
                                <button type="submit" class="btn-danger-sm">Eliminar</button>
                            </form>
                            <?php endif; ?>
                        </td>
                    </tr>
                    <?php endforeach; ?>
                </tbody>
            </table>
        </section>
    </div>
    <?php else: ?>
    <section class="card">
        <h2 class="card-title">Sección en construcción</h2>
        <p class="card-sub">Completaremos esta pestaña en los siguientes pasos.</p>
    </section>
    <?php endif; ?>
</div>

<script src="assets/js/contabilidad.js"></script>