using module ".\LogHelper.psm1"
using module ".\XamlHelper.psm1"
using module ".\Parameters.psm1"

<#
.SYNOPSIS
非同期処理管理クラス
#>
class AsyncManager {
    # シングルトン
    Hidden static $instance
    # コントロール保持用
    Hidden [hashtable] $syncControlTable = [hashtable]::Synchronized(@{})
    # 非同期処理RunspacePool
    Hidden [System.Management.Automation.Runspaces.RunspacePool] $runspacePool
    # Logger
    Hidden [Logger] $logger = [Logger]::GetInstance()
    
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
            $this.logger.Debug($PSItem)
            $this.logger.Debug("非同期処理管理の初期設定に失敗しました。")
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
        try{
            if($null -ne $this.runspacePool) {
                $this.runspacePool.Open()
                $this.logger.Debug("非同期処理RunspacePoolを開始しました。")
            }
        } catch {
            $this.logger.Debug($PSItem)
            $this.logger.Debug("非同期処理RunspacePool開始に失敗しました。[$($this.runspacePool)]")
        }
    }

    <#
    .SYNOPSIS
    RunspacePoolを終了する
    #>
    CloseRunspacePool() {
        try {
            if($null -ne $this.runspacePool) {
                $this.runspacePool.Close()
                $this.runspacePool.Dispose()
                $this.logger.Debug("非同期処理RunspacePoolを終了しました。")
            }
        } catch {
            $this.logger.Debug($PSItem)
            $this.logger.Debug("非同期処理RunspacePool終了に失敗しました。[$($this.runspacePool)]")
        }
    }

    <#
    .SYNOPSIS
    ScriptBlockをasyncParamsオブジェクトをパラメタとして実行する。
    #>
    InvokeAsync([System.Management.Automation.ScriptBlock]$scriptBlock, [pscustomobject]$asyncParamObject) {
        [System.Management.Automation.PowerShell]$psCmd = $null
        try{
            $psCmd = [System.Management.Automation.PowerShell]::Create()

            # 使用するモジュールをすべて記述
            $psCmd.AddScript("using module ${PSScriptRoot}/LogHelper.psm1")
            $psCmd.AddScript("using module ${PSScriptRoot}/XmlHelper.psm1")
            # ScriptBlock実行記述
            $psCmd.AddCommand("Invoke-Command")
            [System.Management.Automation.ScriptBlock]$sb = [System.Management.Automation.ScriptBlock]::Create($scriptBlock)
            $psCmd.AddParameter("ScriptBlock", $sb)
            # ScriptBlockのparamに設定するpscustomobject設定
            $psCmd.AddParameter("ArgumentList", @($asyncParamObject))
            $psCmd.RunspacePool = $this.runspacePool

            $psCmd.BeginInvoke()
        } catch {
            $this.logger.Debug($PSItem)
            $this.logger.Debug("非同期処理実行に失敗しました。[${psCmd}]")
        }
    }
}