# Скрипта за чистење непотребних фајлова на Windows 11 са извештајем о броју обрисаних ставки

# Функција која пребројава и уклања све ставке из дате локације, а затим исписује број обрисаних ставки.
function Remove-ItemsWithCount {
    param(
        [string]$TargetPath, # Путања до фасцикле (сав садржај ће бити обрисан)
        [string]$Description    # Опис локације (за испис)
    )
    # Додајемо ѕвезду (*) да би обрадили садржај фасцикле, а не саму фасциклу.
    $searchPath = $TargetPath + "*"
    
    # Пре бројања ставки, преузмимо све ставке рекурзивно
    $items = Get-ChildItem -Path $searchPath -Recurse -Force -ErrorAction SilentlyContinue
    $count = $items.Count
    
    if ($count -gt 0) {
        Remove-Item $searchPath -Recurse -Force -ErrorAction SilentlyContinue
    }
    Write-Output "$Description: Обрисано је $count ставки."
}

Write-Output "Почиње се чистење система..."

# 1. Чишћење привремених фајлова корисника
$tempPath = [System.IO.Path]::GetTempPath()
Write-Output "Чишћење привремених фајлова из: $tempPath"
Remove-ItemsWithCount -TargetPath $tempPath -Description "Привремени фајлови"

# 2. Чишћење Windows Temp директоријума
$windowsTemp = "C:\Windows\Temp\"
Write-Output "Чишћење Windows Temp директоријума: $windowsTemp"
Remove-ItemsWithCount -TargetPath $windowsTemp -Description "Windows Temp фајлови"

# 3. Испражњавање корпе за отпатке
Write-Output "Испражњавање корпе за отпатке..."
# Коришћење COM објекта за приступ корпи за отпатке
$shell = New-Object -ComObject Shell.Application
$binNamespace = $shell.Namespace(0xA)
$binItems = $binNamespace.Items()
$recycleCount = $binItems.Count

foreach ($item in $binItems) {
    Remove-Item $item.Path -Recurse -Force -ErrorAction SilentlyContinue
}
Write-Output "Корпа за отпатке: Обрисано је $recycleCount ставки."

Write-Output "Чишћење је завршено!"
