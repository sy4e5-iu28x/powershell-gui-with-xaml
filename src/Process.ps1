Add-Type -AssemblyName PresentationFramework, PresentationCore

[xml]$appXaml = Get-Content -Encoding UTF8 .\xaml\App.xaml
[xml]$windowXaml = Get-Content -Encoding UTF8 .\xaml\Window.xaml

[System.Xml.XmlNodeReader]$appReader = [System.Xml.XmlNodeReader]::new($appXaml)
[System.Windows.Application]$app = [System.Windows.Markup.XamlReader]::Load($appReader)

[System.Xml.XmlNodeReader]$windowReader = [System.Xml.XmlNodeReader]::new($windowXaml)
[System.Windows.Window]$window = [System.Windows.Markup.XamlReader]::Load($windowReader)

$app.run($window)