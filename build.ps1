if (Test-Path balls.love) {
    Remove-Item balls.love
}
7z a balls.love -tzip -mx9 *.lua
