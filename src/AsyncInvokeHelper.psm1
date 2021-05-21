using module ".\LogHelper.psm1"
using module ".\XamlHelper.psm1"
using module ".\Parameters.psm1"

<#
.SYNOPSIS
非同期処理管理クラス
#>
class AsyncManager {
    
    Hidden static $instance
    # コントロール保持用
    Hidden [hashtable] $syncControlTable = [hashtable]::Synchronized(@{})
    # 非同期処理RunspacePool
    Hidden [System.Management.Automation.Runspaces.RunspacePool] $runspacePool

    <#
    .SYNOPSIS
    コンストラクタ
    #>
    Hidden AsyncManager() {}

    <#
    .SYNOPSIS
    インスタンス取得
    #>
    [AsyncManager] static GetInstance() {
        if($null -ne [AsyncManager]::instance) {
            [AsyncManager]::instance
        }
        [AsyncManager]::instance = [AsyncManager]::new()
        return [AsyncManager]::instance
    }

    <#
    .SYNOPSIS
    初期設定
    #>
    [AsyncManager] Initialize($parameterHost) {
        try {
            # 非同期スレッドから参照できる変数を追加
            [System.Management.Automation.Runspaces.SessionStateVariableEntry] $variable =
                [System.Management.Automation.Runspaces.SessionStateVariableEntry]::new('syncControlTable', $this.syncControlTable, $null)
            [System.Management.Automation.Runspaces.InitialSessionState] $initialSessionState = 
                [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
            $initialSessionState.Variables.Add($variable)

            # 非同期実行するRunspacePoolを生成
            $this.runspacePool = 
                [runspacefactory]::CreateRunspacePool([AppParameters]::minRunspaces, [AppParameters]::maxRunspaces ,$initialSessionState, $parameterHost)
            $this.runspacePool.ApartmentState = "STA"
            $this.runspacePool.ThreadOptions = "ReuseThread"
            return $this
        } catch {
            [Logger]::GetInstance().Debug($PSItem)
            [Logger]::GetInstance().Debug("非同期処理管理の初期設定に失敗しました。")
            return $this
        }
    }

    <#
    .SYNOPSIS
    コントロールを同期ハッシュテーブルへ追加する
    #>
    AddWindowControl($key, $object) {
        $this.syncControlTable.$key = $object
    }

    <#
    .SYNOPSIS
    コントロールを同期ハッシュテーブルから取得する
    #>
    [object] GetWindowControl($key) {
        return $this.syncControlTable.$key
    }

    <#
    .SYNOPSIS
    RunspacePoolを開始する
    #>
    OpenRunspacePool() {
        if($null -ne $this.runspacePool) {
            $this.runspacePool.Open()
            [Logger]::GetInstance().Debug("非同期処理RunspacePoolを開始しました。")
        }
    }

    <#
    .SYNOPSIS
    RunspacePoolを終了する
    #>
    CloseRunspacePool() {
        if($null -ne $this.runspacePool) {
            $this.runspacePool.Close()
            [Logger]::GetInstance().Debug("非同期処理RunspacePoolを終了しました。")
        }
    }
}