// Anleitung zur Aktualisierung der Entität "CustomFunctionLibrary":
// ... welche Version hab ich aktuell ...

// Version 20250106: Wir haben Bugs in der Funktion GetEntityFromDataSource für den SharePoint gefixt.

// 20241119 / Torsten:
//   (Letzte) Idee / Versuch ... siehe unten ... hatte dann aber noch immer die Meldung "dynamic data sources"
//   War dann aber plötzlich nach dem Publish "getrennt" worden ... ich weiss aber nicht warum
//   Vorherige Version wurde zuvor einfach nur reduziert (kommentiert) worden.
//   Wollte im weiteren Verlauf zu guter letzt dann nochmal testen, die Anzahl nach String überprüfter Parameter
//   auf nur einen zu reduzieren. Also dann nurnoch 
//         __DataSource = "DF_Std"  // << hier ist dann die Info bzgl "Data Source Connector" enthalten
//   folgende Zeile und damit Parameter sollte dann gar nicht nötig sein ... auch als globaler Param nicht mehr
//          @#"Standard - DataSource Connector" = "Dataflows"
//   Alternativ dann vielleicht doch nochmal von der Version 4 ausgehen und eine andere Lösung ausdenken.
let

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
      // 'Power Platform - Power BI Dataflows (Legacy)'
      Entity_DF_Legacy_Std =
        if __DataSource
          = "Standard"
          and @#"Standard - DataSource Connector" = "Power BI Dataflows (Legacy)"
          and @#"Standard - WorkspaceId" <> null
          and @#"Standard - DataflowId" <> null
          and _Entity <> null
        then
          let
            Connector = PowerBI.Dataflows(null),
            Workspace = Connector{[workspaceId = @#"Standard - WorkspaceId"]}[Data],  // << muss beides via globalem Parameter passieren 
            Dataflow  = Workspace{[dataflowId = @#"Standard - DataflowId"]}[Data],  // << sonst wird es im DataLineage nicht verbunden
            Entity    = Dataflow{[entity = _Entity]}[Data]
          in
            Entity
        else if __DataSource
          = "Standard"
          and @#"Standard - DataSource Connector" = "Power BI Dataflows (Legacy)"
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
      // "SQL Server Datenbank"
      Entity_Sql_Std =
        if __DataSource
          = "Standard"
          and @#"Standard - DataSource Connector" = "SQL Server Datenbank"
          and @#"Standard - SqlInstance" <> null
          and @#"Standard - SqlDatabase" <> null
          and _Schema <> null
          and _Entity <> null
        then
          let
            Database = Sql.Database(@#"Standard - SqlInstance", @#"Standard - SqlDatabase"),
            Entity   = Database{[Schema = _Schema, Item = _Entity]}[Data]
          in
            Entity
        else if __DataSource
          = "Standard"
          and @#"Standard - DataSource Connector" = "SQL Server Datenbank"
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
                "@Standard - SqlInstance:",
                Text.From(@#"Standard - SqlInstance"),
                ", @Standard - SqlDatabase:",
                Text.From(@#"Standard - SqlDatabase"),
                ", _Schema:",
                Text.From(_Schema),
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
      // SideLoad komplett identisch zu Standard
      // 'Microsoft Fabric - Dataflows' = 'Power Platform - Dataflows'
      Entity_DF_SL =
        if __DataSource
          = "SideLoad"
          and @#"SideLoad - DataSource Connector" = "Dataflows"
          and @#"SideLoad - WorkspaceId" <> null
          and @#"SideLoad - DataflowId" <> null
          and _Entity <> null
        then
          let
            Connector  = PowerPlatform.Dataflows(null),
            Workspaces = Connector{[Id = "Workspaces"]}[Data],
            Workspace  = Workspaces{[workspaceId = @#"SideLoad - WorkspaceId"]}[Data],  // << muss beides via globalem Parameter passieren 
            Dataflow   = Workspace{[dataflowId = @#"SideLoad - DataflowId"]}[Data],  // << sonst wird es im DataLineage nicht verbunden
            Entity     = Dataflow{[entity = _Entity]}[Data]
          in
            Entity
        else if __DataSource = "SideLoad" and @#"SideLoad - DataSource Connector" = "Dataflows" then
          error [
            Reason = Text.Combine(
              {
                "Parameter for using 'SideLoad - DataSource Connector' = '",
                Text.From(@#"SideLoad - DataSource Connector"),
                "' missing."
              }
            ),
            Message = "Check the detailed Message for current parametrization.",
            Detail = Text.Combine(
              {
                "@SideLoad - WorkspaceId:",
                Text.From(@#"SideLoad - WorkspaceId"),
                ", @SideLoad - DataflowId:",
                Text.From(@#"SideLoad - DataflowId"),
                ", _Entity:",
                Text.From(_Entity)
              },
              " "
            )
          ]
        else
          null,
      // 'Power Platform - Power BI Dataflows (Legacy)'
      Entity_DF_Legacy_SL =
        if __DataSource
          = "SideLoad"
          and @#"SideLoad - DataSource Connector" = "Power BI Dataflows (Legacy)"
          and @#"SideLoad - WorkspaceId" <> null
          and @#"SideLoad - DataflowId" <> null
          and _Entity <> null
        then
          let
            Connector = PowerBI.Dataflows(null),
            Workspace = Connector{[workspaceId = @#"SideLoad - WorkspaceId"]}[Data],  // << muss beides via globalem Parameter passieren 
            Dataflow  = Workspace{[dataflowId = @#"SideLoad - DataflowId"]}[Data],  // << sonst wird es im DataLineage nicht verbunden
            Entity    = Dataflow{[entity = _Entity]}[Data]
          in
            Entity
        else if __DataSource
          = "SideLoad"
          and @#"SideLoad - DataSource Connector" = "Power BI Dataflows (Legacy)"
        then
          error [
            Reason = Text.Combine(
              {
                "Parameter for using 'SideLoad - DataSource Connector' = '",
                Text.From(@#"SideLoad - DataSource Connector"),
                "' missing."
              }
            ),
            Message = "Check the detailed Message for current parametrization.",
            Detail = Text.Combine(
              {
                "@SideLoad - WorkspaceId:",
                Text.From(@#"SideLoad - WorkspaceId"),
                ", @SideLoad - DataflowId:",
                Text.From(@#"SideLoad - DataflowId"),
                ", _Entity:",
                Text.From(_Entity)
              },
              " "
            )
          ]
        else
          null,
      // "SQL Server Datenbank"
      Entity_Sql_SL =
        if __DataSource
          = "SideLoad"
          and @#"SideLoad - DataSource Connector" = "SQL Server Datenbank"
          and @#"SideLoad - SqlInstance" <> null
          and @#"SideLoad - SqlDatabase" <> null
          and _Schema <> null
          and _Entity <> null
        then
          let
            Database = Sql.Database(@#"SideLoad - SqlInstance", @#"SideLoad - SqlDatabase"),
            Entity   = Database{[Schema = _Schema, Item = _Entity]}[Data]
          in
            Entity
        else if __DataSource
          = "SideLoad"
          and @#"SideLoad - DataSource Connector" = "SQL Server Datenbank"
        then
          error [
            Reason = Text.Combine(
              {
                "Parameter for using 'SideLoad - DataSource Connector' = '",
                Text.From(@#"SideLoad - DataSource Connector"),
                "' missing."
              }
            ),
            Message = "Check the detailed Message for current parametrization.",
            Detail = Text.Combine(
              {
                "@SideLoad - SqlInstance:",
                Text.From(@#"SideLoad - SqlInstance"),
                ", @SideLoad - SqlDatabase:",
                Text.From(@#"SideLoad - SqlDatabase"),
                ", _Schema:",
                Text.From(_Schema),
                ", _Entity:",
                Text.From(_Entity)
              },
              " "
            )
          ]
        else
          null,
      // "SharePoint Ordner"
      Entity_SP_SL =
        if __DataSource
          = "SideLoad"
          and @#"SideLoad - DataSource Connector" = "SharePoint Ordner"
          and @#"SideLoad - SharePointSiteUrl" <> null
          and _SharePointFolderPath <> null
          and _FileName <> null
        then
          let
            Source = SharePoint.Files(@#"SideLoad - SharePointSiteUrl", [ApiVersion = 15]),  // << muss via globalem Parameter passieren, sonst ist es i.d. Cloud nicht aktualisierbar (= "dynamic data sources")
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
          = "SideLoad"
          and @#"SideLoad - DataSource Connector" = "SharePoint Ordner"
        then
          error [
            Reason = Text.Combine(
              {
                "Parameter for using 'SideLoad - DataSource Connector' = '",
                Text.From(@#"SideLoad - DataSource Connector"),
                "' missing."
              }
            ),
            Message = "Check the detailed Message for current parametrization.",
            Detail = Text.Combine(
              {
                "@SideLoad - SharePointSiteUrl:",
                Text.From(@#"SideLoad - SharePointSiteUrl"),
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
        else if Entity_DF_Legacy_Std <> null then
          Entity_DF_Legacy_Std
        else if Entity_Sql_Std <> null then
          Entity_Sql_Std
        else if Entity_SP_Std <> null then
          Entity_SP_Std
        else if Entity_DF_SL <> null then
          Entity_DF_SL
        else if Entity_DF_Legacy_SL <> null then
          Entity_DF_Legacy_SL
        else if Entity_Sql_SL <> null then
          Entity_Sql_SL
        else if Entity_SP_SL <> null then
          Entity_SP_SL
        else
          null
    in
      Result,
  // Funktion, um (mehrere) HTML Dateien von SharePoint (=OneDrive) zu laden
  // und gleichzeitig zu splitten, damit sie in einem PBI Visual verwendet
  // werden können
  GetMediaFilesFromStandardSharePointFolder = 
  (
    optional __SharePointFolderPath as text
) as table =>
    let
        // Liste aller Dateien im angegebenen Ordner
        Source = SharePoint.Files(@#"Standard - SharePointSiteUrl", [ApiVersion = 15]),
        
        // Ordnerpfad festlegen
        _SharePointFolderPath =
            if __SharePointFolderPath = null then
                @#"Standard - SharePointFolderPath"
            else
                __SharePointFolderPath,

        // Filterung der unterstützten Dateiformate
        FilteredFiles = Table.SelectRows(
            Source,
            each Text.Contains([Folder Path], _SharePointFolderPath)
            and (
                Text.EndsWith([Extension], "html")
                or Text.EndsWith([Extension], "htm")
                or Text.EndsWith([Extension], "svg")
                or Text.EndsWith([Extension], "png")
                or Text.EndsWith([Extension], "jpg")
                or Text.EndsWith([Extension], "jpeg")
                or Text.EndsWith([Extension], "pdf")
            )
        ),

        // Hinzufügen der FileName-Spalte (Dateiname ohne Erweiterung)
        FilesWithFileName = Table.AddColumn(
            FilteredFiles,
            "FileName",
            each Text.Combine(List.RemoveLastN(Text.Split([Name], "."), 1), "."),
            type text
        ),

        // Hinzufügen der FileType-Spalte
        FilesWithFileType = Table.AddColumn(
            FilesWithFileName,
            "FileType",
            each if Text.EndsWith([Extension], "html") or Text.EndsWith([Extension], "htm") then "HTML"
                 else if Text.EndsWith([Extension], "svg") then "SVG"
                 else if Text.EndsWith([Extension], "png") then "PNG"
                 else if Text.EndsWith([Extension], "jpg") or Text.EndsWith([Extension], "jpeg") then "JPEG"
                 else if Text.EndsWith([Extension], "pdf") then "PDF"
                 else "Unknown",
            type text
        ),

        // Hinzufügen von HTML- und SVG-Inhalten (Text) sowie Base64 für andere Formate
        FilesWithContentText = Table.AddColumn(
            FilesWithFileType,
            "ContentText",
            each if [FileType] = "HTML" or [FileType] = "SVG" then 
                    Text.FromBinary([Content], TextEncoding.Utf8) // HTML und SVG in Text umwandeln
                 else 
                    null, // Andere Formate ignorieren
            type text
        ),

        FilesWithBase64 = Table.AddColumn(
            FilesWithContentText,
            "Base64Content",
            each if [FileType] <> "HTML" and [FileType] <> "SVG" then 
                    Binary.ToText([Content], BinaryEncoding.Base64) // Base64 für PDF und andere Formate
                 else 
                    null, // HTML und SVG ignorieren
            type text
        ),

        // Aufteilen der Inhalte in Abschnitte (HTML und Base64 separat behandeln)
        SplitHtmlContent = Table.TransformColumns(
            FilesWithBase64,
            {
                {
                    "ContentText",
                    each if _ <> null then Splitter.SplitTextByRepeatedLengths(30000)(_) else null,
                    type list
                }
            }
        ),

        SplitBase64Content = Table.TransformColumns(
            SplitHtmlContent,
            {
                {
                    "Base64Content",
                    each if _ <> null then Splitter.SplitTextByRepeatedLengths(30000)(_) else null,
                    type list
                }
            }
        ),

        // Expandieren der Inhalte in einzelne Zeilen
        ExpandedHtmlContent = Table.ExpandListColumn(SplitBase64Content, "ContentText"),
        ExpandedBase64Content = Table.ExpandListColumn(ExpandedHtmlContent, "Base64Content"),

        // Hinzufügen der Index-Spalte pro Datei und Dateityp
        FilesWithIndex = Table.Group(
            ExpandedBase64Content,
            {"FileName", "FileType"},
            {
                {"AllData", each Table.AddIndexColumn(_, "Index", 0, 1, Int64.Type), type table}
            }
        ),

        // Expandieren der Gruppen und Sortieren nach FileName, FileType und Index
        SortedResult = Table.Sort(
            Table.ExpandTableColumn(FilesWithIndex, "AllData", {"ContentText", "Base64Content", "Index"}),
            {{"FileName", Order.Ascending}, {"FileType", Order.Ascending}, {"Index", Order.Ascending}}
        )
    in
        SortedResult,

    // Funktion zur Zeitstempelverarbeitung
  
    
    // Function: GetRefreshTimeStamp
    GetRefreshTimeStamp = 
        let
            Documentation_Metadata = [
                Documentation.Name = "Get Refresh TimeStamp",
                Documentation.Description = "Calculates the current date and time in the specified time zone, accounting for daylight saving time (DST).",
                Documentation.Examples = {
                    [
                        Description = "Calculate the current time in Central European Time (CET) during summer (DST).",
                        Code = "GetRefreshTimeStamp(2, 1)",
                        Result = "A datetimezone value corresponding to the current time with a +2 offset for summer."
                    ],
                    [
                        Description = "Calculate the current time in Central European Time (CET) during winter.",
                        Code = "GetRefreshTimeStamp(1, 1)",
                        Result = "A datetimezone value corresponding to the current time with a +1 offset for winter."
                    ]
                }
            ],
            fn = ( __Summer_GMT_Offset as number, __Winter_GMT_Offset as number ) =>
                let
                    __UTC_DateTimeZone = DateTimeZone.UtcNow(),
                    __UTC_Date = Date.From(__UTC_DateTimeZone),
                    __StartSummerTime = Date.StartOfWeek(#date(Date.Year(__UTC_Date), 3, 31), Day.Sunday),
                    __StartWinterTime = Date.StartOfWeek(#date(Date.Year(__UTC_Date), 10, 31), Day.Sunday),
                    __UTC_Offset =
                        if __UTC_Date >= __StartSummerTime and __UTC_Date < __StartWinterTime then
                            __Summer_GMT_Offset
                        else
                            __Winter_GMT_Offset,
                    __CET_Timezone = DateTimeZone.SwitchZone(__UTC_DateTimeZone, __UTC_Offset)
                in
                    __CET_Timezone,
            fnWithMeta = Value.ReplaceType(fn, Value.ReplaceMetadata(Value.Type(fn), Documentation_Metadata))
        in
            fnWithMeta,

    // Funktion für den Datenzugriff
    DoAccess = (
        __InputTable as table
    ) =>
    let
        __Source = __InputTable,
        __DevFilterFirstN = if DevMode then Table.FirstN(__Source, FilterFirstN) else __Source
    in
        __DevFilterFirstN,

    // Funktion zur Datenmodellierung
    DoDataModel = (
        __InputTable as table, 
        optional __Culture as nullable text
    ) as table =>
    let
        __ValidTypes = {
            type any,
            type number,
            type date,
            type datetime,
            type datetimezone,
            type time,
            type duration,
            type logical,
            type text,
            type binary,
            Int64.Type,
            Percentage.Type,
            Currency.Type
        },
        __Top200Rows = Table.FirstN(__InputTable, FilterFirstN),
        __ColumnNameList = Table.ColumnNames(__Top200Rows),
        __ColumnDataLists = List.Accumulate(
            __ColumnNameList,
            {},
            (accumulated, i) => accumulated & {Table.Column(__Top200Rows, i)}
        ),
        __ColumnTypes = List.Transform(__ColumnDataLists, (i) => 
            let
                __ItemType = List.Distinct(List.Transform(i, each if _ = null then type null else Value.Type(_))),
                __MergedType = if List.Count(__ItemType) = 1 then __ItemType{0} else type any
            in
                __MergedType
        ),
        __TransformList = List.Zip({__ColumnNameList, __ColumnTypes}),
        __TypedTable = Table.TransformColumnTypes(__InputTable, __TransformList, __Culture)
    in
        __TypedTable,

    // Funktion zur Flachlegung von Hierarchien
    FlattenPcHierarchy = 
(ParChTable as table,
ChildKey as text,
ParentKey as text,
LevelColumnName as text) =>
let

/*/Debug Parameters
ParChTable = SourceData_Loop,
ChildKey = "NodeKey",
ParentKey = "ParentKey",
LevelColumnName = "Name",
*/

    SelectRelevantColumns = Table.SelectColumns(ParChTable, {ChildKey, ParentKey, LevelColumnName}),
    #"Changed Type" = Table.TransformColumnTypes(SelectRelevantColumns ,{{ChildKey, type text}, {ParentKey, type text}}),
    ReplaceNulls = Table.ReplaceValue(#"Changed Type",null,"",Replacer.ReplaceValue,{ParentKey}),
    //    CleanParChTable = Table.Distinct(ReplaceNulls , {ChildKey, ParentKey}),
    MissingParents = List.Buffer(List.Select(List.Difference(List.Distinct(Table.Column(ReplaceNulls , ParentKey)), List.Distinct(Table.Column(ReplaceNulls , ChildKey))), each _ <> "")),
    AddMissingParents = Table.Buffer(Table.Combine({ReplaceNulls , #table({ChildKey, LevelColumnName, ParentKey}, List.Transform(MissingParents, each {_, "Unknown TopLevel"& Text.From(List.PositionOf(MissingParents, _)), ""}))})),
    #"Merged Queries0" = Table.NestedJoin(AddMissingParents,{ChildKey},AddMissingParents,{ParentKey},"SelectRelevantColumns",JoinKind.LeftOuter),
    CheckIfIsLeaf = Table.AddColumn(#"Merged Queries0", "IsLeaf", each if Table.IsEmpty([SelectRelevantColumns]) then "yes" else "no"),
    #"Replaced Value1" = Table.ReplaceValue(CheckIfIsLeaf,null,"",Replacer.ReplaceValue,{ParentKey, LevelColumnName}),
    AddStartPath = Table.AddColumn(#"Replaced Value1", "Path", each Text.Trim(Record.Field(_, ChildKey)&"|"&Record.Field(_,ParentKey), "|")),
    #"Duplicated Column" = Table.DuplicateColumn(AddStartPath, LevelColumnName, "FirstName"),
    Feed = Table.DuplicateColumn(#"Duplicated Column", ParentKey, "FirstParentKey"),

// Retrieve all parents per row
    fnAllParents = List.Generate(()=>
    [Result= Feed, Level=1, EndlessLoop = false, StopEndlessLoop = false],
    each Table.RowCount([Result]) > 0 and not [StopEndlessLoop],
    each [ Result= let
            #"Merged Queries" = Table.NestedJoin([Result],{ParentKey},AddMissingParents,{ChildKey},"Added Custom",JoinKind.Inner),
            #"Removed Columns1" = Table.RemoveColumns(#"Merged Queries",{ParentKey}),
            #"Expanded Added Custom" = Table.ExpandTableColumn(#"Removed Columns1", "Added Custom", {ParentKey, LevelColumnName}, {"ParentKey.1", "Name.1"}),
            #"Duplicated Column" = Table.DuplicateColumn(#"Expanded Added Custom", "ParentKey.1", ParentKey),
            #"Merged Columns" = Table.CombineColumns(#"Duplicated Column",{"Path", "ParentKey.1"},Combiner.CombineTextByDelimiter("|", QuoteStyle.None),"Path"),
            #"Merged Columns2" = Table.CombineColumns( #"Merged Columns" ,{LevelColumnName, "Name.1"},Combiner.CombineTextByDelimiter("|", QuoteStyle.None),LevelColumnName)
          in
            Table.Buffer(#"Merged Columns2"),
          Level = [Level]+1,
          EndlessLoop = List.Sort(List.Distinct(Table.Column(Result, ChildKey))) = List.Sort(List.Distinct(Table.Column([Result], ChildKey))),
          StopEndlessLoop = [EndlessLoop]
        ]),
    ConvertToTable = Table.FromList(fnAllParents, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
    ExpandLevel = Table.ExpandRecordColumn(ConvertToTable, "Column1", {"Result", "Level", "EndlessLoop"}, {"Result", "Level", "EndlessLoop"}),
    ExpandLG = Table.ExpandTableColumn(ExpandLevel, "Result", {LevelColumnName, ParentKey, ChildKey, "Path", "FirstName", "FirstParentKey"}, {"Name", "ParentKey", "NodeKey", "Path", "FirstName", "FirstParentKey"}),
    FilterParents = Table.SelectRows(ExpandLG, each ([ParentKey] = null or [ParentKey] = "")),
    #"Removed Columns" = Table.RemoveColumns(FilterParents,{"ParentKey"}),
    #"Trimmed Text" = Table.TransformColumns(#"Removed Columns",{{"Path", each Text.Trim(_, "|")}}),
    ReverseOrderName = Table.TransformColumns(#"Trimmed Text",{{"Name", each Text.Combine(List.Reverse(Text.Split(_, "|")), "|")}}),
    ReverseOrderPath = Table.TransformColumns(ReverseOrderName,{{"Path", each Text.Combine(List.Reverse(Text.Split(_, "|")), "|")}}),
    #"Reordered Columns" = Table.ReorderColumns(ReverseOrderPath,{"NodeKey", "FirstParentKey", "Path", "FirstName", "Level", "Name"}),
    #"Split Column by Delimiter" = Table.SplitColumn(#"Reordered Columns", "Name", Splitter.SplitTextByDelimiter("|", QuoteStyle.Csv), List.Transform({1..Table.RowCount(ConvertToTable)}, each "Level "&Text.From(_))),
    #"Merged Queries" = Table.NestedJoin(#"Split Column by Delimiter",{"NodeKey", "FirstParentKey"},ParChTable ,{ChildKey, ParentKey},"Split Column by Delimiter",JoinKind.LeftOuter),
    #"Expanded Split Column by Delimiter" = Table.ExpandTableColumn(#"Merged Queries", "Split Column by Delimiter", List.Difference(Table.ColumnNames(ParChTable), Table.ColumnNames(#"Replaced Value1"))),
    Rename = Table.RenameColumns(#"Expanded Split Column by Delimiter",{{"Level", "HierarchyDepth"}}),
    Parents = List.Buffer(Rename[FirstParentKey]),
    IsLeaf = Table.AddColumn(Rename, "IsLeaf", each not List.Contains(Parents, [NodeKey])),
    NoOfInterations = List.Count(fnAllParents),
    LastIteration = Table.SelectRows(ExpandLG, each ([Level] = NoOfInterations)),
    EndlessLoops = LastIteration[EndlessLoop],
    IsEndlessLoop = EndlessLoops{0},
    RemainingResults = Table.NestedJoin(IsLeaf, {ChildKey}, LastIteration, {ChildKey}, "x", JoinKind.LeftAnti),
    Custom1 = if IsEndlessLoop then [Message= "The data is in an endless loop. Check Table in  ""Endless Loop""", #" Endless Loop"= LastIteration] meta [ResultsSoFar = RemainingResults] else IsLeaf
in
    Custom1,

   
    // Zeit-Tabelle
 
    GetTimeTable = 
    let
        // Diese ganze Zahl zeigt die Anzahl der Minuten pro Tag
        Documentation_Metadata = [
            Documentation.Name = "GetTimeTable",
            Documentation.Description = "Generates a time dimension table with time intervals, lower and upper bounds for various aggregation levels (e.g., 5-minute, 15-minute, 30-minute intervals).",
            Documentation.Examples = {
                [
                    Description = "Generate a time table with minute intervals for a full day.",
                    Code = "GetTimeTable()",
                    Result = "Table with columns representing time, lower and upper bounds for 5, 15, 30, 45, and 60-minute intervals."
                ]
            }
        ],
        __Source = Table.FromList({1 .. 1440}, Splitter.SplitByNothing()), // Falls eine Zeitdimension auf Sekundenebene gewünscht ist, dann muss eine Liste von Sekunden von 1 bis 86.400 erstellt werden.
        __RenamedColumns = Table.RenameColumns(__Source, {{"Column1", "ID"}}),
        __TimeColumnAdded = Table.AddColumn(
            __RenamedColumns,
            "Time",
            each Time.From(#datetime(1970, 1, 1, 0, 0, 0) + #duration(0, 0, [ID], 0))
        ),
        __FiveMinLowerBand = Table.AddColumn(
            __TimeColumnAdded,
            "FiveMinLowerBand",
            each Time.From(
                #datetime(1970, 1, 1, 0, 0, 0) + #duration(0, 0, Number.RoundDown([ID] / 5) * 5, 0)
            )
        ),
        __FifteenMinLowerBand = Table.AddColumn(
            __FiveMinLowerBand,
            "FifteenMinLowerBand",
            each Time.From(
                #datetime(1970, 1, 1, 0, 0, 0) + #duration(0, 0, Number.RoundDown([ID] / 15) * 15, 0)
            )
        ),
        __ThirtyMinLowerBand = Table.AddColumn(
            __FifteenMinLowerBand,
            "ThirtyMinLowerBand",
            each Time.From(
                #datetime(1970, 1, 1, 0, 0, 0) + #duration(0, 0, Number.RoundDown([ID] / 30) * 30, 0)
            )
        ),
        __FortyFiveMinLowerBand = Table.AddColumn(
            __ThirtyMinLowerBand,
            "FortyFiveMinLowerBand",
            each Time.From(
                #datetime(1970, 1, 1, 0, 0, 0) + #duration(0, 0, Number.RoundDown([ID] / 45) * 45, 0)
            )
        ),
        __SixtyMinLowerBand = Table.AddColumn(
            __FortyFiveMinLowerBand,
            "SixtyMinLowerBand",
            each Time.From(
                #datetime(1970, 1, 1, 0, 0, 0) + #duration(0, 0, Number.RoundDown([ID] / 60) * 60, 0)
            )
        ),
        __FiveMinUpperBand = Table.AddColumn(
            __SixtyMinLowerBand,
            "FiveMinUpperBand",
            each Time.From(
                #datetime(1970, 1, 1, 0, 0, 0) + #duration(0, 0, Number.RoundUp([ID] / 5) * 5, 0)
            )
        ),
        __FifteenMinUpperBand = Table.AddColumn(
            __FiveMinUpperBand,
            "FifteenMinUpperBand",
            each Time.From(
                #datetime(1970, 1, 1, 0, 0, 0) + #duration(0, 0, Number.RoundUp([ID] / 15) * 15, 0)
            )
        ),
        __ThirtyMinUpperBand = Table.AddColumn(
            __FifteenMinUpperBand,
            "ThirtyMinUpperBand",
            each Time.From(
                #datetime(1970, 1, 1, 0, 0, 0) + #duration(0, 0, Number.RoundUp([ID] / 30) * 30, 0)
            )
        ),
        __FortyFiveMinUpperBand = Table.AddColumn(
            __ThirtyMinUpperBand,
            "FortyFiveMinUpperBand",
            each Time.From(
                #datetime(1970, 1, 1, 0, 0, 0) + #duration(0, 0, Number.RoundUp([ID] / 45) * 45, 0)
            )
        ),
        __SixtyMinUpperBand = Table.AddColumn(
            __FortyFiveMinUpperBand,
            "SixtyMinUpperBand",
            each Time.From(
                #datetime(1970, 1, 1, 0, 0, 0) + #duration(0, 0, Number.RoundUp([ID] / 60) * 60, 0)
            )
        ),
        __ChangedType = Table.TransformColumnTypes(
            __SixtyMinUpperBand,
            {
                {"Time", type time},
                {"FiveMinLowerBand", type time},
                {"FifteenMinLowerBand", type time},
                {"ThirtyMinLowerBand", type time},
                {"FortyFiveMinLowerBand", type time},
                {"SixtyMinLowerBand", type time},
                {"FiveMinUpperBand", type time},
                {"FifteenMinUpperBand", type time},
                {"ThirtyMinUpperBand", type time},
                {"FortyFiveMinUpperBand", type time},
                {"SixtyMinUpperBand", type time}
            }
        )
    in
        Value.ReplaceType(__ChangedType, Value.ReplaceMetadata(Value.Type(__ChangedType), Documentation_Metadata)),
// Next Function
    GetPeriodsTable = 
let
    // Documentation for GetPeriodsTable
    Documentation_Metadata = [
        Documentation.Name = "GetPeriodsTable",
        Documentation.Description = "Generates a table containing predefined date ranges (periods) for reporting purposes, such as last 7 days, current month to date, and previous year. Each period is described with start and end dates, a sort order, and a detailed description for user context.",
        Documentation.Examples = {
            [
                Description = "Generates predefined periods such as 'Today', 'Last 7 Days', and 'Current Month to Date'.",
                Code = "GetPeriodsTable",
                Result = "A table with columns Period, Date, Sort, and Description."
            ]
        }
    ],

    // Current Date
    TodaysDate = Date.From(DateTimeZone.FixedUtcNow()),

    // Define Ranges
    Ranges = {
        {"Today", TodaysDate, TodaysDate, 1, "Today's date only"},
        {"Yesterday", Date.AddDays(TodaysDate, -1), Date.AddDays(TodaysDate, -1), 2, "The previous day's date"},
        {"Last 7 Days", Date.AddDays(TodaysDate, -6), TodaysDate, 3, "The last 7 days including today"},
        {"Last 14 Days", Date.AddDays(TodaysDate, -13), TodaysDate, 4, "The last 14 days including today"},
        {"Last 30 Days", Date.AddDays(TodaysDate, -29), TodaysDate, 5, "The last 30 days including today"},
        {"Last 45 Days", Date.AddDays(TodaysDate, -44), TodaysDate, 6, "The last 45 days including today"},
        {"Last 90 Days", Date.AddDays(TodaysDate, -89), TodaysDate, 7, "The last 90 days including today"},
        {"Current Week to Date", Date.From(Date.StartOfWeek(TodaysDate, Day.Monday)), TodaysDate, 8, "From the start of this week to today"},
        {"Previous Week", Date.From(Date.StartOfWeek(Date.AddWeeks(TodaysDate, -1), Day.Monday)), Date.From(Date.EndOfWeek(Date.AddWeeks(TodaysDate, -1), Day.Monday)), 9, "The previous week's full date range"},
        {"Prior Previous Week", Date.From(Date.StartOfWeek(Date.AddWeeks(TodaysDate, -2), Day.Monday)), Date.From(Date.EndOfWeek(Date.AddWeeks(TodaysDate, -2), Day.Monday)), 10, "The week before the previous week"},
        {"Current Month to Date", Date.From(Date.StartOfMonth(TodaysDate)), TodaysDate, 11, "From the start of this month to today"},
        {"Previous Month", Date.From(Date.StartOfMonth(Date.AddMonths(TodaysDate, -1))), Date.From(Date.EndOfMonth(Date.AddMonths(TodaysDate, -1))), 12, "The previous month's full date range"},
        {"Prior Previous Month", Date.From(Date.StartOfMonth(Date.AddMonths(TodaysDate, -2))), Date.From(Date.EndOfMonth(Date.AddMonths(TodaysDate, -2))), 13, "The month before the previous month"},
        {"Current Quarter to Date", Date.From(Date.StartOfQuarter(TodaysDate)), TodaysDate, 14, "From the start of this quarter to today"},
        {"Previous Quarter", Date.From(Date.AddQuarters(Date.StartOfQuarter(TodaysDate), -1)), Date.From(Date.EndOfQuarter(Date.AddQuarters(TodaysDate, -1))), 15, "The previous quarter's full date range"},
        {"Prior Previous Quarter", Date.From(Date.AddQuarters(Date.StartOfQuarter(TodaysDate), -2)), Date.From(Date.EndOfQuarter(Date.AddQuarters(TodaysDate, -2))), 16, "The quarter before the previous quarter"},
        {"Current Year To Date", Date.From(Date.StartOfYear(TodaysDate)), TodaysDate, 17, "From the start of this year to today"},
        {"Previous Year To Date", Date.From(Date.AddYears(Date.StartOfYear(TodaysDate), -1)), Date.From(Date.AddYears(Date.StartOfDay(TodaysDate), -1)), 18, "From the start of the previous year to today"},
        {"Previous Year", Date.From(Date.AddYears(Date.StartOfYear(TodaysDate), -1)), Date.From(Date.AddYears(Date.EndOfYear(TodaysDate), -1)), 19, "The previous year's full date range"},
        {"Prior Previous Year", Date.From(Date.AddYears(Date.StartOfYear(TodaysDate), -2)), Date.From(Date.AddYears(Date.EndOfYear(TodaysDate), -2)), 20, "The year before the previous year"}
    },

    // Generate Period Table for Each Range
    fxCreatePeriodTable = (PeriodName as text, StartDate as date, EndDate as date, SortOrder as number, Description as text) as table =>
        let
            DayCount = Duration.Days(EndDate - StartDate) + 1,
            DateList = List.Dates(StartDate, DayCount, #duration(1, 0, 0, 0)),
            AddPeriodName = List.Transform(DateList, each {PeriodName, _, SortOrder, Description}),
            CreateTable = #table(type table [Period = text, Date = date, Sort = number, Description = text], AddPeriodName)
        in
            CreateTable,

    // Combine All Period Tables
    GetTables = List.Transform(Ranges, each fxCreatePeriodTable(_{0}, _{1}, _{2}, _{3}, _{4})),
    Output = Table.Combine(GetTables),

    // Apply Documentation Metadata
    ResultWithMeta = Value.ReplaceType(Output, Value.ReplaceMetadata(Value.Type(Output), Documentation_Metadata))
in
    ResultWithMeta,

    GetCalendarTable = 
    let
    // Dokumentation der Funktion
    Documentation_Metadata = [
        Documentation.Name = "GetCalendarTable",
        Documentation.Description = "Generates a calendar table for specified date ranges and cultures, including detailed date attributes.",
        Documentation.LongDescription = "The GetCalendarTable function dynamically generates an ISO-8601 compliant calendar table for multiple cultures. It calculates detailed attributes such as year, month, quarter, week, weekdays, and offsets, providing a rich time dimension for analysis.",
        Documentation.Parameters = {
            [Name = "StartDateOption", Type = "text", Description = "Defines the start date of the calendar. Options include 'Years to Keep as of Today' and 'Years to Keep start of year'."],
            [Name = "EndDateOption", Type = "text", Description = "Defines the end date of the calendar. Options include 'Today', 'End of current year', 'End of next year', '+ 1 Year', and '+ 2 Years'."],
            [Name = "YearsToKeep", Type = "number", Description = "Specifies the number of years to keep in the calendar. Defaults to 1 if not provided."]
        },
        Documentation.Returns = [
            Type = "table",
            Description = "A table containing a date range with detailed calendar attributes, including year, quarter, month, weeks, weekdays, and culture-specific formatting."
        ],
        Documentation.Examples = {
            [
                Description = "Generates a calendar table starting from the current year and ending at the end of the next year.",
                Code = "GetCalendarTable(\""Years to Keep start of year\"", \""End of next year\"", 2)",
                Result = "A table with dates, year, month, week, and other time attributes."
            ],
            [
                Description = "Generates a calendar table starting from today and ending after one year.",
                Code = "GetCalendarTable(\""Years to Keep as of Today\"", \""+ 1 Year\"", 1)",
                Result = "A table containing all days from today to the same date next year."
            ]
        }
    ],

    // Globale Parameter
    _StartDateOption = @#"StartDateOption",
    _EndDateOption = @#"EndDateOption",
    _YearsToKeep = @#"YearsToKeep",
    _Culture = @#"Culture",

    // Parameter für Start- und Enddatum
    CurrentDate = Date.From(DateTime.LocalNow()),
    StartDate = 
        if _StartDateOption = "Years to Keep as of Today" then Date.AddYears(CurrentDate, -_YearsToKeep)
        else if _StartDateOption = "Years to Keep start of year" then #date(Date.Year(CurrentDate) - _YearsToKeep, 1, 1)
        else null,
    EndDate = 
        if _EndDateOption = "Today" then CurrentDate
        else if _EndDateOption = "End of current year" then #date(Date.Year(CurrentDate), 12, 31)
        else if _EndDateOption = "End of next year" then #date(Date.Year(CurrentDate) + 1, 12, 31)
        else if _EndDateOption = "+ 1 Year" then Date.AddYears(CurrentDate, 1)
        else if _EndDateOption = "+ 2 Years" then Date.AddYears(CurrentDate, 2)
        else null,

    // Generierung der Datumswerte
    DateList = List.Dates(StartDate, Duration.Days(EndDate - StartDate) + 1, #duration(1, 0, 0, 0)),
    BaseTable = Table.FromList(DateList, Splitter.SplitByNothing(), {"Date"}),

    // Basisinformationen
    AddYear = Table.AddColumn(BaseTable, "Year", each Date.Year([Date]), type number),
    AddYearOffset = Table.AddColumn(AddYear, "Year Offset", each Date.Year([Date]) - Date.Year(CurrentDate), type number),
    AddYearCompleted = Table.AddColumn(AddYearOffset, "Year Completed", each CurrentDate > Date.EndOfYear([Date]), type logical),

    // Quartalsinformationen
    AddQuarterNumber = Table.AddColumn(AddYearCompleted, "Quarter Number", each Date.QuarterOfYear([Date]), type number),
    AddQuarter = Table.AddColumn(AddQuarterNumber, "Quarter", each "Q" & Text.From([Quarter Number]), type text),
    AddStartOfQuarter = Table.AddColumn(AddQuarter, "Start of Quarter", each Date.StartOfQuarter([Date]), type date),
    AddEndOfQuarter = Table.AddColumn(AddStartOfQuarter, "End of Quarter", each Date.EndOfQuarter([Date]), type date),
    AddQuarterCompleted = Table.AddColumn(AddEndOfQuarter, "Quarter Completed", each CurrentDate > Date.EndOfQuarter([Date]), type logical),
    AddQuarterOffset = Table.AddColumn(AddQuarterCompleted, "Quarter Offset", each ([Year] - Date.Year(CurrentDate)) * 4 + ([Quarter Number] - Date.QuarterOfYear(CurrentDate)), type number),
    AddQuarterAndYear = Table.AddColumn(AddQuarterOffset, "Quarter & Year", each "Q" & Text.From([Quarter Number]) & "/" & Text.From([Year]), type text),
    AddYearQuarterNumber = Table.AddColumn(AddQuarterAndYear, "Year Quarter Number", each [Year] * 10 + [Quarter Number], Int64.Type),

    // Monatsinformationen
    AddMonthNumber = Table.AddColumn(AddYearQuarterNumber, "Month Number", each Date.Month([Date]), type number),
    AddMonth = Table.AddColumn(AddMonthNumber, "Month", each Date.ToText([Date], "MMMM", _Culture), type text),
    AddMonthShort = Table.AddColumn(AddMonth, "Month Short", each Date.ToText([Date], "MMM", _Culture), type text),
    AddMonthCompleted = Table.AddColumn(AddMonthShort, "Month Completed", each CurrentDate > Date.EndOfMonth([Date]), type logical),
    AddStartOfMonth = Table.AddColumn(AddMonthCompleted, "Start of Month", each Date.StartOfMonth([Date]), type date),
    AddEndOfMonth = Table.AddColumn(AddStartOfMonth, "End of Month", each Date.EndOfMonth([Date]), type date),
    AddMonthOffset = Table.AddColumn(AddEndOfMonth, "Month Offset", each (Date.Year([Date]) * 12 + Date.Month([Date])) - (Date.Year(CurrentDate) * 12 + Date.Month(CurrentDate)), Int64.Type),
    AddMonthShortYear = Table.AddColumn(AddMonthOffset, "Month Short & Year", each Date.ToText([Date], "MMM yyyy", _Culture), type text),
    AddMonthYear = Table.AddColumn(AddMonthShortYear, "Month Year", each [Year] * 100 + [Month Number], Int64.Type),

    // Halbjahresinformationen
    AddHalfYearNumber = Table.AddColumn(AddMonthYear, "Half Year Number", each if Date.Month([Date]) <= 6 then 1 else 2, type number),
    AddHalfYearAndYear = Table.AddColumn(AddHalfYearNumber, "Half Year & Year", each "H" & Text.From([Half Year Number]) & "/" & Text.From([Year]), type text),

    // Wocheninformationen (ISO-8601)
    AddStartOfWeek = Table.AddColumn(AddHalfYearAndYear, "Start of Week", each Date.StartOfWeek([Date], Day.Monday), type date),
    AddWeekNumber = Table.AddColumn(
    AddStartOfWeek,
    "Week Number",
    each 
        let
            WeekNum = Number.RoundDown((Date.DayOfYear([Date]) - (Date.DayOfWeek([Date], Day.Monday) + 1) + 10) / 7),
            AdjustedWeekNum =
                if WeekNum = 0 then
                    Number.RoundDown(
                        (Date.DayOfYear(#date(Date.Year([Date]) - 1, 12, 31)) - 
                        (Date.DayOfWeek(#date(Date.Year([Date]) - 1, 12, 31), Day.Monday) + 1) + 10) / 7
                    )
                else if WeekNum = 53 and 
                    (Date.DayOfWeek(#date(Date.Year([Date]), 12, 31), Day.Monday) + 1 < 4) then
                    1
                else
                    WeekNum
        in
            AdjustedWeekNum,
    Int64.Type
),
    AddWeekYear = Table.AddColumn(
    AddWeekNumber,
    "Week Year",
    each 
        if [Week Number] = 1 and Date.Month([Date]) = 12 then 
            Date.Year([Date]) + 1 
        else if [Week Number] >= 52 and Date.Month([Date]) = 1 then 
            Date.Year([Date]) - 1 
        else 
            Date.Year(Date.AddDays([Date], -Date.DayOfWeek([Date], Day.Monday) + 3)),
    Int64.Type
),
    AddWeekAndYear = Table.AddColumn(
    AddWeekYear,
    "Week & Year",
    each Text.PadStart(Text.From([Week Number]), 2, "0") & "/" & Text.From([Week Year]),
    type text
),
    AddEndOfWeek = Table.AddColumn(AddWeekAndYear, "End of Week", each Date.EndOfWeek([Date], Day.Monday), type date),
    AddWeekOffset = Table.AddColumn(
    AddEndOfWeek,
    "Week Offset",
    each (Date.StartOfWeek([Date], Day.Monday) - Date.StartOfWeek(CurrentDate, Day.Monday)) / #duration(7, 0, 0, 0),
    type number
),

    // Wochentage
    AddDayOfWeekNumber = Table.AddColumn(AddWeekOffset, "Day of Week Number", each Date.DayOfWeek([Date], Day.Monday) + 1, type number),
    AddDayOfWeek = Table.AddColumn(AddDayOfWeekNumber, "Day of Week", each Date.ToText([Date], "dddd", _Culture), type text),
    AddDayOfWeekShort = Table.AddColumn(AddDayOfWeek, "Day of Week Short", each Date.ToText([Date], "ddd", _Culture), type text),
    AddWeekdayOffset = Table.AddColumn(AddDayOfWeekShort, "Weekday Offset", each -Duration.Days(Date.From(CurrentDate) - [Date]), Int64.Type),

    // Arbeitstage
    AddIsWorkingDay = Table.AddColumn(AddWeekdayOffset, "Is Working Day", each Date.DayOfWeek([Date], Day.Monday) < 5, type logical),
    AddWorkingDayValue = Table.AddColumn(AddIsWorkingDay, "Working Day Value", each if Date.DayOfWeek([Date], Day.Monday) < 5 then 1 else 0, Int64.Type),

    // Formate zuweisen
    ChangeFormat = Table.TransformColumnTypes(AddWorkingDayValue,{{"Date", type date}, {"Year", Int64.Type}, {"Year Offset", Int64.Type}, {"Year Completed", type logical}, {"Quarter Number", Int64.Type}, {"Start of Quarter", type date}, {"End of Quarter", type date}, {"Quarter Offset", Int64.Type}, {"Year Quarter Number", Int64.Type}, {"Month Number", Int64.Type}, {"Week Offset", Int64.Type}, {"Day of Week Number", Int64.Type}, {"Half Year Number", Int64.Type}}),

    // Finalisierung
    FinalCalendar = ChangeFormat,

    // Metadaten einfügen
    fnWithMeta = Value.ReplaceType(FinalCalendar, Value.ReplaceMetadata(Value.Type(FinalCalendar), Documentation_Metadata))
in
    fnWithMeta
in
  [
    GetEntityFromDataSource                  = GetEntityFromDataSource,
    GetMediaFilesFromStandardSharePointFolder = GetMediaFilesFromStandardSharePointFolder,
    GetRefreshTimeStamp = GetRefreshTimeStamp,
    DoAccess = DoAccess,
    DoDataModel = DoDataModel,
    FlattenPcHierarchy = FlattenPcHierarchy,
    GetTimeTable = GetTimeTable,
    GetPeriodsTable = GetPeriodsTable,
    GetCalendarTable = GetCalendarTable 
  ]
