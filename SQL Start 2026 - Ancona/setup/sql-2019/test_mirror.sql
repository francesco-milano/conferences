use AdventureWorks
go

select count(*) from Production.TransactionHistory;

/*
	Let's generate a bunch of records in the Production.TransactionHistory table
*/
insert Production.TransactionHistory
	([ProductID], [ReferenceOrderID], [ReferenceOrderLineID], [TransactionDate], [TransactionType], [Quantity], [ActualCost], [ModifiedDate])
select top 1
	[ProductID], [ReferenceOrderID], [ReferenceOrderLineID], [TransactionDate], [TransactionType], [Quantity], [ActualCost], [ModifiedDate]
from Production.TransactionHistory
cross join
(
	select top 10 o.object_id from sys.objects as o
) as t

select count(*) from Production.TransactionHistory;



-- reset Production.TransactionHistory table
-- delete from Production.TransactionHistory where TransactionId > 213442
