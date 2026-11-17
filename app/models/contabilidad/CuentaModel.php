<?php
require_once __DIR__ . '/../../../config/database.php';

class CuentaModel {
    private PDO $db;

    public function __construct() {
        $this->db = Database::getConnection();
    }

    private function obtenerIdEmpresa(): int {
        $id = $this->db->query("SELECT id_empresa FROM empresas ORDER BY id_empresa ASC LIMIT 1")->fetchColumn();
        return $id ? (int)$id : 1;
    }

    private function determinarNaturaleza(string $tipo): string {
        return in_array($tipo, ['activo', 'costo', 'gasto'], true) ? 'deudora' : 'acreedora';
    }

    public function listarTodas(): array {
        $sql = "SELECT
                    c.id_cuenta,
                    c.id_cuenta_padre,
                    p.codigo AS padre_codigo,
                    p.nombre AS padre_nombre,
                    c.codigo,
                    c.nombre,
                    c.tipo,
                    c.naturaleza,
                    c.acepta_movimientos,
                    (SELECT COUNT(*) FROM detalle_asientos d WHERE d.id_cuenta = c.id_cuenta) AS total_movimientos
                FROM cuentas c
                LEFT JOIN cuentas p ON c.id_cuenta_padre = p.id_cuenta
                WHERE c.id_empresa = :id_empresa
                ORDER BY c.codigo ASC";
        $stmt = $this->db->prepare($sql);
        $stmt->execute([':id_empresa' => $this->obtenerIdEmpresa()]);
        return $stmt->fetchAll();
    }

    public function crear(string $codigo, string $nombre, string $tipo, ?int $idCuentaPadre, bool $aceptaMovimientos): void {
        $codigo = trim($codigo);
        $nombre = trim($nombre);

        if ($codigo === '' || $nombre === '') {
            throw new Exception("El código y el nombre de la cuenta son obligatorios.");
        }

        try {
            $sql = "INSERT INTO cuentas (id_empresa, id_cuenta_padre, codigo, nombre, tipo, naturaleza, acepta_movimientos)
                    VALUES (:id_empresa, :id_cuenta_padre, :codigo, :nombre, :tipo, :naturaleza, :acepta_movimientos)";
            $stmt = $this->db->prepare($sql);
            $stmt->execute([
                ':id_empresa'         => $this->obtenerIdEmpresa(),
                ':id_cuenta_padre'    => $idCuentaPadre ?: null,
                ':codigo'             => $codigo,
                ':nombre'             => $nombre,
                ':tipo'               => $tipo,
                ':naturaleza'         => $this->determinarNaturaleza($tipo),
                ':acepta_movimientos' => $aceptaMovimientos ? 'true' : 'false'
            ]);
        } catch (PDOException $e) {
            if ($e->getCode() === '23505') {
                throw new Exception("Ya existe una cuenta registrada con el código '{$codigo}'.");
            }
            throw $e;
        }
    }

    public function actualizar(int $idCuenta, string $codigo, string $nombre, string $tipo, ?int $idCuentaPadre, bool $aceptaMovimientos): void {
        $codigo = trim($codigo);
        $nombre = trim($nombre);

        if ($idCuenta <= 0 || $codigo === '' || $nombre === '') {
            throw new Exception("Datos incompletos para actualizar la cuenta.");
        }
        if ($idCuentaPadre !== null && $idCuentaPadre === $idCuenta) {
            throw new Exception("Una cuenta no puede ser su propia cuenta padre.");
        }

        try {
            $sql = "UPDATE cuentas
                    SET id_cuenta_padre = :id_cuenta_padre,
                        codigo = :codigo,
                        nombre = :nombre,
                        tipo = :tipo,
                        naturaleza = :naturaleza,
                        acepta_movimientos = :acepta_movimientos
                    WHERE id_cuenta = :id_cuenta";
            $stmt = $this->db->prepare($sql);
            $stmt->execute([
                ':id_cuenta_padre'    => $idCuentaPadre ?: null,
                ':codigo'             => $codigo,
                ':nombre'             => $nombre,
                ':tipo'               => $tipo,
                ':naturaleza'         => $this->determinarNaturaleza($tipo),
                ':acepta_movimientos' => $aceptaMovimientos ? 'true' : 'false',
                ':id_cuenta'          => $idCuenta
            ]);
        } catch (PDOException $e) {
            if ($e->getCode() === '23505') {
                throw new Exception("El código '{$codigo}' ya pertenece a otra cuenta.");
            }
            throw $e;
        }
    }

    public function eliminar(int $idCuenta): void {
        $stmtCheck = $this->db->prepare("SELECT COUNT(*) FROM detalle_asientos WHERE id_cuenta = :id");
        $stmtCheck->execute([':id' => $idCuenta]);

        if ((int)$stmtCheck->fetchColumn() > 0) {
            throw new Exception("No se puede eliminar esta cuenta porque ya tiene movimientos en el Libro Diario.");
        }

        $stmtDel = $this->db->prepare("DELETE FROM cuentas WHERE id_cuenta = :id");
        $stmtDel->execute([':id' => $idCuenta]);
    }
}