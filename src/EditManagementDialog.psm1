using module ".\LogHelper.psm1"
using module ".\AsyncInvokeHelper.psm1"
using module ".\XmlHelper.psm1"
using module ".\WpfFunctions.psm1"
using module ".\Parameters.psm1"
Add-Type -AssemblyName PresentationFramework, PresentationCore

<#
.SYNOPSIS
データ管理ダイアログ初期設定
#>
function Initialize-EditManagementDialog {
    param([AsyncManager] $asyncManager)

    # ListViewのItemsSource設定
    [System.Collections.ObjectModel.ObservableCollection[System.Object]] $Global:editManagementDialogListItemsSource
    try{
        $Global:editManagementDialogListItemsSource = [System.Collections.ObjectModel.ObservableCollection[System.Object]]::new()
        [System.Object]$lockObject = [System.Object]::new()
        [System.Windows.Data.BindingOperations]::EnableCollectionSynchronization($Global:editManagementDialogListItemsSource, $lockObject)
        ([System.Windows.Controls.ListView] $asyncManager.GetWindowControl("EditManagementDialogList")).ItemsSource = $Global:editManagementDialogListItemsSource
    } catch {
        [Logger]::GetInstance().Debug($PSItem)
        [Logger]::GetInstance().Debug("リスト初期化に失敗しました。")
    }

    # ListView Loaded
    ([System.Windows.Controls.ListView] $asyncManager.GetWindowControl("EditManagementDialogList")).Add_Loaded({
        [System.Windows.Controls.ListView]$listView = ([System.Windows.Controls.ListView] $asyncManager.GetWindowControl("EditManagementDialogList"))
        # 各ListViewItem要素を取得
        $listView.ItemContainerGenerator.Items | ForEach-Object {
            [System.Windows.Controls.ListViewItem]$listViewItem = $listView.ItemContainerGenerator.ContainerFromItem($_)

            # ListViewItem Selected
            $listViewItem.Add_Selected({
                # Button要素を取得
                [System.Collections.ArrayList]$results = [System.Collections.ArrayList]::new()
                Get-InnerControls -parent $this -targetControlType ([System.Windows.Controls.Button]) -results $results
                
                # ListViewItem上のButton Click
                $results | ForEach-Object {
                    $_.Add_Click({
                        ([System.Windows.Controls.TabItem]$asyncManager.GetWindowControl("FileDirPickerDialog")).isSelected = $true
                        # 画像ファイル抽出モード指定
                        ([System.Windows.Controls.TextBlock] $asyncManager.GetWindowControl("FileDirPickerDialogPickMode")).Text = [PickMode]::File
                        # デフォルトでのファイルディレクトリ項目表示更新
                        Update-FileDirItemsDefault
                        ([System.Windows.Controls.Grid]$asyncManager.GetWindowControl("OverlayDialogArea")).Visibility = "Visible"
                    })
                }
            })
        }
    })

    # キャンセルボタン Click
    ([System.Windows.Controls.Button] $asyncManager.GetWindowControl("EditManagementDialogCancelButton")).Add_Click({
        ([System.Windows.Controls.Grid]$asyncManager.GetWindowControl("OverlayDialogArea")).Visibility = "Collapsed"
    })

    # OKボタン Click
    ([System.Windows.Controls.Button] $asyncManager.GetWindowControl("EditManagementDialogOkButton")).Add_Click({
        # ダイアログ非表示
        ([System.Windows.Controls.Grid]$asyncManager.GetWindowControl("OverlayDialogArea")).Visibility = "Collapsed"
        # パラメタ
        [pscustomobject] $param = New-Object psobject

        Add-Member -InputObject $param -MemberType NoteProperty -Name "DataType" -Value $tableDataType
        
        # Guid (空文字の場合は、新規登録。値がある場合は更新)
        [string] $guid = ([System.Windows.Controls.TextBlock] $asyncManager.GetWindowControl("DefinitionGuidTextBlock")).Text
        Add-Member -InputObject $param -MemberType NoteProperty -Name "Guid" -Value $guid

        # 非同期処理
        $scriptblock = {
            param($asyncParamObject)
            # パラメタ生成時の変数名を参照
            try { 
                [DataSourceXmlHelper] $dataSourceXmlHelper = [DataSourceXmlHelper]::GetInstance().Initialize()
                if([System.String]::Empty -eq $asyncParamObject.Guid) {
                    # XML新規登録
                } else {
                    # XML更新処理
                }
            } catch {
                [Logger]::GetInstance().Debug($PSItem)
                [Logger]::GetInstance().Debug("非同期スクリプトブロック処理実行に失敗しました。")
            }
        }
        # 非同期実行
        $asyncManager.InvokeAsync($scriptblock, $param)
        [Logger]::GetInstance().Debug("非同期スクリプトブロック処理実行します。")
    })
}