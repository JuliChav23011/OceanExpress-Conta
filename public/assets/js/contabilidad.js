document.addEventListener('DOMContentLoaded', () => {
    const btnCancelar = document.getElementById('btnCancelarEdicion');
    if (btnCancelar) {
        btnCancelar.addEventListener('click', () => {
            const form = document.getElementById('formCuenta');
            document.getElementById('tituloFormCuenta').textContent = 'Nueva cuenta contable';
            form.action = '/index.php?pagina=contabilidad&accion=guardarCuenta';
            document.getElementById('editIdCuenta').value = '';
            form.reset();
            document.getElementById('btnGuardarCuenta').textContent = 'Guardar cuenta';
            btnCancelar.style.display = 'none';
        });
    }
});

function cargarEdicionCuenta(cta) {
    const form = document.getElementById('formCuenta');
    document.getElementById('tituloFormCuenta').textContent = 'Editar cuenta contable';
    form.action = '/index.php?pagina=contabilidad&accion=editarCuenta';
    document.getElementById('editIdCuenta').value = cta.id_cuenta;
    document.getElementById('cuentaCodigo').value = cta.codigo;
    document.getElementById('cuentaNombre').value = cta.nombre;
    document.getElementById('cuentaTipo').value   = cta.tipo;
    document.getElementById('cuentaAcepta').checked = Boolean(cta.acepta_movimientos);
    document.getElementById('btnGuardarCuenta').textContent = 'Actualizar cuenta';
    document.getElementById('btnCancelarEdicion').style.display = 'block';
}

const alertaFlash = document.getElementById('alertaFlash');
    if (alertaFlash) {
        setTimeout(() => {
            alertaFlash.style.opacity = '0';
            setTimeout(() => alertaFlash.remove(), 400);
        }, 4000);
    }

function inicializarPaginacion() {
    document.querySelectorAll('table.tabla-paginada').forEach((tabla) => {
        const tbody = tabla.querySelector('tbody');
        if (!tbody) return;

        const filas = Array.from(tbody.querySelectorAll('tr'));
        const porPagina = parseInt(tabla.dataset.porPagina, 10) || 10;
        const totalFilas = filas.length;
        const totalPaginas = Math.ceil(totalFilas / porPagina);

        if (totalPaginas <= 1) return;

        let paginaActual = 1;
        const barra = document.createElement('div');
        barra.className = 'paginacion-bar';
        tabla.insertAdjacentElement('afterend', barra);

        const obtenerRango = (actual, total) => {
            if (total <= 7) return Array.from({ length: total }, (_, i) => i + 1);
            if (actual <= 3) return [1, 2, 3, 4, '...', total];
            if (actual >= total - 2) return [1, '...', total - 3, total - 2, total - 1, total];
            return [1, '...', actual - 1, actual, actual + 1, '...', total];
        };

        const renderizar = () => {
            const inicio = (paginaActual - 1) * porPagina;
            const fin = Math.min(inicio + porPagina, totalFilas);

            filas.forEach((fila, idx) => {
                fila.style.display = (idx >= inicio && idx < fin) ? '' : 'none';
            });

            const botonesHtml = obtenerRango(paginaActual, totalPaginas).map((item) => {
                if (item === '...') {
                    return `<button type="button" class="btn-pag" disabled>...</button>`;
                }
                const activa = item === paginaActual ? 'active' : '';
                return `<button type="button" class="btn-pag ${activa}" data-pag="${item}">${item}</button>`;
            }).join('');

            barra.innerHTML = `
                <span>Mostrando ${inicio + 1}–${fin} de ${totalFilas} registros</span>
                <div class="paginacion-botones">
                    <button type="button" class="btn-pag" data-pag="${paginaActual - 1}" ${paginaActual === 1 ? 'disabled' : ''}>&laquo; Anterior</button>
                    ${botonesHtml}
                    <button type="button" class="btn-pag" data-pag="${paginaActual + 1}" ${paginaActual === totalPaginas ? 'disabled' : ''}>Siguiente &raquo;</button>
                </div>
            `;
        };

        barra.addEventListener('click', (e) => {
            const btn = e.target.closest('.btn-pag');
            if (!btn || btn.disabled || !btn.dataset.pag) return;
            paginaActual = parseInt(btn.dataset.pag, 10);
            renderizar();
        });

        renderizar();
    });
}