# 新電腦安裝：建立 .venv_phase3、安裝固定版本套件、檢查 FFmpeg 與 ADB、建立桌面捷徑。
[CmdletBinding()]
param([switch]$NoShortcut)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $projectRoot
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function Fail([string]$message) {
    Write-Host ""
    Write-Host $message -ForegroundColor Red
    Write-Host "安裝失敗，請把上方訊息截圖給組員。" -ForegroundColor Red
    exit 1
}

Write-Host "========================================"
Write-Host " 肌少症檢測系統 - 新電腦安裝"
Write-Host "========================================"

# 套件檔名很長，資料夾路徑太深會超過 Windows 260 字元限制而安裝失敗
$longPaths = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" -ErrorAction SilentlyContinue).LongPathsEnabled
if ($projectRoot.Length -gt 60 -and $longPaths -ne 1) {
    Fail "資料夾路徑太長（$($projectRoot.Length) 個字元）：$projectRoot`n請把整個資料夾移到較短的位置，例如 C:\Kebbi\，再重新執行。"
}

Write-Host "`n[1/4] 檢查 Python 3.12..."
$python = $null
foreach ($candidate in @(@("py", "-3.12"), @("python"))) {
    $exe = Get-Command $candidate[0] -ErrorAction SilentlyContinue
    if (-not $exe) { continue }
    $args312 = @($candidate | Select-Object -Skip 1) + @("-c", "import sys; sys.exit(0 if sys.version_info[:2] == (3, 12) else 1)")
    & $exe.Source @args312 2>$null
    if ($LASTEXITCODE -eq 0) { $python = @($exe.Source) + @($candidate | Select-Object -Skip 1); break }
}
if (-not $python) {
    Fail "找不到 Python 3.12。請到 https://www.python.org/downloads/ 安裝 3.12 版（勾選 Add python.exe to PATH），再重新執行。"
}
Write-Host "  使用 $($python -join ' ')"

Write-Host "`n[2/4] 建立虛擬環境 .venv_phase3..."
$venvPython = Join-Path $projectRoot ".venv_phase3\Scripts\python.exe"
if (Test-Path $venvPython) {
    Write-Host "  已存在，略過建立。"
} else {
    $pyArgs = @($python | Select-Object -Skip 1) + @("-m", "venv", ".venv_phase3")
    & $python[0] @pyArgs
    if ($LASTEXITCODE -ne 0) { Fail "建立虛擬環境失敗。" }
}

Write-Host "`n[3/4] 安裝套件（需要網路，約 5 至 15 分鐘）..."
& $venvPython -m pip install --upgrade pip
& $venvPython -m pip install -r requirements-lock.txt
if ($LASTEXITCODE -ne 0) { Fail "套件安裝失敗，請確認網路連線。" }

Write-Host "`n[4/4] 檢查 FFmpeg 與 ADB..."
$ffmpeg = & $venvPython -c "from webcam_capture import find_ffmpeg; print(find_ffmpeg(required=False) or '')"
if ($ffmpeg) {
    Write-Host "  FFmpeg：$ffmpeg"
} else {
    Write-Host "  找不到 FFmpeg，正在用 winget 安裝..." -ForegroundColor Yellow
    winget install --id Gyan.FFmpeg -e --accept-source-agreements --accept-package-agreements
    Write-Host "  若安裝成功，請關閉視窗後再執行一次本安裝檔確認。" -ForegroundColor Yellow
}
$adb = Join-Path $projectRoot "tools\platform-tools\adb.exe"
if (Test-Path $adb) {
    Write-Host "  ADB：$adb"
} elseif (Get-Command adb -ErrorAction SilentlyContinue) {
    Write-Host "  ADB：$((Get-Command adb).Source)"
} else {
    Write-Host "  找不到 ADB：請確認 tools\platform-tools 資料夾有一起複製過來。" -ForegroundColor Yellow
}

if (-not $NoShortcut) {
    $shortcutPath = Join-Path ([Environment]::GetFolderPath("Desktop")) "肌少症檢測系統.lnk"
    $shortcut = (New-Object -ComObject WScript.Shell).CreateShortcut($shortcutPath)
    $shortcut.TargetPath = Join-Path $projectRoot "start_kebbi.bat"
    $shortcut.WorkingDirectory = $projectRoot
    $shortcut.Save()
    Write-Host "`n已建立桌面捷徑「肌少症檢測系統」。"
}

Write-Host "`n========================================"
Write-Host " 安裝完成！接上凱比與 C922 後，"
Write-Host " 雙擊桌面「肌少症檢測系統」即可啟動。"
Write-Host "========================================"
