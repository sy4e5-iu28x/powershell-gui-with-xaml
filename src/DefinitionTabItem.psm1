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

    # ListView MouseDoubleClick
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

<#
.SYNOPSIS
データ定義リスト再読込処理
#>
function Update-DefinitionDataList {
    param([AsyncManager] $asyncManager)

    [pscustomobject]$param = [pscustomobject]::new()
    Add-Member -InputObject $param -MemberType ScriptMethod -Name GetExpandoObject -Value (Get-SciptBlockExpandoObject)

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

<#
.SYNOPSIS
バインド処理に対応(INotifyPropertyChangedインタフェース)したオブジェクトを作成する。
#>
function Get-SciptBlockExpandoObject{
    try{
        $script = {
            param($inputObject)
            try {
                [System.Dynamic.ExpandoObject] $returnObject = [System.Dynamic.ExpandoObject]::new()
                $inputObject | Get-Member | Where-Object {$_.MemberType -eq "NoteProperty"} |
                ForEach-Object {$returnObject.($_.Name) = $inputObject.($_.Name)}
                [Logger]::GetInstance().Debug("ExpandoObject生成しました。[input:${inputObject}, return:${returnObject}]")
                return $returnObject
            } catch {
                [Logger]::GetInstance().Debug($PSItem)
                [Logger]::GetInstance().Debug("ExpandoObject生成に失敗しました。[${inputObject}]")
                return $null
            }
        }
        [System.Management.Automation.ScriptBlock]$scriptBlock = [System.Management.Automation.ScriptBlock]::Create($script)
    } catch {
        [Logger]::GetInstance().Debug($PSItem)
        [Logger]::GetInstance().Debug("ScriptBlockの生成に失敗しました。[${inputObject}]")
    }
    
    return $scriptBlock
}