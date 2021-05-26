using module ".\LogHelper.psm1"
using module ".\AsyncInvokeHelper.psm1"
using module ".\XmlHelper.psm1"
using module ".\Parameters.psm1"
Add-Type -AssemblyName PresentationFramework, PresentationCore

<#
.SYNOPSIS
ファイル・ディレクトリ選択ダイアログ初期設定
#>
function Initialize-FileDirPickerDialog {
    param([AsyncManager] $asyncManager)

    # ListViewのItemsSource設定(ファイルディレクトリ一覧用)
    [System.Collections.ObjectModel.ObservableCollection[System.Object]] $Global:fileDirlistItemsSource
    try{
        $Global:fileDirlistItemsSource = [System.Collections.ObjectModel.ObservableCollection[System.Object]]::new()
        [System.Object]$lockObject = [System.Object]::new()
        [System.Windows.Data.BindingOperations]::EnableCollectionSynchronization($Global:fileDirlistItemsSource, $lockObject)
        ([System.Windows.Controls.ListView] $asyncManager.GetWindowControl("FileDirDialogList")).ItemsSource = $Global:fileDirlistItemsSource
    } catch {
        [Logger]::GetInstance().Debug($PSItem)
        [Logger]::GetInstance().Debug("リスト初期化に失敗しました。")
    }

    # TabItem Loaded
    ([System.Windows.Controls.TabItem] $asyncManager.GetWindowControl("FileDirPickerDialog")).Add_Loaded({
        try {
            # リスト再描画
            $Global:fileDirlistItemsSource.Clear()
            # データソースファイルパス取得
            [string]$dataSourceFilePath = [ConfigXmlHelper]::GetInstance().GetDataSourceXmlFilePath()
            [string]$currentDir = Convert-Path (Split-Path $dataSourceFilePath -Parent)
            ([System.Windows.Controls.TextBlock] $asyncManager.GetWindowControl("FileDirPickerDialogCurrentDir")).Text = $currentDir
            
            # ディレクトリのみを抽出
            Get-ChildItem -Path $currentDir | Where-Object{"Directory" -eq $_.Attributes} | ForEach-Object {$Global:fileDirlistItemsSource.Add($_) }
        } catch {
            [Logger]::GetInstance().Debug($PSItem)
            [Logger]::GetInstance().Debug("設定画面読込に失敗しました。")
        }
    })

    # 親フォルダ遷移 Click
    ([System.Windows.Controls.Button] $asyncManager.GetWindowControl("FileDirPickerDialogGoParent")).Add_Click({
        try {
            # カレントパス取得
            [string]$currentDir = ([System.Windows.Controls.TextBlock] $asyncManager.GetWindowControl("FileDirPickerDialogCurrentDir")).Text 
            if([string]::Empty -eq (Split-Path $currentDir -Parent)) {
                # ルートディレクトリの場合は何もしない。
                return
            }
            # リスト再描画
            $Global:fileDirlistItemsSource.Clear()
            [string] $currentDir = ([System.Windows.Controls.TextBlock] $asyncManager.GetWindowControl("FileDirPickerDialogCurrentDir")).Text
            [string] $parentDir = Split-Path $currentDir -Parent
            ([System.Windows.Controls.TextBlock] $asyncManager.GetWindowControl("FileDirPickerDialogCurrentDir")).Text = $parentDir
            Get-ChildItem -Path $parentDir | Where-Object{"Directory" -eq $_.Attributes} | ForEach-Object {$Global:fileDirlistItemsSource.Add($_) }
        } catch {
            [Logger]::GetInstance().Debug($PSItem)
            [Logger]::GetInstance().Debug("設定画面読込に失敗しました。")
        }
    })

    # キャンセルボタン Click
    ([System.Windows.Controls.Button] $asyncManager.GetWindowControl("FileDirPickerDialogCancelButton")).Add_Click({
        ([System.Windows.Controls.Grid]$asyncManager.GetWindowControl("OverlayDialogArea")).Visibility = "Collapsed"
        [Logger]::GetInstance().Debug("同期処理からログに出力しました。")
    })

    # OKボタン Click
    ([System.Windows.Controls.Button] $asyncManager.GetWindowControl("FileDirPickerDialogOkButton")).Add_Click({
        ([System.Windows.Controls.Grid]$asyncManager.GetWindowControl("OverlayDialogArea")).Visibility = "Collapsed"
        [Logger]::GetInstance().Debug("同期処理からログに出力しました。")
    })

    # ListView MouseDoubleClick
    ([System.Windows.Controls.ListView] $asyncManager.GetWindowControl("FileDirDialogList")).Add_MouseDoubleClick({
        # ダブルクリックされたファイル名
        [string] $selectedDir = ([System.Windows.Controls.ListView] $asyncManager.GetWindowControl("FileDirDialogList")).SelectedItem.Name
        [Logger]::GetInstance().Debug("データ定義一覧で項目がダブルクリックされました。[$($selectedDir)]")
        # カレントディレクトリを更新
        [string] $currentDir = ([System.Windows.Controls.TextBlock] $asyncManager.GetWindowControl("FileDirPickerDialogCurrentDir")).Text
        [string] $newCurrentDir = Join-Path $currentDir $selectedDir

        # リスト再描画
        $Global:fileDirlistItemsSource.Clear()
        ([System.Windows.Controls.TextBlock] $asyncManager.GetWindowControl("FileDirPickerDialogCurrentDir")).Text = $newCurrentDir
        Get-ChildItem -Path $newCurrentDir | Where-Object{"Directory" -eq $_.Attributes} | ForEach-Object {$Global:fileDirlistItemsSource.Add($_) }
    })
}