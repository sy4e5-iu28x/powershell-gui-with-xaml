using module ".\LogHelper.psm1"
using module ".\Parameters.psm1"

<#
.SYNOPSIS
Xaml共通ヘルパクラス

.PARAMETER xamlFilePath
対象のXamlファイルパス
#>
class XamlCommonHelper {

    <#
    .Description
    コンストラクタ
    #>
    XamlCommonHelper(){}

    static [System.Xml.XmlNamespaceManager]CreateXamlNsManager([string]$xamlFilePath) {
        [xml]$targetXaml = Get-Content -Encoding UTF8 -Path $xamlFilePath
        [System.Xml.XmlNamespaceManager]$nsManager = [System.Xml.XmlNamespaceManager]::new($targetXaml.NameTable)
        $nsManager.AddNamespace("ns", $targetXaml.DocumentElement.GetAttribute("xmlns"))
        $nsManager.AddNamespace("x", $targetXaml.DocumentElement.GetAttribute("xmlns:x"))
        return $nsManager
    }
}

<#
.SYNOPSIS
ApplicationXamlヘルパクラス
#>
class ApplicationXamlHelper {
    # シングルトン
    Hidden static [ApplicationXamlHelper] $instance
    # ApplicationXamlファイルパス
    Hidden [string] $filePath
    # ApplicationXaml
    Hidden [xml] $appXaml
    # Logger
    Hidden [Logger] $logger = [Logger]::GetInstance()

    <#
    .Description
    コンストラクタ
    #>
    Hidden ApplicationXamlHelper() {}

    <#
    .Description
    インスタンス取得
    #>
    static [ApplicationXamlHelper] GetInstance() {
        if($null -ne [ApplicationXamlHelper]::instance) {
            return [ApplicationXamlHelper]::instance
        }
        [ApplicationXamlHelper]::instance = [ApplicationXamlHelper]::new()
        return [ApplicationXamlHelper]::instance
    }

    <#
    .Description
    初期設定
    #>
    [ApplicationXamlHelper] Initialize() {
        $this.filePath = [AppParameters]::appXamlFilePath
        try {
            $this.appXaml = Get-Content -Encoding UTF8 -Path $this.filePath
            return $this
        } catch {
            $this.logger.Debug($PSItem)
            $message = "ApplicationXamlの読み込みに失敗しました。[$($this.filePath)]"
            $this.logger.Debug($message)
            Write-Error -Message $message
            return $this
        }
    }

    <#
    .SYNOPSIS
    XmlDocumentを取得する
    #>
    [xml] GetXmlDocument() {
        return $this.appXaml
    }

    <#
    .SYNOPSIS
    ResourceDictionaryのSourceを絶対パスに変換する
    #>
    [ApplicationXamlHelper] ApplyResourceDicSouce() {
        try {
            $xPath = "/ns:Application/ns:Application.Resources/ns:ResourceDictionary/ns:ResourceDictionary.MergedDictionaries/ns:ResourceDictionary"
            [System.Xml.XmlNamespaceManager]$nsManager = [XamlCommonHelper]::CreateXamlNsManager($this.filePath)

            # 相対パスを絶対パスに変換する
            [System.Xml.XmlNodeList] $tabItemNodes = $this.appXaml.SelectNodes($xPath, $nsManager)
            $tabItemNodes | ForEach-Object {
                $attributeSource = ([System.Xml.XmlNode]$_).Attributes.GetNamedItem("Source")
                $relativePath = $attributeSource.Value
                $currentPath = Get-Location
                $fullPath = Join-Path $currentPath $relativePath
                $attributeSource.Value = $fullPath
            }
            $this.logger.Debug("ResourceDictionaryの絶対パス変換が完了しました。")
            return $this
        } catch {
            $this.logger.Debug($PSItem)
            $message = "ResourceDictionaryの属性Sourceの絶対パス変換に失敗しました。"
            $this.logger.Debug($message)
            Write-Error -Message $message
            return $this
        }
    }
}

<#
.SYNOPSIS
WindowXamlヘルパクラス
#>
class WindowXamlHelper {
    Hidden static [WindowXamlHelper] $instance
    Hidden [string] $filePath
    Hidden [xml] $windowXaml

    <#
    .Description
    コンストラクタ
    #>
    Hidden WindowXamlHelper() {}

    <#
    .Description
    インスタンス取得
    #>
    static [WindowXamlHelper] GetInstance() {
        if($null -ne [WindowXamlHelper]::instance) {
            return [WindowXamlHelper]::instance
        }
        [WindowXamlHelper]::instance = [WindowXamlHelper]::new()
        return [WindowXamlHelper]::instance
    }

    <#
    .Description
    初期設定
    #>
    [WindowXamlHelper] Initialize() {
        $this.filePath = [AppParameters]::windowXamlFilePath
        try {
            $this.windowXaml = Get-Content -Encoding UTF8 -Path $this.filePath
            return $this
        } catch {
            $this.logger.Debug($PSItem)
            $message = "WindowXamlの読み込みに失敗しました。[$($this.filePath)]"
            $this.logger.Debug($message)
            Write-Error -Message $message
            return $this
        }
    }

    <#
    .SYNOPSIS
    XmlDocumentを取得する
    #>
    [xml] GetXmlDocument() {
        return $this.windowXaml
    }

    <#
    .Description
    指定ファイルパス集合から任意XPathで取得したノードを、任意XPathで指定したWindow.xaml内の任意ノードに追加する共通処理。

    .PARAMETER srcFilePaths
    対象のxamlファイルパス集合

    .PARAMETER srcXPath
    追加元のXPath

    .PARAMETER destWindowXpath
    追加先のWindow.xaml内のXPath
    #>
    Hidden [WindowXamlHelper] ApplyFromTo([string[]] $srcFilePaths, [string] $srcXPath, [string] $destWindowXpath) {
        try {
            [System.Xml.XmlNamespaceManager]$nsManager = [XamlCommonHelper]::CreateXamlNsManager($this.filePath)
            
            $srcFilePaths | ForEach-Object {

                [xml] $srcXaml = Get-Content -Encoding UTF8 -Path $_
                [System.Xml.XmlNode] $targetNode = $srcXaml.SelectSingleNode($srcXPath, $nsManager)

                if($null -eq $targetNode) {
                    $this.logger.Debug("${_}は${srcXPath}の定義が見つかりませんでした。")
                    continue
                }
                $tabControlXPath = $destWindowXpath
                $dest = $this.windowXaml.SelectSingleNode($tabControlXPath, $nsManager)
                $dest.AppendChild($this.windowXaml.ImportNode($targetNode, $true))
            }
            return $this
        } catch {
            $this.logger.Debug($PSItem)
            $message = "${destWindowXpath}への${srcXPath}追加処理に失敗しました。"
            $this.logger.Debug($message)
            Write-Error -Message $message
            return $this
        }
    }

    <#
    .SYNOPSIS
    WindowTabControlへTabItemを追加する。

    .PARAMETER xamlFilePathCollection
    対象のxamlファイルパスのstring配列
    #>
    [WindowXamlHelper] ApplyWindowTabs([string[]] $xamlFilePathCollection) {
        $srcXPath = "/ns:TabItem"
        $destWindowXPath = "//*[@x:Name='WindowTabControl']"
        $this.ApplyFromTo($xamlFilePathCollection, $srcXPath, $destWindowXPath)
        return $this
    }

    <#
    .SYNOPSIS
    DialogTabControlへTabItemを追加する。

    .PARAMETER xamlFilePathCollection
    対象のxamlファイルパスのstring配列
    #>
    [WindowXamlHelper] ApplyDialogs([string[]] $xamlFilePathCollection) {
        $srcXPath = "/ns:TabItem"
        $destWindowXPath = "//*[@x:Name='DialogTabControl']"
        $this.ApplyFromTo($xamlFilePathCollection, $srcXPath, $destWindowXPath)
        return $this
    }

    <#
    .SYNOPSIS
    x:Name属性のついたすべてのノードを取得する。
    #>
    [System.Xml.XmlNodeList] GetAllXNamedNode() {
        $nsManager = [XamlCommonHelper]::CreateXamlNsManager($this.filePath)
        [string] $xPath = "//*[@x:Name !='']"
        return $this.windowXaml.SelectNodes($xPath, $nsManager)
    }
}