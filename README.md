# Table of contents
* [Downloading](#Downloading)
  * [Git](#Git)
  * [ZIP](#ZIP)
* [Importing](#Importing)
* [Contributing](#Contributing)

# Downloading
## Git
The best way to use this repository is with Git. It makes updating very easy and allows you to contribute your own PowerShell scanners or fixes.

#### Setup
1. Install Git. We have a package for this in [PDQ Deploy](https://www.pdq.com/pdq-deploy/)'s [Package Library](https://www.pdq.com/package-library/) ;)
1. Clone this repository to the root of your C drive. This is necessary because the [PowerShell Scanner](https://link.pdq.com/docs-inventory?powershell-scanner.htm) feature does not currently support variables all will assume `C:\PowerShell-Scanners`.
```PowerShell
git clone https://github.com/pdq/PowerShell-Scanners.git C:\PowerShell-Scanners
```

#### Updating
1. Navigate to your clone of this repository.
1. Run `git pull`.
```PowerShell
cd C:\PowerShell-Scanners
git pull
```

## ZIP
An alternative download method if you can't/don't want to install Git.

#### Setup
1. Click the green "Code" button toward the top-right of this page.
1. Click the "Download ZIP" link.
1. Save the ZIP anywhere you want.
1. Extract the contents of the ZIP to the root of your C drive. This is necessary because the PowerShell Scanner feature does not currently support variables.
1. Rename `PowerShell-Scanners-master` to `PowerShell-Scanners`.

#### Updating
1. Delete `C:\PowerShell-Scanners` (as long as you haven't edited anything!).
1. Follow the Setup instructions again.

# Importing
Now that you have this repository downloaded, it's time to import the PowerShell Scanner profile(s) that you want!

1. In [PDQ Inventory](https://www.pdq.com/pdq-inventory/) (version 19.0.40.0 or later), go to Computer --> Scan Profiles.
1. Click the Import button.
1. Navigate to the folder of the PowerShell Scanner you want, such as `C:\PowerShell-Scanners\PowerShell Scanners\Mapped Drives`.
1. Click on `Scan Profile.xml`.
1. Click the Open button.

That's it! To update your imported profile(s), follow the appropriate Updating section above. You shouldn't have to re-import any Scan Profiles unless you see a note telling you to in that profile's README file.

# Contributing
If you have created a PowerShell Scanner that you would like to add to this repository, please read the [Contributing guide](CONTRIBUTING.md).
