using module ".\LogHelper.psm1"
using module ".\XamlHelper.psm1"

Add-Type -AssemblyName PresentationFramework, PresentationCore

try{
    [string] $appXamlFilePath = ".\xaml\App.xaml"
    # ResourceDictionaryのSource絶対パス変換処理
    [ApplicationXamlHelper] $appXamlHelper = [ApplicationXamlHelper]::new($appXamlFilePath)
    [xml] $appXaml = $appXamlHelper.ApplyResourceDicSouce()
    [Logger]::GetInstance().Debug("ResourceDictionaryの絶対パス変換が完了しました。")
    
    [System.Xml.XmlNodeReader] $appReader = [System.Xml.XmlNodeReader]::new($appXaml)
    [System.Windows.Application] $app = [System.Windows.Markup.XamlReader]::Load($appReader)
    [Logger]::GetInstance().Debug("ApplicationインスタンスのLoadが完了しました。")

    [string] $windowXamlFilePath = ".\xaml\Window.xaml"
    # WindowTab定義の動的追加処理
    [WindowXamlHelper] $windowXamlHelper = [WindowXamlHelper]::new($windowXamlFilePath)
    $windowTabXamlFilePaths = @(
        ".\xaml\windowtabs\ManagementTabItem.xaml",
        ".\xaml\windowtabs\DefinitionTabItem.xaml",
        ".\xaml\windowtabs\ConfigurationTabItem.xaml"
    )
    $windowXamlHelper.ApplyWindowTabs($windowTabXamlFilePaths) 

    # Dialog定義の動的追加処理
    $dialogTabXamlFilePaths = @(
        ".\xaml\dialogs\DefaultTabItem.xaml"
    )
    [xml] $windowXaml = $windowXamlHelper.ApplyDialogs($dialogTabXamlFilePaths)

    [System.Xml.XmlNodeReader] $windowReader = [System.Xml.XmlNodeReader]::new($windowXaml)
    [System.Windows.Window] $window = [System.Windows.Markup.XamlReader]::Load($windowReader)
    
    $app.run($window)
} catch {
    [Logger]::GetInstance().Debug($PSItem)
}