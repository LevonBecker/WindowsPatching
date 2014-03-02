[array]$List = @()
[array]$List = Get-Content -Path "C:\Users\xlbecker\Documents\HostLists\2013-01-18\Default-GAQ.txt"

[array]$List01 = @()
[array]$List01 = For ($Item = 0;$Item -lt $List.Count;$Item += 2) {$List[$Item]}

[array]$List02 = @()
[array]$List02 = For ($Item = 1;$Item -lt $List.Count;$Item += 2) {$List[$Item]}

Out-File -InputObject $List01 -FilePath "C:\Users\xlbecker\Documents\HostLists\2013-01-18\Default-GAQ01.txt" -Encoding ASCII -Force
Out-File -InputObject $List02 -FilePath "C:\Users\xlbecker\Documents\HostLists\2013-01-18\Default-GAQ02.txt" -Encoding ASCII -Force

Write-Host ''
Write-Host 'Full List Item Count:   ' -NoNewline
$List.Count
Write-Host 'List 01 Item Count:     ' -NoNewline
$List01.Count
Write-Host 'List 02 Item Count:     ' -NoNewline
$List02.Count