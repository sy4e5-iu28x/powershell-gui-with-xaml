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

    # ListViewのItemsSource設定
    [System.Collections.ObjectModel.ObservableCollection[System.Object]] $Global:listItemsSource =
    [System.Collections.ObjectModel.ObservableCollection[System.Object]]::new()
    [System.Object]$lockObject = [System.Object]::new()
    [System.Windows.Data.BindingOperations]::EnableCollectionSynchronization($Global:listItemsSource, $lockObject)
    ([System.Windows.Controls.ListView] $asyncManager.GetWindowControl("DefinitionDataList")).ItemsSource = $Global:listItemsSource

    # 新規作成ボタン Click
    ([System.Windows.Controls.Button] $asyncManager.GetWindowControl("AddNewDataDefinitionButton")).Add_Click({
        ([System.Windows.Controls.TabItem]$asyncManager.GetWindowControl("EditDefinitionDialog")).isSelected = $true
        ([System.Windows.Controls.Grid]$asyncManager.GetWindowControl("OverlayDialogArea")).Visibility = "Visible"

        [Logger]::GetInstance().Debug("同期処理からログに出力しました。")
    })

    # TabItem Loaded
    ([System.Windows.Controls.TabItem] $asyncManager.GetWindowControl("ManagementTabItem")).Add_Loaded({
        # パラメタ
        [pscustomobject] $param = New-Object psobject
        Add-Member -InputObject $param -MemberType NoteProperty -Name "Name" -Value "名前です"
        Add-Member -InputObject $param -MemberType NoteProperty -Name "DataType" -Value "データ型です"

        # 処理
        $scriptblock = {
            param($asyncParamObject)
            try {
                ([System.Windows.Controls.ListView] $asyncManager.GetWindowControl("DefinitionDataList")).ItemsSource.Add($asyncParamObject)
                [Logger]::GetInstance().Debug("非同期処理からログに出力しました。[$($asyncParamObject)]")
            } catch {
                [Logger]::GetInstance().Debug($PSItem)
                [Logger]::GetInstance().Debug("非同期スクリプトブロック処理実行に失敗しました。")
            }
        }
        # 非同期実行
        $asyncManager.InvokeAsync($scriptblock, $param)
    })
}