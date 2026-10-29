---------------------
-- QUI SONO IN SQLDB
---------------------

-- 01. creating a new schema and table, these should get mirrored shortly
create schema logging;
go
create table logging.table_list
(
	object_id int primary key,
	name varchar(255),
	type_desc varchar(max)
)

-- 02. inserting some rows
insert logging.table_list
(
	object_id, name, type_desc
)
select
	t.object_id,
	t.name,
	t.type_desc
from
	sys.tables as t


-- 03a. adding a new column
alter table logging.table_list
	add sort_order int


-- 03b. updating the new column
update src
	set sort_order = rn
from
(
	select
		t.sort_order,
		rn = row_number() over(order by t.object_id)
	from
		logging.table_list as t
) as src


-- 04. inserting a big bunch of records (500k)
insert SalesLT.SalesOrderDetail
(
	SalesOrderID, 
	OrderQty, 
	ProductID, 
	UnitPrice, 
	UnitPriceDiscount, 
	rowguid, 
	ModifiedDate
)
select
	sod.SalesOrderID, 
	sod.OrderQty, 
	sod.ProductID, 
	sod.UnitPrice, 
	sod.UnitPriceDiscount, 
	rowguid = newid(), 
	ModifiedDate = getdate()
from
	SalesLT.SalesOrderDetail as sod
cross join
	generate_series(1, 1000, 1) as gs



-- 99. cleanup
drop table logging.table_list

delete 
	SalesLT.SalesOrderDetail
where
	ModifiedDate > datefromparts(year(getdate()), 1, 1)
	




