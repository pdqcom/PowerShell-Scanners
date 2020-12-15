# Contributing
Thank you for your interest in contributing to this project! 

Please abide by the [Code of Conduct](CODE_OF_CONDUCT.md) for all interactions with this repository.

## Pull Requests
Pull requests are the mechanism you can use to submit your PowerShell Scanners to this repository. GitHub itself has some [great documentation](https://help.github.com/articles/about-pull-requests/) on using the Pull Request feature. We use the "fork and pull" model [described here](https://help.github.com/articles/about-collaborative-development-models/), where contributors push changes to their personal fork and create pull requests to bring those changes into the source repository.

Please follow the [Style Guide](STYLE_GUIDE.md) when crafting your pull request.

All pull requests are reviewed by a PDQ.com employee. We'll try to get to your pull request as soon as we can, but please be patient.

#### Folder Structure
Each scanner gets its own folder. Give your folder a descriptive name. These are the expected files:

* Scan Profile.xml
  * This is a Scan Profile exported from Inventory as an XML file. It points to your .ps1 file with the File field.
* "Script".ps1
  * Replace "Script" with the same name you used for your folder.
* README.md
  * Put in as much detail as you think is necessary. Look at the other scanners for ideas.

## Bug Reports
If you discover a bug, please [search existing issues](https://github.com/pdq/PowerShell-Scanners/search?type=Issues) to see if it has already been reported.

When you [file your issue](https://github.com/pdq/PowerShell-Scanners/issues/new), please be as descriptive as possible. This helps other people search for your issue, and it helps us find and fix the issue as quickly as possible. Screenshots can be very helpful too!