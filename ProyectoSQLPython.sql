/*
📊 PROYECTO SQL SERVER + PYTHON: GRÁFICOS INTERACTIVOS 🚀  

Este archivo contiene las consultas SQL utilizadas para extraer y analizar datos de la **Base de Datos Northwind**,  
las cuales serán almacenadas en **Vistas** para facilitar su reutilización y optimización.  

🔹 **Tecnologías utilizadas:**  
- SQL Server (Consultas, Vistas, Optimización)  
- Python + Plotly (Visualización de Datos Interactiva)  

🔹 **Objetivo:**  
Transformar datos en insights accionables mediante consultas SQL estructuradas y visualizaciones interactivas.  

📌 **Consulta cada vista para explorar los diferentes análisis de datos.**  

*/


USE Northwind

/* 1 : Analizar la evolución mensual del total de ventas en cada categoría
       de producto durante los últimos 2 años. */
GO
CREATE OR ALTER VIEW v_TendenciaVentasPorCategoriaProductos
AS
SELECT
FORMAT(O.OrderDate,'yyyy'+'-'+'MM') AS 'Año-Mes',
C.CategoryName AS Categoria,
ROUND(SUM(OD.Quantity*OD.UnitPrice*(1-OD.Discount)),2) AS TotalVentas
FROM Orders O INNER JOIN [Order Details] OD
ON O.OrderID = OD.OrderID
INNER JOIN Products P ON P.ProductID = OD.ProductID
INNER JOIN Categories C ON C.CategoryID = P.CategoryID
WHERE YEAR(O.OrderDate) IN (1997,1998)
GROUP BY FORMAT(O.OrderDate,'yyyy'+'-'+'MM'),C.CategoryName
GO
SELECT * FROM v_TendenciaVentasPorCategoriaProductos

/* 2: Obtener el total de ingresos generados en cada región en el último año. */
GO
CREATE OR ALTER VIEW v_ComparasionIngresosPorRegion
AS
SELECT 
O.ShipRegion AS Region,
ROUND(SUM(OD.Quantity*OD.UnitPrice*(1-OD.Discount)),2) AS TotalVentas
FROM ORDERS O INNER JOIN [Order Details] OD
ON O.OrderID = OD.OrderID AND O.ShipRegion IS NOT NULL
WHERE YEAR(O.OrderDate) IN (SELECT MAX(YEAR(OrderDate)) FROM Orders)
GROUP BY O.ShipRegion
GO
SELECT* FROM v_ComparasionIngresosPorRegion

/* 3: Determinar cuántos pedidos ha realizado cada cliente 
      en el último año y cuáles son los clientes con más pedidos (TOP 5). */
GO
CREATE OR ALTER VIEW v_DistribucionPedidosPorCliente
AS
SELECT TOP 5 WITH TIES
O.CustomerID,
C.CompanyName,
COUNT(O.OrderID) AS CantidadPedidos
FROM Customers C INNER JOIN Orders O
ON C.CustomerID = O.CustomerID
GROUP BY O.CustomerID,C.CompanyName
ORDER BY 3 DESC
GO
SELECT * FROM v_DistribucionPedidosPorCliente

/* 4: Analizar si existe una relación entre el precio unitario de los productos
      y la cantidad total vendida en el último año. */
GO
CREATE OR ALTER VIEW v_ProductoPrecioCantidadVendida
AS
SELECT
P.ProductName,
P.UnitPrice,
SUM(OD.Quantity) AS CantidadTotalVendida
FROM Products P INNER JOIN [Order Details] OD
ON P.ProductID = OD.ProductID
INNER JOIN Orders O ON O.OrderID = OD.OrderID
WHERE YEAR(O.OrderDate) = (SELECT MAX(YEAR(OrderDate)) FROM Orders)
GROUP BY P.ProductName,P.UnitPrice
GO
SELECT * FROM v_ProductoPrecioCantidadVendida

/* 5: Identificar qué meses han tenido mayores ventas en cada categoría de producto. */
GO
CREATE OR ALTER VIEW v_VentasMensualesPorCategoria
AS
SELECT
C.CategoryName AS Categoria,
MONTH(O.OrderDate) AS Mes,
ROUND(SUM(OD.Quantity*OD.UnitPrice*(1-OD.Discount)),2) AS TotalVentas
FROM Products P INNER JOIN [Order Details] OD
ON P.ProductID = OD.ProductID
INNER JOIN Categories C ON C.CategoryID = P.CategoryID
INNER JOIN Orders O ON O.OrderID = OD.OrderID
GROUP BY C.CategoryName, MONTH(O.OrderDate)
GO
SELECT * FROM v_VentasMensualesPorCategoria

/* 6: Determinar los 10 productos más vendidos en términos de cantidad total en el último año. */
GO
CREATE OR ALTER VIEW v_Top10ProductoMasVendidos
AS
SELECT TOP 10 WITH TIES
P.ProductName,
SUM(OD.Quantity) AS CantidadTotalVendida
FROM Products P INNER JOIN [Order Details] OD
ON P.ProductID = OD.ProductID
INNER JOIN Orders O ON O.OrderID = OD.OrderID
WHERE YEAR(O.OrderDate) = (SELECT MAX(YEAR(OrderDate)) FROM Orders)
GROUP BY P.ProductName
ORDER BY 2 DESC
GO
SELECT * FROM v_Top10ProductoMasVendidos

/* 7: Calcular el tiempo promedio (en días) entre la fecha del pedido
      y la fecha de entrega por cada país de destino. */
GO
CREATE OR ALTER VIEW v_PromedioDiasPedido
AS
SELECT
ShipCountry,
AVG(DATEDIFF(DAY,OrderDate,ShippedDate)) AS DiferenciaDiasEntrega
FROM Orders
GROUP BY ShipCountry
GO
SELECT * FROM v_PromedioDiasPedido

/* 8: Analizar qué empleados han generado más ingresos en el último año y comparar su desempeño. */
GO
CREATE OR ALTER VIEW v_VentasPorEmpleado
AS
SELECT
CONCAT_WS(', ',E.LastName,E.FirstName) AS Employee,
ROUND(SUM(OD.Quantity*OD.UnitPrice*(1-OD.Discount)),2) AS TotalVentas
FROM Employees E INNER JOIN Orders O 
ON E.EmployeeID = O.EmployeeID
INNER JOIN [Order Details] OD 
ON O.OrderID = OD.OrderID
WHERE YEAR(O.OrderDate) = (SELECT MAX(YEAR(OrderDate)) FROM Orders)
GROUP BY CONCAT_WS(', ',E.LastName,E.FirstName)
GO
SELECT * FROM v_VentasPorEmpleado

/* 9: Calcular el porcentaje de participación de cada proveedor 
      en la cantidad total de productos vendidos. */
GO
CREATE OR ALTER VIEW v_ParticipacionProveedoresTotalUnidadesVendidas
AS
SELECT
S.CompanyName AS Supplier,
SUM(OD.Quantity) AS CantidadTotalVendida,
ROUND((SUM(OD.Quantity)/CAST((SELECT SUM(Quantity) FROM [Order Details]) AS FLOAT)*100),2) AS '%Participacion'
FROM Suppliers S INNER JOIN Products P
ON S.SupplierID = P.SupplierID
INNER JOIN [Order Details] OD ON P.ProductID = OD.ProductID
GROUP BY S.CompanyName
GO
SELECT * FROM v_ParticipacionProveedoresTotalUnidadesVendidas

/* 10: Evaluar en qué categorías de productos se aplican más descuentos y qué impacto tienen en las ventas.*/

GO
CREATE OR ALTER VIEW v_DescuentosAplicadosPorCategoria
AS
SELECT
C.CategoryName AS Categoria,
ROUND(AVG(OD.UnitPrice*1-OD.Discount),2) AS PromedioDescuentoAplicado,
COUNT(OD.OrderID) AS TotalVentasDescontadas
FROM Categories C INNER JOIN Products P 
ON C.CategoryID = P.CategoryID
INNER JOIN [Order Details] OD ON OD.ProductID = P.ProductID
GROUP BY C.CategoryName
GO
SELECT * FROM v_DescuentosAplicadosPorCategoria


