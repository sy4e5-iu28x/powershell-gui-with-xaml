<#
.SYNOPSIS
ログ出力クラス
#>
class Logger {
    # ログファイル名
    Hidden $filename = "./logger_debug.log"
    # ログ名
    Hidden $logName = "DebugLog"

    # シングルトン
    Hidden static $instance
    <#
    .SYNOPSIS
    コンストラクタ
    #>
    Hidden Logger() {
        [System.Diagnostics.TextWriterTraceListener]$twTraceListener = 
            [System.Diagnostics.TextWriterTraceListener]::new($this.filename, $this.logName)
        [System.Diagnostics.Trace]::Listeners.Add($twTraceListener)
        [System.Diagnostics.Trace]::AutoFlush = $true
    }

    <#
    .SYNOPSIS
    インスタンス取得処理
    #>
    static [Logger]GetInstance() {
        if($null -ne [Logger]::instance) {
            return [Logger]::instance
        }

        [Logger]::instance = [Logger]::new()
        return [Logger]::instance
    }

    <#
    .SYNOPSIS
    デバッグログ出力(メッセージ)

    .PARAMETER message
    メッセージ
    #>
    Debug([string]$message) {
        [System.Diagnostics.Debug]::WriteLine($message)
    }

    <#
    .SYNOPSIS
    デバッグログ出力(オブジェクト)

    .PARAMETER object
    対象のオブジェクト
    #>
    Debug([System.Object]$object) {
        [System.Diagnostics.Debug]::WriteLine($object.ToString())
    }

    <#
    .SYNOPSIS
    デバッグログ出力(例外情報出力)

    .PARAMETER errorRecord
    例外情報
    #>
    Debug([System.Management.Automation.ErrorRecord]$errorRecord) {
        $this.Debug($PSItem.Exception.InnerException)
        $this.Debug($PSItem.ScriptStackTrace)
        $this.Debug($PSItem.Exception.StackTrace) 
        $this.Debug($PSItem.Exception.Message)
        $this.Debug($PSItem.InvocationInfo)
    }
}