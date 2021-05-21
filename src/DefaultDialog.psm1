using module ".\LogHelper.psm1"
using module ".\AsyncInvokeHelper.psm1"
using module ".\XmlHelper.psm1"
Add-Type -AssemblyName PresentationFramework, PresentationCore

function Initialize-DefaultDialog {
    param([AsyncManager] $asyncManager)
    
    ([System.Windows.Controls.Button]$asyncManager.GetWindowControl("DefaultDialogCancelButton")).Add_Click({
        ([System.Windows.Controls.Grid]$asyncManager.GetWindowControl("OverlayDialogArea")).Visibility = "Collapsed"
    })
}