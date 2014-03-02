net stop wuauserv
REG DELETE "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate" /v AccountDomainSid /f
REG DELETE "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate" /v PingID /f
REG DELETE "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate" /v SusClientId /f
REG DELETE "HKLM\Software\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update" /v LastWaitTimeout /f
REG DELETE "HKLM\Software\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update" /v DetectionStartTime /f
REG DELETE "HKLM\Software\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update" /v NextDetectionTime /f
REG DELETE "HKLM\Software\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update" /v AUState /f
net start wuauserv
wuauclt /resetauthorization /detectnow