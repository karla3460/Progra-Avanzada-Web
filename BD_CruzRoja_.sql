-- Cruz Roja Costarricense
-- Comité Auxiliar de Santa Ana
-- Control de recursos operativos e inventario
-- Ejecutar completo en MySQL Workbench (UTF-8).
-- Vuelve a crear la base. Las contraseñas de demostración son CruzRoja2026
-- y se guardan como hash, no en texto legible.

DROP DATABASE IF EXISTS cruz_roja_santa_ana;
CREATE DATABASE cruz_roja_santa_ana CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE cruz_roja_santa_ana;

-- TABLAS
CREATE TABLE rol (
  id_rol INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(80) NOT NULL UNIQUE,
  descripcion VARCHAR(250) NULL
);

CREATE TABLE usuario (
  id_usuario INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(80) NOT NULL,
  apellido VARCHAR(80) NOT NULL,
  identificador VARCHAR(120) NOT NULL UNIQUE,
  contrasena_hash VARCHAR(200) NOT NULL,
  activo TINYINT(1) NOT NULL DEFAULT 1,
  id_rol INT NOT NULL,
  CONSTRAINT fk_usuario_rol FOREIGN KEY (id_rol) REFERENCES rol (id_rol)
);

CREATE TABLE configuracion (
  id_configuracion INT AUTO_INCREMENT PRIMARY KEY,
  clave VARCHAR(80) NOT NULL UNIQUE,
  valor VARCHAR(80) NOT NULL,
  fecha_actualizacion DATETIME NOT NULL,
  id_usuario INT NULL,
  CONSTRAINT fk_config_usuario FOREIGN KEY (id_usuario) REFERENCES usuario (id_usuario)
);

CREATE TABLE categoria (
  id_categoria INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(120) NOT NULL UNIQUE,
  descripcion VARCHAR(250) NULL,
  tipo VARCHAR(40) NOT NULL,
  activo TINYINT(1) NOT NULL DEFAULT 1
);

CREATE TABLE ubicacion (
  id_ubicacion INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(120) NOT NULL UNIQUE,
  direccion VARCHAR(200) NULL,
  responsable VARCHAR(120) NULL,
  activo TINYINT(1) NOT NULL DEFAULT 1
);

CREATE TABLE estado_recurso (
  id_estado INT PRIMARY KEY,
  nombre VARCHAR(60) NOT NULL UNIQUE,
  descripcion VARCHAR(200) NULL
);

CREATE TABLE recurso (
  id_recurso INT AUTO_INCREMENT PRIMARY KEY,
  codigo VARCHAR(30) NOT NULL UNIQUE,
  nombre VARCHAR(150) NOT NULL,
  descripcion VARCHAR(300) NULL,
  marca VARCHAR(80) NULL,
  modelo VARCHAR(80) NULL,
  serie VARCHAR(80) NULL,
  fecha_adquisicion DATE NULL,
  fecha_vencimiento DATE NULL,
  observaciones VARCHAR(500) NULL,
  origen VARCHAR(120) NULL,
  hallazgo_pendiente TINYINT(1) NOT NULL DEFAULT 0,
  id_categoria INT NOT NULL,
  id_ubicacion INT NOT NULL,
  id_estado INT NOT NULL,
  activo TINYINT(1) NOT NULL DEFAULT 1,
  CONSTRAINT fk_recurso_categoria FOREIGN KEY (id_categoria) REFERENCES categoria (id_categoria),
  CONSTRAINT fk_recurso_ubicacion FOREIGN KEY (id_ubicacion) REFERENCES ubicacion (id_ubicacion),
  CONSTRAINT fk_recurso_estado FOREIGN KEY (id_estado) REFERENCES estado_recurso (id_estado)
);

CREATE TABLE prestamo (
  id_prestamo INT AUTO_INCREMENT PRIMARY KEY,
  id_recurso INT NOT NULL,
  id_usuario_responsable INT NOT NULL,
  id_usuario_recibe INT NULL,
  destino VARCHAR(150) NOT NULL,
  fecha_salida DATETIME NOT NULL,
  fecha_retorno_prevista DATETIME NOT NULL,
  fecha_retorno_real DATETIME NULL,
  condicion_recibida VARCHAR(40) NULL,
  observaciones VARCHAR(500) NULL,
  estado VARCHAR(20) NOT NULL,
  recurso_abierto INT GENERATED ALWAYS AS (CASE WHEN estado = 'Abierto' THEN id_recurso ELSE NULL END) STORED,
  CONSTRAINT fk_prestamo_recurso FOREIGN KEY (id_recurso) REFERENCES recurso (id_recurso),
  CONSTRAINT fk_prestamo_responsable FOREIGN KEY (id_usuario_responsable) REFERENCES usuario (id_usuario),
  CONSTRAINT fk_prestamo_recibe FOREIGN KEY (id_usuario_recibe) REFERENCES usuario (id_usuario),
  UNIQUE KEY uq_prestamo_abierto (recurso_abierto)
);

CREATE TABLE inspeccion (
  id_inspeccion INT AUTO_INCREMENT PRIMARY KEY,
  id_recurso INT NOT NULL,
  id_usuario_inspector INT NOT NULL,
  fecha DATETIME NOT NULL,
  resultado VARCHAR(20) NOT NULL,
  observaciones VARCHAR(500) NULL,
  siguiente_fecha DATE NULL,
  hallazgo_pendiente TINYINT(1) NOT NULL DEFAULT 0,
  CONSTRAINT fk_insp_recurso FOREIGN KEY (id_recurso) REFERENCES recurso (id_recurso),
  CONSTRAINT fk_insp_usuario FOREIGN KEY (id_usuario_inspector) REFERENCES usuario (id_usuario)
);

CREATE TABLE mantenimiento (
  id_mantenimiento INT AUTO_INCREMENT PRIMARY KEY,
  id_recurso INT NOT NULL,
  id_usuario_responsable INT NOT NULL,
  tipo_trabajo VARCHAR(150) NOT NULL,
  fecha_programada DATE NOT NULL,
  fecha_inicio DATETIME NULL,
  fecha_cierre DATETIME NULL,
  resultado VARCHAR(40) NULL,
  observaciones VARCHAR(500) NULL,
  resuelve_hallazgos TINYINT(1) NOT NULL DEFAULT 0,
  estado VARCHAR(30) NOT NULL,
  recurso_en_curso INT GENERATED ALWAYS AS (CASE WHEN estado = 'En curso' THEN id_recurso ELSE NULL END) STORED,
  CONSTRAINT fk_mant_recurso FOREIGN KEY (id_recurso) REFERENCES recurso (id_recurso),
  CONSTRAINT fk_mant_usuario FOREIGN KEY (id_usuario_responsable) REFERENCES usuario (id_usuario),
  UNIQUE KEY uq_mant_curso (recurso_en_curso)
);

CREATE TABLE articulo (
  id_articulo INT AUTO_INCREMENT PRIMARY KEY,
  codigo VARCHAR(30) NOT NULL UNIQUE,
  nombre VARCHAR(150) NOT NULL,
  descripcion VARCHAR(300) NULL,
  unidad_medida VARCHAR(40) NOT NULL,
  stock_minimo DECIMAL(12,2) NOT NULL DEFAULT 0,
  activo TINYINT(1) NOT NULL DEFAULT 1,
  id_categoria INT NOT NULL,
  CONSTRAINT fk_art_categoria FOREIGN KEY (id_categoria) REFERENCES categoria (id_categoria)
);

CREATE TABLE lote (
  id_lote INT AUTO_INCREMENT PRIMARY KEY,
  id_articulo INT NOT NULL,
  numero_lote VARCHAR(40) NOT NULL,
  fecha_vencimiento DATE NULL,
  cantidad_inicial DECIMAL(12,2) NOT NULL,
  cantidad_actual DECIMAL(12,2) NOT NULL,
  CONSTRAINT uq_lote UNIQUE (id_articulo, numero_lote),
  CONSTRAINT fk_lote_articulo FOREIGN KEY (id_articulo) REFERENCES articulo (id_articulo)
);

CREATE TABLE movimiento_insumo (
  id_movimiento INT AUTO_INCREMENT PRIMARY KEY,
  id_articulo INT NOT NULL,
  id_lote INT NOT NULL,
  id_usuario INT NOT NULL,
  tipo VARCHAR(20) NOT NULL,
  cantidad DECIMAL(12,2) NOT NULL,
  fecha DATETIME NOT NULL,
  motivo VARCHAR(300) NULL,
  saldo_resultante DECIMAL(12,2) NOT NULL,
  CONSTRAINT fk_mov_articulo FOREIGN KEY (id_articulo) REFERENCES articulo (id_articulo),
  CONSTRAINT fk_mov_lote FOREIGN KEY (id_lote) REFERENCES lote (id_lote),
  CONSTRAINT fk_mov_usuario FOREIGN KEY (id_usuario) REFERENCES usuario (id_usuario)
);

CREATE TABLE historial (
  id_historial INT AUTO_INCREMENT PRIMARY KEY,
  id_recurso INT NULL,
  id_articulo INT NULL,
  id_usuario INT NOT NULL,
  tipo_evento VARCHAR(80) NOT NULL,
  fecha DATETIME NOT NULL,
  detalle VARCHAR(500) NOT NULL,
  CONSTRAINT fk_hist_recurso FOREIGN KEY (id_recurso) REFERENCES recurso (id_recurso),
  CONSTRAINT fk_hist_articulo FOREIGN KEY (id_articulo) REFERENCES articulo (id_articulo),
  CONSTRAINT fk_hist_usuario FOREIGN KEY (id_usuario) REFERENCES usuario (id_usuario)
);

CREATE TABLE sesion_revocada (
  jti VARCHAR(64) PRIMARY KEY,
  expira DATETIME NOT NULL
);

INSERT INTO rol (id_rol, nombre, descripcion) VALUES
(1, 'Administrador', 'Todas las funciones, usuarios y plazo de alertas'),
(2, 'Responsable de control', 'Inventario, préstamos, mantenimiento y reportes'),
(3, 'Personal operativo', 'Consulta su inventario y sus asignaciones');

-- Hash SHA-256 de CruzRojaSantaAna.v1|CruzRoja2026
INSERT INTO usuario (id_usuario, nombre, apellido, identificador, contrasena_hash, activo, id_rol) VALUES
(1, 'Elian', 'Salinas', 'Elian Salinas', 'G58fWes5CjLwr6/IyhbvzDHPaeueY/kqVwmtG2yjlfc=', 1, 1),
(2, 'Karla', 'Llosent', 'Karla Llosent', 'G58fWes5CjLwr6/IyhbvzDHPaeueY/kqVwmtG2yjlfc=', 1, 2),
(3, 'Jason', 'Arias', 'Jason Arias', 'G58fWes5CjLwr6/IyhbvzDHPaeueY/kqVwmtG2yjlfc=', 1, 3),
(4, 'Aaron', 'García', 'Aaron García', 'G58fWes5CjLwr6/IyhbvzDHPaeueY/kqVwmtG2yjlfc=', 0, 3);

INSERT INTO configuracion (clave, valor, fecha_actualizacion, id_usuario) VALUES
('dias_anticipacion', '45', '2026-10-01 08:00:00', 1);

INSERT INTO categoria (id_categoria, nombre, descripcion, tipo, activo) VALUES
(1, 'Equipo médico', 'Equipos de atención', 'Equipo', 1),
(2, 'Rescate', 'Equipos de rescate', 'Equipo', 1),
(3, 'Comunicación', 'Radios y comunicación', 'Equipo', 1),
(4, 'Insumo clínico', 'Material consumible', 'Insumo', 1);

INSERT INTO ubicacion (id_ubicacion, nombre, direccion, responsable, activo) VALUES
(1, 'Ambulancia 1', 'Comité Santa Ana', 'Turno A', 1),
(2, 'Ambulancia 2', 'Comité Santa Ana', 'Turno B', 1),
(3, 'Bodega', 'Sede Santa Ana', 'Control de inventario', 1),
(4, 'Sala de radio', 'Sede Santa Ana', 'Comunicaciones', 1);

INSERT INTO estado_recurso (id_estado, nombre, descripcion) VALUES
(1, 'Disponible', 'Listo para asignación'),
(2, 'En préstamo', 'Asignado a un responsable'),
(3, 'En mantenimiento', 'Trabajo de mantenimiento en curso'),
(4, 'Fuera de servicio', 'No disponible hasta nueva habilitación');

INSERT INTO recurso (id_recurso, codigo, nombre, marca, serie, fecha_adquisicion, fecha_vencimiento, id_categoria, id_ubicacion, id_estado, hallazgo_pendiente, activo) VALUES
(1, 'R-001', 'Desfibrilador DEA', 'Zoll', 'DEA-1001', '2024-03-01', '2027-03-01', 1, 1, 1, 0, 1),
(2, 'R-002', 'Camilla rígida', 'Ferno', 'CAM-204', '2023-06-15', NULL, 2, 3, 2, 0, 1),
(3, 'R-003', 'Tanque de oxígeno', 'Praxair', 'OX-330', '2022-11-20', NULL, 1, 2, 3, 0, 1),
(4, 'R-004', 'Radio portátil', 'Motorola', 'RAD-018', '2024-01-10', NULL, 3, 4, 1, 0, 1),
(5, 'R-005', 'Collarín cervical', 'Laerdal', 'COL-077', '2021-08-01', NULL, 2, 3, 4, 1, 1),
(6, 'R-006', 'Kit de inmovilización', 'Laerdal', 'KIT-006', '2020-09-30', '2026-09-30', 2, 1, 1, 0, 1);

INSERT INTO prestamo (id_prestamo, id_recurso, id_usuario_responsable, destino, fecha_salida, fecha_retorno_prevista, estado) VALUES
(1, 2, 3, 'Evento comunitario', '2026-10-07 09:12:00', '2026-10-12 18:00:00', 'Abierto');

INSERT INTO mantenimiento (id_mantenimiento, id_recurso, id_usuario_responsable, tipo_trabajo, fecha_programada, fecha_inicio, estado) VALUES
(1, 3, 1, 'Recarga y prueba hidrostática', '2026-10-06', '2026-10-06 14:30:00', 'En curso'),
(2, 4, 1, 'Cambio de batería', '2026-10-05', NULL, 'Programado');

INSERT INTO inspeccion (id_inspeccion, id_recurso, id_usuario_inspector, fecha, resultado, observaciones, hallazgo_pendiente) VALUES
(1, 5, 2, '2026-10-04 11:00:00', 'No conforme', 'Hebilla dañada. No debe asignarse hasta reparación.', 1);

INSERT INTO articulo (id_articulo, codigo, nombre, unidad_medida, stock_minimo, activo, id_categoria) VALUES
(1, 'GAS-01', 'Gasas estériles', 'caja', 10, 1, 4),
(2, 'GUA-01', 'Guantes de nitrilo', 'par', 50, 1, 4),
(3, 'SUE-01', 'Suero fisiológico 500 ml', 'unidad', 6, 1, 4);

INSERT INTO lote (id_lote, id_articulo, numero_lote, fecha_vencimiento, cantidad_inicial, cantidad_actual) VALUES
(1, 1, 'L-22', '2026-11-15', 40, 40),
(2, 2, 'L-07', '2027-06-01', 200, 200),
(3, 3, 'L-13', '2026-10-20', 12, 12);

INSERT INTO movimiento_insumo (id_articulo, id_lote, id_usuario, tipo, cantidad, fecha, motivo, saldo_resultante) VALUES
(1, 1, 2, 'Entrada', 40, '2026-09-01 08:00:00', 'Ingreso inicial', 40),
(2, 2, 2, 'Entrada', 200, '2026-09-01 08:05:00', 'Ingreso inicial', 200),
(3, 3, 2, 'Entrada', 12, '2026-09-01 08:10:00', 'Ingreso inicial', 12);

INSERT INTO historial (id_recurso, id_articulo, id_usuario, tipo_evento, fecha, detalle) VALUES
(1, NULL, 1, 'Registro', '2026-10-01 08:00:00', 'Registro del recurso R-001'),
(2, NULL, 1, 'Registro', '2026-10-01 08:01:00', 'Registro del recurso R-002'),
(3, NULL, 1, 'Registro', '2026-10-01 08:02:00', 'Registro del recurso R-003'),
(4, NULL, 1, 'Registro', '2026-10-01 08:03:00', 'Registro del recurso R-004'),
(5, NULL, 1, 'Registro', '2026-10-01 08:04:00', 'Registro del recurso R-005'),
(6, NULL, 1, 'Registro', '2026-10-01 08:05:00', 'Registro del recurso R-006'),
(5, NULL, 2, 'Inspeccion', '2026-10-04 11:00:00', 'Inspección no conforme de R-005. Hebilla dañada.'),
(4, NULL, 1, 'Mantenimiento', '2026-10-05 09:00:00', 'Programación de mantenimiento de R-004: Cambio de batería'),
(3, NULL, 1, 'Mantenimiento', '2026-10-06 14:30:00', 'Inicio de mantenimiento de R-003'),
(2, NULL, 2, 'Prestamo', '2026-10-07 09:12:00', 'Préstamo de R-002 a Jason Arias'),
(NULL, 1, 2, 'Insumo', '2026-09-01 08:00:00', 'Entrada de Gasas estériles lote L-22');

DELIMITER $$

-- PROCEDIMIENTOS ALMACENADOS 
CREATE PROCEDURE sp_prestamo_abrir(
  IN p_id_recurso INT,
  IN p_id_responsable INT,
  IN p_destino VARCHAR(150),
  IN p_fecha_salida DATETIME,
  IN p_fecha_retorno DATETIME,
  IN p_id_usuario INT
)
BEGIN
  DECLARE v_estado INT DEFAULT NULL;
  DECLARE v_codigo VARCHAR(30);
  DECLARE v_nombre VARCHAR(160);

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;
  SELECT id_estado, codigo INTO v_estado, v_codigo FROM recurso WHERE id_recurso = p_id_recurso FOR UPDATE;
  IF v_estado IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El recurso no existe.';
  END IF;
  IF v_estado <> 1 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El recurso no está disponible para préstamo.';
  END IF;
  IF p_fecha_retorno <= p_fecha_salida THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La fecha de retorno debe ser posterior a la salida.';
  END IF;
  SELECT CONCAT(nombre, ' ', apellido) INTO v_nombre FROM usuario WHERE id_usuario = p_id_responsable AND activo = 1;
  IF v_nombre IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El responsable no está activo.';
  END IF;

  INSERT INTO prestamo (id_recurso, id_usuario_responsable, destino, fecha_salida, fecha_retorno_prevista, estado)
  VALUES (p_id_recurso, p_id_responsable, p_destino, p_fecha_salida, p_fecha_retorno, 'Abierto');
  UPDATE recurso SET id_estado = 2 WHERE id_recurso = p_id_recurso;
  INSERT INTO historial (id_recurso, id_usuario, tipo_evento, fecha, detalle)
  VALUES (p_id_recurso, p_id_usuario, 'Prestamo', NOW(), CONCAT('Préstamo de ', v_codigo, ' a ', v_nombre));
  COMMIT;
END$$

CREATE PROCEDURE sp_prestamo_cerrar(
  IN p_id_prestamo INT,
  IN p_fecha_retorno DATETIME,
  IN p_condicion VARCHAR(40),
  IN p_id_ubicacion INT,
  IN p_observaciones VARCHAR(500),
  IN p_id_usuario INT,
  IN p_id_estado INT
)
BEGIN
  DECLARE v_estado VARCHAR(20);
  DECLARE v_salida DATETIME;
  DECLARE v_recurso INT;
  DECLARE v_codigo VARCHAR(30);

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;
  SELECT estado, fecha_salida, id_recurso INTO v_estado, v_salida, v_recurso
  FROM prestamo WHERE id_prestamo = p_id_prestamo FOR UPDATE;
  IF v_estado IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El préstamo no existe.';
  END IF;
  IF v_estado <> 'Abierto' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ese préstamo ya está cerrado.';
  END IF;
  IF p_fecha_retorno < v_salida THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La devolución no puede ser anterior a la salida.';
  END IF;

  SELECT codigo INTO v_codigo FROM recurso WHERE id_recurso = v_recurso FOR UPDATE;
  UPDATE prestamo
     SET estado = 'Cerrado', fecha_retorno_real = p_fecha_retorno, condicion_recibida = p_condicion,
         observaciones = p_observaciones, id_usuario_recibe = p_id_usuario
   WHERE id_prestamo = p_id_prestamo;
  UPDATE recurso SET id_estado = p_id_estado, id_ubicacion = p_id_ubicacion WHERE id_recurso = v_recurso;
  INSERT INTO historial (id_recurso, id_usuario, tipo_evento, fecha, detalle)
  VALUES (v_recurso, p_id_usuario, 'Devolucion', NOW(),
          CONCAT('Devolución de ', v_codigo, ' (', p_condicion, ')'));
  COMMIT;
END$$

CREATE PROCEDURE sp_mantenimiento_iniciar(
  IN p_id INT,
  IN p_id_usuario INT,
  IN p_fecha DATETIME
)
BEGIN
  DECLARE v_estado VARCHAR(30);
  DECLARE v_recurso INT;
  DECLARE v_codigo VARCHAR(30);
  DECLARE v_trabajo VARCHAR(150);
  DECLARE v_prestamo INT DEFAULT 0;
  DECLARE v_otro INT DEFAULT 0;

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;
  SELECT estado, id_recurso, tipo_trabajo INTO v_estado, v_recurso, v_trabajo
  FROM mantenimiento WHERE id_mantenimiento = p_id FOR UPDATE;
  IF v_estado IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El mantenimiento no existe.';
  END IF;
  IF v_estado <> 'Programado' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Solo se puede iniciar un mantenimiento programado.';
  END IF;
  SELECT COUNT(*) INTO v_prestamo FROM prestamo WHERE id_recurso = v_recurso AND estado = 'Abierto';
  IF v_prestamo > 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El recurso tiene un préstamo abierto.';
  END IF;
  SELECT COUNT(*) INTO v_otro FROM mantenimiento WHERE id_recurso = v_recurso AND estado = 'En curso';
  IF v_otro > 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ya hay un mantenimiento en curso.';
  END IF;
  SELECT codigo INTO v_codigo FROM recurso WHERE id_recurso = v_recurso FOR UPDATE;
  UPDATE mantenimiento SET estado = 'En curso', fecha_inicio = p_fecha WHERE id_mantenimiento = p_id;
  UPDATE recurso SET id_estado = 3 WHERE id_recurso = v_recurso;
  INSERT INTO historial (id_recurso, id_usuario, tipo_evento, fecha, detalle)
  VALUES (v_recurso, p_id_usuario, 'Mantenimiento', NOW(), CONCAT('Inicio de mantenimiento de ', v_codigo, ': ', v_trabajo));
  COMMIT;
END$$

CREATE PROCEDURE sp_mantenimiento_cerrar(
  IN p_id INT,
  IN p_id_usuario INT,
  IN p_fecha DATETIME,
  IN p_resultado VARCHAR(40),
  IN p_observaciones VARCHAR(500),
  IN p_resuelve TINYINT,
  IN p_id_estado INT
)
BEGIN
  DECLARE v_estado VARCHAR(30);
  DECLARE v_inicio DATETIME;
  DECLARE v_recurso INT;
  DECLARE v_codigo VARCHAR(30);

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;
  SELECT estado, fecha_inicio, id_recurso INTO v_estado, v_inicio, v_recurso
  FROM mantenimiento WHERE id_mantenimiento = p_id FOR UPDATE;
  IF v_estado <> 'En curso' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Solo se puede cerrar un mantenimiento en curso.';
  END IF;
  IF p_fecha < v_inicio THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El cierre no puede ser anterior al inicio.';
  END IF;
  SELECT codigo INTO v_codigo FROM recurso WHERE id_recurso = v_recurso FOR UPDATE;
  UPDATE mantenimiento
     SET estado = 'Cerrado', fecha_cierre = p_fecha, resultado = p_resultado,
         observaciones = p_observaciones, resuelve_hallazgos = p_resuelve
   WHERE id_mantenimiento = p_id;
  UPDATE recurso
     SET id_estado = p_id_estado,
         hallazgo_pendiente = CASE WHEN p_resuelve = 1 THEN 0 ELSE hallazgo_pendiente END
   WHERE id_recurso = v_recurso;
  INSERT INTO historial (id_recurso, id_usuario, tipo_evento, fecha, detalle)
  VALUES (v_recurso, p_id_usuario, 'Mantenimiento', NOW(),
          CONCAT('Cierre ', p_resultado, ' del mantenimiento de ', v_codigo));
  COMMIT;
END$$

CREATE PROCEDURE sp_insumo_movimiento(
  IN p_id_lote INT,
  IN p_tipo VARCHAR(20),
  IN p_cantidad DECIMAL(12,2),
  IN p_motivo VARCHAR(300),
  IN p_id_usuario INT
)
BEGIN
  DECLARE v_saldo DECIMAL(12,2);
  DECLARE v_vence DATE;
  DECLARE v_articulo INT;
  DECLARE v_numero VARCHAR(40);
  DECLARE v_nombre VARCHAR(150);
  DECLARE v_nuevo DECIMAL(12,2);

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;
  SELECT cantidad_actual, fecha_vencimiento, id_articulo, numero_lote
    INTO v_saldo, v_vence, v_articulo, v_numero
  FROM lote WHERE id_lote = p_id_lote FOR UPDATE;
  IF v_saldo IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El lote no existe.';
  END IF;
  IF p_cantidad <= 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La cantidad debe ser mayor que cero.';
  END IF;
  IF p_tipo IN ('AjusteAumento', 'AjusteDisminucion') AND (p_motivo IS NULL OR CHAR_LENGTH(TRIM(p_motivo)) = 0) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El ajuste requiere un motivo.';
  END IF;
  IF p_tipo = 'Consumo' AND v_vence IS NOT NULL AND v_vence < CURDATE() THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se permite el consumo de un lote vencido.';
  END IF;

  IF p_tipo IN ('Entrada', 'AjusteAumento') THEN
    SET v_nuevo = v_saldo + p_cantidad;
  ELSEIF p_tipo IN ('Consumo', 'AjusteDisminucion') THEN
    SET v_nuevo = v_saldo - p_cantidad;
  ELSE
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El tipo de movimiento no es válido.';
  END IF;
  IF v_nuevo < 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La salida dejaría la existencia en negativo.';
  END IF;

  SELECT nombre INTO v_nombre FROM articulo WHERE id_articulo = v_articulo;
  UPDATE lote SET cantidad_actual = v_nuevo WHERE id_lote = p_id_lote;
  INSERT INTO movimiento_insumo (id_articulo, id_lote, id_usuario, tipo, cantidad, fecha, motivo, saldo_resultante)
  VALUES (v_articulo, p_id_lote, p_id_usuario, p_tipo, p_cantidad, NOW(), NULLIF(p_motivo, ''), v_nuevo);
  INSERT INTO historial (id_articulo, id_usuario, tipo_evento, fecha, detalle)
  VALUES (v_articulo, p_id_usuario, 'Insumo', NOW(),
          CONCAT(p_tipo, ' de ', v_nombre, ' lote ', v_numero, '. Saldo ', v_nuevo));
  COMMIT;
END$$

CREATE PROCEDURE sp_reporte_inventario(
  IN p_categoria INT,
  IN p_ubicacion INT,
  IN p_estado INT
)
BEGIN
  SELECT r.codigo AS Codigo,
         r.nombre AS Recurso,
         e.nombre AS Estado,
         u.nombre AS Ubicacion,
         c.nombre AS Categoria
  FROM recurso r
  JOIN estado_recurso e ON e.id_estado = r.id_estado
  JOIN ubicacion u ON u.id_ubicacion = r.id_ubicacion
  JOIN categoria c ON c.id_categoria = r.id_categoria
  WHERE r.activo = 1
    AND (p_categoria IS NULL OR p_categoria = 0 OR r.id_categoria = p_categoria)
    AND (p_ubicacion IS NULL OR p_ubicacion = 0 OR r.id_ubicacion = p_ubicacion)
    AND (p_estado IS NULL OR p_estado = 0 OR r.id_estado = p_estado)
  ORDER BY r.codigo;
END$$

DELIMITER ;


-- ============================================================
-- Recursos: consultar, obtener, crear, editar y eliminar
-- ============================================================

CREATE PROCEDURE sp_recurso_consultar(
  IN p_texto VARCHAR(150),
  IN p_id_estado INT,
  IN p_id_categoria INT,
  IN p_ordenar VARCHAR(20),
  IN p_descendente TINYINT
)
BEGIN
  SELECT * FROM vw_recurso v
  WHERE v.Activo = 1
    AND (p_texto IS NULL OR p_texto = ''
         OR v.Codigo LIKE CONCAT('%', p_texto, '%')
         OR v.Nombre LIKE CONCAT('%', p_texto, '%')
         OR v.Serie LIKE CONCAT('%', p_texto, '%'))
    AND (p_id_estado IS NULL OR p_id_estado = 0 OR v.IdEstado = p_id_estado)
    AND (p_id_categoria IS NULL OR p_id_categoria = 0 OR v.IdCategoria = p_id_categoria)
  ORDER BY
    CASE WHEN p_descendente = 0 THEN
      CASE p_ordenar WHEN 'nombre' THEN v.Nombre WHEN 'estado' THEN v.Estado WHEN 'categoria' THEN v.Categoria ELSE v.Codigo END
    END ASC,
    CASE WHEN p_descendente = 1 THEN
      CASE p_ordenar WHEN 'nombre' THEN v.Nombre WHEN 'estado' THEN v.Estado WHEN 'categoria' THEN v.Categoria ELSE v.Codigo END
    END DESC,
    v.Codigo ASC;
END$$

CREATE PROCEDURE sp_recurso_obtener(IN p_id INT)
BEGIN
  SELECT * FROM vw_recurso WHERE IdRecurso = p_id;
END$$

CREATE PROCEDURE sp_recurso_crear(
  IN p_codigo VARCHAR(30),
  IN p_nombre VARCHAR(150),
  IN p_descripcion VARCHAR(300),
  IN p_marca VARCHAR(80),
  IN p_modelo VARCHAR(80),
  IN p_serie VARCHAR(80),
  IN p_fecha_adquisicion DATE,
  IN p_fecha_vencimiento DATE,
  IN p_observaciones VARCHAR(500),
  IN p_id_categoria INT,
  IN p_id_ubicacion INT
)
BEGIN
  IF EXISTS (SELECT 1 FROM recurso WHERE codigo = p_codigo) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ya existe un recurso con ese código.';
  END IF;

  INSERT INTO recurso (codigo, nombre, descripcion, marca, modelo, serie, fecha_adquisicion, fecha_vencimiento,
                       observaciones, id_categoria, id_ubicacion, id_estado, hallazgo_pendiente, activo)
  VALUES (p_codigo, p_nombre, p_descripcion, p_marca, p_modelo, p_serie, p_fecha_adquisicion, p_fecha_vencimiento,
          p_observaciones, p_id_categoria, p_id_ubicacion, 1, 0, 1);
END$$

CREATE PROCEDURE sp_recurso_editar(
  IN p_id INT,
  IN p_codigo VARCHAR(30),
  IN p_nombre VARCHAR(150),
  IN p_descripcion VARCHAR(300),
  IN p_marca VARCHAR(80),
  IN p_modelo VARCHAR(80),
  IN p_serie VARCHAR(80),
  IN p_fecha_adquisicion DATE,
  IN p_fecha_vencimiento DATE,
  IN p_observaciones VARCHAR(500),
  IN p_id_categoria INT,
  IN p_id_ubicacion INT
)
BEGIN
  IF NOT EXISTS (SELECT 1 FROM recurso WHERE id_recurso = p_id AND activo = 1) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El recurso no existe.';
  END IF;
  IF EXISTS (SELECT 1 FROM recurso WHERE codigo = p_codigo AND id_recurso <> p_id) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ya existe un recurso con ese código.';
  END IF;

  UPDATE recurso
     SET codigo = p_codigo, nombre = p_nombre, descripcion = p_descripcion, marca = p_marca, modelo = p_modelo,
         serie = p_serie, fecha_adquisicion = p_fecha_adquisicion, fecha_vencimiento = p_fecha_vencimiento,
         observaciones = p_observaciones, id_categoria = p_id_categoria, id_ubicacion = p_id_ubicacion
   WHERE id_recurso = p_id;
END$$

-- Eliminación lógica: el recurso deja de aparecer, pero su historial se conserva.
CREATE PROCEDURE sp_recurso_eliminar(
  IN p_id INT,
  IN p_id_usuario INT
)
BEGIN
  DECLARE v_activo TINYINT DEFAULT NULL;
  DECLARE v_codigo VARCHAR(30);

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;
  SELECT activo, codigo INTO v_activo, v_codigo FROM recurso WHERE id_recurso = p_id FOR UPDATE;
  IF v_activo IS NULL OR v_activo = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El recurso no existe o ya fue eliminado.';
  END IF;
  IF EXISTS (SELECT 1 FROM prestamo WHERE id_recurso = p_id AND estado = 'Abierto') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se puede eliminar: el recurso tiene un préstamo abierto.';
  END IF;
  IF EXISTS (SELECT 1 FROM mantenimiento WHERE id_recurso = p_id AND estado IN ('Programado', 'En curso')) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se puede eliminar: el recurso tiene un mantenimiento pendiente.';
  END IF;

  UPDATE recurso SET activo = 0 WHERE id_recurso = p_id;
  INSERT INTO historial (id_recurso, id_usuario, tipo_evento, fecha, detalle)
  VALUES (p_id, p_id_usuario, 'Eliminacion', NOW(), CONCAT('Eliminación del recurso ', v_codigo));
  COMMIT;
END$$

-- ============================================================
-- Categorías: consultar, crear, editar y eliminar
-- ============================================================

CREATE PROCEDURE sp_categoria_consultar(IN p_solo_activas TINYINT)
BEGIN
  SELECT id_categoria, nombre, descripcion, tipo, activo
  FROM categoria
  WHERE p_solo_activas = 0 OR activo = 1
  ORDER BY nombre;
END$$

CREATE PROCEDURE sp_categoria_crear(
  IN p_nombre VARCHAR(120),
  IN p_descripcion VARCHAR(250),
  IN p_tipo VARCHAR(40),
  IN p_activo TINYINT
)
BEGIN
  IF EXISTS (SELECT 1 FROM categoria WHERE nombre = p_nombre) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ya existe una categoría con ese nombre.';
  END IF;
  INSERT INTO categoria (nombre, descripcion, tipo, activo) VALUES (p_nombre, p_descripcion, p_tipo, p_activo);
END$$

CREATE PROCEDURE sp_categoria_editar(
  IN p_id INT,
  IN p_nombre VARCHAR(120),
  IN p_descripcion VARCHAR(250),
  IN p_tipo VARCHAR(40),
  IN p_activo TINYINT
)
BEGIN
  IF NOT EXISTS (SELECT 1 FROM categoria WHERE id_categoria = p_id) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La categoría no existe.';
  END IF;
  IF EXISTS (SELECT 1 FROM categoria WHERE nombre = p_nombre AND id_categoria <> p_id) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ya existe una categoría con ese nombre.';
  END IF;
  UPDATE categoria SET nombre = p_nombre, descripcion = p_descripcion, tipo = p_tipo, activo = p_activo
   WHERE id_categoria = p_id;
END$$

-- Eliminación física: solo si ningún recurso o artículo la usa.
CREATE PROCEDURE sp_categoria_eliminar(IN p_id INT)
BEGIN
  IF NOT EXISTS (SELECT 1 FROM categoria WHERE id_categoria = p_id) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La categoría no existe.';
  END IF;
  IF EXISTS (SELECT 1 FROM recurso WHERE id_categoria = p_id)
     OR EXISTS (SELECT 1 FROM articulo WHERE id_categoria = p_id) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se puede eliminar: la categoría tiene recursos o artículos. Desactívela en su lugar.';
  END IF;
  DELETE FROM categoria WHERE id_categoria = p_id;
END$$

-- ============================================================
-- Ubicaciones: consultar, crear, editar y eliminar
-- ============================================================

CREATE PROCEDURE sp_ubicacion_consultar(IN p_solo_activas TINYINT)
BEGIN
  SELECT id_ubicacion, nombre, direccion, responsable, activo
  FROM ubicacion
  WHERE p_solo_activas = 0 OR activo = 1
  ORDER BY nombre;
END$$

CREATE PROCEDURE sp_ubicacion_crear(
  IN p_nombre VARCHAR(120),
  IN p_direccion VARCHAR(200),
  IN p_responsable VARCHAR(120),
  IN p_activo TINYINT
)
BEGIN
  IF EXISTS (SELECT 1 FROM ubicacion WHERE nombre = p_nombre) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ya existe una ubicación con ese nombre.';
  END IF;
  INSERT INTO ubicacion (nombre, direccion, responsable, activo) VALUES (p_nombre, p_direccion, p_responsable, p_activo);
END$$

CREATE PROCEDURE sp_ubicacion_editar(
  IN p_id INT,
  IN p_nombre VARCHAR(120),
  IN p_direccion VARCHAR(200),
  IN p_responsable VARCHAR(120),
  IN p_activo TINYINT
)
BEGIN
  IF NOT EXISTS (SELECT 1 FROM ubicacion WHERE id_ubicacion = p_id) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La ubicación no existe.';
  END IF;
  IF EXISTS (SELECT 1 FROM ubicacion WHERE nombre = p_nombre AND id_ubicacion <> p_id) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ya existe una ubicación con ese nombre.';
  END IF;
  UPDATE ubicacion SET nombre = p_nombre, direccion = p_direccion, responsable = p_responsable, activo = p_activo
   WHERE id_ubicacion = p_id;
END$$

-- Eliminación física: solo si ningún recurso está en esa ubicación.
CREATE PROCEDURE sp_ubicacion_eliminar(IN p_id INT)
BEGIN
  IF NOT EXISTS (SELECT 1 FROM ubicacion WHERE id_ubicacion = p_id) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La ubicación no existe.';
  END IF;
  IF EXISTS (SELECT 1 FROM recurso WHERE id_ubicacion = p_id) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se puede eliminar: hay recursos en esa ubicación. Desactívela en su lugar.';
  END IF;
  DELETE FROM ubicacion WHERE id_ubicacion = p_id;
END$$

DELIMITER ;

CREATE USER IF NOT EXISTS 'cruzroja'@'localhost' IDENTIFIED BY 'CruzRoja2026';
GRANT ALL PRIVILEGES ON cruz_roja_santa_ana.* TO 'cruzroja'@'localhost';
FLUSH PRIVILEGES;

