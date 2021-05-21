using module ".\LogHelper.psm1"
using module ".\AsyncInvokeHelper.psm1"
using module ".\XmlHelper.psm1"
Add-Type -AssemblyName PresentationFramework, PresentationCore

<#
.SYNOPSIS
デフォルトダイアログ初期設定
#>
function Initialize-EditDefinitionDialog {
    param([AsyncManager] $asyncManager)
    # キャンセルボタン Click
    ([System.Windows.Controls.Button] $asyncManager.GetWindowControl("EditDefinitionDialogCancelButton")).Add_Click({
        ([System.Windows.Controls.Grid]$asyncManager.GetWindowControl("OverlayDialogArea")).Visibility = "Collapsed"
    })

    # OKボタン Click
    ([System.Windows.Controls.Button] $asyncManager.GetWindowControl("EditDefinitionDialogOkButton")).Add_Click({
        # ダイアログ非表示
        ([System.Windows.Controls.Grid]$asyncManager.GetWindowControl("OverlayDialogArea")).Visibility = "Collapsed"
        # パラメタ
        [pscustomobject] $param = New-Object psobject
        # 項目名
        [string]$definitionNameValue = ([System.Windows.Controls.TextBox] $asyncManager.GetWindowControl("DefinitionNameTextBox")).Text
        Add-Member -InputObject $param -MemberType NoteProperty -Name "TableName" -Value $definitionNameValue
        
        # テーブルデータ型 ラジオボタン選択状態でデータを取得
        [string]$tableDataType = $null
        if(([System.Windows.Controls.RadioButton] $asyncManager.GetWindowControl("EditDefinitionDialogDataTypeText")).IsChecked){
            $tableDataType = [TableDataType]::Text
        } elseif (([System.Windows.Controls.RadioButton] $asyncManager.GetWindowControl("EditDefinitionDialogDataTypeImage")).IsChecked) {
            $tableDataType = [TableDataType]::Image
        }
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
                    $dataSourceXmlHelper.AddTableDefinition($asyncParamObject.TableName, $asyncParamObject.DataType)
                } else {
                    # XML更新処理
                    $dataSourceXmlHelper.UpdateTableDefinition($asyncParamObject.Guid, $asyncParamObject.TableName, $asyncParamObject.DataType)
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