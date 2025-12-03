use [<demo azure sql datatabase>]

-- 01. creating a new table, this should get mirrored shortly
create table dbo.all_tables
(
	object_id int primary key,
	name varchar(255),
	type_desc varchar(max)
)

-- 02. inserting some rows
insert dbo.all_tables
(
	object_id, name, type_desc
)
select
	t.object_id,
	t.name,
	t.type_desc
from
	sys.tables as t


-- 03. adding a new column
alter table dbo.all_tables
	add sort_order int


-- 04. updating the new column
update src
	set sort_order = rn
from
(
	select
		t.sort_order,
		rn = row_number() over(order by t.object_id)
	from
		dbo.all_tables as t
) as src


-- 05. dropping the table
drop table dbo.all_tables



