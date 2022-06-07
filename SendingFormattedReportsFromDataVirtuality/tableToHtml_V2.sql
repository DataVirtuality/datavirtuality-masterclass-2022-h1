alter VIRTUAL PROCEDURE x_utils.tableToHtml_v2( 
	IN tableName string NOT NULL Options (Annotation 'Table or view which has to be converted') 
)
RETURNS( 
	html string options (Annotation 'Xml converted from a table or view') 
)  Options (Annotation 'Converts a given table or view to xml')
AS
BEGIN
    Insert Into #__LOCAL__UTILS_tableToXml
    Select datasourceName, tableShortName From (
        call UTILS.formatTableName(
            tableName => tableName,
            checkExists => true
        )
    )x;

    Declare string datasourceName = Select datasourceName From #__LOCAL__UTILS_tableToXml;
    Declare string tableShortName = Select tableShortName From #__LOCAL__UTILS_tableToXml;

	/* hdrs will look like this
	xmlelement( NAME "th", 'salesorderid'),
	xmlelement( NAME "th", 'linenumber'),
	xmlelement( NAME "th", 'productid'),
	xmlelement( NAME "th", 'specialofferid')
	*/
    DECLARE clob hdrs = select string_agg( 'xmlelement( NAME "th", ''' || "Name" || ''')', ',' || UNESCAPE( '\n' ))  from "SYS.Columns" where LCase(schemaName) = LCase(datasourceName)  and lCase(TableName) = lCase(tableShortName);

	/* columns will look like this
	xmlelement( NAME "td", "cli"."salesorderid"),
	xmlelement( NAME "td", "cli"."linenumber"),
	xmlelement( NAME "td", "cli"."productid"),
	xmlelement( NAME "td", "cli"."specialofferid")
	*/
    DECLARE clob columns = select string_agg( 'xmlelement( NAME "td", "cli"."' || "Name" || '")', ',' || UNESCAPE( '\n' ))  from "SYS.Columns" where LCase(schemaName) = LCase(datasourceName)  and lCase(TableName) = lCase(tableShortName);

	declare clob qry = 
	 'select 
	 		xmlelement(NAME "table",
	 			XMLATTRIBUTES(''1'' AS "border", ''0'' as cellspacing, ''4'' as cellpadding),
	 			XMLELEMENT(NAME "thead", 
	 				XMLATTRIBUTES(''#FF7B22'' AS "bgcolor", ''color:#FFFFFF'' AS "style"),
					XMLELEMENT(NAME "tr", ' || hdrs || ')
	 			),
	 			XMLELEMENT(NAME "tbody", 
					XMLAGG (
						XMLELEMENT(NAME "tr", ' || columns || ')
					)
	 			)
			) as body
		from "' || datasourceName || '"."' || tableShortName || '" cli';

	execute IMMEDIATE qry as body xml into #hdr;
		
	select cast(body as string) from #hdr;
	
	-- Use https://codebeautify.org/htmlviewer to test HTML
END;;