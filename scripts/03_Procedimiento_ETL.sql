-- =====================================================================
-- 03_Procedimiento_ETL.sql
-- Extraccion, transformacion y carga: Ferreteria (OLTP) -> Ferreteria_DataMart
-- =====================================================================

USE Ferreteria_DataMart;
GO
SET LANGUAGE Spanish;
GO

BEGIN TRY
    BEGIN TRANSACTION;

    -- Limpieza
    DELETE FROM dm.Fact_Ventas;
    DELETE FROM dm.Dim_Cliente;
    DELETE FROM dm.Dim_Producto;
    DELETE FROM dm.Dim_Empleado;
    DELETE FROM dm.Dim_Estado_Venta;
    DELETE FROM dm.Dim_Tiempo;
    DBCC CHECKIDENT ('dm.Dim_Estado_Venta', RESEED, 0);

    -- DIMENSION TIEMPO
    DECLARE @ini DATE, @fin DATE;
    SELECT @ini = DATEFROMPARTS(YEAR(MIN(Fecha_Venta)), 1, 1),
           @fin = DATEFROMPARTS(YEAR(MAX(Fecha_Venta)), 12, 31)
    FROM Ferreteria.dbo.Ventas;

    WHILE @ini <= @fin
    BEGIN
        INSERT INTO dm.Dim_Tiempo (Fecha, [Año], Trimestre, Mes, Nombre_Mes, Dia, Nombre_Dia)
        VALUES (@ini, YEAR(@ini), DATEPART(QUARTER, @ini), MONTH(@ini),
                DATENAME(MONTH, @ini), DAY(@ini), DATENAME(WEEKDAY, @ini));
        SET @ini = DATEADD(DAY, 1, @ini);
    END;

    -- DIMENSION ESTADO DE VENTA
    INSERT INTO dm.Dim_Estado_Venta (Estado)
    SELECT DISTINCT LTRIM(RTRIM(Estado)) FROM Ferreteria.dbo.Ventas;

    -- DIMENSION CLIENTE
    INSERT INTO dm.Dim_Cliente (ID_Cliente, Tipo_Documento, Numero_Documento, Nombre, Direccion)
    SELECT ID_Cliente, Tipo_Documento, Numero_Documento,
           LTRIM(RTRIM(Nombre)),
           ISNULL(NULLIF(LTRIM(RTRIM(Direccion)), ''), 'Sin direccion')
    FROM Ferreteria.dbo.Clientes;

    -- DIMENSION EMPLEADO
    INSERT INTO dm.Dim_Empleado (ID_Empleado, Nombre, DNI, Cargo, Fecha_Ingreso)
    SELECT ID_Empleado, LTRIM(RTRIM(Nombre)), DNI, LTRIM(RTRIM(Cargo)), Fecha_Ingreso
    FROM Ferreteria.dbo.Empleados;

    -- DIMENSION PRODUCTO (producto + categoria)
    INSERT INTO dm.Dim_Producto
        (ID_Producto, Nombre_Producto, ID_Categoria, Nombre_Categoria, Precio_Lista, Stock)
    SELECT P.ID_Producto, LTRIM(RTRIM(P.Nombre_Producto)), P.ID_Categoria,
           LTRIM(RTRIM(C.Nombre_Categoria)), P.Precio_Unitario, P.Stock
    FROM Ferreteria.dbo.Productos P
    INNER JOIN Ferreteria.dbo.Categorias C ON C.ID_Categoria = P.ID_Categoria;

    -- TABLA DE HECHOS (una fila por linea de detalle)
    INSERT INTO dm.Fact_Ventas
        (ID_Detalle, ID_Venta, Fecha, ID_Cliente, ID_Empleado, ID_Estado,
         ID_Producto, Cantidad, Precio_Unitario, Subtotal, Descuento, Total)
    SELECT D.ID_Detalle, V.ID_Venta, CAST(V.Fecha_Venta AS DATE), V.ID_Cliente,
           V.ID_Empleado, E.ID_Estado, D.ID_Producto, D.Cantidad,
           D.Precio_Unitario, D.Subtotal, 0, D.Subtotal
    FROM Ferreteria.dbo.Ventas V
    INNER JOIN Ferreteria.dbo.Detalle_Venta D ON D.ID_Venta = V.ID_Venta
    INNER JOIN dm.Dim_Estado_Venta E ON E.Estado = LTRIM(RTRIM(V.Estado))
    WHERE NOT EXISTS (SELECT 1 FROM dm.Fact_Ventas F WHERE F.ID_Detalle = D.ID_Detalle);

    COMMIT TRANSACTION;
    PRINT 'Proceso ETL ejecutado y confirmado exitosamente.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    PRINT 'Error en el ETL: ' + ERROR_MESSAGE();
END CATCH;
GO

-- =====================================================================
-- VERIFICACION DE LA CARGA Y CUADRE (ejecutar despues del ETL)
-- =====================================================================
USE Ferreteria_DataMart;
GO

SELECT 'Dim_Tiempo' AS Tabla, COUNT(*) AS Filas FROM dm.Dim_Tiempo
UNION ALL SELECT 'Dim_Cliente',      COUNT(*) FROM dm.Dim_Cliente
UNION ALL SELECT 'Dim_Empleado',     COUNT(*) FROM dm.Dim_Empleado
UNION ALL SELECT 'Dim_Producto',     COUNT(*) FROM dm.Dim_Producto
UNION ALL SELECT 'Dim_Estado_Venta', COUNT(*) FROM dm.Dim_Estado_Venta
UNION ALL SELECT 'Fact_Ventas',      COUNT(*) FROM dm.Fact_Ventas;

SELECT (SELECT SUM(Subtotal) FROM Ferreteria.dbo.Detalle_Venta)
     - (SELECT SUM(Total)    FROM dm.Fact_Ventas) AS Diferencia;
GO

-- =====================================================================
-- VERIFICACION DE KPI: ventas por estado
-- =====================================================================
SELECT E.Estado,
       COUNT(DISTINCT F.ID_Venta) AS Ventas,
       SUM(F.Cantidad)            AS Unidades,
       SUM(F.Subtotal)            AS Ventas_Totales
FROM dm.Fact_Ventas F
INNER JOIN dm.Dim_Estado_Venta E ON E.ID_Estado = F.ID_Estado
GROUP BY E.Estado;
GO
