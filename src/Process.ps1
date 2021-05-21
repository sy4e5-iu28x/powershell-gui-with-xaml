﻿using module ".\LogHelper.psm1"
using module ".\XamlHelper.psm1"
using module ".\Initialization.psm1"
using module ".\AsyncInvokeHelper.psm1"

Add-Type -AssemblyName PresentationFramework, PresentationCore

[AsyncManager]  $global:asyncManager

try{
    # ResourceDictionaryのSource絶対パス変換処理
    [xml] $appXaml = [ApplicationXamlHelper]::GetInstance().Initialize().ApplyResourceDicSouce().GetXmlDocument()
    
    [System.Xml.XmlNodeReader] $appReader = [System.Xml.XmlNodeReader]::new($appXaml)
    [System.Windows.Application] $app = [System.Windows.Markup.XamlReader]::Load($appReader)
    [Logger]::GetInstance().Debug("ApplicationインスタンスのLoadが完了しました。")

    [WindowXamlHelper] $windowXamlHelper = [WindowXamlHelper]::GetInstance().Initialize()
    # WindowTab定義の動的追加処理
    Initialize-WindowTabs -windowXamlHelper $windowXamlHelper
    # Dialog定義の動的追加処理
    Initialize-Dialogs -windowXamlHelper $windowXamlHelper

    [xml] $windowXaml = $windowXamlHelper.GetXmlDocument()
    [System.Xml.XmlNodeReader] $windowReader = [System.Xml.XmlNodeReader]::new($windowXaml)
    [System.Windows.Window] $window = [System.Windows.Markup.XamlReader]::Load($windowReader)
    [Logger]::GetInstance().Debug("WindowインスタンスのLoadが完了しました。")
    
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
    # ウィンドウ表示
    $app.run($window)
} catch {
    [Logger]::GetInstance().Debug($PSItem)
} finally {
    # 非同期RunspacePool終了
    $global:asyncManager.CloseRunspacePool()
}