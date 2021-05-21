using module ".\LogHelper.psm1"
using module ".\Parameters.psm1"

<#
.SYNOPSIS
Xmlヘルパクラス
#>
class XmlHelper {
    # シングルトン
    Hidden static [XmlHelper] $instance
    # テンプレートxml
    Hidden [xml] $templateXml
    # Logger
    Hidden [Logger] $logger = [Logger]::GetInstance()

    <#
    .SYNOPSIS
    インスタンス取得
    #>
    Hidden XmlHelper() {}

    static [XmlHelper] GetInstance() {
        if($null -ne [XmlHelper]::instance) {
            return [XmlHelper]::instance
        }

        [XmlHelper]::instance = [XmlHelper]::new()
        return [XmlHelper]::instance
    }

    <#
    .SYNOPSIS
    XML読込処理(ストリーム)

    .PARAMETER srcFilePath
    読込Xmlファイルパス
    #>
    [xml] ReadXmlWithStream([string] $srcFilePath) {
        [System.IO.FileStream]$fs = $null
        try {
            # 読み込み
            $fs = [System.IO.File]::Open($srcFilePath, `
                [System.IO.FileMode]::Open, `
                [System.IO.FileAccess]::Read, `
                [System.IO.FileShare]::Read)
            
            [System.Xml.XmlDocument]$xmlDoc = New-Object System.Xml.XmlDocument
            $xmlDoc.Load($fs)
            return $xmlDoc
        } catch {
            $this.logger.Debug($PSItem)
            $this.logger.Debug("Xml読み込みに失敗しました。[${srcFilePath}]")
            return $null
        } finally {
            $fs.Close()
        }
    }

    <#
    .SYNOPSIS
    XML書込処理(ストリーム)

    .PARAMETER srcXmlDoc
    保存XmlDocument

    .PARAMETER destFilePath
    Xml保存先ファイルパス
    #>
    WriteXmlWithStream([xml] $srcXmlDoc, [string]$destFilePath) {
        [System.IO.FileStream]$fs = $null
        try {
            # 書き込み
            $fs = [System.IO.File]::Open($destFilePath, `
                [System.IO.FileMode]::Create, `
                [System.IO.FileAccess]::ReadWrite, `
                [System.IO.FileShare]::Read)
            $srcXmlDoc.Save($fs)
            $fs.Flush()
            
        } catch {
            $this.logger.Debug($PSItem)
            $this.logger.Debug("Xml書き込みに失敗しました。[${srcXmlDoc}, ${destFilePath}]")
        } finally {
            $fs.Close()
        }
    }
}

<#
.SYNOPSIS
アプリ設定Xmlヘルパクラス
#>
class ConfigXmlHelper {
    # シングルトン
    Hidden static [ConfigXmlHelper] $instance
    # ファイルパス
    Hidden [string] $filePath = [AppParameters]::configXmlFilePath
    # xml
    Hidden [xml] $xmlDoc
    # Logger
    Hidden [Logger] $logger = [Logger]::GetInstance()

    <#
    .SYNOPSIS
    コンストラクタ
    #>
    Hidden ConfigXmlHelper() {}

    <#
    .SYNOPSIS
    インスタンス取得
    #>
    static [ConfigXmlHelper] GetInstance() {
        if($null -ne [ConfigXmlHelper]::instance) {
            return [ConfigXmlHelper]::instance
        }

        [ConfigXmlHelper]::instance = [ConfigXmlHelper]::new()
        return [ConfigXmlHelper]::instance
    }

    <#
    .SYNOPSIS
    初期設定
    #>
    [ConfigXmlHelper] Initialize() {
        try {
            if(Test-Path $this.filePath) {
                # 存在する場合は読込を行う
                $this.xmlDoc = [XmlHelper]::GetInstance().ReadXmlWithStream($this.filePath)
                return $this
            }
            # 存在しない場合、ファイルを生成する
            $this.xmlDoc = [System.Xml.XmlDocument]::new()
            [System.Xml.XmlDeclaration] $xmlDecl = $this.xmlDoc.CreateXmlDeclaration("1.0", "UTF-8", $null)
            $this.xmlDoc.InsertBefore($xmlDecl, $this.xmlDoc.DocumentElement)

            # テンプレートXmlからノードを複製する
            [NodeTemplateXmlHelper] $templateXmlHelper = [NodeTemplateXmlHelper]::GetInstance()
            $templateXmlHelper.Initialize()
            [string] $xPath = "//*[@TemplateName='AppConfigurationsXml']"
            $configNode = $templateXmlHelper.GetTemplateSingleNode($xPath)
            $this.xmlDoc.AppendChild($this.xmlDoc.ImportNode($configNode, $true))
            $dataSourcePathNode = $this.xmlDoc.SelectSingleNode("/Configurations/DataSourceFilePath")
            # アプリデータソースファイルパス初期値の設定
            $dataSourcePathNode.InnerText = [AppParameters]::defaultDataSourceFilePath
            # ファイル保存
            [XmlHelper]::GetInstance().WriteXmlWithStream($this.xmlDoc, $this.filePath)
            return $this
        } catch {
            $this.logger.Debug($PSItem)
            $this.logger.Debug("Xml書き込みに失敗しました。[$($this.xmlDoc)], $($this.filePath)]")
            return $this
        }
    }

    <#
    .SYNOPSIS
    アプリデータソースXmlファイルパス取得
    #>
    [string] GetDataSourceXmlFilePath() {
        try {
            [string] $xPath = "/Configurations/DataSourceFilePath"
            return $this.xmlDoc.SelectSingleNode($xPath).InnerText
        } catch {
            $this.logger.Debug($PSItem)
            $this.logger.Debug("アプリデータソースXmlファイルパス取得に失敗しました。[$($this.filePath)]")
            return $null
        }
    }
}

<#
.SYNOPSIS
テンプレートXmlヘルパクラス
#>
class NodeTemplateXmlHelper {
    # シングルトン
    Hidden static [NodeTemplateXmlHelper] $instance
    # ファイルパス
    Hidden [string] $filePath = [AppParameters]::templateFilePath
    # xml
    Hidden [xml] $xmlDoc
    # Logger
    Hidden [Logger] $logger = [Logger]::GetInstance()

    <#
    .SYNOPSIS
    コンストラクタ
    #>
    Hidden NodeTemplateXmlHelper() {}

    <#
    .SYNOPSIS
    インスタンス取得
    #>
    static [NodeTemplateXmlHelper] GetInstance() {
        if($null -ne [NodeTemplateXmlHelper]::instance) {
            return [NodeTemplateXmlHelper]::instance
        }

        [NodeTemplateXmlHelper]::instance = [NodeTemplateXmlHelper]::new()
        return [NodeTemplateXmlHelper]::instance
    }

    <#
    .SYNOPSIS
    初期設定
    #>
    [NodeTemplateXmlHelper] Initialize() {
        try {
            # テンプレートXmlは必ず存在する想定
            $this.xmlDoc = [XmlHelper]::GetInstance().ReadXmlWithStream($this.filePath)
            return $this
        } catch {
            $this.logger.Debug($PSItem)
            $this.logger.Debug("NodeTemplate.xml読み込みに失敗しました。[$($this.filePath)]")
            return $this
        }
    }

    <#
    .SYNOPSIS
    初期設定

    .PARAMETER xPath
    テンプレートから取得する際の条件XPath
    #>
    [System.Xml.XmlNode] GetTemplateSingleNode([string] $xPath) {
        try {
            [System.Xml.XmlNode] $targetNode = $this.xmlDoc.SelectSingleNode($xPath)
            $targetNode.Attributes.RemoveNamedItem("TemplateName")
            return $targetNode
        } catch {
            $this.logger.Debug($PSItem)
            $this.logger.Debug("NodeTemplate.xmlからノード取得に失敗しました。[$($this.filePath),${xPath}]")
            return $null
        }
    }
}

<#
.SYNOPSIS
Tableデータ型Enum
#>
enum TableDataType {
    Text = 0
    Image = 1
}

<#
.SYNOPSIS
アプリデータソースXmlヘルパクラス
#>
class DataSourceXmlHelper {
    # シングルトン
    Hidden static [DataSourceXmlHelper] $instance
    # ファイルパス
    Hidden [string] $filePath
    # xml
    Hidden [xml] $xmlDoc
    # Logger
    Hidden [Logger] $logger = [Logger]::GetInstance()

    <#
    .SYNOPSIS
    コンストラクタ
    #>
    Hidden DataSourceXmlHelper() {}

    <#
    .SYNOPSIS
    インスタンス取得
    #>
    static [DataSourceXmlHelper] GetInstance() {
        if($null -ne [DataSourceXmlHelper]::instance) {
            return [DataSourceXmlHelper]::instance
        }

        [DataSourceXmlHelper]::instance = [DataSourceXmlHelper]::new()
        return [DataSourceXmlHelper]::instance
    }

    <#
    .SYNOPSIS
    初期設定
    #>
    [DataSourceXmlHelper] Initialize() {
        try {
            # アプリデータソースXmlのファイルパス取得
            [ConfigXmlHelper] $configXmlHelper = [ConfigXmlHelper]::GetInstance()
            $configXmlHelper.Initialize()
            $this.filePath = $configXmlHelper.GetDataSourceXmlFilePath()

            if(Test-Path $this.filePath) {
                # 存在する場合は読込を行う
                $this.xmlDoc = [XmlHelper]::GetInstance().ReadXmlWithStream($this.filePath)
                return $this
            }
            # 存在しない場合、ファイルを生成する
            $this.xmlDoc = [System.Xml.XmlDocument]::new()
            [System.Xml.XmlDeclaration] $xmlDecl = $this.xmlDoc.CreateXmlDeclaration("1.0", "UTF-8", $null)
            $this.xmlDoc.InsertBefore($xmlDecl, $this.xmlDoc.DocumentElement)
            
            # テンプレートXmlからノードを複製する
            [NodeTemplateXmlHelper] $templateXmlHelper = [NodeTemplateXmlHelper]::GetInstance()
            $templateXmlHelper.Initialize()
            [string] $templateXPath = "//*[@TemplateName='DataSourceXml']"
            $dataSourceNode = $templateXmlHelper.GetTemplateSingleNode($templateXPath)
            $this.xmlDoc.AppendChild($this.xmlDoc.ImportNode($dataSourceNode, $true))

            # データベースID設定
            $databaseID = New-Guid
            $this.xmlDoc.SelectSingleNode("/Databases/Database").Attributes.GetNamedItem("ID").Value = $databaseID
            
            # TableDefinition, Tableノードの削除(テンプレートから複製したものが残っているため)
            $this.xmlDoc.SelectSingleNode("/Databases/Database/Definitions/TableDefinitions").RemoveAll()
            $this.xmlDoc.SelectSingleNode("/Databases/Database/Tables").RemoveAll()
            
            # ファイル保存
            [XmlHelper]::GetInstance().WriteXmlWithStream($this.xmlDoc, $this.filePath)
            return $this
        } catch {
            $this.logger.Debug($PSItem)
            $this.logger.Debug("Xml書き込みに失敗しました。[$($this.xmlDoc)], $($this.filePath)]")
            return $this
        }
    }

    <#
    .SYNOPSIS
    テーブル追加

    .PARAMETER tableName
    テーブル名

    .PARAMETER dataType
    データタイプ
    #>
    AddTableDefinition([string] $tableName, [TableDataType]$dataType) {
        try{
            # テンプレートXmlヘルパクラス
            [NodeTemplateXmlHelper] $templateXmlHelper = [NodeTemplateXmlHelper]::GetInstance().Initialize()

            # ID発番
            $tableID = New-Guid
            # TableDefinitionsノード(テーブル定義ノード)
            [System.Xml.XmlNode] $templateDataSourceNode = $templateXmlHelper.GetTemplateSingleNode("//*[@TemplateName='DataSourceXml']")
            $tableDefinitionXPath = "Database/Definitions/TableDefinitions/TableDefinition" 
            [System.Xml.XmlNode] $newTableDefinitionNode = $templateDataSourceNode.SelectSingleNode($tableDefinitionXPath)
            $newTableDefinitionNode.Attributes.GetNamedItem("ID").Value = $tableID
            # テーブル名
            $newTableDefinitionNode.SelectSingleNode("Name").InnerText = $tableName
            # データ型
            $newTableDefinitionNode.SelectSingleNode("DataType").InnerText = $dataType.ToString()
        
            $destTableDefinitionsNode = $this.xmlDoc.SelectSingleNode("/Databases/Database/Definitions/TableDefinitions")
            $destTableDefinitionsNode.AppendChild($this.xmlDoc.ImportNode($newTableDefinitionNode, $true))
        
            # Tableノード(レコード格納ノード)
            $tableXpath = "Database/Tables/Table"
            [System.Xml.XmlNode] $newTableNode = $templateDataSourceNode.SelectSingleNode($tableXpath)
            # Table配下にあるRecordノードテンプレートは削除(TableのID属性も削除される)
            $newTableNode.RemoveAll()
            # ID属性追加
            [System.Xml.XmlNode]$idAttribute = $this.xmlDoc.CreateNode([System.Xml.XmlNodeType]::Attribute, "ID", $null)
            $idAttribute.Value = $tableID
            $newTableNode.Attributes.SetNamedItem($idAttribute)

            $destTableNode = $this.xmlDoc.SelectSingleNode("/Databases/Database/Tables")
            $destTableNode.AppendChild($this.xmlDoc.ImportNode($newTableNode, $true))

            # ファイルへ反映
            [XmlHelper]::GetInstance().WriteXmlWithStream($this.xmlDoc, $this.filePath)
            $this.logger.Debug("テーブル定義を追加しました。[${tableName},${dataType},${templateDataSourceNode}]")
        } catch {
            $this.logger.Debug($PSItem)
            $this.logger.Debug("テーブル定義追加に失敗しました。[${tableName},${dataType}]")
        }
    }

    <#
    .SYNOPSIS
    テーブル定義更新
    #>
    UpdateTableDefinition([string] $guid, [string] $tableName, [TableDataType] $dataType) {
        try {
            $this.logger.Debug("テーブル定義更新を開始します。[${guid},${tableName},${dataType}]")
            # Guidで抽出
            $tableDefinitionXPath = "/Databases/Database/Definitions/TableDefinitions/TableDefinition[@ID='${guid}']"
            [System.Xml.XmlNode] $targetNode = $this.xmlDoc.SelectSingleNode($tableDefinitionXPath)
            # テーブル名
            $targetNode.SelectSingleNode("Name").InnerText = $tableName
            # データ型
            $targetNode.SelectSingleNode("DataType").InnerText = $dataType
            # ファイルへ反映
            [XmlHelper]::GetInstance().WriteXmlWithStream($this.xmlDoc, $this.filePath)
            $this.logger.Debug("テーブル定義を更新しました。[${guid},${tableName},${dataType}]")
        } catch {
            $this.logger.Debug($PSItem)
            $this.logger.Debug("テーブル定義更新に失敗しました。[${guid},${tableName},${dataType}]")
        }
    }

    <#
    .SYNOPSIS
    テーブル定義一覧取得
    #>
    [System.Collections.ArrayList] GetTableDefinitionList() {
        try {
            [System.Collections.ArrayList]$results = [System.Collections.ArrayList]::new()
            [string] $xPath = "/Databases/Database/Definitions/TableDefinitions/TableDefinition"
            [System.Xml.XmlNodeList] $nodeList = $this.xmlDoc.SelectNodes($xPath)
            $nodeList | ForEach-Object {
                [string] $tableName = ([System.Xml.XmlNode]$_).SelectSingleNode("Name").InnerText
                [string] $dataType = ([System.Xml.XmlNode]$_).SelectSingleNode("DataType").InnerText
                [string] $guid = ([System.Xml.XmlNode]$_).Attributes.GetNamedItem("ID").Value

                [pscustomobject] $item = New-Object psobject
                Add-Member -InputObject $item -MemberType NoteProperty -Name "Name" -Value $tableName
                Add-Member -InputObject $item -MemberType NoteProperty -Name "DataType" -Value $dataType
                Add-Member -InputObject $item -MemberType NoteProperty -Name "Guid" -Value $guid
                $results.Add($item)
            }
            return $results
        } catch {
            $this.logger.Debug($PSItem)
            $this.logger.Debug("テーブル一覧取得に失敗しました。")
            return $null
        }
    }

    <#
    .SYNOPSIS
    レコード追加

    .PARAMETER psObject
    PSCustomObject
    #>
    AddRecord([pscustomobject] $psObject) {
        # レコード発番
        $newRecordID = New-Guid
        # 保有するすべてのメンバの値を追加する
        $psObject | Get-Member -MemberType NoteProperty | ForEach-Object {
            # メンバー名
            $memberName = $_
            # メンバー名と同一のテーブルをTableDefinitionsから探し、テーブルIDを照会する
            $tableDefinitionNode = $this.xmlDoc.SelectSingleNode("/Databases/Database/Definitions/TableDefinitions/TableDefinition/Name[text()='${memberName}']/..")
            $tableID = $tableDefinitionNode.Attributes.GetNamedItem("ID").Value
            # テーブルIDから、Recordノード追加先のTableノードを取得する
            $tableNode = $this.xmlDoc.SelectSingleNode("/Databases/Database/Tables/Table[@ID='${tableID}']")
            
            #レコードノードに発番したレコードIDを設定し、値を設定し、追加する
            $newRecordNode = [NodeTemplateXmlHelper]::GetInstance().Initialize().GetTemplateSingleNode("/Databases/Database/Tables/Table/Record")
            $newRecordNode.Attributes.GetNamedItem("ID").Value = $newRecordID
            $newRecordNode.InnerText = $psObject.$memberName
            $tableNode.AppendChild($this.xmlDoc.ImportNode($newRecordNode, $true))
        }
        # すべて追加した後、ファイルへ反映する
        [XmlHelper]::GetInstance().WriteXmlWithStream($this.xmlDoc, $this.filePath)
    }
}