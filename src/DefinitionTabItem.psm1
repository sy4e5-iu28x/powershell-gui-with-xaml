using module ".\LogHelper.psm1"
using module ".\AsyncInvokeHelper.psm1"
using module ".\XmlHelper.psm1"
Add-Type -AssemblyName PresentationFramework, PresentationCore

<#
.SYNOPSIS
データ定義画面初期設定
#>
function Initialize-DefinitionTabItem {
    param([AsyncManager] $asyncManager)

    # ListViewのItemsSource設定
    [System.Collections.ObjectModel.ObservableCollection[System.Object]] $Global:listItemsSource
    try{
        $Global:listItemsSource = [System.Collections.ObjectModel.ObservableCollection[System.Object]]::new()
        [System.Object]$lockObject = [System.Object]::new()
        [System.Windows.Data.BindingOperations]::EnableCollectionSynchronization($Global:listItemsSource, $lockObject)
        ([System.Windows.Controls.ListView] $asyncManager.GetWindowControl("DefinitionDataList")).ItemsSource = $Global:listItemsSource
    } catch {
        [Logger]::GetInstance().Debug($PSItem)
        [Logger]::GetInstance().Debug("リスト初期化に失敗しました。")
    }

    # 新規作成ボタン Click
    ([System.Windows.Controls.Button] $asyncManager.GetWindowControl("AddNewDataDefinitionButton")).Add_Click({
        # 遷移先ダイアログの設定
        # Guid
        ([System.Windows.Controls.TextBlock]$asyncManager.GetWindowControl("DefinitionGuidTextBlock")).Text = [System.String]::Empty
        # 項目名
        ([System.Windows.Controls.TextBox]$asyncManager.GetWindowControl("DefinitionNameTextBox")).Text = [System.String]::Empty
        # データ型(Textを規定値)
        ([System.Windows.Controls.RadioButton]$asyncManager.GetWindowControl("EditDefinitionDialogDataTypeText")).IsChecked = $true
        ([System.Windows.Controls.RadioButton]$asyncManager.GetWindowControl("EditDefinitionDialogDataTypeImage")).IsChecked = $false
        
        ([System.Windows.Controls.TabItem]$asyncManager.GetWindowControl("EditDefinitionDialog")).isSelected = $true
        ([System.Windows.Controls.Grid]$asyncManager.GetWindowControl("OverlayDialogArea")).Visibility = "Visible"
    })

    # TabItem Loaded
    ([System.Windows.Controls.TabItem] $asyncManager.GetWindowControl("ManagementTabItem")).Add_Loaded({
        try {
            Update-DefinitionDataList -asyncManager $asyncManager
        } catch {
            [Logger]::GetInstance().Debug($PSItem)
            [Logger]::GetInstance().Debug("非同期スクリプトブロック処理実行に失敗しました。")
        }
    })

    # 編集ダイアログOKボタン押下後
    ([System.Windows.Controls.Button]$asyncManager.GetWindowControl("EditDefinitionDialogOkButton")).Add_Click({
        try {
            Update-DefinitionDataList -asyncManager $asyncManager
        } catch {
            [Logger]::GetInstance().Debug($PSItem)
            [Logger]::GetInstance().Debug("非同期スクリプトブロック処理実行に失敗しました。")
        }
    })

    # ListView Loaded
    ([System.Windows.Controls.ListView] $asyncManager.GetWindowControl("DefinitionDataList")).Add_Loaded({
        $this.ItemContainerGenerator.Items | ForEach-Object {
            $listViewItem = $this.ItemContainerGenerator.ContainerFromItem($_)
            
            # ListViewItem MouseDoubleClick
            $listViewItem.Add_MouseDoubleClick({
                $selectedItem = $asyncManager.GetWindowControl("DefinitionDataList").ItemContainerGenerator.ItemFromContainer($this)
                
                # 遷移先ダイアログの設定
                # Guid
                ([System.Windows.Controls.TextBlock]$asyncManager.GetWindowControl("DefinitionGuidTextBlock")).Text = $selectedItem.TableGuid
                # 項目名
                ([System.Windows.Controls.TextBox]$asyncManager.GetWindowControl("DefinitionNameTextBox")).Text = $selectedItem.DefinitionName
                # データ型
                if([TableDataType]::Text.ToString() -eq $selectedItem.DataType) {
                    ([System.Windows.Controls.RadioButton]$asyncManager.GetWindowControl("EditDefinitionDialogDataTypeText")).IsChecked = $true
                } elseif([TableDataType]::Image.ToString() -eq $selectedItem.DataType) {
                    ([System.Windows.Controls.RadioButton]$asyncManager.GetWindowControl("EditDefinitionDialogDataTypeImage")).IsChecked = $true
                }

                ([System.Windows.Controls.TabItem]$asyncManager.GetWindowControl("EditDefinitionDialog")).isSelected = $true
                ([System.Windows.Controls.Grid]$asyncManager.GetWindowControl("OverlayDialogArea")).Visibility = "Visible"
            })
        }
    })
}

<#
.SYNOPSIS
データ定義リスト再読込処理
#>
function Update-DefinitionDataList {
    param([AsyncManager] $asyncManager)

    [pscustomobject]$param = [pscustomobject]::new()

    # 非同期処理
    $reloadScriptBlock = {
        param($asyncParamObject)
        try {
            # Xml更新反映分を見越して待機
            Start-Sleep -Milliseconds 500
            ([System.Windows.Controls.ListView] $asyncManager.GetWindowControl("DefinitionDataList")).ItemsSource.Clear()
            [System.Collections.ArrayList] $tableDefinitionList = [DataSourceXmlHelper]::GetInstance().Initialize().GetTableDefinitionList()
            $tableDefinitionList | ForEach-Object {
                ([System.Windows.Controls.ListView] $asyncManager.GetWindowControl("DefinitionDataList")).ItemsSource.Add($_)
            }
        } catch {
            [Logger]::GetInstance().Debug($PSItem)
            [Logger]::GetInstance().Debug("非同期スクリプトブロック処理実行に失敗しました。")
        }
    }
    # 非同期実行
    $asyncManager.InvokeAsync($reloadScriptBlock, $param)
}