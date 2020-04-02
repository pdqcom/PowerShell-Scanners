# Downloading
## Git
The best way to use this repository is with Git. It makes updating very easy.

#### Setup
1. Install Git. We have a package for this in PDQ Deploy's Package Library ;)
1. Clone this repository to the root of your C drive. This is necessary because the PowerShell Scanner feature does not currently support variables.
    ```
    cd C:\
    git clone https://github.com/pdq/PowerShell-Scanners.git
    ```

#### Updating
1. Navigate to your clone of this repository.
1. Run a git pull.
    ```
    cd C:\PowerShell-Scanners
    git pull
    ```

## ZIP
An alternative download method if you can't/don't want to install Git.

#### Setup
1. Click the green "Clone or download" button toward the top-right of this page.
1. Click the "Download ZIP" link.
1. Save the ZIP anywhere you want.
1. Extract the contents of the ZIP to the root of your C drive. This is necessary because the PowerShell Scanner feature does not currently support variables.
1. Rename `PowerShell-Scanners-master` to `PowerShell-Scanners`.

#### Updating
Delete `C:\PowerShell-Scanners` (as long as you haven't edited anything!), then follow the Setup instructions again.

# Importing
Now that you have this repository downloaded, it's time to import the PowerShell Scanner profile(s) that you want!

1. In Inventory, go to Options --> Scan Profiles.
1. Click the Import button.
1. Navigate to the folder of the PowerShell Scanner you want, such as `C:\PowerShell-Scanners\PowerShell Scanners\Mapped Drives`.
1. Click on `Scan Profile.xml`.
1. Click the Open button.

That's it! To update your imported profile(s), follow the appropriate Updating section above. You shouldn't have to re-import any Scan Profiles unless you see a note telling you to in that profile's README file.