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
        $nsManager.AddNamespace("def", $targetXaml.DocumentElement.GetAttribute("xmlns"))
        $nsManager.AddNamespace("x", $targetXaml.DocumentElement.GetAttribute("xmlns:x"))
        return $nsManager
    }
}

<#
.SYNOPSIS
ApplicationXamlヘルパクラス
#>
class ApplicationXamlHelper {
    [string] $filePath
    [xml] $appXaml

    <#
    .Description
    コンストラクタ

    .PARAMETER xamlFilePath
    対象のapp.xamlファイルパス
    #>
    ApplicationXamlHelper([string] $xamlFilePath) {
        $this.filePath = $xamlFilePath
        $this.appXaml = Get-Content -Encoding UTF8 -Path $this.filePath
    }

    <#
    .SYNOPSIS
    ResourceDictionaryのSourceを絶対パスに変換する
    #>
    [xml] ApplyResourceDicSouce() {
        try {
            $xPath = "/def:Application/def:Application.Resources/def:ResourceDictionary/def:ResourceDictionary.MergedDictionaries/def:ResourceDictionary"

            [XamlCommonHelper]$commonHelper = [XamlCommonHelper]::new()
            [System.Xml.XmlNamespaceManager]$nsManager = $commonHelper.CreateXamlNsManager($this.filePath)

            # 相対パスを絶対パスに変換する
            [System.Xml.XmlNodeList]$this.appXaml.SelectNodes($xPath, $nsManager) | ForEach-Object {
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
            Write-Error -Message $message
            [Logger]::GetInstance().Debug($message)
            return $null
        }
    }
}