[
			#"Standard - DataSource Connector" = #"Standard - DataSource Connector",
			#"Standard - WorkspaceId" = #"Standard - WorkspaceId",
			#"Standard - DataflowId" = #"Standard - DataflowId",
			#"Standard - SqlInstance" = #"Standard - SqlInstance",
			#"Standard - SqlDatabase" = #"Standard - SqlDatabase",
			#"Standard - SharePointSiteUrl" = #"Standard - SharePointSiteUrl",
			#"Standard - SharePointFolderPath" = #"Standard - SharePointFolderPath",
			PowerPlatform.Dataflows = PowerPlatform.Dataflows,

        // Funktion um tabellenbasierte Daten von unterschiedlichen Quellen zu laden
	// __DataSource = "Standard", "SideLoad"
	// Connectoren "SQL Server Datenbank", "Power BI Dataflows (Legacy)", "Dataflows", "SharePoint-Ordner"
	GetEntityFromDataSource = (
	__DataSource as text,
	optional __Schema as text,  //                      __SqlSchema     __FileName
	optional __Entity as text // __Entity             __SqlObject     __Entity
	// optional __SqlQuery as nullable text     // lassen wir bis auf Weiteres deaktiviert
	) as table =>
	let
	  _FileName = __Schema,
	  _Entity = __Entity,
	  _Schema = if __Schema is null then "dbo" else __Schema,

		// "SharePoint Ordner"
		Entity_SP_Std =
		if __DataSource
		  = "Standard"
		  and @#"Standard - DataSource Connector" = "SharePoint Ordner"
		  and @#"Standard - SharePointSiteUrl" <> null
		  and @#"Standard - SharePointFolderPath" <> null
		  and _FileName <> null
		then
		  let
			Source = SharePoint.Files(@#"Standard - SharePointSiteUrl", [ApiVersion = 15]),  // << muss via globalem Parameter passieren, sonst ist es i.d. Cloud nicht aktualisierbar (= "dynamic data sources")
			FilteredFile = Table.SelectRows(
			  Source,
			  each Text.Contains([Folder Path], @#"Standard - SharePointFolderPath") and [Name] = _FileName
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
				Text.From(@#"Standard - SharePointFolderPath"),
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
		if Entity_SP_Std <> null then
		  Entity_SP_Std		
		else
		  null
	in
	  Result
]
