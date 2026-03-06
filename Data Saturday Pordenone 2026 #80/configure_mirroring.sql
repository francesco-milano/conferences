-- 01. check if a MI exists (either on master or target database)
select * from sys.dm_server_managed_identities;



-- 02. create a login on the master database
--use master
--go
/* SQL Auth		*/  
-- create login [fabric_login] with password = '<strong password>';
/* Entra ID		*/  
-- create login [bob@contoso.com] from external provider;
/* SPN			*/  
-- create login [Service Principal Name] from external provider;
/* WKS Identity */	
-- create login [Workspace Identity Name] from external provider;



-- 03a. create a mapped/contained user on the target database
--use [sql-demo-fm-datasatpn]
--go
/* Mapped User: just fill the Login Name with the one created in step 01	*/  
--create user [Mirroring Demo] for login [<Login Name>];
/* Contained User */
create user [Mirroring Demo] from external provider;



-- 04. grant proper permissions to the mapped/contained user
grant 
	select, 
	alter any external mirror, 
	view database performance state, 
	view database security state 
to [Mirroring Demo];



-- 05. cleanup
/*
	drop user [Mirroring Demo];		-- on target database
	-- drop login [Mirroring Demo];	-- on master database
*/

