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
        # 非同期処理
        $reloadScriptBlock = {
            param($asyncParamObject)
            try {
                [System.Collections.ArrayList] $tableDefinitionList = [DataSourceXmlHelper]::GetInstance().Initialize().GetTableDefinitionList()
                $tableDefinitionList | ForEach-Object {
                    ([System.Windows.Controls.ListView] $asyncManager.GetWindowControl("DefinitionDataList")).ItemsSource.Add($_)
                }
                [Logger]::GetInstance().Debug("非同期処理からログに出力しました。[$($asyncParamObject)]")
            } catch {
                [Logger]::GetInstance().Debug($PSItem)
                [Logger]::GetInstance().Debug("非同期スクリプトブロック処理実行に失敗しました。")
            }
        }
        # 非同期実行
        $asyncManager.InvokeAsync($reloadScriptBlock, $null)
    })

    # ListView DoubleClick
    ([System.Windows.Controls.ListView] $asyncManager.GetWindowControl("DefinitionDataList")).Add_MouseDoubleClick({
        [pscustomobject] $target = ([System.Windows.Controls.ListView] $asyncManager.GetWindowControl("DefinitionDataList")).SelectedItem
        [Logger]::GetInstance().Debug("データ定義一覧で項目がダブルクリックされました。[$($target)]")

        # 遷移先ダイアログの設定
        # Guid
        ([System.Windows.Controls.TextBlock]$asyncManager.GetWindowControl("DefinitionGuidTextBlock")).Text = $target.Guid
        # 項目名
        ([System.Windows.Controls.TextBox]$asyncManager.GetWindowControl("DefinitionNameTextBox")).Text = $target.Name
        # データ型
        if([TableDataType]::Text.ToString() -eq $target.DataType) {
            ([System.Windows.Controls.RadioButton]$asyncManager.GetWindowControl("EditDefinitionDialogDataTypeText")).IsChecked = $true
        } elseif([TableDataType]::Image.ToString() -eq $target.DataType) {
            ([System.Windows.Controls.RadioButton]$asyncManager.GetWindowControl("EditDefinitionDialogDataTypeImage")).IsChecked = $true
        }

        ([System.Windows.Controls.TabItem]$asyncManager.GetWindowControl("EditDefinitionDialog")).isSelected = $true
        ([System.Windows.Controls.Grid]$asyncManager.GetWindowControl("OverlayDialogArea")).Visibility = "Visible"
    })

    
}