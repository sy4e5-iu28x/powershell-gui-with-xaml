using module ".\LogHelper.psm1"
using module ".\XamlHelper.psm1"

Add-Type -AssemblyName PresentationFramework, PresentationCore

try{
    [string]$appXamlFilePath = ".\xaml\App.xaml"
    [ApplicationXamlHelper]$appXamlHelper = [ApplicationXamlHelper]::new($appXamlFilePath)
    # ResourceDictionaryのSource絶対パス変換処理
    [xml]$appXaml = $appXamlHelper.ApplyResourceDicSouce()
    [Logger]::GetInstance().Debug("ResourceDictionaryの絶対パス変換が完了しました。")
    
    [System.Xml.XmlNodeReader]$appReader = [System.Xml.XmlNodeReader]::new($appXaml)
    [System.Windows.Application]$app = [System.Windows.Markup.XamlReader]::Load($appReader)
    [Logger]::GetInstance().Debug("ApplicationインスタンスのLoadが完了しました。")

    [xml]$windowXaml = Get-Content -Encoding UTF8 .\xaml\Window.xaml
    [System.Xml.XmlNodeReader]$windowReader = [System.Xml.XmlNodeReader]::new($windowXaml)
    [System.Windows.Window]$window = [System.Windows.Markup.XamlReader]::Load($windowReader)
    
    $app.run($window)
} catch {
    [Logger]::GetInstance().Debug($PSItem)
}