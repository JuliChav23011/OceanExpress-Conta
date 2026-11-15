BEGIN;

CREATE TABLE empresas (
    id_empresa SERIAL PRIMARY KEY,
    nombre_comercial VARCHAR(150) NOT NULL,
    razon_social VARCHAR(150) NOT NULL,
    nit VARCHAR(25) NOT NULL UNIQUE,
    nrc VARCHAR(25) NOT NULL UNIQUE,
    giro VARCHAR(200) NOT NULL,
    direccion TEXT NOT NULL,
    telefono VARCHAR(25),
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE periodos_contables (
    id_periodo SERIAL PRIMARY KEY,
    id_empresa INTEGER NOT NULL REFERENCES empresas(id_empresa) ON DELETE CASCADE,
    nombre_periodo VARCHAR(50) NOT NULL, -- Ej: 'Septiembre 2026'
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NOT NULL,
    estado VARCHAR(20) NOT NULL DEFAULT 'abierto' CHECK (estado IN ('abierto', 'cerrado')),
    CONSTRAINT chk_fechas_periodo CHECK (fecha_fin >= fecha_inicio),
    CONSTRAINT uq_empresa_periodo UNIQUE (id_empresa, fecha_inicio, fecha_fin)
);

CREATE TABLE cuentas (
    id_cuenta SERIAL PRIMARY KEY,
    id_empresa INTEGER NOT NULL REFERENCES empresas(id_empresa) ON DELETE CASCADE,
    codigo VARCHAR(20) NOT NULL,
    nombre VARCHAR(150) NOT NULL,
    tipo VARCHAR(20) NOT NULL CHECK (tipo IN ('activo', 'pasivo', 'patrimonio', 'ingreso', 'costo', 'gasto')),
    naturaleza VARCHAR(15) NOT NULL CHECK (naturaleza IN ('deudora', 'acreedora')),
    id_cuenta_padre INTEGER NULL REFERENCES cuentas(id_cuenta) ON DELETE RESTRICT,
    acepta_movimientos BOOLEAN NOT NULL DEFAULT TRUE,
    activa BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT uq_codigo_cuenta_empresa UNIQUE (id_empresa, codigo)
);

CREATE TABLE asientos (
    id_asiento SERIAL PRIMARY KEY,
    id_periodo INTEGER NOT NULL REFERENCES periodos_contables(id_periodo) ON DELETE RESTRICT,
    numero_asiento INTEGER NOT NULL,
    fecha DATE NOT NULL,
    concepto TEXT NOT NULL,
    tipo_asiento VARCHAR(20) NOT NULL DEFAULT 'diario' CHECK (tipo_asiento IN ('apertura', 'diario', 'ajuste', 'cierre')),
    referencia VARCHAR(80),
    estado VARCHAR(20) NOT NULL DEFAULT 'contabilizado' CHECK (estado IN ('borrador', 'contabilizado', 'anulado')),
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_asiento_periodo UNIQUE (id_periodo, numero_asiento)
);

CREATE TABLE detalle_asientos (
    id_detalle SERIAL PRIMARY KEY,
    id_asiento INTEGER NOT NULL REFERENCES asientos(id_asiento) ON DELETE CASCADE,
    id_cuenta INTEGER NOT NULL REFERENCES cuentas(id_cuenta) ON DELETE RESTRICT,
    descripcion_linea VARCHAR(255),
    debe NUMERIC(14,2) NOT NULL DEFAULT 0.00 CHECK (debe >= 0),
    haber NUMERIC(14,2) NOT NULL DEFAULT 0.00 CHECK (haber >= 0),
    CONSTRAINT chk_debe_o_haber CHECK (
        (debe > 0 AND haber = 0) OR (haber > 0 AND debe = 0)
    )
);

CREATE TABLE evidencias (
    id_evidencia SERIAL PRIMARY KEY,
    id_empresa INTEGER NOT NULL REFERENCES empresas(id_empresa) ON DELETE CASCADE,
    codigo_anexo VARCHAR(30), -- Ej: 'Anexo 2', 'Anexo 3'
    nombre_archivo VARCHAR(255) NOT NULL,
    ruta_archivo TEXT NOT NULL,
    tipo_documento VARCHAR(50) NOT NULL, -- Ej: 'FacturaSV DTE', 'Cuaderno', 'Carta Autorización'
    descripcion TEXT,
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Esta tabla es para reutilizar una misma foto/PDF en varios asientos para que no se vayan a duplicar
CREATE TABLE asiento_evidencias (
    id_asiento INTEGER NOT NULL REFERENCES asientos(id_asiento) ON DELETE CASCADE,
    id_evidencia INTEGER NOT NULL REFERENCES evidencias(id_evidencia) ON DELETE CASCADE,
    PRIMARY KEY (id_asiento, id_evidencia)
);

CREATE TABLE servicios (
    id_servicio SERIAL PRIMARY KEY,
    id_empresa INTEGER NOT NULL REFERENCES empresas(id_empresa) ON DELETE CASCADE,
    nombre VARCHAR(150) NOT NULL,
    descripcion TEXT,
    precio_venta NUMERIC(14,2) NOT NULL DEFAULT 0.00 CHECK (precio_venta >= 0),
    activo BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE costos (
    id_costo SERIAL PRIMARY KEY,
    id_periodo INTEGER NOT NULL REFERENCES periodos_contables(id_periodo) ON DELETE RESTRICT,
    id_servicio INTEGER NULL REFERENCES servicios(id_servicio) ON DELETE SET NULL,
    id_detalle INTEGER NULL REFERENCES detalle_asientos(id_detalle) ON DELETE SET NULL,
    descripcion TEXT NOT NULL,
    clasificacion VARCHAR(20) NOT NULL CHECK (clasificacion IN ('directo', 'indirecto')),
    comportamiento VARCHAR(20) NOT NULL CHECK (comportamiento IN ('fijo', 'variable', 'mixto')),
    monto NUMERIC(14,2) NOT NULL CHECK (monto >= 0),
    fecha DATE NOT NULL
);

CREATE TABLE ordenes_servicio (
    id_orden SERIAL PRIMARY KEY,
    id_servicio INTEGER NOT NULL REFERENCES servicios(id_servicio) ON DELETE RESTRICT,
    id_periodo INTEGER NOT NULL REFERENCES periodos_contables(id_periodo) ON DELETE RESTRICT,
    numero_orden VARCHAR(30) NOT NULL,
    fecha DATE NOT NULL,
    cantidad_unidades INTEGER NOT NULL DEFAULT 1 CHECK (cantidad_unidades > 0),
    estado VARCHAR(20) NOT NULL DEFAULT 'completada' CHECK (estado IN ('pendiente', 'en_proceso', 'completada', 'cancelada')),
    CONSTRAINT uq_numero_orden UNIQUE (id_periodo, numero_orden)
);

CREATE TABLE detalle_costos_orden (
    id_detalle_costo SERIAL PRIMARY KEY,
    id_orden INTEGER NOT NULL REFERENCES ordenes_servicio(id_orden) ON DELETE CASCADE,
    id_costo INTEGER NOT NULL REFERENCES costos(id_costo) ON DELETE RESTRICT,
    monto_asignado NUMERIC(14,2) NOT NULL CHECK (monto_asignado >= 0)
);

CREATE TABLE alternativas_costos (
    id_alternativa SERIAL PRIMARY KEY,
    id_empresa INTEGER NOT NULL REFERENCES empresas(id_empresa) ON DELETE CASCADE,
    nombre VARCHAR(150) NOT NULL,
    descripcion TEXT,
    costo_total_estimado NUMERIC(14,2) NOT NULL DEFAULT 0.00 CHECK (costo_total_estimado >= 0),
    observaciones TEXT
);

CREATE TABLE detalle_alternativas_costos (
    id_rubro_alt SERIAL PRIMARY KEY,
    id_alternativa INTEGER NOT NULL REFERENCES alternativas_costos(id_alternativa) ON DELETE CASCADE,
    concepto VARCHAR(150) NOT NULL,
    tipo_costo VARCHAR(20) NOT NULL CHECK (tipo_costo IN ('inversion_inicial', 'fijo_mensual', 'variable_unitario')),
    monto NUMERIC(14,2) NOT NULL CHECK (monto >= 0)
);


CREATE TABLE verificaciones (
    id_verificacion SERIAL PRIMARY KEY,
    id_periodo INTEGER NOT NULL REFERENCES periodos_contables(id_periodo) ON DELETE RESTRICT,
    modulo VARCHAR(30) NOT NULL CHECK (modulo IN ('contabilidad', 'costos')),
    tipo_resultado VARCHAR(80) NOT NULL, -- Ej: 'Utilidad Neta', 'Total Activo', 'Costo Unitario'
    referencia_resultado VARCHAR(100),
    resultado_manual NUMERIC(14,2) NOT NULL,
    resultado_sistema NUMERIC(14,2) NOT NULL,
    diferencia NUMERIC(14,2) GENERATED ALWAYS AS (resultado_sistema - resultado_manual) STORED,
    estado VARCHAR(20) NOT NULL DEFAULT 'coincide' CHECK (estado IN ('coincide', 'no_coincide')),
    fecha_verificacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    observaciones TEXT
);

CREATE TABLE evidencias_verificacion (
    id_verificacion INTEGER NOT NULL REFERENCES verificaciones(id_verificacion) ON DELETE CASCADE,
    id_evidencia INTEGER NOT NULL REFERENCES evidencias(id_evidencia) ON DELETE CASCADE,
    PRIMARY KEY (id_verificacion, id_evidencia)
);


CREATE INDEX idx_cuentas_padre ON cuentas(id_cuenta_padre);
CREATE INDEX idx_asientos_periodo ON asientos(id_periodo);
CREATE INDEX idx_detalle_asiento ON detalle_asientos(id_asiento);
CREATE INDEX idx_detalle_cuenta ON detalle_asientos(id_cuenta);
CREATE INDEX idx_costos_periodo ON costos(id_periodo);


-- Vista 1: Balanza de Comprobación y Saldos Ajustados por Período
CREATE VIEW vw_balanza_comprobacion AS
SELECT 
    a.id_periodo,
    c.id_cuenta,
    c.codigo,
    c.nombre,
    c.tipo,
    c.naturaleza,
    COALESCE(SUM(da.debe), 0.00) AS total_debe,
    COALESCE(SUM(da.haber), 0.00) AS total_haber,
    CASE 
        WHEN c.naturaleza = 'deudora' THEN COALESCE(SUM(da.debe - da.haber), 0.00)
        ELSE 0.00 
    END AS saldo_deudor,
    CASE 
        WHEN c.naturaleza = 'acreedora' THEN COALESCE(SUM(da.haber - da.debe), 0.00)
        ELSE 0.00 
    END AS saldo_acreedor
FROM cuentas c
LEFT JOIN detalle_asientos da ON c.id_cuenta = da.id_cuenta
LEFT JOIN asientos a ON da.id_asiento = a.id_asiento AND a.estado = 'contabilizado'
WHERE c.acepta_movimientos = TRUE
GROUP BY a.id_periodo, c.id_cuenta, c.codigo, c.nombre, c.tipo, c.naturaleza
HAVING COALESCE(SUM(da.debe), 0) > 0 OR COALESCE(SUM(da.haber), 0) > 0
ORDER BY c.codigo;

-- Vista 2: Resumen para Estado de Resultados
CREATE VIEW vw_estado_resultados AS
SELECT 
    id_periodo,
    codigo,
    nombre,
    tipo,
    CASE 
        WHEN tipo = 'ingreso' THEN saldo_acreedor
        ELSE saldo_deudor
    END AS monto
FROM vw_balanza_comprobacion
WHERE tipo IN ('ingreso', 'costo', 'gasto')
ORDER BY codigo;


-- 7.1 Empresa
INSERT INTO empresas (nombre_comercial, razon_social, nit, nrc, giro, direccion, telefono)
VALUES (
    'Ocean Express',
    'Milena Vanessa Amaya Castillo',
    '1123-220994-101-5',
    '372024-4',
    'Encomiendas EE. UU. - El Salvador, casillero internacional, trámites aduanales y tienda Ocean Blue Store',
    'Usulután, Departamento de Usulután, El Salvador',
    '0000-0000'
);

-- 7.2 Periodo Contable Base
INSERT INTO periodos_contables (id_empresa, nombre_periodo, fecha_inicio, fecha_fin, estado)
VALUES (1, 'Septiembre 2026', '2026-09-01', '2026-09-30', 'abierto');

-- 7.3 Catalogo de Cuentas Jerarquico
-- Nivel 1: Rubros Principales (No aceptan movimientos directos)
INSERT INTO cuentas (id_empresa, codigo, nombre, tipo, naturaleza, id_cuenta_padre, acepta_movimientos) VALUES
(1, '1', 'ACTIVO', 'activo', 'deudora', NULL, FALSE),
(1, '2', 'PASIVO', 'pasivo', 'acreedora', NULL, FALSE),
(1, '3', 'PATRIMONIO NETO', 'patrimonio', 'acreedora', NULL, FALSE),
(1, '4', 'INGRESOS', 'ingreso', 'acreedora', NULL, FALSE),
(1, '5', 'COSTOS', 'costo', 'deudora', NULL, FALSE),
(1, '6', 'GASTOS DE OPERACIÓN', 'gasto', 'deudora', NULL, FALSE);

-- Nivel 2: Clasificaciones (No aceptan movimientos directos)
INSERT INTO cuentas (id_empresa, codigo, nombre, tipo, naturaleza, id_cuenta_padre, acepta_movimientos) VALUES
(1, '11', 'ACTIVO CORRIENTE', 'activo', 'deudora', (SELECT id_cuenta FROM cuentas WHERE codigo = '1'), FALSE),
(1, '12', 'ACTIVO NO CORRIENTE', 'activo', 'deudora', (SELECT id_cuenta FROM cuentas WHERE codigo = '1'), FALSE),
(1, '21', 'PASIVO CORRIENTE', 'pasivo', 'acreedora', (SELECT id_cuenta FROM cuentas WHERE codigo = '2'), FALSE),
(1, '22', 'PASIVO NO CORRIENTE', 'pasivo', 'acreedora', (SELECT id_cuenta FROM cuentas WHERE codigo = '2'), FALSE),
(1, '31', 'CAPITAL Y RESULTADOS', 'patrimonio', 'acreedora', (SELECT id_cuenta FROM cuentas WHERE codigo = '3'), FALSE),
(1, '41', 'INGRESOS DE OPERACIÓN', 'ingreso', 'acreedora', (SELECT id_cuenta FROM cuentas WHERE codigo = '4'), FALSE),
(1, '51', 'COSTOS DE OPERACIÓN Y SERVICIOS', 'costo', 'deudora', (SELECT id_cuenta FROM cuentas WHERE codigo = '5'), FALSE),
(1, '61', 'GASTOS DE ADMINISTRACIÓN', 'gasto', 'deudora', (SELECT id_cuenta FROM cuentas WHERE codigo = '6'), FALSE),
(1, '62', 'GASTOS DE VENTA Y PUBLICIDAD', 'gasto', 'deudora', (SELECT id_cuenta FROM cuentas WHERE codigo = '6'), FALSE),
(1, '63', 'GASTOS FINANCIEROS', 'gasto', 'deudora', (SELECT id_cuenta FROM cuentas WHERE codigo = '6'), FALSE);

-- Nivel 3: Cuentas de Mayor (No aceptan movimientos directos)
INSERT INTO cuentas (id_empresa, codigo, nombre, tipo, naturaleza, id_cuenta_padre, acepta_movimientos) VALUES
(1, '1101', 'Efectivo y Equivalentes de Efectivo', 'activo', 'deudora', (SELECT id_cuenta FROM cuentas WHERE codigo = '11'), FALSE),
(1, '1102', 'Cuentas y Documentos por Cobrar', 'activo', 'deudora', (SELECT id_cuenta FROM cuentas WHERE codigo = '11'), FALSE),
(1, '1103', 'Inventarios (Ocean Blue Store)', 'activo', 'deudora', (SELECT id_cuenta FROM cuentas WHERE codigo = '11'), FALSE),
(1, '1201', 'Propiedad, Planta y Equipo', 'activo', 'deudora', (SELECT id_cuenta FROM cuentas WHERE codigo = '12'), FALSE),
(1, '1202', 'Depreciación Acumulada', 'activo', 'acreedora', (SELECT id_cuenta FROM cuentas WHERE codigo = '12'), FALSE),
(1, '2101', 'Cuentas por Pagar a Corto Plazo', 'pasivo', 'acreedora', (SELECT id_cuenta FROM cuentas WHERE codigo = '21'), FALSE),
(1, '2102', 'Retenciones y Cotizaciones por Pagar', 'pasivo', 'acreedora', (SELECT id_cuenta FROM cuentas WHERE codigo = '21'), FALSE),
(1, '2103', 'Impuestos por Pagar', 'pasivo', 'acreedora', (SELECT id_cuenta FROM cuentas WHERE codigo = '21'), FALSE),
(1, '3101', 'Capital Propietario', 'patrimonio', 'acreedora', (SELECT id_cuenta FROM cuentas WHERE codigo = '31'), FALSE),
(1, '3102', 'Resultados Acumulados', 'patrimonio', 'acreedora', (SELECT id_cuenta FROM cuentas WHERE codigo = '31'), FALSE),
(1, '3103', 'Resultado del Ejercicio', 'patrimonio', 'acreedora', (SELECT id_cuenta FROM cuentas WHERE codigo = '31'), FALSE),
(1, '4101', 'Ingresos por Servicios Operativos', 'ingreso', 'acreedora', (SELECT id_cuenta FROM cuentas WHERE codigo = '41'), FALSE),
(1, '5101', 'Costos Directos de Servicios de Encomienda', 'costo', 'deudora', (SELECT id_cuenta FROM cuentas WHERE codigo = '51'), FALSE),
(1, '6101', 'Gastos de Personal', 'gasto', 'deudora', (SELECT id_cuenta FROM cuentas WHERE codigo = '61'), FALSE),
(1, '6102', 'Gastos de Servicios Generales y Alquileres', 'gasto', 'deudora', (SELECT id_cuenta FROM cuentas WHERE codigo = '61'), FALSE),
(1, '6103', 'Depreciaciones y Amortizaciones', 'gasto', 'deudora', (SELECT id_cuenta FROM cuentas WHERE codigo = '61'), FALSE),
(1, '6201', 'Gastos de Comercialización y Publicidad', 'gasto', 'deudora', (SELECT id_cuenta FROM cuentas WHERE codigo = '62'), FALSE);

-- Nivel 4: Subcuentas de Detalle (Si aceptan movimientos contables)
INSERT INTO cuentas (id_empresa, codigo, nombre, tipo, naturaleza, id_cuenta_padre, acepta_movimientos) VALUES
(1, '1101-01', 'Caja General', 'activo', 'deudora', (SELECT id_cuenta FROM cuentas WHERE codigo = '1101'), TRUE),
(1, '1101-02', 'Caja Chica', 'activo', 'deudora', (SELECT id_cuenta FROM cuentas WHERE codigo = '1101'), TRUE),
(1, '1101-03', 'Bancos (Cuentas de Ahorro/Cheques)', 'activo', 'deudora', (SELECT id_cuenta FROM cuentas WHERE codigo = '1101'), TRUE),
(1, '1102-01', 'Clientes Locales', 'activo', 'deudora', (SELECT id_cuenta FROM cuentas WHERE codigo = '1102'), TRUE),
(1, '1103-01', 'Inventario Mercadería Ocean Blue Store', 'activo', 'deudora', (SELECT id_cuenta FROM cuentas WHERE codigo = '1103'), TRUE),
(1, '1103-02', 'Inventario Materiales de Empaque', 'activo', 'deudora', (SELECT id_cuenta FROM cuentas WHERE codigo = '1103'), TRUE),
(1, '1201-01', 'Mobiliario y Equipo de Oficina', 'activo', 'deudora', (SELECT id_cuenta FROM cuentas WHERE codigo = '1201'), TRUE),
(1, '1201-02', 'Equipo de Cómputo y Oficina', 'activo', 'deudora', (SELECT id_cuenta FROM cuentas WHERE codigo = '1201'), TRUE),
(1, '1201-03', 'Vehículos de Transporte', 'activo', 'deudora', (SELECT id_cuenta FROM cuentas WHERE codigo = '1201'), TRUE),
(1, '1202-01', 'Depreciación Acumulada Mobiliario y Equipo', 'activo', 'acreedora', (SELECT id_cuenta FROM cuentas WHERE codigo = '1202'), TRUE),
(1, '1202-02', 'Depreciación Acumulada Equipo de Cómputo', 'activo', 'acreedora', (SELECT id_cuenta FROM cuentas WHERE codigo = '1202'), TRUE),
(1, '2101-01', 'Proveedores y Transportistas Subcontratados', 'pasivo', 'acreedora', (SELECT id_cuenta FROM cuentas WHERE codigo = '2101'), TRUE),
(1, '2103-01', 'IVA Débito Fiscal (13%)', 'pasivo', 'acreedora', (SELECT id_cuenta FROM cuentas WHERE codigo = '2103'), TRUE),
(1, '2103-02', 'Pago a Cuenta ISR por Pagar', 'pasivo', 'acreedora', (SELECT id_cuenta FROM cuentas WHERE codigo = '2103'), TRUE),
(1, '3101-01', 'Capital Propietario (Milena Amaya)', 'patrimonio', 'acreedora', (SELECT id_cuenta FROM cuentas WHERE codigo = '3101'), TRUE),
(1, '3103-01', 'Utilidad del Presente Ejercicio', 'patrimonio', 'acreedora', (SELECT id_cuenta FROM cuentas WHERE codigo = '3103'), TRUE),
(1, '4101-01', 'Ingresos por Servicios de Encomiendas y Tienda', 'ingreso', 'acreedora', (SELECT id_cuenta FROM cuentas WHERE codigo = '4101'), TRUE),
(1, '4101-02', 'Ingresos por Trámites de Aduana y Casillero', 'ingreso', 'acreedora', (SELECT id_cuenta FROM cuentas WHERE codigo = '4101'), TRUE),
(1, '5101-01', 'Pasajes Aéreos de Transporte de Equipaje', 'costo', 'deudora', (SELECT id_cuenta FROM cuentas WHERE codigo = '5101'), TRUE),
(1, '5101-02', 'Gastos Aduanales e Importaciones', 'costo', 'deudora', (SELECT id_cuenta FROM cuentas WHERE codigo = '5101'), TRUE),
(1, '5101-03', 'Fletes y Distribuidores Externos (El Salvador Express)', 'costo', 'deudora', (SELECT id_cuenta FROM cuentas WHERE codigo = '5101'), TRUE),
(1, '6101-01', 'Sueldos y Salarios', 'gasto', 'deudora', (SELECT id_cuenta FROM cuentas WHERE codigo = '6101'), TRUE),
(1, '6102-01', 'Alquiler Local Comercial Usulután', 'gasto', 'deudora', (SELECT id_cuenta FROM cuentas WHERE codigo = '6102'), TRUE),
(1, '6102-02', 'Alquiler Bodega EE. UU.', 'gasto', 'deudora', (SELECT id_cuenta FROM cuentas WHERE codigo = '6102'), TRUE),
(1, '6103-01', 'Depreciación Mobiliario y Equipo de Oficina', 'gasto', 'deudora', (SELECT id_cuenta FROM cuentas WHERE codigo = '6103'), TRUE),
(1, '6103-02', 'Depreciación Equipo de Cómputo y Oficina', 'gasto', 'deudora', (SELECT id_cuenta FROM cuentas WHERE codigo = '6103'), TRUE),
(1, '6201-01', 'Publicidad y Propaganda Digital', 'gasto', 'deudora', (SELECT id_cuenta FROM cuentas WHERE codigo = '6201'), TRUE);

-- 7.4 Asientos Contables Reales de Septiembre 2026 (es de las evidencias contables que nos dio la empresa)
-- Partida 1: Apertura
INSERT INTO asientos (id_periodo, numero_asiento, fecha, concepto, tipo_asiento, referencia)
VALUES (1, 1, '2026-09-01', 'Asiento de apertura e inventario inicial de activos fijos', 'apertura', 'INV-001');

INSERT INTO detalle_asientos (id_asiento, id_cuenta, descripcion_linea, debe, haber) VALUES
(1, (SELECT id_cuenta FROM cuentas WHERE codigo = '1101-01'), 'Efectivo inicial disponible en caja', 500.00, 0.00),
(1, (SELECT id_cuenta FROM cuentas WHERE codigo = '1201-01'), '3 mesas, 1 escritorio, 4 sillas, 3 estantes', 1200.00, 0.00),
(1, (SELECT id_cuenta FROM cuentas WHERE codigo = '1201-02'), '1 laptop operativa y 1 aire acondicionado', 1100.00, 0.00),
(1, (SELECT id_cuenta FROM cuentas WHERE codigo = '3101-01'), 'Aporte inicial propietaria Milena Amaya', 0.00, 2800.00);

-- Partida 2: Ingresos Septiembre 2026 (FacturaSV)
INSERT INTO asientos (id_periodo, numero_asiento, fecha, concepto, tipo_asiento, referencia)
VALUES (1, 2, '2026-09-30', 'Registro de ingresos brutos e IVA Débito Fiscal según FacturaSV', 'diario', 'DTE-SEP-2026');

INSERT INTO detalle_asientos (id_asiento, id_cuenta, descripcion_linea, debe, haber) VALUES
(2, (SELECT id_cuenta FROM cuentas WHERE codigo = '1101-01'), 'Ingreso total ventas al contado septiembre', 4426.04, 0.00),
(2, (SELECT id_cuenta FROM cuentas WHERE codigo = '4101-01'), 'Ventas netas encomiendas y Ocean Blue Store', 0.00, 3916.88),
(2, (SELECT id_cuenta FROM cuentas WHERE codigo = '2103-01'), 'IVA Débito Fiscal 13% generado en ventas', 0.00, 509.16);

-- Partida 3: Gastos Fijos Mensuales ($600.00)
INSERT INTO asientos (id_periodo, numero_asiento, fecha, concepto, tipo_asiento, referencia)
VALUES (1, 3, '2026-09-30', 'Pago de alquileres (Usulután y EE. UU.) y salarios del mes', 'diario', 'EGR-SEP-2026');

INSERT INTO detalle_asientos (id_asiento, id_cuenta, descripcion_linea, debe, haber) VALUES
(3, (SELECT id_cuenta FROM cuentas WHERE codigo = '6102-01'), 'Alquiler local Usulután (incluye agua, luz e internet)', 200.00, 0.00),
(3, (SELECT id_cuenta FROM cuentas WHERE codigo = '6102-02'), 'Alquiler bodega operativa en EE. UU.', 200.00, 0.00),
(3, (SELECT id_cuenta FROM cuentas WHERE codigo = '6101-01'), 'Salarios personal eventual (8 colaboradores)', 200.00, 0.00),
(3, (SELECT id_cuenta FROM cuentas WHERE codigo = '1101-01'), 'Salida de efectivo por gastos operativos', 0.00, 600.00);

-- Partida 4: Ajuste por Depreciacion Mensual
INSERT INTO asientos (id_periodo, numero_asiento, fecha, concepto, tipo_asiento, referencia)
VALUES (1, 4, '2026-09-30', 'Ajuste mensual por depreciación en línea recta de activos fijos', 'ajuste', 'AJU-DEP-09');

INSERT INTO detalle_asientos (id_asiento, id_cuenta, descripcion_linea, debe, haber) VALUES
(4, (SELECT id_cuenta FROM cuentas WHERE codigo = '6103-01'), 'Depreciación mensual mobiliario (5 años)', 20.00, 0.00),
(4, (SELECT id_cuenta FROM cuentas WHERE codigo = '6103-02'), 'Depreciación mensual equipo cómputo/aire (2 años)', 45.83, 0.00),
(4, (SELECT id_cuenta FROM cuentas WHERE codigo = '1202-01'), 'Acumulación depreciación mobiliario', 0.00, 20.00),
(4, (SELECT id_cuenta FROM cuentas WHERE codigo = '1202-02'), 'Acumulación depreciación equipo cómputo', 0.00, 45.83);

-- 7.5 Evidencias Documentales Registradas   (despues subo las imagenes)
INSERT INTO evidencias (id_empresa, codigo_anexo, nombre_archivo, ruta_archivo, tipo_documento, descripcion) VALUES
(1, 'Anexo 1', 'carta_autorizacion_ocean_express.pdf', 'uploads/evidencias/carta_autorizacion.pdf', 'Carta Autorización', 'Carta firmada por Milena Vanessa Amaya Castillo'),
(1, 'Anexo 2', 'reporte_facturasv_septiembre_2026.pdf', 'uploads/evidencias/facturasv_sep2026.pdf', 'Reporte Fiscal DTE', 'Resumen ejecutivo FacturaSV con ventas por $4,426.04'),
(1, 'Anexo 3', 'cuaderno_registros_ventas_01.jpg', 'uploads/evidencias/cuaderno_01.jpg', 'Cuaderno Físico', 'Control diario manual de encomiendas y tienda');

INSERT INTO asiento_evidencias (id_asiento, id_evidencia) VALUES
(2, 2),
(2, 3),
(3, 3);

COMMIT;