using module ".\LogHelper.psm1"

<#
.SYNOPSIS
Xml共通ヘルパクラス

.PARAMETER xamlFilePath
対象のXamlファイルパス
#>
class XamlCommonHelper {
    [System.Xml.XmlNamespaceManager]CreateXamlNsManager([string]$xamlFilePath) {
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
    Hidden [string] $filePath
    Hidden [xml] $appXaml

    <#
    .Description
    コンストラクタ

    .PARAMETER xamlFilePath
    対象のapp.xamlファイルパス
    #>
    ApplicationXamlHelper([string] $xamlFilePath) {
        $this.filePath = $xamlFilePath
        try {
            $this.appXaml = Get-Content -Encoding UTF8 -Path $this.filePath
        } catch {
            [Logger]::GetInstance().Debug($PSItem)
            $message = "ApplicationXamlの読み込みに失敗しました。[${xamlFilePath}]"
            [Logger]::GetInstance().Debug($message)
            Write-Error -Message $message
        }
    }

    <#
    .SYNOPSIS
    ResourceDictionaryのSourceを絶対パスに変換する
    #>
    [xml] ApplyResourceDicSouce() {
        try {
            $xPath = "/ns:Application/ns:Application.Resources/ns:ResourceDictionary/ns:ResourceDictionary.MergedDictionaries/ns:ResourceDictionary"

            [XamlCommonHelper]$commonHelper = [XamlCommonHelper]::new()
            [System.Xml.XmlNamespaceManager]$nsManager = $commonHelper.CreateXamlNsManager($this.filePath)

            # 相対パスを絶対パスに変換する
            [System.Xml.XmlNodeList] $tabItemNodes = $this.appXaml.SelectNodes($xPath, $nsManager)
            [Logger]::GetInstance().Debug("TabItem:${tabItemNodes}")
            $tabItemNodes | ForEach-Object {
                $attributeSource = ([System.Xml.XmlNode]$_).Attributes.GetNamedItem("Source")
                $relativePath = $attributeSource.Value
                $currentPath = Get-Location
                $fullPath = Join-Path $currentPath $relativePath
                $attributeSource.Value = $fullPath
            }
            return $this.appXaml
        } catch {
            [Logger]::GetInstance().Debug($PSItem)
            $message = "ResourceDictionaryの属性Sourceの絶対パス変換に失敗しました。"
            [Logger]::GetInstance().Debug($message)
            Write-Error -Message $message
            return $null
        }
    }
}

<#
.SYNOPSIS
WindowXamlヘルパクラス
#>
class WindowXamlHelper {
    Hidden [string] $filePath
    Hidden [xml] $windowXaml

    <#
    .Description
    コンストラクタ

    .PARAMETER xamlFilePath
    対象のapp.xamlファイルパス
    #>
    WindowXamlHelper([string] $xamlFilePath) {
        $this.filePath = $xamlFilePath
        try {
            $this.windowXaml = Get-Content -Encoding UTF8 -Path $this.filePath
        } catch {
            [Logger]::GetInstance().Debug($PSItem)
            $message = "WindowXamlの読み込みに失敗しました。[${xamlFilePath}]"
            [Logger]::GetInstance().Debug($message)
            Write-Error -Message $message
        }
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
    Hidden [xml] ApplyFromTo([string[]] $srcFilePaths, [string] $srcXPath, [string] $destWindowXpath) {
        try {
            [XamlCommonHelper]$commonHelper = [XamlCommonHelper]::new()
            [System.Xml.XmlNamespaceManager]$nsManager = $commonHelper.CreateXamlNsManager($this.filePath)
            
            $srcFilePaths | ForEach-Object {

                [xml] $srcXaml = Get-Content -Encoding UTF8 -Path $_
                [System.Xml.XmlNode] $targetNode = $srcXaml.SelectSingleNode($srcXPath, $nsManager)

                if($null -eq $targetNode) {
                    [Logger]::GetInstance().Debug("${_}は${srcXPath}の定義が見つかりませんでした。")
                    continue
                }
                $tabControlXPath = $destWindowXpath
                $dest = $this.windowXaml.SelectSingleNode($tabControlXPath, $nsManager)
                $dest.AppendChild($this.windowXaml.ImportNode($targetNode, $true))
            }
            return $this.windowXaml
        } catch {
            [Logger]::GetInstance().Debug($PSItem)
            $message = "${destWindowXpath}への${srcXPath}追加処理に失敗しました。"
            [Logger]::GetInstance().Debug($message)
            Write-Error -Message $message
            return $null
        }
    }

    <#
    .SYNOPSIS
    WindowTabControlへTabItemを追加する。

    .PARAMETER xamlFilePathCollection
    対象のxamlファイルパスのstring配列
    #>
    [xml] ApplyWindowTabs([string[]] $xamlFilePathCollection) {
        $srcXPath = "/ns:TabItem"
        $destWindowXPath = "//*[@x:Name='WindowTabControl']"
        return $this.ApplyFromTo($xamlFilePathCollection, $srcXPath, $destWindowXPath)
    }

    <#
    .SYNOPSIS
    DialogTabControlへTabItemを追加する。

    .PARAMETER xamlFilePathCollection
    対象のxamlファイルパスのstring配列
    #>
    [xml] ApplyDialogs([string[]] $xamlFilePathCollection) {
        $srcXPath = "/ns:TabItem"
        $destWindowXPath = "//*[@x:Name='DialogTabControl']"
        return $this.ApplyFromTo($xamlFilePathCollection, $srcXPath, $destWindowXPath)
    }
}