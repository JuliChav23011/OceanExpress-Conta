<?php
require_once __DIR__ . '/../../models/contabilidad/CuentaModel.php';

class ContabilidadController {
    private CuentaModel $cuentaModel;

    public function __construct() {
        if (session_status() === PHP_SESSION_NONE) {
            session_start();
        }
        $this->cuentaModel = new CuentaModel();
    }

    public function index(): void {
        $tab = $_GET['tab'] ?? 'catalogo';
        $catalogoCuentas = $this->cuentaModel->listarTodas();

        $flashExito = $_SESSION['flash_exito'] ?? null;
        $flashError = $_SESSION['flash_error'] ?? null;
        unset($_SESSION['flash_exito'], $_SESSION['flash_error']);
        session_write_close();

        require __DIR__ . '/../../views/contabilidad/index.php';
    }

    public function guardarCuenta(): void {
        if ($_SERVER['REQUEST_METHOD'] === 'POST') {
            try {
                $idPadre = !empty($_POST['id_cuenta_padre']) ? (int)$_POST['id_cuenta_padre'] : null;

                $this->cuentaModel->crear(
                    $_POST['codigo'] ?? '',
                    $_POST['nombre'] ?? '',
                    $_POST['tipo'] ?? 'activo',
                    $idPadre,
                    isset($_POST['acepta_movimientos'])
                );
                $_SESSION['flash_exito'] = "Cuenta agregada correctamente al catálogo.";
            } catch (Throwable $e) {
                $_SESSION['flash_error'] = $e->getMessage();
            }
        }
        $this->redirigir('catalogo');
    }

    public function editarCuenta(): void {
        if ($_SERVER['REQUEST_METHOD'] === 'POST') {
            try {
                $idPadre = !empty($_POST['id_cuenta_padre']) ? (int)$_POST['id_cuenta_padre'] : null;

                $this->cuentaModel->actualizar(
                    (int)($_POST['id_cuenta'] ?? 0),
                    $_POST['codigo'] ?? '',
                    $_POST['nombre'] ?? '',
                    $_POST['tipo'] ?? 'activo',
                    $idPadre,
                    isset($_POST['acepta_movimientos'])
                );
                $_SESSION['flash_exito'] = "Cuenta contable actualizada.";
            } catch (Throwable $e) {
                $_SESSION['flash_error'] = $e->getMessage();
            }
        }
        $this->redirigir('catalogo');
    }

    public function eliminarCuenta(): void {
        if ($_SERVER['REQUEST_METHOD'] === 'POST') {
            try {
                $this->cuentaModel->eliminar((int)($_POST['id_cuenta'] ?? 0));
                $_SESSION['flash_exito'] = "Cuenta eliminada del catálogo.";
            } catch (Throwable $e) {
                $_SESSION['flash_error'] = $e->getMessage();
            }
        }
        $this->redirigir('catalogo');
    }

    private function redirigir(string $tab): void {
        header("Location: /index.php?pagina=contabilidad&tab={$tab}");
        exit;
    }
}