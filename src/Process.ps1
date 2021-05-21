using module ".\LogHelper.psm1"
using module ".\XamlHelper.psm1"
using module ".\Initialization.psm1"
using module ".\AsyncInvokeHelper.psm1"

Add-Type -AssemblyName PresentationFramework, PresentationCore

# 非同期処理管理
[AsyncManager] $global:asyncManager
[Logger]$logger = [Logger]::GetInstance()

try{
    # ResourceDictionaryのSource絶対パス変換処理
    [xml] $appXaml = [ApplicationXamlHelper]::GetInstance().Initialize().ApplyResourceDicSouce().GetXmlDocument()
    
    [System.Xml.XmlNodeReader] $appReader = [System.Xml.XmlNodeReader]::new($appXaml)
    [System.Windows.Application] $app = [System.Windows.Markup.XamlReader]::Load($appReader)
    $logger.Debug("ApplicationインスタンスのLoadが完了しました。")

    [WindowXamlHelper] $windowXamlHelper = [WindowXamlHelper]::GetInstance().Initialize()
    # WindowTab定義の動的追加処理
    Initialize-XamlWindowTabs -windowXamlHelper $windowXamlHelper
    # Dialog定義の動的追加処理
    Initialize-XamlDialogs -windowXamlHelper $windowXamlHelper

    [xml] $windowXaml = $windowXamlHelper.GetXmlDocument()
    [System.Xml.XmlNodeReader] $windowReader = [System.Xml.XmlNodeReader]::new($windowXaml)
    [System.Windows.Window] $window = [System.Windows.Markup.XamlReader]::Load($windowReader)
    $logger.Debug("WindowインスタンスのLoadが完了しました。")
    
    # アプリ関連ファイル初期設定
    Initialize-AppFiles

    # 非同期処理初期設定
    $global:asyncManager = [AsyncManager]::GetInstance()
    $asyncInitParams = @{
        asyncManager = $global:asyncManager
        window = $window
    }
    Initialize-AsyncManager @asyncInitParams

    # 非同期RunspacePool開始
    $global:asyncManager.OpenRunspacePool()

    # ウィンドウコンポーネント初期設定
    Initialize-WindowComponents -asyncManager $global:asyncManager
    # ウィンドウ表示
    $app.run($window)
} catch {
    $logger.Debug($PSItem)
} finally {
    # 非同期RunspacePool終了
    $global:asyncManager.CloseRunspacePool()
    $logger.Close()
}