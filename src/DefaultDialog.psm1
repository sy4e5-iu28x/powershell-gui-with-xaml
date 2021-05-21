using module ".\LogHelper.psm1"
using module ".\AsyncInvokeHelper.psm1"
using module ".\XmlHelper.psm1"
Add-Type -AssemblyName PresentationFramework, PresentationCore

<#
.SYNOPSIS
デフォルトダイアログ初期設定
#>
function Initialize-DefaultDialog {
    param([AsyncManager] $asyncManager)
    # キャンセルボタン_Click
    ([System.Windows.Controls.Button]$asyncManager.GetWindowControl("DefaultDialogCancelButton")).Add_Click({
        ([System.Windows.Controls.Grid]$asyncManager.GetWindowControl("OverlayDialogArea")).Visibility = "Collapsed"
        [Logger]::GetInstance().Debug("同期処理からログに出力しました。")
    })

    # OKボタン_Click
    ([System.Windows.Controls.Button]$asyncManager.GetWindowControl("DefaultDialogOkButton")).Add_Click({
        # パラメタ
        [pscustomobject] $param = New-Object psobject
        Add-Member -InputObject $param -MemberType NoteProperty -Name "SampleParam" -Value "パラメタ値です"

        # 処理
        $scriptblock = {
            param($asyncParamObject)
            try {
                [Logger]::GetInstance().Debug("非同期処理からログに出力しました。[$($asyncParamObject.SampleParam)]")

            } catch {
                [Logger]::GetInstance().Debug($PSItem)
                [Logger]::GetInstance().Debug("非同期スクリプトブロック処理実行に失敗しました。")
            }
        }
        # 非同期実行
        $asyncManager.InvokeAsync($scriptblock, $param)
    })
}