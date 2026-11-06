# Poor Man's Nmap

## Instructions

[How to use this repository](../../README.md)

## Description

Does a simple port scan over devices on the local network, based on the common default ports of usual
services.

Serves as a simple port scanner without needing to use something like [nmap](https://nmap.org/download).

The scanner:

1. Auto-detects the active local IPv4 subnet using `Get-NetIPConfiguration` (the adapter that is `Up` and has a default gateway).
2. Runs a parallel ICMP sweep across the subnet to find live hosts.
3. TCP-connect probes a set of common service ports on each live host.
4. Enriches every listening host with its hostname (via DNS) and MAC address (via `Get-NetNeighbor`, falling back to `arp`).

One object is emitted per listening host, so the scanner maps the properties to columns. Hosts with no
open ports are skipped.

The following common ports/services are scanned by default:

`21/ftp`, `22/ssh`, `23/telnet`, `25/smtp`, `53/dns`, `80/http`, `110/pop3`, `135/msrpc`, `139/netbios`,
`143/imap`, `389/ldap`, `443/https`, `445/smb`, `587/submission`, `993/imaps`, `995/pop3s`, `1433/mssql`,
`3306/mysql`, `3389/rdp`, `5432/postgres`, `5900/vnc`, `8080/http-alt`, `8443/https-alt`

## Requirements

* The device running the scan must have an active IPv4 adapter with a default gateway.
* Network and host firewalls must permit outbound ICMP and TCP connections for results to be accurate.

This scanner takes no parameters. Configuration (the list of ports in `$Ports` and the per-probe
`$TimeoutMs`) is edited directly in `Script.ps1`.

## Compatibility

* PDQ Connect

## Output

| Column | Description |
| --- | --- |
| `IPAddress` | The IPv4 address of the listening host. |
| `Hostname` | The DNS hostname of the host, if it could be resolved. |
| `MAC` | The MAC (link-layer) address of the host, if available. |
| `OpenPorts` | A comma-separated list of the open ports and their service names (e.g. `80/http, 443/https`). |

## Author

* Bogdan Calapod  
