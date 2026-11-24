from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def test_one_click_launcher_starts_hidden_server_and_opens_kebbi_flow():
    batch = (ROOT / "start_kebbi.bat").read_text(encoding="utf-8")
    script = (ROOT / "scripts" / "start_kebbi_session.ps1").read_text(encoding="utf-8")

    assert "start_kebbi_session.ps1" in batch
    assert "-WindowStyle Hidden" in script
    assert '"http://127.0.0.1:8000/health"' in script
    assert "reverse tcp:8000 tcp:8000" in script
    assert '"http://127.0.0.1:8000/?kebbi=1"' in script
    assert 'Start-Process "http://localhost:8000/control"' in script


def test_launcher_prefers_kebbi_app_over_firefox():
    script = (ROOT / "scripts" / "start_kebbi_session.ps1").read_text(encoding="utf-8")
    assert '$kebbiApp = "tw.sarcopenia.kebbi"' in script
    assert "am force-stop org.mozilla.firefox" in script
    assert 'am start -n "$kebbiApp/.MainActivity"' in script
    assert "shell monkey" not in script


def test_launcher_does_not_add_breeze_dependency():
    requirements = (ROOT / "requirements.txt").read_text(encoding="utf-8").casefold()
    launcher = (ROOT / "scripts" / "start_kebbi_session.ps1").read_text(
        encoding="utf-8"
    ).casefold()

    assert "breeze" not in requirements
    assert "breeze" not in launcher


def test_portable_install_finds_bundled_tools_and_pins_packages():
    script = (ROOT / "scripts" / "start_kebbi_session.ps1").read_text(encoding="utf-8")
    assert r'Join-Path $projectRoot "tools\platform-tools\adb.exe"' in script
    capture = (ROOT / "webcam_capture.py").read_text(encoding="utf-8")
    assert 'bundled / "bin" / "ffmpeg.exe"' in capture

    installer = (ROOT / "install_windows.bat").read_bytes()
    assert b"\r\n" in installer and b"\n" not in installer.replace(b"\r\n", b"")
    # cmd 在 chcp 65001 下會誤解區塊內的多位元組字元，.bat 必須維持純 ASCII
    assert installer.isascii()
    assert b"install_windows.ps1" in installer
    setup = (ROOT / "scripts" / "install_windows.ps1").read_bytes()
    # PowerShell 5.1 需要 BOM 才會以 UTF-8 讀取中文訊息
    assert setup.startswith(b"\xef\xbb\xbf")
    assert b"requirements-lock.txt" in setup
    lock = (ROOT / "requirements-lock.txt").read_text(encoding="utf-8")
    for package in ("torch==", "mediapipe==", "fastapi==", "faster-whisper=="):
        assert package in lock
