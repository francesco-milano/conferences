-- 01. check if a MI exists (either on master or target database)
select * from sys.dm_server_managed_identities;



-- 02. create a login on the master database
use master
go
/* SQL Auth		*/  
-- create login [fabric_login] with password = '<strong password>';
/* Entra ID		*/  
-- create login [bob@contoso.com] from external provider;
/* SPN			*/  
-- create login [Service Principal Name] from external provider;
/* WKS Identity */	
-- create login [Workspace Identity Name] from external provider;



-- 03. create a mapped user on the target database
use [<demo azure sql datatabase>]
go
/* Just fill the Login Name with the one created in step 01	*/  
-- create user [daa68ce0-8b7e-4d89-8605-1bba07636989] for login [<Login Name>];
create user [Workspace Identity Name] for login [Workspace Identity Name];



-- 04. grant proper permissions to mapped user
/* Just fill the Login Name with the one created in step 01	*/  
-- grant select, alter any external mirror, view database performance state, view database security state to [<Login Name>];
grant 
	select, 
	alter any external mirror, 
	view database performance state, 
	view database security state 
to [Workspace Identity Name];



-- 05. cleanup
/*
	drop user [Workspace Identity Name];		-- on target database
	drop login [Workspace Identity Name];	-- on master database
*/