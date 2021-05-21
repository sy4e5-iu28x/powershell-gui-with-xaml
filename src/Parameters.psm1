class AppParameters {
    # アプリ設定ファイルパス
    static [string] $configXmlFilePath = "./xml/AppConfig.xml"
    # Xmlテンプレートファイルパス
    static [string] $templateFilePath = "./xml/NodeTemplate.xml"
    # アプリデータソースファイルパス
    static [string] $defaultDataSourceFilePath = "./xml/AppDataSource.xml"
    # ApplicationXamlファイルパス
    static [string] $appXamlFilePath = "./xaml/App.xaml"
    # WindowXamlファイルパス
    static [string] $windowXamlFilePath = "./xaml/Window.xaml"
    # 非同期実行RunspacePool最小数
    static [int] $minRunspaces = 1
    # 非同期実行RunspacePool最大数
    static [int] $maxRunspaces = 2
}