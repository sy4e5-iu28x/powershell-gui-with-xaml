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
                [System.IO.FileMode]::OpenOrCreate, `
                [System.IO.FileAccess]::Read, `
                [System.IO.FileShare]::Read)
            
            [System.Xml.XmlDocument]$xmlDoc = New-Object System.Xml.XmlDocument
            $xmlDoc.Load($fs)
            return $xmlDoc
        } catch {
            [Logger]::GetInstance().Debug($PSItem)
            [Logger]::GetInstance().Debug("Xml読み込みに失敗しました。[${srcFilePath}]")
            return $null
        } finally {
            $fs.Close()
        }
    }

    <#
    .SYNOPSIS
    XML読込処理(ストリーム)

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
                [System.IO.FileMode]::OpenOrCreate, `
                [System.IO.FileAccess]::ReadWrite, `
                [System.IO.FileShare]::Read)
    
            $srcXmlDoc.Save($fs)
            $fs.Flush()
            
        } catch {
            [Logger]::GetInstance().Debug($PSItem)
            [Logger]::GetInstance().Debug("Xml書き込みに失敗しました。[${srcXmlDoc}, ${destFilePath}]")
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
            $this.xmlDoc.CreateXmlDeclaration("1.0", "UTF-8", $null)
            
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
            [Logger]::GetInstance().Debug($PSItem)
            [Logger]::GetInstance().Debug("Xml書き込みに失敗しました。[$($this.xmlDoc)], $($this.filePath)]")
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
            [Logger]::GetInstance().Debug($PSItem)
            [Logger]::GetInstance().Debug("アプリデータソースXmlファイルパス取得に失敗しました。[$($this.filePath)]")
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
            [Logger]::GetInstance().Debug($PSItem)
            [Logger]::GetInstance().Debug("NodeTemplate.xml読み込みに失敗しました。[$($this.filePath)]")
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
            [Logger]::GetInstance().Debug($PSItem)
            [Logger]::GetInstance().Debug("NodeTemplate.xmlからノード取得に失敗しました。[$($this.filePath),${xPath}]")
            return $null
        }
    }
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
            $this.xmlDoc.CreateXmlDeclaration("1.0", "UTF-8", $null)
            
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
            [Logger]::GetInstance().Debug($PSItem)
            [Logger]::GetInstance().Debug("Xml書き込みに失敗しました。[$($this.xmlDoc)], $($this.filePath)]")
            return $this
        }
    }
}