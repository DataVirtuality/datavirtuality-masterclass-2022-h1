/*
-- This example uses a FILE data source called "csv_local_sales".
-- The file data source was created with the wizard. The definition is included here for completeness.
call SYSADMIN.createConnection(name => 'csv_local_sales', jbossCliTemplateName => 'ufile', connectionOrResourceAdapterProperties => 'ParentDirectory=/mnt/hgfs/_DV_bin_linux/data_files/csv_sales,decompressCompressedFiles=false', encryptedProperties => '');;
call SYSADMIN.createDatasource(name => 'csv_local_sales', translator => 'ufile', modelProperties => 'importer.useFullSchemaName=false', translatorProperties => '', encryptedModelProperties => '', encryptedTranslatorProperties => '');;
*/

begin

-- Use HTML formatting to add line breaks.
declare string email_body = '
Welcome to the Master Class,
<p>
Please find the CSV and JSON files attached.
<p>
Warm regards,<br>
Data Virtuality
';

-- Create two CSV files: example1.csv, example2.csv
call "UTILS.csvExport"(
    "sourceSchema" => 'views', /* Mandatory: The source schema in datavirtuality. */
    "sourceTable" => 'SampleOfData', /* Mandatory: The source table in datavirtuality. */
    "targetSchema" => 'csv_local_sales', /* Mandatory: A file datasource in datavirtuality. The file will be stored in the directory assigned to the file datasource. */
    "targetFile" => 'example1.csv', /* Optional: The name of the file to store the exported data. If a file with same name exists, it will be overwritten. If omitted, name will be created: sourceSchema_sourceTable.csv. */
    "header" => true, /* Optional: If HEADER is specified, the result contains the header row as the first line - the header line will be present even if there are no rows in a group. */
    "encoding" => 'UTF-8' /* Optional: Encoding for the created file. Default is the systems default encoding. */
) without return;

call "UTILS.csvExport"(
    "sourceSchema" => 'views', /* Mandatory: The source schema in datavirtuality. */
    "sourceTable" => 'SampleOfData', /* Mandatory: The source table in datavirtuality. */
    "targetSchema" => 'csv_local_sales', /* Mandatory: A file datasource in datavirtuality. The file will be stored in the directory assigned to the file datasource. */
    "targetFile" => 'example2.csv', /* Optional: The name of the file to store the exported data. If a file with same name exists, it will be overwritten. If omitted, name will be created: sourceSchema_sourceTable.csv. */
    "header" => true, /* Optional: If HEADER is specified, the result contains the header row as the first line - the header line will be present even if there are no rows in a group. */
    "encoding" => 'UTF-8' /* Optional: Encoding for the created file. Default is the systems default encoding. */
) without return;

-- Create two CSV files: example3.json, example4.json
declare clob json = (select a.json from (call "UTILS.tableToJson"("tableName" => 'views.SampleOfData')) as a);
call "csv_local_sales.saveFile"("filePath" => 'example3.json', "file" => json) without return;

json = (select a.json from (call "UTILS.tableToJson"("tableName" => 'views.SampleOfData')) as a);
call "csv_local_sales.saveFile"("filePath" => 'example4.json', "file" => json) without return;

-- Create the subject line for the email.
declare string subject = 'View your new report ' || FORMATTIMESTAMP(now(), 'MM.dd.yyyy ''at'' hh:mm:ss');

-- Create arrays of the file data, file names, and mime types.
SELECT 
	array_agg(x.file) as array_files, 
	array_agg(x.filePath) as array_file_names,
	array_agg(x.mime_types) as array_mime_types		
into #tmp
FROM 
	(
		select file, filePath, 'text/plain' as mime_types from (CALL "csv_local_sales.getFiles"("pathAndPattern" => '*.csv')) csv
		union all
		select file, filePath, 'application/json' as mime_types from (CALL "csv_local_sales.getFiles"("pathAndPattern" => '*.json')) json
	) x;

-- Assign the data inside the table to variables.
declare OBJECT array_files = select array_files from #tmp;
declare OBJECT array_file_names = select array_file_names from #tmp;
declare OBJECT array_mime_types = select array_mime_types from #tmp;

-- Send the files
call "UTILS.sendMail"(
    "Recipients" => 'datavirtuality@yopmail.com',
    "Subject" => subject,
    "Body" => cast(email_body as clob),
	"Attachments" => array_files,
    "AttachmentNames" => array_file_names,
	"AttachmentMimeTypes" => array_mime_types
) without return;

-- This isn't necessary, but included to see the visualization of the data.
select 
	subject, 
	array_files, 
	array_file_names, 
	cast(array_get(array_file_names, 1) as string) as first_file_name, 
	array_mime_types,
	cast(array_get(array_mime_types, 1) as string) as first_mime_type;

end;;



