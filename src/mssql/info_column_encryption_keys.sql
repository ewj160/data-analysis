/*
# Column Encyption Keys
*/

set nocount on;

select cek.Name as [CEK Name]
, cek.create_date as [Created On]
, cek.modify_date as [Modified On]
from sys.column_encryption_keys cek
order by [CEK Name];

if exists ( select 1 from sys.column_encryption_keys) begin
	-- fields used by CEK
	select cek.name as [CEK Name]
	, schemas.name as [Schema Name]
	, tables.name as [Table Name]
	, columns.name as [Column Name]
	from sys.all_objects tables
		inner join sys.schemas on (tables.schema_id = schemas.schema_id)
		inner join sys.all_columns columns on (tables.object_id = columns.object_id)
		inner join sys.column_encryption_keys cek on (columns.column_encryption_key_id = cek.column_encryption_key_id)
	order by [CEK Name], [Schema Name], [Table Name], columns.name;
end;

/*
# Column Master Keys
*/

set nocount on;

select cmk.Name as [CMK Name]
, cmk.create_date as [Created On]
, cmk.modify_date as [Modified On]
, cmk.key_store_provider_name as [Key Store Provider Name]
, cmk.key_path as [Key Path]
, cmk.allow_enclave_computations as [Allow Enclave Computations]
, cmk.signature as [Signature]
from sys.column_master_keys cmk
order by [CMK Name];

if exists (select 1 from sys.column_master_keys) begin
	select cmk.name as [CMK Name]
	, cek.name as [CEK Name]
	, cekv.encryption_algorithm_name as [Encryption Algorithm Name]
	, cekv.encrypted_value as [Encrypted Value]
	from sys.column_encryption_key_values cekv
		inner join sys.column_master_keys cmk on (cekv.column_master_key_id = cmk.column_master_key_id)
		inner join sys.column_encryption_keys cek on (cekv.column_encryption_key_id = cek.column_encryption_key_id)
	order by [CMK Name], [CEK Name];
end;