# PowerShell Scanners

## Table of Contents

- [PowerShell Scanners](#powershell-scanners)
  - [Table of Contents](#table-of-contents)
  - [Downloading](#downloading)
    - [Git](#git)
      - [Setup](#setup)
      - [Updating](#updating)
    - [ZIP](#zip)
      - [Setup](#setup-1)
      - [Updating](#updating-1)
  - [Scanner Compatibility](#scanner-compatibility)
    - [Inventory and Connect matrix](#inventory-and-connect-matrix)
    - [Connect issue queue](#connect-issue-queue)
      - [Needs a Connect version](#needs-a-connect-version)
      - [Needs testing or a final call](#needs-testing-or-a-final-call)
    - [Contributing to Connect support](#contributing-to-connect-support)
  - [Importing](#importing)
  - [Using in PDQ Connect](#using-in-pdq-connect)
  - [Contributing](#contributing)

## Downloading

### Git

The best way to use this repository is with Git. It makes updating very easy and allows you to contribute your own PowerShell scanners or fixes.

#### Setup

1. Install Git. We have a package for this in [PDQ Deploy](https://www.pdq.com/pdq-deploy/)'s [Package Library](https://www.pdq.com/package-library/) ;)
1. Clone this repository to the root of your C drive. This is necessary because the [PowerShell Scanner](https://link.pdq.com/docs-inventory?powershell-scanner.htm) feature does not currently support variables, and all paths assume `C:\PowerShell-Scanners`.

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

### ZIP

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

## Scanner Compatibility

Every scanner listed below is built for PDQ Inventory. The table also mirrors the current PDQ Connect note from each scanner README so you can quickly see what is confirmed, what needs testing, and what still needs a Connect-specific version.

### Inventory and Connect matrix

| Scanner | PDQ Inventory | PDQ Connect |
| --- | --- | --- |
| [AutoPilot Hash](PowerShell%20Scanners/AutoPilot%20Hash/README.md) | Yes | Yes |
| [Battery Status](PowerShell%20Scanners/Battery%20Status/README.md) | Yes | Maybe |
| [BitLocker Information](PowerShell%20Scanners/BitLocker%20Information/README.md) | Yes | Yes |
| [Cellular Adapter Info](PowerShell%20Scanners/Cellular%20Adapter%20Info/README.md) | Yes | Maybe |
| [Certificates](PowerShell%20Scanners/Certificates/README.md) | Yes | Yes, but output needs to be trimmed |
| [Chromium-based Browser Extensions](PowerShell%20Scanners/Chromium-based%20Browser%20Extensions/README.md) | Yes | Yes |
| [Cipher Suite Detection](PowerShell%20Scanners/Cipher%20Suite%20Detection/README.md) | Yes | Yes |
| [Dell BIOS Information](PowerShell%20Scanners/Dell%20BIOS%20Information/README.md) | Yes | No |
| [DNS Servers](PowerShell%20Scanners/DNS%20Servers/README.md) | Yes | Yes |
| [File Hash](PowerShell%20Scanners/File%20Hash/README.md) | Yes | No - different version needed |
| [Get Available Windows Updates](PowerShell%20Scanners/Get%20Available%20Windows%20Updates/README.md) | Yes | No, working on a version that does |
| [Get CDP Neighbor Data](PowerShell%20Scanners/Get%20CDP%20Neighbor%20Data/README.md) | Yes | No, but it's possible |
| [Get Chocolatey Packages](PowerShell%20Scanners/Get%20Chocolatey%20Packages/README.md) | Yes | Maybe |
| [Get Windows Update History](PowerShell%20Scanners/Get%20Windows%20Update%20History/README.md) | Yes | No, but i think it's possible |
| [Get-ScheduledTasksActions](PowerShell%20Scanners/Get-ScheduledTasksActions/README.md) | Yes | Yes, but Connect version probably needs ot output less |
| [Hardware Hash](PowerShell%20Scanners/Hardware%20Hash/README.md) | Yes | Yes |
| [Hosts File](PowerShell%20Scanners/Hosts%20File/README.md) | Yes | Yes, check more first |
| [IIS App Pools](PowerShell%20Scanners/IIS%20App%20Pools/README.md) | Yes | probably on your IIS servers |
| [Important Events](PowerShell%20Scanners/Important%20Events/README.md) | Yes | Yes |
| [LLMNR Enabled](PowerShell%20Scanners/LLMNR%20Enabled/README.md) | Yes | Yes |
| [Mapped Drives](PowerShell%20Scanners/Mapped%20Drives/README.md) | Yes | I think it does, gotta test |
| [Mapped Printers](PowerShell%20Scanners/Mapped%20Printers/README.md) | Yes | maybe |
| [Mozilla Firefox Extensions](PowerShell%20Scanners/Mozilla%20Firefox%20Extensions/README.md) | Yes | Yes |
| [PowerShell Modules](PowerShell%20Scanners/PowerShell%20Modules/README.md) | Yes | Yes |
| [RDP Last Logoff](PowerShell%20Scanners/RDP%20Last%20Logoff/README.md) | Yes | Yes |
| [RSOP (Basic GPO Information)](PowerShell%20Scanners/RSOP%20(Basic%20GPO%20Information)/Readme.md) | Yes | Yes |
| [SMB Connections](PowerShell%20Scanners/SMB%20Connections/README.md) | Yes | No, but maybe |
| [SQL Server Databases](PowerShell%20Scanners/SQL%20Server%20Databases/README.md) | Yes | No, but test |
| [System Stability](PowerShell%20Scanners/System%20Stability/README.md) | Yes | Yes |
| [Unsigned Drivers](PowerShell%20Scanners/Unsigned%20Drivers/README.md) | Yes | Yes |
| [User AD Groups](PowerShell%20Scanners/User%20AD%20Groups/README.md) | Yes | No |
| [User Last Logged On](PowerShell%20Scanners/User%20Last%20Logged%20On/README.md) | Yes | Yes |
| [User Profile Size](PowerShell%20Scanners/User%20Profile%20Size/README.md) | Yes | Yes |
| [User Sessions](PowerShell%20Scanners/User%20Sessions/README.md) | Yes | Yes |
| [Windows Defender Information](PowerShell%20Scanners/Windows%20Defender%20Information/README.md) | Yes | Yes |
| [Windows Defender Threats](PowerShell%20Scanners/Windows%20Defender%20Threats/README.md) | Yes | Yes but test |
| [Windows Firewall Rules](PowerShell%20Scanners/Windows%20Firewall%20Rules/README.md) | Yes | Yes |
| [Windows Update Last Installed](PowerShell%20Scanners/Windows%20Update%20Last%20Installed/README.md) | Yes | No, but maybe possible |
| [WizTree - Largest Files](PowerShell%20Scanners/WizTree%20-%20Largest%20Files/README.md) | Yes | No |
| [WizTree - User Profiles](PowerShell%20Scanners/WizTree%20-%20User%20Profiles/README.md) | Yes | No |

### Connect issue queue

If you want to help with PDQ Connect coverage, start with the scanners below.

Use the `connect` label for scanners that still need a Connect-specific version, `needs-testing` for scanners that already look promising but need validation in PDQ Connect, and `help-wanted` when you want to signal that contributors can jump in. If a scanner turns out not to be a good fit for Connect, close the issue with the reason and link any test output.

#### Needs a Connect version

* [Dell BIOS Information](PowerShell%20Scanners/Dell%20BIOS%20Information/README.md)
* [File Hash](PowerShell%20Scanners/File%20Hash/README.md)
* [Get Available Windows Updates](PowerShell%20Scanners/Get%20Available%20Windows%20Updates/README.md)
* [Get CDP Neighbor Data](PowerShell%20Scanners/Get%20CDP%20Neighbor%20Data/README.md)
* [Get Windows Update History](PowerShell%20Scanners/Get%20Windows%20Update%20History/README.md)
* [SMB Connections](PowerShell%20Scanners/SMB%20Connections/README.md)
* [SQL Server Databases](PowerShell%20Scanners/SQL%20Server%20Databases/README.md)
* [User AD Groups](PowerShell%20Scanners/User%20AD%20Groups/README.md)
* [Windows Update Last Installed](PowerShell%20Scanners/Windows%20Update%20Last%20Installed/README.md)
* [WizTree - Largest Files](PowerShell%20Scanners/WizTree%20-%20Largest%20Files/README.md)
* [WizTree - User Profiles](PowerShell%20Scanners/WizTree%20-%20User%20Profiles/README.md)

#### Needs testing or a final call

* [Battery Status](PowerShell%20Scanners/Battery%20Status/README.md)
* [Cellular Adapter Info](PowerShell%20Scanners/Cellular%20Adapter%20Info/README.md)
* [Certificates](PowerShell%20Scanners/Certificates/README.md)
* [Get Chocolatey Packages](PowerShell%20Scanners/Get%20Chocolatey%20Packages/README.md)
* [Get-ScheduledTasksActions](PowerShell%20Scanners/Get-ScheduledTasksActions/README.md)
* [Hosts File](PowerShell%20Scanners/Hosts%20File/README.md)
* [IIS App Pools](PowerShell%20Scanners/IIS%20App%20Pools/README.md)
* [Mapped Drives](PowerShell%20Scanners/Mapped%20Drives/README.md)
* [Mapped Printers](PowerShell%20Scanners/Mapped%20Printers/README.md)
* [Windows Defender Threats](PowerShell%20Scanners/Windows%20Defender%20Threats/README.md)

### Contributing to Connect support

When you pick up a scanner for PDQ Connect, try this workflow:

1. Create or claim an issue with the `connect` or `needs-testing` label.
1. Build or update a `Connect-<ScannerName>.ps1` script.
1. Test it in PDQ Connect against a real device or a safe test target.
1. Trim output if Connect needs less data than Inventory.
1. Close the issue with your findings if the scanner cannot be made Connect-safe.

If you need help with scripting, Git, or GitHub workflow, jump into [discord.gg/pdq](https://discord.gg/pdq) and ask in the `powershell-scripting` channel.

## Importing

Now that you have this repository downloaded, it's time to import the PowerShell Scanner profile(s) that you want!

1. Open [PDQ Inventory](https://www.pdq.com/pdq-inventory/) (version 19.0.40.0 or later).
1. Go to `File > Import`.
1. Navigate to the folder of the PowerShell Scanner you want, such as `C:\PowerShell-Scanners\PowerShell Scanners\Mapped Drives`.
1. Click on `Scan Profile.xml`.
1. Click the Open button.

That's it! To update your imported profile(s), follow the appropriate Updating section above. You shouldn't have to re-import any Scan Profiles unless you see a note telling you to in that profile's README file.

## Using in PDQ Connect

Pick a scanner from the compatibility matrix above, check its README for any parameter notes, then copy the PowerShell code from the scanner's `.ps1` file into a PDQ Connect Run PowerShell script action.

For scanners that still need Connect work, use the issue queue above to track the missing version or the test result before closing it out.

## Contributing

If you have created a PowerShell Scanner that you would like to add to this repository, please read the [Contributing guide](CONTRIBUTING.md).
