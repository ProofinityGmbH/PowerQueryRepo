[
	// Funktion um tabellenbasierte Daten von unterschiedlichen Quellen zu laden
	// __DataSource = "Standard", "SideLoad"
	// Connectoren "SQL Server Datenbank", "Power BI Dataflows (Legacy)", "Dataflows", "SharePoint-Ordner"
	GetEntityFromDataSource = (
	__DataSource as text,  // "Power BI Dataflow"  "SQL-Server"    "SharePoint-Folder"
	optional __Server as text,  //                      __SqlInstance   !!! nur via globalem Parameter !!!
	optional __DataBase as text,  //                      __SqlDataBase   __SharePointFolderPath
	optional __Schema as text,  //                      __SqlSchema     __FileName
	optional __Entity as text // __Entity             __SqlObject     __Entity
	// optional __SqlQuery as nullable text     // lassen wir bis auf Weiteres deaktiviert
	) as table =>
	let
	  _SharePointFolderPath = __DataBase,
	  _FileName = __Schema,
	  _Entity = __Entity,
	  _Schema = if __Schema is null then "dbo" else __Schema,
	  // Prüfen, ob die jeweils nötigen Parameter vorhanden sind
	  // bzgl WorkspaceId & DataflowId quasi fix angelegt werden. Dazu einfach den Block kopieren und entsprechend anpassen.
	  // 'Microsoft Fabric - Dataflows' = 'Power Platform - Dataflows'
	  Entity_DF_Std =
		if __DataSource
		  = "Standard"
		  and @#"Standard - DataSource Connector" = "Dataflows"
		  and @#"Standard - WorkspaceId" <> null
		  and @#"Standard - DataflowId" <> null
		  and _Entity <> null
		then
		  let
			Connector  = PowerPlatform.Dataflows(null),
			Workspaces = Connector{[Id = "Workspaces"]}[Data],
			Workspace  = Workspaces{[workspaceId = @#"Standard - WorkspaceId"]}[Data],  // << muss beides via globalem Parameter passieren 
			Dataflow   = Workspace{[dataflowId = @#"Standard - DataflowId"]}[Data],  // << sonst wird es im DataLineage nicht verbunden
			Entity     = Dataflow{[entity = _Entity]}[Data]
		  in
			Entity
		else if __DataSource = "Standard" and @#"Standard - DataSource Connector" = "Dataflows" then
		  error [
			Reason = Text.Combine(
			  {
				"Parameter for using 'Standard - DataSource Connector' = '",
				Text.From(@#"Standard - DataSource Connector"),
				"' missing."
			  }
			),
			Message = "Check the detailed Message for current parametrization.",
			Detail = Text.Combine(
			  {
				"@Standard - WorkspaceId:",
				Text.From(@#"Standard - WorkspaceId"),
				", @Standard - DataflowId:",
				Text.From(@#"Standard - DataflowId"),
				", _Entity:",
				Text.From(_Entity)
			  },
			  " "
			)
		  ]
		else
		  null,

		// "SharePoint Ordner"
		Entity_SP_Std =
		if __DataSource
		  = "Standard"
		  and @#"Standard - DataSource Connector" = "SharePoint Ordner"
		  and @#"Standard - SharePointSiteUrl" <> null
		  and _SharePointFolderPath <> null
		  and _FileName <> null
		then
		  let
			Source = SharePoint.Files(@#"Standard - SharePointSiteUrl", [ApiVersion = 15]),  // << muss via globalem Parameter passieren, sonst ist es i.d. Cloud nicht aktualisierbar (= "dynamic data sources")
			FilteredFile = Table.SelectRows(
			  Source,
			  each Text.Contains([Folder Path], _SharePointFolderPath) and [Name] = _FileName
			),
			IsCsv = Text.EndsWith(_FileName, ".csv"),
			IsExcel = Text.EndsWith(_FileName, ".xlsx") or Text.EndsWith(_FileName, ".xls"),
			Entity =
			  if IsCsv then
				let
				  CsvContent = Csv.Document(
					FilteredFile{0}[Content],
					[Delimiter = ",", Encoding = 1252, QuoteStyle = QuoteStyle.None]
				  ),
				  CsvPromotedHeaders = Table.PromoteHeaders(CsvContent, [PromoteAllScalars = true]),
				  CsvRemovedEmpty = Table.SelectRows(
					CsvPromotedHeaders,
					each List.NonNullCount(Record.FieldValues(_)) > 0
				  ),
				  CsvColumns = Table.ColumnNames(CsvRemovedEmpty),
				  Entity = Table.TransformColumnTypes(
					CsvRemovedEmpty,
					List.Transform(CsvColumns, each {_, type text})
				  )
				in
				  Entity
			  else if IsExcel then
				let
				  ExcelWorkbook = Excel.Workbook(FilteredFile{0}[Content], null, true),
				  Entity =
					if _Entity <> null then
					  Table.SelectRows(ExcelWorkbook, each [Kind] = "Table" and [Name] = _Entity){0}[
						Data
					  ]
					else
					  Table.SelectRows(ExcelWorkbook, each [Kind] = "Table"){0}[Data]
				in
				  Entity
			  else
				error [
				  Reason  = "File type not supported",
				  Message = "Only CSV and Excel files are supported.",
				  Detail  = Text.Combine({"_FileName:", _FileName}, " ")
				]
		  in
			Entity
		else if __DataSource
		  = "Standard"
		  and @#"Standard - DataSource Connector" = "SharePoint Ordner"
		then
		  error [
			Reason = Text.Combine(
			  {
				"Parameter for using 'Standard - DataSource Connector' = '",
				Text.From(@#"Standard - DataSource Connector"),
				"' missing."
			  }
			),
			Message = "Check the detailed Message for current parametrization.",
			Detail = Text.Combine(
			  {
				"@Standard - SharePointSiteUrl:",
				Text.From(@#"Standard - SharePointSiteUrl"),
				", _SharePointFolderPath:",
				Text.From(_SharePointFolderPath),
				", _FileName:",
				Text.From(_FileName)
			  },
			  " "
			)
		  ]
		else
		  null,

	  // final result
	  Result =
		if Entity_DF_Std <> null then
		  Entity_DF_Std
		elseif Entity_SP_Std <> null then
		  Entity_SP_Std		
		else
		  null
	in
	  Result
]
