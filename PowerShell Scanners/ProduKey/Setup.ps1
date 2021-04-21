# Disable progress bars.
$ProgressPreference = 'SilentlyContinue'

Remove-Item -Path '.\ProduKey.exe' -ErrorAction 'SilentlyContinue'

[System.Net.WebClient]::new().DownloadFile('https://www.nirsoft.net/utils/produkey.zip', "$PWD\produkey.zip")

Expand-Archive -Path '.\produkey.zip' -DestinationPath .

Remove-Item -Path '.\produkey.zip', '.\ProduKey.chm', '.\readme.txt'