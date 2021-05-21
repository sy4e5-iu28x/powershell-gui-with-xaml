using module ".\LogHelper.psm1"
using module ".\AsyncInvokeHelper.psm1"
using module ".\XmlHelper.psm1"
Add-Type -AssemblyName PresentationFramework, PresentationCore

<#
.SYNOPSIS
デフォルトダイアログ初期設定
#>
function Initialize-DefinitionTabItem {
    param([AsyncManager] $asyncManager)
    # 新規作成ボタン Click
    ([System.Windows.Controls.Button] $asyncManager.GetWindowControl("AddNewDataDefinitionButton")).Add_Click({
        ([System.Windows.Controls.TabItem]$asyncManager.GetWindowControl("EditDefinitionDialog")).isSelected = $true
        ([System.Windows.Controls.Grid]$asyncManager.GetWindowControl("OverlayDialogArea")).Visibility = "Visible"

        [Logger]::GetInstance().Debug("同期処理からログに出力しました。")
    })
}