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
	  // final result
	  Result =
		if Entity_DF_Std <> null then
		  Entity_DF_Std
		else
		  null
	in
	  Result
]
