# 输入时用灰字显示匹配的历史命令
Import-Module PSReadLine
Set-PSReadLineOption -PredictionSource History -PredictionViewStyle InlineView
Set-PSReadLineKeyHandler -Chord 'Alt+l' -Function AcceptSuggestion

# Tab 补全命令、参数和路径，有多个候选时显示菜单
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete

# 使用 dotfiles 里的 Tokyo Night 提示符
$env:STARSHIP_CONFIG = "$HOME\dotfiles\WSL\.config\starship.toml"
Invoke-Expression (&starship init powershell)

Set-Alias -Name lolcat -Value "$env:LOCALAPPDATA\Programs\expldfsh-lolcat\lolcat.exe"

$PSStyle.FileInfo.Directory = $PSStyle.Foreground.FromRgb(0x7DCFFF)

function f {
    fastfetch --pipe true --logo Windows | lolcat -f -b
}

function y {
    $cwdFile = (New-TemporaryFile).FullName
    try {
        $yaziArgs = $args
        if ($yaziArgs.Count -eq 0) {
            $yaziArgs = @($ExecutionContext.SessionState.Path.CurrentFileSystemLocation.ProviderPath)
        }
        yazi.exe @yaziArgs --cwd-file="$cwdFile"
        $target = Get-Content -LiteralPath $cwdFile -TotalCount 1 -Encoding utf8
        if ($target -and (Test-Path -LiteralPath $target -PathType Container)) {
            Set-Location -LiteralPath $target
        }
    }
    finally {
        Remove-Item -LiteralPath $cwdFile
    }
}

# 在普通 PowerShell 中首次使用 nmake 时加载 MSVC，并保留当前目录
function nmake {
    if (-not $env:VSCMD_VER -or -not (Get-Command nmake.exe -CommandType Application -ErrorAction SilentlyContinue)) {
        $vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
        $installDir = & $vswhere -latest -products '*' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
        if (-not $installDir) { throw '找不到 Visual Studio x64/x86 C++ 生成工具。' }

        $devShell = Join-Path $installDir 'Common7\Tools\Launch-VsDevShell.ps1'
        & $devShell -Arch amd64 -HostArch amd64 -SkipAutomaticLocation
    }
    nmake.exe @args
}

if (![Console]::IsInputRedirected -and ![Console]::IsOutputRedirected -and (Get-Command fastfetch -ErrorAction SilentlyContinue)) {
    f
}