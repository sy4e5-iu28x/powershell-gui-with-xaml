using module ".\LogHelper.psm1"
using module ".\AsyncInvokeHelper.psm1"
using module ".\XmlHelper.psm1"
using module ".\Parameters.psm1"
Add-Type -AssemblyName PresentationFramework, PresentationCore

<#
.SYNOPSIS
設定画面読込
#>
function Initialize-ConfigurationTabItem {
    param([AsyncManager] $asyncManager)

    # TabItem Loaded
    ([System.Windows.Controls.TabItem] $asyncManager.GetWindowControl("ConfigurationTabItem")).Add_Loaded({
        try {
            # データソースファイルパス取得
            [string]$dataSourceFilePath = [ConfigXmlHelper]::GetInstance().GetDataSourceXmlFilePath()
            ([System.Windows.Controls.TextBlock] $asyncManager.GetWindowControl("ConfigurationAppDataSourceFilePath")).Text = $dataSourceFilePath
        } catch {
            [Logger]::GetInstance().Debug($PSItem)
            [Logger]::GetInstance().Debug("設定画面読込に失敗しました。")
        }
    })
    
    # 変更ボタン Click
    ([System.Windows.Controls.Button] $asyncManager.GetWindowControl("ConfigurationAppDataSourceFilePathChangeButton")).Add_Click({
        # データソースファイルパス取得
        [string]$dataSourceFilePath = [ConfigXmlHelper]::GetInstance().GetDataSourceXmlFilePath()
        ([System.Windows.Controls.TextBlock] $asyncManager.GetWindowControl("ConfigurationAppDataSourceFilePath")).Text = $dataSourceFilePath

        # ファイルピッカーダイアログ表示
        ([System.Windows.Controls.TabItem]$asyncManager.GetWindowControl("FileDirPickerDialog")).isSelected = $true
        ([System.Windows.Controls.Grid]$asyncManager.GetWindowControl("OverlayDialogArea")).Visibility = "Visible"
    })

    # 遷移先ファイルピッカーOKボタン Click
    ([System.Windows.Controls.Button] $asyncManager.GetWindowControl("FileDirPickerDialogOkButton")).Add_Click({
        # カレントパス
        [string] $currentDir = ([System.Windows.Controls.TextBlock] $asyncManager.GetWindowControl("FileDirPickerDialogCurrentDir")).Text
        # リストで選択されたディレクトリ名
        [string] $selectedDir = ([System.Windows.Controls.ListView] $asyncManager.GetWindowControl("FileDirDialogList")).SelectedItem.Name
        # ファイル名
        [string] $fileName = Split-Path -Leaf ([AppParameters]::defaultDataSourceFilePath)
        # 保存先パス
        [string]$newDataSourceFileDir = Join-Path $currentDir $selectedDir | Join-Path -ChildPath $fileName
        # パラメタ
        [pscustomobject] $param = New-Object psobject
        Add-Member -InputObject $param -MemberType NoteProperty -Name "NewDataSourceFilePath" -Value $newDataSourceFileDir

        # 処理
        $scriptblock = {
            param($asyncParamObject)
            try {
                [ConfigXmlHelper] $configXmlHelper = [ConfigXmlHelper]::GetInstance()
                [string] $srcFilePath = $configXmlHelper.GetDataSourceXmlFilePath()
                [string] $destFilePath = $asyncParamObject.NewDataSourceFilePath
                # 設定更新
                [ConfigXmlHelper]::GetInstance().SetDataSourceXmlFilePath($destFilePath)
                # ファイル移動
                Move-Item -Path $srcFilePath -Destination $destFilePath
                [Logger]::GetInstance().Debug("アプリデータソースファイル保存先を変更しました。[変更前：${srcFilePath}, 変更後:${destFilePath}]")
                # データソースファイルパス取得
                [string]$dataSourceFilePath = [ConfigXmlHelper]::GetInstance().GetDataSourceXmlFilePath()
                
                # 設定画面更新
                ([System.Windows.Window] $asyncManager.GetWindowControl("AppWindow")).Dispatcher.invoke({
                    ([System.Windows.Controls.TextBlock] $asyncManager.GetWindowControl("ConfigurationAppDataSourceFilePath")).Text = $dataSourceFilePath
                })
            } catch {
                [Logger]::GetInstance().Debug($PSItem)
                [Logger]::GetInstance().Debug("非同期スクリプトブロック処理実行に失敗しました。")
            }
        }
        # 非同期実行
        $asyncManager.InvokeAsync($scriptblock, $param)
    })
}