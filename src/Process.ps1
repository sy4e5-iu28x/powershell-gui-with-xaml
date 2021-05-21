using module ".\XamlHelper.psm1"
using module ".\LogHelper.psm1"

Add-Type -AssemblyName PresentationFramework, PresentationCore, System.Runtime

try{
    [string]$appXamlFilePath = ".\xaml\App.xaml"
    [ApplicationXamlHelper]$appXamlHelper = [ApplicationXamlHelper]::new($appXamlFilePath)
    # ResourceDictionaryのSource絶対パス変換処理
    [xml]$appXaml = $appXamlHelper.ApplyResourceDicSouce()

    [System.Xml.XmlNodeReader]$appReader = [System.Xml.XmlNodeReader]::new($appXaml)
    [System.Windows.Application]$app = [System.Windows.Markup.XamlReader]::Load($appReader)
    
    [xml]$windowXaml = Get-Content -Encoding UTF8 .\xaml\Window.xaml
    [System.Xml.XmlNodeReader]$windowReader = [System.Xml.XmlNodeReader]::new($windowXaml)
    [System.Windows.Window]$window = [System.Windows.Markup.XamlReader]::Load($windowReader)

    $app.run($window)
} catch {
    [Logger]::GetInstance().Debug($PSItem)
}