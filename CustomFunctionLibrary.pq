[
	// Funktion um tabellenbasierte Daten von unterschiedlichen Quellen zu laden
	// __DataSource = "Standard", "SideLoad"
	// Connectoren "SQL Server Datenbank", "Power BI Dataflows (Legacy)", "Dataflows", "SharePoint-Ordner"
	GetEntityFromDataSource = () as table =>
	let
		Standard_DataSource_Connector = "SharePoint Ordner",
		Standard_SharePointSiteUrl = "https://proofinity.sharepoint.com/sites/PowerBIProjekttools",
		Standard_SharePointFolderPath = "Freigegebene Dokumente/Power Plattform Solutions/001_Proofinity/Contoso Data Generator/2.0.0/csv-10k",
		__DataSource = "Standard",
		__Schema = "store.csv",
		__Entity = "",
	  _FileName = __Schema,
	  _Entity = __Entity,
	  _Schema = if __Schema is null then "dbo" else __Schema,

		// "SharePoint Ordner"
		Entity_SP_Std =
		if __DataSource
		  = "Standard"
		  and Standard_DataSource_Connector = "SharePoint Ordner"
		  and Standard_SharePointSiteUrl <> null
		  and Standard_SharePointFolderPath <> null
		  and _FileName <> null
		then
		  let
			Source = SharePoint.Files("https://proofinity.sharepoint.com/sites/PowerBIProjekttools", [ApiVersion = 15]),  // << muss via globalem Parameter passieren, sonst ist es i.d. Cloud nicht aktualisierbar (= "dynamic data sources")
			FilteredFile = Table.SelectRows(
			  Source,
			  each Text.Contains([Folder Path], "Freigegebene Dokumente/Power Plattform Solutions/001_Proofinity/Contoso Data Generator/2.0.0/csv-10k") and [Name] = _FileName
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
		  and Standard_DataSource_Connector = "SharePoint Ordner"
		then
		  error [
			Reason = Text.Combine(
			  {
				"Parameter for using 'Standard - DataSource Connector' = '",
				Text.From(Standard_DataSource_Connector),
				"' missing."
			  }
			),
			Message = "Check the detailed Message for current parametrization.",
			Detail = Text.Combine(
			  {
				"Standard_SharePointSiteUrl:",
				Text.From(Standard_SharePointSiteUrl),
				", SharePointFolderPath:",
				Text.From(Standard_SharePointFolderPath),
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
