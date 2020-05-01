# Description

Recursively scans every folder in `C:\Users`, then adds up the size of every file to get an approximate size for every user's profile.

This scanner may take a while to run!

## Parameters

```powershell
-In
```

Accepts 'KB','MB', or 'GB' and returns friendly size representative of the chosen increment, rounded to 2 decimal places.

Defaults to 'MB'.

## Sample Output

```powershell
FolderName    FolderPath                   Size FriendlySize
----------    ----------                   ---- ------------
Administrator C:\Users\Administrator  496406547 473.41 MB
All Users     C:\Users\All Users     7630976535 7277.47 MB
```

## Author

Nate Blevins