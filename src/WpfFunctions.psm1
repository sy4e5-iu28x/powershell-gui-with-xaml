using module ".\LogHelper.psm1"
Add-Type -AssemblyName PresentationFramework, PresentationCore

<#
.SYNOPSIS
再帰的子要素コントロール取得

.PARAMETER parent
    探索対象

.PARAMETER targetControlType
    探索する型

.PARAMETER results
    結果格納用
#>
function Get-InnerControls {
    param($parent, [System.Type] $targetControlType, [System.Collections.ArrayList]$results)

    # 結果格納用リストがnullの場合生成する
    if($null -eq $results) {
        $results = [System.Collections.ArrayList]::new()
    }

    # 必須要素がnullの場合は空の結果を返す
    if($null -eq $parent -Or $null -eq $targetControlType) {
        return
    }

    # 該当する型か判定
    if($parent -is $targetControlType) {
        [Logger]::GetInstance().Debug("型が一致しました[$parent, $targetControlType]")
        $results.Add($parent)
    }

    [int]$childrenCount = [System.Windows.Media.VisualTreeHelper]::GetChildrenCount($parent)
    # 子要素を持つ場合、再帰処理
    if ($childrenCount -ne 0) {
        for($i=0; $i -lt $childrenCount; $i++) {
            $newParent = [System.Windows.Media.VisualTreeHelper]::GetChild($parent, $i)
            Get-InnerControls -parent $newParent -targetControlType $targetControlType -results $results
        }
    } 
}