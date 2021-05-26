using module ".\LogHelper.psm1"
using module ".\XmlHelper.psm1"
using module ".\AsyncInvokeHelper.psm1"
using module ".\Window.psm1"
using module ".\DefinitionTabItem.psm1"
using module ".\ConfigurationTabItem.psm1"
using module ".\DefaultDialog.psm1"
using module ".\EditDefinitionDialog.psm1"
using module ".\FileDirPickerDialog.psm1"
Add-Type -AssemblyName PresentationFramework, PresentationCore

<#
.SYNOPSIS
ファイル初期設定処理
#>
function Initialize-AppFiles {
    # アプリ設定ファイル初期化
    [ConfigXmlHelper]::GetInstance().Initialize()
    # データソースファイル初期化
    [DataSourceXmlHelper]::GetInstance().Initialize()
    [Logger]::GetInstance().Debug("アプリ関連ファイルの初期設定が完了しました。")
}

<#
.SYNOPSIS
ウィンドウタブ初期設定
#>
function Initialize-XamlWindowTabs {
    param([WindowXamlHelper] $windowXamlHelper)
    $windowTabXamlFilePaths = @(
        ".\xaml\windowtabs\ManagementTabItem.xaml",
        ".\xaml\windowtabs\DefinitionTabItem.xaml",
        ".\xaml\windowtabs\ConfigurationTabItem.xaml"
    )
    $windowXamlHelper.ApplyWindowTabs($windowTabXamlFilePaths)
    return $windowXamlHelper
}

<#
.SYNOPSIS
ダイアログ初期設定
#>
function Initialize-XamlDialogs {
    param([WindowXamlHelper] $windowXamlHelper)
    $dialogTabXamlFilePaths = @(
        ".\xaml\dialogs\DefaultTabItem.xaml"
        ".\xaml\dialogs\EditDefinitionTabItem.xaml"
        ".\xaml\dialogs\FileDirPickerTabItem.xaml"
    )
    $windowXamlHelper.ApplyDialogs($dialogTabXamlFilePaths)
    return $windowXamlHelper
}

<#
.SYNOPSIS
非同期処理初期設定処理
#>
function Initialize-AsyncManager {
    param(
        [AsyncManager] $asyncManager,
        [System.Windows.Window] $window
    )

    # 引数チェック
    if(($null -eq $asyncManager) -or ($null -eq $window)) {
        [string]$message = "引数がnullです。処理に失敗しました(asyncManager[${asyncManager}], window[${window}]"
        [Logger]::GetInstance().Debug($message)
        Write-Error -Message $message
    }
    # x:Name属性付与されたノードは非同期処理で操作する可能性があるものとしすべて追加する
    [System.Xml.XmlNodeList] $xNamedNodes = [WindowXamlHelper]::GetInstance().GetAllXNamedNode()
    $xNamedNodes | ForEach-Object {
        [System.Xml.XmlNode]$xNamedNode = $_
        [string]$xName = $xNamedNode.Attributes.GetNamedItem("x:Name").Value
        # 同期ハッシュテーブルに追加
        $asyncManager.AddWindowControl($xName, $window.FindName($xName))
    }
    $asyncManager.Initialize($Host)
}

<#
.SYNOPSIS
ウィンドウコンポーネント初期設定処理
#>
function Initialize-WindowComponents {
    param([AsyncManager]$asyncManager)
    Initialize-Window -asyncManager $asyncManager
    Initialize-DefinitionTabItem -asyncManager $asyncManager
    Initialize-ConfigurationTabItem -asyncManager $asyncManager
    Initialize-DefaultDialog -asyncManager $asyncManager
    Initialize-EditDefinitionDialog -asyncManager $asyncManager
    Initialize-FileDirPickerDialog -asyncManager $asyncManager
}