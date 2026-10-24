-- =====================================================================
-- 02_Script_Creacion_OLAP.sql
-- Data Mart 'Ferreteria_DataMart': esquema dm, 5 dimensiones y Fact_Ventas
-- =====================================================================

USE master;
GO

CREATE DATABASE Ferreteria_DataMart;
GO

USE Ferreteria_DataMart;
GO

CREATE SCHEMA dm;
GO

CREATE TABLE dm.Dim_Tiempo (
    Fecha       DATE         NOT NULL PRIMARY KEY,
    [Año]       INT          NOT NULL,
    Trimestre   TINYINT      NOT NULL,
    Mes         TINYINT      NOT NULL,
    Nombre_Mes  VARCHAR(15)  NOT NULL,
    Dia         TINYINT      NOT NULL,
    Nombre_Dia  VARCHAR(15)  NOT NULL
)
GO

CREATE TABLE dm.Dim_Cliente (
    ID_Cliente       INT           NOT NULL PRIMARY KEY,
    Tipo_Documento   VARCHAR(10)   NULL,
    Numero_Documento BIGINT        NULL,
    Nombre           NVARCHAR(300) NULL,
    Direccion        NVARCHAR(500) NULL
)
GO

CREATE TABLE dm.Dim_Empleado (
    ID_Empleado   INT          NOT NULL PRIMARY KEY,
    Nombre        VARCHAR(200) NOT NULL,
    DNI           CHAR(8)      NOT NULL,
    Cargo         VARCHAR(100) NULL,
    Fecha_Ingreso DATE         NULL
)
GO

CREATE TABLE dm.Dim_Producto (
    ID_Producto      INT           NOT NULL PRIMARY KEY,
    Nombre_Producto  NVARCHAR(300) NOT NULL,
    ID_Categoria     INT           NOT NULL,
    Nombre_Categoria NVARCHAR(100) NOT NULL,
    Precio_Lista     DECIMAL(10,2) NULL,
    Stock            INT           NULL
)
GO

CREATE TABLE dm.Dim_Estado_Venta (
    ID_Estado INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    Estado    VARCHAR(20)       NOT NULL UNIQUE
)
GO

CREATE TABLE dm.Fact_Ventas (
    ID_Detalle      INT           NOT NULL PRIMARY KEY,
    ID_Venta        INT           NOT NULL,
    Fecha           DATE          NOT NULL,
    ID_Cliente      INT           NOT NULL,
    ID_Empleado     INT           NULL,
    ID_Estado       INT           NOT NULL,
    ID_Producto     INT           NOT NULL,
    Cantidad        INT           NOT NULL,
    Precio_Unitario DECIMAL(10,2) NOT NULL,
    Subtotal        DECIMAL(10,2) NOT NULL,
    Descuento       DECIMAL(10,2) NOT NULL DEFAULT 0,
    Total           DECIMAL(10,2) NOT NULL,

    CONSTRAINT FK_Fact_Tiempo   FOREIGN KEY (Fecha)       REFERENCES dm.Dim_Tiempo(Fecha),
    CONSTRAINT FK_Fact_Cliente  FOREIGN KEY (ID_Cliente)  REFERENCES dm.Dim_Cliente(ID_Cliente),
    CONSTRAINT FK_Fact_Empleado FOREIGN KEY (ID_Empleado) REFERENCES dm.Dim_Empleado(ID_Empleado),
    CONSTRAINT FK_Fact_Estado   FOREIGN KEY (ID_Estado)   REFERENCES dm.Dim_Estado_Venta(ID_Estado),
    CONSTRAINT FK_Fact_Producto FOREIGN KEY (ID_Producto) REFERENCES dm.Dim_Producto(ID_Producto)
)
GO
