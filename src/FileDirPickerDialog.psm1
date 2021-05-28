using module ".\LogHelper.psm1"
using module ".\AsyncInvokeHelper.psm1"
using module ".\XmlHelper.psm1"
using module ".\Parameters.psm1"
Add-Type -AssemblyName PresentationFramework, PresentationCore
# 画像対象拡張子
[string] $targetImgExtentions = ".png|.PNG|.jpg|.JPG|.bmp|.BMP|.gif|.GIF"

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
            Update-FileDirItemsDefault
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

            # 動作モードに応じて実行
            Get-ChildFileDirItems -currentDir $parentDir | ForEach-Object {$Global:fileDirlistItemsSource.Add($_) }
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

    # ListView Loaded
    ([System.Windows.Controls.ListView] $asyncManager.GetWindowControl("FileDirDialogList")).Add_GotFocus({
        $this.ItemContainerGenerator.Items | ForEach-Object {
            $listViewItem = $this.ItemContainerGenerator.ContainerFromItem($_)
            
            # ListViewItem MouseDoubleClick
            $listViewItem.Add_MouseDoubleClick({
                $selectedItem = $asyncManager.GetWindowControl("FileDirDialogList").ItemContainerGenerator.ItemFromContainer($this)
                [Logger]::GetInstance().Debug("selectedItem=[$($selectedItem)]")
                if($selectedItem.Attributes -ne "Directory"){
                    # ディレクトリでない場合は、処理を終了する。
                    return
                }

                # ダブルクリックされたファイル名
                [string] $selectedDir = $selectedItem.Name
                [Logger]::GetInstance().Debug("データ定義一覧でディレクトリがダブルクリックされました。[$($selectedDir)]")
                # カレントディレクトリを更新
                [string] $currentDir = ([System.Windows.Controls.TextBlock] $asyncManager.GetWindowControl("FileDirPickerDialogCurrentDir")).Text
                [string] $newCurrentDir = Join-Path $currentDir $selectedDir

                # リスト再描画
                $Global:fileDirlistItemsSource.Clear()
                ([System.Windows.Controls.TextBlock] $asyncManager.GetWindowControl("FileDirPickerDialogCurrentDir")).Text = $newCurrentDir

                # 動作モードに応じて実行
                Get-ChildFileDirItems -currentDir $newCurrentDir | ForEach-Object {$Global:fileDirlistItemsSource.Add($_) }
            })
        }
    })
}

<#
.SYNOPSIS
ファイル・ディレクトリ項目取得
動作モードに応じて項目を取得する([PickMode]::Directory,[PickMode]::File)
#>
function Get-ChildFileDirItems {
    param([string] $currentDir)
    # 動作モードに応じて実行
    [string]$pickMode = ([System.Windows.Controls.TextBlock] $asyncManager.GetWindowControl("FileDirPickerDialogPickMode")).Text

    if([PickMode]::Directory.ToString() -eq $pickMode){
        ([System.Windows.Controls.TextBlock] $asyncManager.GetWindowControl("FileDirPickerDialogTitle")).Text = "ディレクトリの選択"
        # ディレクトリのみを抽出
        Get-ChildItem -Path $currentDir |
            Where-Object{"Directory" -eq $_.Attributes} |
                ForEach-Object{return $_}

    } elseif([PickMode]::File.ToString() -eq $pickMode) {
        ([System.Windows.Controls.TextBlock] $asyncManager.GetWindowControl("FileDirPickerDialogTitle")).Text = "ファイルの選択"
        # ディレクトリと画像ファイルを抽出
        Get-ChildItem -Path $currentDir |
            Where-Object{"Directory" -eq $_.Attributes -Or (("Directory" -ne $_.Attributes) -And $targetImgExtentions.IndexOf($_.Extension) -ge 0)} |
                ForEach-Object {return $_}
    } else {
        return
    }
}

<#
.SYNOPSIS
ファイル・ディレクトリ項目更新
データソースファイル保存場所パスにて表示を更新する。
#>
function Update-FileDirItemsDefault {
    # リスト再描画
    $Global:fileDirlistItemsSource.Clear()
    # データソースファイルパス取得
    [string]$dataSourceFilePath = [ConfigXmlHelper]::GetInstance().GetDataSourceXmlFilePath()
    [string]$currentDir = Convert-Path (Split-Path $dataSourceFilePath -Parent)
    ([System.Windows.Controls.TextBlock] $asyncManager.GetWindowControl("FileDirPickerDialogCurrentDir")).Text = $currentDir

    # 動作モードに応じて実行
    Get-ChildFileDirItems -currentDir $currentDir | ForEach-Object {$Global:fileDirlistItemsSource.Add($_) }
}