using module ".\LogHelper.psm1"
using module ".\AsyncInvokeHelper.psm1"
using module ".\XmlHelper.psm1"
Add-Type -AssemblyName PresentationFramework, PresentationCore

<#
.SYNOPSIS
データ管理画面初期設定
#>
function Initialize-ManagementTabItem {
    param([AsyncManager] $asyncManager)

    # ListViewのItemsSource設定
    [System.Collections.ObjectModel.ObservableCollection[System.Object]] $Global:managementListItemsSource
    try{
        $Global:managementListItemsSource = [System.Collections.ObjectModel.ObservableCollection[System.Object]]::new()
        [System.Object]$lockObject = [System.Object]::new()
        [System.Windows.Data.BindingOperations]::EnableCollectionSynchronization($Global:managementListItemsSource, $lockObject)
        ([System.Windows.Controls.ListView] $asyncManager.GetWindowControl("ManagementDataList")).ItemsSource = $Global:managementListItemsSource
    } catch {
        [Logger]::GetInstance().Debug($PSItem)
        [Logger]::GetInstance().Debug("リスト初期化に失敗しました。")
    }

    # 新規作成ボタン Click
    ([System.Windows.Controls.Button] $asyncManager.GetWindowControl("AddNewDataButton")).Add_Click({
        # 遷移先ダイアログの設定
        # 全テーブルの項目名、データタイプをPSObjectのListとして生成する
        $Global:editManagementDialogListItemsSource.Clear()
        [System.Collections.ArrayList] $tableDefinitionList = [DataSourceXmlHelper]::GetInstance().Initialize().GetTableDefinitionList()
        $tableDefinitionList | ForEach-Object {$Global:editManagementDialogListItemsSource.Add($_)}

        ([System.Windows.Controls.TabItem]$asyncManager.GetWindowControl("EditManagementDialog")).isSelected = $true
        ([System.Windows.Controls.Grid]$asyncManager.GetWindowControl("OverlayDialogArea")).Visibility = "Visible"
    })

    # TabItem Loaded
    ([System.Windows.Controls.TabItem] $asyncManager.GetWindowControl("ManagementTabItem")).Add_Loaded({
        try {
            
        } catch {
            [Logger]::GetInstance().Debug($PSItem)
            [Logger]::GetInstance().Debug("非同期スクリプトブロック処理実行に失敗しました。")
        }
    })

    # 編集ダイアログOKボタン押下後
    ([System.Windows.Controls.Button]$asyncManager.GetWindowControl("EditManagementDialogOkButton")).Add_Click({
        try {
            
        } catch {
            [Logger]::GetInstance().Debug($PSItem)
            [Logger]::GetInstance().Debug("非同期スクリプトブロック処理実行に失敗しました。")
        }
    })
}