$desktopPath = "C:\Users\*\Desktop\"

get-childitem $desktopPath -Recurse -Force -exclude *.ini, *.png, *.jpg -erroraction silentlycontinue
