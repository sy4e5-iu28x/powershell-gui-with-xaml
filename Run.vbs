'.ps1コンソール非表示 実行スクリプト

Option Explicit

Dim objFSO
Dim objWshShell

Set objFSO = CreateObject("Scripting.FileSystemObject")
Set objWshShell = WScript.CreateObject("WScript.Shell")

'vbsファイルパス
Dim vbsSelfPath
'vbsファイルパスの格納ディレクトリパス
Dim currentDir
'srcディレクトリパス
Dim srcDir
'ps1ファイルパス
Dim ps1Path
'PowerShellコマンド
Dim psCmd

'.vbsと.ps1が同じディレクトリにある前提
vbsSelfPath = Wscript.ScriptFullName
currentDir = objFSO.GetFile(vbsSelfPath).ParentFolder
'.ps1パス
srcDir = objFSO.BuildPath(currentDir, "src")
ps1Path = objFSO.BuildPath(srcDir, "process.ps1")
'Powershellコマンド要素
psCmd = Join(Array("Powershell", "-NoProfile", "-ExecutionPolicy", "RemoteSigned", ps1Path), " ")

'起動コマンド, PowerShellコマンド, ウィンドウ非表示, powershellコマンド終了待ち合わせしない
objWshShell.Run psCmd, 0, false

'リソース開放
Set objFSO = Nothing
Set objWshShell = Nothing

Wscript.Quit