# Solución de Business Intelligence – Ferretería Multiconstrucciones Río Santa S.A.C.

Curso: Base de Datos Avanzadas y Big Data · NRC 26055 · 2026-2
Docente: Chavez Bardales Victor Isaac

## Integrantes

- Bonifacio Rosales David Gonzalo
- Portugal Goycochea Esperanza Jasmine
- Principe Altamirano Oscar Sebastian
- Mas Checan Segundo Manuel
- Gabriel Tuesta Angel Fabian

## Descripción

Solución básica de BI para la ferretería Multiconstrucciones Río Santa S.A.C. (Huaral). A partir de la base transaccional `Ferreteria` (OLTP) se construye un Data Mart con modelo estrella (`Ferreteria_DataMart`), se carga mediante un proceso ETL en T-SQL y se presenta en un dashboard de Power BI.

Datos del caso: 1,948 productos, 14 categorías, 4,386 clientes, 9 empleados, 5,959 ventas y 18,111 líneas de detalle (octubre 2025 – septiembre 2026), con un importe total de S/ 1,624,689.27.

**Modelo estrella**
- Tabla de hechos: `dm.Fact_Ventas` (grano: una fila por línea de detalle de venta).
- Dimensiones: `dm.Dim_Tiempo`, `dm.Dim_Cliente`, `dm.Dim_Producto`, `dm.Dim_Empleado`, `dm.Dim_Estado_Venta`.

**Arquitectura:** OLTP (SQL Server) → ETL (T-SQL) → Data Mart (SQL Server) → Power BI.

## Estructura del proyecto

```
PROYECTO-FERRETERIA-BI/
├── docs/
│   ├── Informe_Final_Ferreteria_Rio_Santa.docx
│   └── Procedimiento_Detallado_Replicacion.pdf
├── scripts/
│   ├── 01_Script_OLTP_Ferreteria.sql
│   ├── 02_Script_Creacion_OLAP.sql
│   └── 03_Procedimiento_ETL.sql
├── powerbi/
│   └── Dashboard_Ferreteria_BI.pbix
├── capturas/
│   ├── 01_modelo_estrella_olap.png
│   ├── 02_ejecucion_etl_cuadre.png
│   ├── 03_vista_relaciones_powerbi.png
│   ├── 04_dashboard_interactivo.png
│   └── visuales_dashboard/        (capturas individuales de cada gráfico del dashboard)
└── README.md
```

## Requisitos

- SQL Server 2022 o superior (Express sirve) y SQL Server Management Studio (SSMS).
- Power BI Desktop (versión reciente).
- Permisos para crear bases de datos en la instancia de SQL Server.
- Ambas bases (`Ferreteria` y `Ferreteria_DataMart`) deben estar en la misma instancia, porque el ETL lee con nombres de tres partes (`Ferreteria.dbo.Ventas`).

## Orden de ejecución

Ejecutar los scripts en SSMS, en este orden:

1. **`scripts/01_Script_OLTP_Ferreteria.sql`**: crea la base transaccional `Ferreteria` con sus tablas, índices y claves foráneas (solo la estructura). Los datos del caso (5,959 ventas, 18,111 detalles, etc.) se cargan aparte, desde el respaldo o los archivos de datos originales, **antes** de ejecutar el ETL.
2. **`scripts/02_Script_Creacion_OLAP.sql`**: crea la base `Ferreteria_DataMart`, el esquema `dm`, las dimensiones y `Fact_Ventas` con sus claves primarias y foráneas.
3. **`scripts/03_Procedimiento_ETL.sql`**: limpia y carga dimensiones y hechos dentro de una transacción (`TRY/CATCH`). Al terminar debe mostrar: *Proceso ETL ejecutado y confirmado exitosamente.*
4. **`powerbi/Dashboard_Ferreteria_BI.pbix`**: abrir con Power BI Desktop. Si es necesario, en *Transformar datos → Configuración de origen de datos* cambiar el servidor por el de tu equipo y actualizar.

## Verificación

Después del ETL, el Data Mart debe contener:

| Tabla | Filas |
|---|---|
| Dim_Tiempo | 730 |
| Dim_Cliente | 4,386 |
| Dim_Empleado | 9 |
| Dim_Producto | 1,948 |
| Dim_Estado_Venta | 3 |
| Fact_Ventas | 18,111 |

- Diferencia de cuadre entre `SUM(Subtotal)` del origen y `SUM(Total)` de `Fact_Ventas`: **0.00**.
- Ventas por estado: Pagado 5,401 (S/ 1,466,195.89), Pendiente 359 (S/ 104,679.19), Anulado 199 (S/ 53,814.19). Total: S/ 1,624,689.27.

## Notas

- La base de la ferretería no registra costo unitario, por lo que no se calculan utilidad ni margen.
- La carga es completa (*full load*) en cada ejecución; la base OLTP solo se lee, nunca se modifica.
- El script 01 fue generado desde SSMS con nivel de compatibilidad 170 y rutas `MSSQL17.SQLEXPRESS`. En SQL Server 2022 cambiar `COMPATIBILITY_LEVEL` a 160 y ajustar las rutas de los archivos `.mdf`/`.ldf` a las de su instancia.
- Los scripts 02 y 03 están en UTF-8 con BOM para que SSMS lea bien los acentos (por ejemplo la columna `[Año]`).
- `03_Procedimiento_ETL.sql` incluye al final las consultas de verificación (conteos, cuadre 0.00 y ventas por estado).
- La documentación completa está en `docs/`.
