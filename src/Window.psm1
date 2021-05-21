using module ".\LogHelper.psm1"
using module ".\AsyncInvokeHelper.psm1"
using module ".\XmlHelper.psm1"
Add-Type -AssemblyName PresentationFramework, PresentationCore

<#
.SYNOPSIS
ウィンドウ初期設定
#>
function Initialize-Window {
    param([AsyncManager] $asyncManager)
    # ウィンドウ ContentRendered .vbs実行時のウィンドウアクティブ化処理
    ([System.Windows.Window] $asyncManager.GetWindowControl("AppWindow")).Add_ContentRendered({
        ([System.Windows.Window] $asyncManager.GetWindowControl("AppWindow")).Activate()
        ([System.Windows.Controls.TabItem] $asyncManager.GetWindowControl("ManagementTabItem")).IsSelected = $true
    })
}