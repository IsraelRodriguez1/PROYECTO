-- phpMyAdmin SQL Dump
-- version 4.9.1
-- https://www.phpmyadmin.net/
--
-- Servidor: localhost
-- Tiempo de generación: 07-09-2022 a las 20:35:37
-- Versión del servidor: 8.0.17
-- Versión de PHP: 7.4.30

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET AUTOCOMMIT = 0;
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de datos: `market-pos`
--

DELIMITER $$
--
-- Procedimientos
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `prc_ListarProductos` ()  NO SQL
BEGIN

SELECT '' as detalles,
		p.id,
        p.codigo_producto,
        c.id_categoria,
        c.nombre_categoria,
        p.descripcion_producto,
        ROUND(p.precio_compra_producto,2) as precio_compa,
        ROUND(p.precio_venta_producto,2) as precio_venta,
        ROUND(p.utilidad,2) as utilidad,
        CASE WHEN c.aplica_peso = 1 THEN concat(p.stock_producto,' Kg(s)') ELSE concat(p.stock_producto, ' Und(s)') END as stock,
        CASE WHEN c.aplica_peso = 1 THEN concat(p.minimo_stock_producto,' Kg(s)') ELSE concat(p.minimo_stock_producto, ' Und(s)') END as minimo_stock,
        CASE WHEN c.aplica_peso = 1 THEN concat(p.ventas_producto,' Kg(s)') ELSE concat(p.ventas_producto, ' Und(s)') END as ventas,
        p.fecha_creacion_producto,
        p.fecha_actualizacion_producto,
        '' as opciones
FROM productos p INNER JOIN categorias c on p.id_categoria_producto = c.id_categoria;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `prc_ListarProductosMasVendidos` ()  NO SQL
BEGIN

SELECT p.codigo_producto,
		p.descripcion_producto,
        SUM(vd.cantidad) as cantidad,
		SUM(Round(vd.total_venta,2)) as total_venta
FROM venta_detalle vd INNER JOIN productos p on vd.codigo_producto = p.codigo_producto

GROUP BY p.codigo_producto,
		p.descripcion_producto
ORDER BY SUM(Round(vd.total_venta,2)) DESC
LIMIT 10;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `prc_ListarProductosPocoStock` ()  NO SQL
BEGIN
SELECT p.codigo_producto,
		p.descripcion_producto,
        p.stock_producto,
        p.minimo_stock_producto
from productos p 
WHERE p.stock_producto <= p.minimo_stock_producto
ORDER BY p.stock_producto asc;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `prc_ObtenerDatosDashboard` ()  NO SQL
BEGIN

DECLARE totalProductos int;
DECLARE totalCompras float; 
DECLARE totalVentas float;
DECLARE ganancias float;
DECLARE productosPocoStock int;
DECLARE ventasHoy float;

SET totalProductos = (SELECT COUNT(*) FROM productos p);
SET totalCompras = (SELECT SUM(p.precio_compra_producto*p.stock_producto) FROM productos p);

SET totalVentas = (SELECT SUM(vc.total_venta) FROM venta_cabecera vc);

SET ganancias = (SELECT SUM(vd.total_venta) - SUM(p.precio_compra_producto * vd.cantidad) FROM venta_detalle vd INNER JOIN productos p ON vd.codigo_producto = p.codigo_producto);

SET productosPocoStock = (SELECT COUNT(1) FROM productos p WHERE p.stock_producto <= p.minimo_stock_producto);

SET ventasHoy = (SELECT SUM(vc.total_venta) FROM venta_cabecera vc WHERE vc.fecha_venta = curdate());

SELECT IFNULL(totalProductos,0) AS totalProductos,
		IFNULL(ROUND(totalCompras,2),0) AS totalCompras,
        IFNULL(ROUND(totalVentas,2),0) AS totalVentas,
        IFNULL(ROUND(ganancias,2),0) AS ganancias,
        IFNULL(productosPocoStock,0) AS productosPocoStock,
        IFNULL(ROUND(ventasHoy,2),0) AS ventasHoy;
        
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `prc_obtenerNroBoleta` ()  NO SQL
select serie_boleta,
		IFNULL(LPAD(max(c.nro_correlativo_venta)+1,8,'0'),'00000001') nro_venta 
from empresa c$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `prc_ObtenerVentasMesActual` ()  NO SQL
BEGIN

SELECT 	date(vc.fecha_venta) as fecha_venta,
		SUM(round(vc.total_venta,2)) as total_venta
FROM venta_cabecera vc

where date(vc.fecha_venta) >= date(last_day(now() - INTERVAL 1 month + INTERVAL 1 day))
and (vc.fecha_venta) <= last_day(date(CURRENT_DATE))
group by date(vc.fecha_venta);
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `categorias`
--

CREATE TABLE `categorias` (
  `id_categoria` int(11) NOT NULL,
  `nombre_categoria` text CHARACTER SET utf8 COLLATE utf8_spanish_ci,
  `aplica_peso` int(11) NOT NULL,
  `fecha_creacion_categoria` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `fecha_actualizacion_categoria` date DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_spanish_ci;

--
-- Volcado de datos para la tabla `categorias`
--

INSERT INTO `categorias` (`id_categoria`, `nombre_categoria`, `aplica_peso`, `fecha_actualizacion_categoria`) VALUES
(1, 'Repuestos', 0, '2022-09-07'),
(2, 'Indumentaria', 0, '2022-09-07'),
(3, 'Aros', 0, '2022-09-07'),
(4, 'Herramientas', 0, '2022-09-07'),
(5, 'Proteccion', 0, '2022-09-07'),
(6, 'Vehiculos', 0, '2022-09-07'),
(7, 'Equipos Construccion', 0, '2022-09-07'),
(8, 'Equipos Mineria', 0, '2022-09-07'),
(9, 'Almacen', 0, '2022-09-07'),
(10, 'maquinas', 0, '2022-09-07'),
(25, 'NUeva', 0, '2022-09-07');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `empresa`
--

CREATE TABLE `empresa` (
  `id_empresa` int(11) NOT NULL,
  `razon_social` text NOT NULL,
  `ruc` bigint(20) NOT NULL,
  `direccion` text NOT NULL,
  `marca` text NOT NULL,
  `serie_boleta` varchar(4) NOT NULL,
  `nro_correlativo_venta` varchar(8) NOT NULL,
  `email` text NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Volcado de datos para la tabla `empresa`
--

INSERT INTO `empresa` (`id_empresa`, `razon_social`, `ruc`, `direccion`, `marca`, `serie_boleta`, `nro_correlativo_venta`, `email`) VALUES
(1, 'Grupo 2 - Market', 10467291241, 'Avenida Brasil 1347 - Jesus María', 'Maga & Tito Market', '0002', '00000043', 'magaytito@gmail.com');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `modulos`
--

CREATE TABLE `modulos` (
  `id` int(11) NOT NULL,
  `modulo` varchar(45) DEFAULT NULL,
  `padre_id` int(11) DEFAULT NULL,
  `vista` varchar(45) DEFAULT NULL,
  `icon_menu` varchar(45) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Volcado de datos para la tabla `modulos`
--

INSERT INTO `modulos` (`id`, `modulo`, `padre_id`, `vista`, `icon_menu`) VALUES
(1, 'Tablero Principal', NULL, 'dashboard.php', 'fas fa-tachometer-alt'),
(2, 'Ventas', NULL, '', 'fas fa-store-alt'),
(3, 'Punto de Venta', 2, 'ventas.php', 'far fa-circle'),
(4, 'Administrar Ventas', 2, 'administrar_ventas.php', 'far fa-circle'),
(5, 'Productos', NULL, NULL, 'fas fa-cart-plus'),
(6, 'Inventario', 5, 'productos.php', 'far fa-circle'),
(7, 'Carga Masiva', 0, 'carga_masiva_productos.php', 'far fa-circle'),
(8, 'Categorías', 5, 'categorias.php', 'far fa-circle'),
(9, 'Compras', NULL, 'compras.php', 'fas fa-dolly'),
(10, 'Reportes', 0, 'reportes.php', 'fas fa-chart-line'),
(11, 'Configuración', NULL, 'configuracion.php', 'fas fa-cogs'),
(12, 'Usuarios', NULL, 'usuarios.php', 'fas fa-users'),
(13, 'Roles y Perfiles', NULL, 'roles_perfiles.php', 'fas fa-tablet-alt');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `perfiles`
--

CREATE TABLE `perfiles` (
  `id_perfil` int(11) NOT NULL,
  `descripcion` varchar(45) DEFAULT NULL,
  `estado` tinyint(4) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Volcado de datos para la tabla `perfiles`
--

INSERT INTO `perfiles` (`id_perfil`, `descripcion`, `estado`) VALUES
(1, 'Administrador', 1),
(2, 'Operario', 2);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `perfil_modulo`
--

CREATE TABLE `perfil_modulo` (
  `idperfil_modulo` int(11) NOT NULL,
  `id_perfil` int(11) DEFAULT NULL,
  `id_modulo` int(11) DEFAULT NULL,
  `vista_inicio` tinyint(4) DEFAULT NULL,
  `estado` tinyint(4) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Volcado de datos para la tabla `perfil_modulo`
--

INSERT INTO `perfil_modulo` (`idperfil_modulo`, `id_perfil`, `id_modulo`, `vista_inicio`, `estado`) VALUES
(1, 1, 1, 1, 1),
(3, 1, 3, NULL, 1),
(6, 1, 6, NULL, 1),
(7, 1, 7, NULL, 1),
(8, 1, 8, NULL, 1),
(9, 1, 9, NULL, 1),
(10, 1, 10, NULL, 1),
(11, 1, 11, NULL, 1),
(12, 1, 12, NULL, 1),
(13, 1, 13, NULL, 1),
(15, 1, 4, NULL, 1),
(16, 1, 5, NULL, 1),
(17, 1, 2, NULL, 1),
(18, 2, 2, NULL, 1),
(19, 2, 3, 1, 1),
(20, 2, 4, NULL, 1),
(21, 2, 10, NULL, 1),
(24, 2, 1, NULL, 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `productos`
--

CREATE TABLE `productos` (
  `id` int(11) NOT NULL,
  `codigo_producto` bigint(13) NOT NULL,
  `id_categoria_producto` int(11) DEFAULT NULL,
  `descripcion_producto` text CHARACTER SET utf8 COLLATE utf8_spanish_ci,
  `precio_compra_producto` float NOT NULL,
  `precio_venta_producto` float NOT NULL,
  `precio_mayor_producto` float NOT NULL,
  `precio_oferta_producto` float NOT NULL,
  `utilidad` float NOT NULL,
  `stock_producto` float DEFAULT NULL,
  `minimo_stock_producto` float DEFAULT NULL,
  `ventas_producto` float DEFAULT NULL,
  `fecha_creacion_producto` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `fecha_actualizacion_producto` date DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_spanish_ci;

--
-- Volcado de datos para la tabla `productos`
--

INSERT INTO `productos` (`id`, `codigo_producto`, `id_categoria_producto`, `descripcion_producto`, `precio_compra_producto`, `precio_venta_producto`, `precio_mayor_producto`, `precio_oferta_producto`, `utilidad`, `stock_producto`, `minimo_stock_producto`, `ventas_producto`, `fecha_actualizacion_producto`) VALUES
(103, 7451071013585, 8, 'Camiones Electricos', 150000, 195000, 0, 0, 45000, 9, 1, 1, '2022-09-07'),
(104, 7151251013481, 5, 'Cascos', 25, 100, 0, 0, 75, 90, 12, 10, '2022-09-07'),
(105, 7851777773588, 4, 'Taladros industriales', 520, 785, 0, 0, 265, 50, 5, 0, '2022-09-07'),
(106, 7451071013588, 8, 'Camiones Extractor', 500000, 600000, 0, 0, 100000, 5, 1, 0, '2022-09-07'),
(107, 74151515, 25, 'Camion', 50000, 100000, 0, 0, 50000, 500, 2, 0, '2022-09-07');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `usuarios`
--

CREATE TABLE `usuarios` (
  `id_usuario` int(11) NOT NULL,
  `nombre_usuario` varchar(100) DEFAULT NULL,
  `apellido_usuario` varchar(100) DEFAULT NULL,
  `usuario` varchar(100) DEFAULT NULL,
  `clave` text,
  `id_perfil_usuario` int(11) DEFAULT NULL,
  `estado` tinyint(4) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Volcado de datos para la tabla `usuarios`
--

INSERT INTO `usuarios` (`id_usuario`, `nombre_usuario`, `apellido_usuario`, `usuario`, `clave`, `id_perfil_usuario`, `estado`) VALUES
(1, 'Israel', 'Rodriguez', 'admin', '$2a$07$azybxcags23425sdg23sdeanQZqjaf6Birm2NvcYTNtJw24CsO5uq', 1, 1),
(2, 'Paolo', 'Guerrero', 'user', '$2a$07$azybxcags23425sdg23sdeanQZqjaf6Birm2NvcYTNtJw24CsO5uq', 2, 2);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `venta_cabecera`
--

CREATE TABLE `venta_cabecera` (
  `id_boleta` int(11) NOT NULL,
  `nro_boleta` varchar(8) NOT NULL,
  `descripcion` text,
  `subtotal` float NOT NULL,
  `igv` float NOT NULL,
  `total_venta` float DEFAULT NULL,
  `fecha_venta` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Volcado de datos para la tabla `venta_cabecera`
--

INSERT INTO `venta_cabecera` (`id_boleta`, `nro_boleta`, `descripcion`, `subtotal`, `igv`, `total_venta`, `fecha_venta`) VALUES
(46, '00000014', 'Venta realizada con Nro Boleta: 00000014', 0, 0, 69, '2021-10-18 21:54:10'),
(47, '00000015', 'Venta realizada con Nro Boleta: 00000015', 0, 0, 17.5, '2021-10-18 22:34:17'),
(48, '00000016', 'Venta realizada con Nro Boleta: 00000016', 0, 0, 16.2, '2021-10-18 22:34:51'),
(49, '00000017', 'Venta realizada con Nro Boleta: 00000017', 0, 0, 5, '2021-10-18 23:01:17'),
(50, '00000018', 'Venta realizada con Nro Boleta: 00000018', 0, 0, 1.8, '2021-10-18 23:56:24'),
(51, '00000019', 'Venta realizada con Nro Boleta: 00000019', 0, 0, 21.2, '2021-10-19 02:27:17'),
(52, '00000020', 'Venta realizada con Nro Boleta: 00000020', 0, 0, 29.5, '2021-10-19 02:29:41'),
(53, '00000021', 'Venta realizada con Nro Boleta: 00000021', 0, 0, 9.2, '2021-10-19 02:31:19'),
(54, '00000022', 'Venta realizada con Nro Boleta: 00000022', 0, 0, 1.25, '2021-10-19 02:32:55'),
(55, '00000023', 'Venta realizada con Nro Boleta: 00000023', 0, 0, 1.8, '2021-10-24 22:27:16'),
(56, '00000024', 'Venta realizada con Nro Boleta: 00000024', 0, 0, 65.8, '2022-07-07 22:27:45'),
(57, '00000025', 'Venta realizada con Nro Boleta: 00000025', 0, 0, 1.2, '2022-07-17 16:50:17'),
(58, '00000026', 'Venta realizada con Nro Boleta: 00000026', 0, 0, 6.7, '2022-07-17 16:52:34'),
(59, '00000027', 'Venta realizada con Nro Boleta: 00000027', 0, 0, 1.2, '2022-07-18 01:21:01'),
(60, '00000028', 'Venta realizada con Nro Boleta: 00000028', 0, 0, 7, '2022-07-18 01:41:03'),
(61, '00000029', 'Venta realizada con Nro Boleta: 00000029', 0, 0, 1220, '2022-07-18 01:52:52'),
(62, '00000030', 'Venta realizada con Nro Boleta: 00000030', 0, 0, 25, '2022-07-18 03:23:53'),
(63, '00000031', 'Venta realizada con Nro Boleta: 00000031', 0, 0, 0.6, '2022-07-18 03:39:50'),
(64, '00000001', 'Venta realizada con Nro Boleta: 00000001', 0, 0, 0.5, '2022-07-18 04:03:29'),
(65, '00000033', 'Venta realizada con Nro Boleta: 00000033', 0, 0, 1.1, '2022-08-07 17:34:57'),
(66, '00000034', 'Venta realizada con Nro Boleta: 00000034', 0, 0, 25, '2022-08-07 18:44:03'),
(67, '00000035', 'Venta realizada con Nro Boleta: 00000035', 0, 0, 5, '2022-08-07 19:02:32'),
(68, '00000036', 'Venta realizada con Nro Boleta: 00000036', 0, 0, 25, '2022-08-07 21:14:13'),
(69, '00000037', 'Venta realizada con Nro Boleta: 00000037', 0, 0, 5, '2022-08-07 21:45:11'),
(70, '00000038', 'Venta realizada con Nro Boleta: 00000038', 0, 0, 30.8, '2022-08-07 21:48:47'),
(71, '00000039', 'Venta realizada con Nro Boleta: 00000039', 0, 0, 25, '2022-08-08 09:03:40'),
(72, '00000040', 'Venta realizada con Nro Boleta: 00000040', 0, 0, 5, '2022-08-08 09:05:39'),
(73, '00000041', 'Venta realizada con Nro Boleta: 00000041', 0, 0, 0.5, '2022-09-06 23:18:22'),
(74, '00000042', 'Venta realizada con Nro Boleta: 00000042', 0, 0, 195000, '2022-09-07 05:41:24'),
(75, '00000043', 'Venta realizada con Nro Boleta: 00000043', 0, 0, 1000, '2022-09-07 19:15:26');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `venta_detalle`
--

CREATE TABLE `venta_detalle` (
  `id` int(11) NOT NULL,
  `nro_boleta` varchar(8) CHARACTER SET utf8 COLLATE utf8_spanish_ci NOT NULL,
  `codigo_producto` bigint(20) NOT NULL,
  `cantidad` float NOT NULL,
  `total_venta` float NOT NULL,
  `fecha_venta` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_spanish_ci;

--
-- Volcado de datos para la tabla `venta_detalle`
--

INSERT INTO `venta_detalle` (`id`, `nro_boleta`, `codigo_producto`, `cantidad`, `total_venta`) VALUES
(521, '00000014', 7755139002809, 3, 69),
(522, '00000015', 7754725000281, 5, 17.5),
(523, '00000016', 7751271021975, 1, 3.3),
(524, '00000016', 7750182006088, 1, 2.5),
(525, '00000016', 7750151003902, 1, 8.8),
(526, '00000016', 7750885012928, 1, 0.8),
(527, '00000016', 7750106002608, 1, 0.8),
(528, '00000017', 7751271027656, 1, 5),
(529, '00000018', 7750182002363, 1, 1.8),
(530, '00000019', 7754725000281, 4, 14),
(531, '00000019', 7750182002363, 4, 7.2),
(532, '00000020', 7759222002097, 1, 9.5),
(533, '00000020', 7755139002809, 1, 20),
(534, '00000021', 10001, 4, 9.2),
(535, '00000022', 10002, 0.25, 1.25),
(536, '00000014', 7755139002809, 3, 69),
(537, '00000015', 7754725000281, 5, 17.5),
(538, '00000016', 7751271021975, 1, 3.3),
(539, '00000016', 7750182006088, 1, 2.5),
(540, '00000016', 7750151003902, 1, 8.8),
(541, '00000016', 7750885012928, 1, 0.8),
(542, '00000016', 7750106002608, 1, 0.8),
(543, '00000017', 7751271027656, 1, 5),
(544, '00000018', 7750182002363, 1, 1.8),
(545, '00000019', 7754725000281, 4, 14),
(546, '00000019', 7750182002363, 4, 7.2),
(547, '00000020', 7759222002097, 1, 9.5),
(548, '00000020', 7755139002809, 1, 20),
(549, '00000021', 10001, 4, 9.2),
(550, '00000022', 10002, 0.25, 1.25),
(551, '00000014', 7755139002809, 3, 69),
(552, '00000015', 7754725000281, 5, 17.5),
(553, '00000016', 7751271021975, 1, 3.3),
(554, '00000016', 7750182006088, 1, 2.5),
(555, '00000016', 7750151003902, 1, 8.8),
(556, '00000016', 7750885012928, 1, 0.8),
(557, '00000016', 7750106002608, 1, 0.8),
(558, '00000017', 7751271027656, 1, 5),
(559, '00000018', 7750182002363, 1, 1.8),
(560, '00000019', 7754725000281, 4, 14),
(561, '00000019', 7750182002363, 4, 7.2),
(562, '00000020', 7759222002097, 1, 9.5),
(563, '00000020', 7755139002809, 1, 20),
(564, '00000021', 10001, 4, 9.2),
(565, '00000022', 10002, 0.25, 1.25),
(566, '00000014', 7755139002809, 3, 69),
(567, '00000015', 7754725000281, 5, 17.5),
(568, '00000016', 7751271021975, 1, 3.3),
(569, '00000016', 7750182006088, 1, 2.5),
(570, '00000016', 7750151003902, 1, 8.8),
(571, '00000016', 7750885012928, 1, 0.8),
(572, '00000016', 7750106002608, 1, 0.8),
(573, '00000017', 7751271027656, 1, 5),
(574, '00000018', 7750182002363, 1, 1.8),
(575, '00000019', 7754725000281, 4, 14),
(576, '00000019', 7750182002363, 4, 7.2),
(577, '00000020', 7759222002097, 1, 9.5),
(578, '00000020', 7755139002809, 1, 20),
(579, '00000021', 10001, 4, 9.2),
(580, '00000022', 10002, 0.25, 1.25),
(581, '00000014', 7755139002809, 3, 69),
(582, '00000015', 7754725000281, 5, 17.5),
(583, '00000016', 7751271021975, 1, 3.3),
(584, '00000016', 7750182006088, 1, 2.5),
(585, '00000016', 7750151003902, 1, 8.8),
(586, '00000016', 7750885012928, 1, 0.8),
(587, '00000016', 7750106002608, 1, 0.8),
(588, '00000017', 7751271027656, 1, 5),
(589, '00000018', 7750182002363, 1, 1.8),
(590, '00000019', 7754725000281, 4, 14),
(591, '00000019', 7750182002363, 4, 7.2),
(592, '00000020', 7759222002097, 1, 9.5),
(593, '00000020', 7755139002809, 1, 20),
(594, '00000021', 10001, 4, 9.2),
(595, '00000022', 10002, 0.25, 1.25),
(596, '00000014', 7755139002809, 3, 69),
(597, '00000015', 7754725000281, 5, 17.5),
(598, '00000016', 7751271021975, 1, 3.3),
(599, '00000016', 7750182006088, 1, 2.5),
(600, '00000016', 7750151003902, 1, 8.8),
(601, '00000016', 7750885012928, 1, 0.8),
(602, '00000016', 7750106002608, 1, 0.8),
(603, '00000017', 7751271027656, 1, 5),
(604, '00000018', 7750182002363, 1, 1.8),
(605, '00000019', 7754725000281, 4, 14),
(606, '00000019', 7750182002363, 4, 7.2),
(607, '00000020', 7759222002097, 1, 9.5),
(608, '00000020', 7755139002809, 1, 20),
(609, '00000021', 10001, 4, 9.2),
(610, '00000022', 10002, 0.25, 1.25),
(611, '00000014', 7755139002809, 3, 69),
(612, '00000015', 7754725000281, 5, 17.5),
(613, '00000016', 7751271021975, 1, 3.3),
(614, '00000016', 7750182006088, 1, 2.5),
(615, '00000016', 7750151003902, 1, 8.8),
(616, '00000016', 7750885012928, 1, 0.8),
(617, '00000016', 7750106002608, 1, 0.8),
(618, '00000017', 7751271027656, 1, 5),
(619, '00000018', 7750182002363, 1, 1.8),
(620, '00000019', 7754725000281, 4, 14),
(621, '00000019', 7750182002363, 4, 7.2),
(622, '00000020', 7759222002097, 1, 9.5),
(623, '00000020', 7755139002809, 1, 20),
(624, '00000021', 10001, 4, 9.2),
(625, '00000022', 10002, 0.25, 1.25),
(626, '00000014', 7755139002809, 3, 69),
(627, '00000015', 7754725000281, 5, 17.5),
(628, '00000016', 7751271021975, 1, 3.3),
(629, '00000016', 7750182006088, 1, 2.5),
(630, '00000016', 7750151003902, 1, 8.8),
(631, '00000016', 7750885012928, 1, 0.8),
(632, '00000016', 7750106002608, 1, 0.8),
(633, '00000017', 7751271027656, 1, 5),
(634, '00000018', 7750182002363, 1, 1.8),
(635, '00000019', 7754725000281, 4, 14),
(636, '00000019', 7750182002363, 4, 7.2),
(637, '00000020', 7759222002097, 1, 9.5),
(638, '00000020', 7755139002809, 1, 20),
(639, '00000021', 10001, 4, 9.2),
(640, '00000022', 10002, 0.25, 1.25),
(641, '00000023', 7750182002363, 1, 1.8),
(642, '00000024', 10001, 1, 2.3),
(643, '00000024', 7501006559019, 1, 3.5),
(644, '00000024', 7755139002809, 3, 60),
(645, '00000025', 7750670011839, 1, 1.2),
(646, '00000026', 7751271021999, 1, 5),
(647, '00000026', 7622300279783, 1, 0.5),
(648, '00000026', 7750670011839, 1, 1.2),
(649, '00000027', 7750670011839, 1, 1.2),
(650, '00000028', 7750182220378, 1, 1.8),
(651, '00000028', 7622300116522, 1, 1),
(652, '00000028', 7750243053037, 7, 4.2),
(653, '00000029', 7755139002809, 61, 1220),
(654, '00000030', 7755139002809, 1, 25),
(655, '00000031', 7750243053037, 1, 0.6),
(656, '00000001', 7622300279783, 1, 0.5),
(657, '00000033', 7622300513917, 1, 0.6),
(658, '00000033', 7622300279783, 1, 0.5),
(659, '00000034', 7755139002809, 1, 25),
(660, '00000035', 7751271021999, 1, 5),
(661, '00000036', 7755139002809, 1, 25),
(662, '00000037', 7751271021999, 1, 5),
(663, '00000038', 7751271021999, 1, 5),
(664, '00000038', 7755139002809, 1, 25),
(665, '00000038', 7590011205158, 1, 0.8),
(666, '00000039', 7755139002809, 1, 25),
(667, '00000040', 7751271021999, 1, 5),
(668, '00000041', 7622300279783, 1, 0.5),
(669, '00000042', 7451071013585, 1, 195000),
(670, '00000043', 7151251013481, 10, 1000);

--
-- Índices para tablas volcadas
--

--
-- Indices de la tabla `categorias`
--
ALTER TABLE `categorias`
  ADD PRIMARY KEY (`id_categoria`);

--
-- Indices de la tabla `empresa`
--
ALTER TABLE `empresa`
  ADD PRIMARY KEY (`id_empresa`);

--
-- Indices de la tabla `modulos`
--
ALTER TABLE `modulos`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `perfiles`
--
ALTER TABLE `perfiles`
  ADD PRIMARY KEY (`id_perfil`);

--
-- Indices de la tabla `perfil_modulo`
--
ALTER TABLE `perfil_modulo`
  ADD PRIMARY KEY (`idperfil_modulo`),
  ADD KEY `id_perfil` (`id_perfil`),
  ADD KEY `id_modulo` (`id_modulo`);

--
-- Indices de la tabla `productos`
--
ALTER TABLE `productos`
  ADD PRIMARY KEY (`id`,`codigo_producto`);

--
-- Indices de la tabla `usuarios`
--
ALTER TABLE `usuarios`
  ADD PRIMARY KEY (`id_usuario`),
  ADD KEY `id_perfil_usuario` (`id_perfil_usuario`);

--
-- Indices de la tabla `venta_cabecera`
--
ALTER TABLE `venta_cabecera`
  ADD PRIMARY KEY (`id_boleta`);

--
-- Indices de la tabla `venta_detalle`
--
ALTER TABLE `venta_detalle`
  ADD PRIMARY KEY (`id`);

--
-- AUTO_INCREMENT de las tablas volcadas
--

--
-- AUTO_INCREMENT de la tabla `categorias`
--
ALTER TABLE `categorias`
  MODIFY `id_categoria` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=26;

--
-- AUTO_INCREMENT de la tabla `empresa`
--
ALTER TABLE `empresa`
  MODIFY `id_empresa` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT de la tabla `modulos`
--
ALTER TABLE `modulos`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=15;

--
-- AUTO_INCREMENT de la tabla `perfiles`
--
ALTER TABLE `perfiles`
  MODIFY `id_perfil` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT de la tabla `perfil_modulo`
--
ALTER TABLE `perfil_modulo`
  MODIFY `idperfil_modulo` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=25;

--
-- AUTO_INCREMENT de la tabla `productos`
--
ALTER TABLE `productos`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=108;

--
-- AUTO_INCREMENT de la tabla `usuarios`
--
ALTER TABLE `usuarios`
  MODIFY `id_usuario` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT de la tabla `venta_cabecera`
--
ALTER TABLE `venta_cabecera`
  MODIFY `id_boleta` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=76;

--
-- AUTO_INCREMENT de la tabla `venta_detalle`
--
ALTER TABLE `venta_detalle`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=671;

--
-- Restricciones para tablas volcadas
--

--
-- Filtros para la tabla `perfil_modulo`
--
ALTER TABLE `perfil_modulo`
  ADD CONSTRAINT `id_modulo` FOREIGN KEY (`id_modulo`) REFERENCES `modulos` (`id`),
  ADD CONSTRAINT `id_perfil` FOREIGN KEY (`id_perfil`) REFERENCES `perfiles` (`id_perfil`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Filtros para la tabla `usuarios`
--
ALTER TABLE `usuarios`
  ADD CONSTRAINT `usuarios_ibfk_1` FOREIGN KEY (`id_perfil_usuario`) REFERENCES `perfiles` (`id_perfil`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
