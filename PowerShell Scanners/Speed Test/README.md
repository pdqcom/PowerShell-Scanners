# Instructions
[How to use this repository](../../README.md)

# Description
Uses [Speedtest CLI](https://www.speedtest.net/apps/cli) to measure the target's internet connection.

Based on this script by Aaron: https://pdq-reddit.slack.com/archives/CGDC3CF1S/p1608059965030900

# Parameters
Name | Default Value | Description
---- | ------------- | -----------
MaxPacketLoss | 2 | The amount of packet loss (as a percentage) you are willing to tolerate.
MaxSpeedDifference | 20 | The amount of change in speed (as a percentage) from the previous test you are willing to tolerate.
MinDownloadSpeed | 25 | The lowest download speed (in Mbps) you are willing to tolerate.
MinUploadSpeed | 4 | The lowest upload speed (in Mbps) you are willing to tolerate.
DownloadUri | [See script](./Speed%20Test.ps1) | Where [Speedtest CLI](https://www.speedtest.net/apps/cli) will be downloaded from.
DownloadLocation | [See script](./Speed%20Test.ps1) | The folder on each target where files such as speedtest.exe and previous results will be stored.
Verbose | Enabled | Enables Verbose log messages. If you don't want Verbose messages in your Output Log, remove `-Verbose` from the Parameters field.

# Authors
* [Aaron](https://pdq-reddit.slack.com/team/UTJP0HF6E)
* Colby Bouma