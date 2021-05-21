using module ".\XmlHelper.psm1"
Add-Type -AssemblyName PresentationFramework, PresentationCore

<#
.SYNOPSIS
ファイル初期設定処理
#>
function Initialize-AppFiles {
    # アプリ設定ファイル初期化
    [ConfigXmlHelper]::GetInstance().Initialize()
    # データソースファイル初期化
}