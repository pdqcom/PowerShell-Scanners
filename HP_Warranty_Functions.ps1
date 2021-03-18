<#
    .DESCRIPTION
        Using HP's warranty API (beta) to get warranty information on computer system.

        To use this script, a valid HP developer API is required, and have to be enrolled CSS (https://developers.hp.com/css-enroll).
#>
function Get-AuthorizationToken {
    <#
        .DESCRIPTION
            Using the APIKey and APISecret, this will retrieve a token that'll be required for every call made to the developer API.

        .EXAMPLE
            Get-AuthorizationToken -APIKey "randomstufff" -APISecret "anotherrandomstuff" -APIVersion "1"
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)]
        [ValidateSet(1,2)]
        [Int]$APIVersion = 1,
        [Parameter(Mandatory=$false)]
        [String]$OAuthURI = "https://css.api.hp.com/oauth/v$APIVersion/token",
        [Parameter(Mandatory=$true)]
        [String]$APIKey,
        [Parameter(Mandatory=$true)]
        [String]$APISecret
    )
    begin {
        $Body = "apiKey=$APIKey&apiSecret=$APISecret&grantType=client_credentials&scope=warranty"
        $PostParams = @{
            Headers = @{
                Accept = "application/json"
            }
            ContentType = "application/x-www-form-urlencoded; charset=utf-8"
            URI = $OAuthURI
            Body = [System.Text.Encoding]::UTF8.GetBytes($Body)
            Method = "post"
        }
    }
    process {
        $Result = (Invoke-WebRequest @PostParams).Content | ConvertFrom-Json
        $Result.access_token
    }
    end {
        Write-Verbose "Ending."
    }
}
function Submit-WarrantyRequestJob {
    <#
        .DESCRIPTION
            Takes an array of SerialNumber with the format of:

            sn: 1CG1111Z1Z
            pn: T6F46UT

            Where "sn" is the serial number of the machine, and the "pn" is the product type without the #ABA/#ABC. This will accept up to 5000 serial numbers.

        .EXAMPLE
            Submit-WarrantyRequestJob -BearerAccessToken $BearerAccessToken -SerialNumbers $SerialNumbers -APIVersion "2" | ConvertFrom-Json

            The JobID that is returned from that request is need to check on the status of the job, and also to retreive the warranty information. This also returns the approximate time that it'll take to get all the warranty information. This number is greatly exaggerated, so Get-WarrantyRequestJobStatus should be use to check completion of the job instead of relying on the approximate time. But note that there is a 100 API limit, so don't use Get-WarrantyRequestJobStatus too much, or else you'll run out of your alloted API calls for the day.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)]
        [ValidateSet(1,2)]
        [Int]$APIVersion = 1,
        [Parameter(Mandatory=$false)]
        [String]$WarrantyJobURI = "https://css.api.hp.com/productWarranty/v$APIVersion/jobs",
        [Parameter(Mandatory=$true)]
        [String]$BearerAccessToken,
        [Parameter(Mandatory=$true)]
        [System.Array]$SerialNumbers
    )
    begin {
        $Authorization = "Bearer $BearerAccessToken"
        $Body = $SerialNumbers | ConvertTo-Json
        $PostParams = @{
            ContentType = "application/json; charset=utf-8"
            URI = $WarrantyJobURI
            Header = @{
                Authorization = $Authorization
                Accept = "application/json"
            }
            Method = "post"
            Body = [System.Text.Encoding]::UTF8.GetBytes($Body)
        }
    }
    process {
        Invoke-WebRequest @PostParams
    }
    end {
        Write-Verbose "Ending."
    }
}
function Get-WarrantyRequestJobStatus {
    <#
        .DESCRIPTION
            Requires the JobID from Submit-WarrantyRequestJob to get the status of the job.

        .EXAMPLE
            $WarrantyJobStatus = (Get-WarrantyRequestJobStatus @WarrantyJobStatusParams).Content | ConvertFrom-Json
            $WarrantyJobStatus.status
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [ValidateSet(1,2)]
        [Int]$APIVersion = 1,
        [Parameter(Mandatory=$false)]
        [String]$WarrantyJobStatusURI = "https://css.api.hp.com/productWarranty/v$APIVersion/jobs/",
        [Parameter(Mandatory=$true)]
        [String]$JobID,
        [Parameter(Mandatory=$true)]
        [String]$BearerAccessToken
    )
    begin {
        $URI = $WarrantyJobStatusURI + "$JobID"
        $Authorization = "Bearer $BearerAccessToken"
        $GetParams = @{
            URI = $URI
            Header   = @{
                Authorization = $Authorization
                Accept = "application/json"
            }
            Method = "get"
        }
    }
    process {
        Invoke-WebRequest @GetParams
    }
    end {
        Write-Verbose "Ending."
    }
}
function Receive-WarrantyRequestJob {
    <#
        .DESCRIPTION
            This requires the JobID as well.

        .EXAMPLE
            $AllWarrantyStatus = (Receive-WarrantyRequestJob -JobID $SubmitJob.jobId -BearerAccessToken $BearerAccessToken -APIVersion "2").Content | ConvertFrom-Json
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [ValidateSet(1,2)]
        [Int]$APIVersion = 1,
        [Parameter(Mandatory=$false)]
        [String]$WarrantyJobStatusURI = "https://css.api.hp.com/productWarranty/v$APIVersion/jobs/",
        [Parameter(Mandatory=$true)]
        [String]$JobID,
        [Parameter(Mandatory=$true)]
        [String]$BearerAccessToken
    )
    begin {
        $URI = $WarrantyJobStatusURI + "$JobID/results"
        $Authorization = "Bearer $BearerAccessToken"
        $GetParams = @{
            URI = $URI
            Header   = @{
                Authorization = $Authorization
                Accept = "application/json"
            }
            Method = "get"
        }
    }
    process {
        Invoke-WebRequest @GetParams
    }
    end {
        Write-Verbose "Ending."
    }
}
function Get-WarrantyStatus {
    <#
        .DESCRIPTION
            This is for a single serial number, so it's strongly recommended that this shouldn't be used because of the low API call limits.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [ValidateSet(1,2)]
        [Int]$APIVersion = 1,
        [Parameter(Mandatory=$false)]
        [String]$URI = "https://css.api.hp.com/productWarranty/v$APIVersion/queries",
        [Parameter(Mandatory=$true)]
        [String]$SerialNumber,
        [Parameter(Mandatory=$true)]
        [String]$ProductNumber,
        [Parameter(Mandatory=$true)]
        [String]$BearerAccessToken
    )
    begin {
        $Authorization = "Bearer $BearerAccessToken"
        $Body = ConvertTo-Json -InputObject @(
            @{
                sn = $SerialNumber
                pn = $ProductNumber
            }
        )
        $PostParams = @{
            URI = $URI
            Header   = @{
                Authorization = $Authorization
                Accept = "application/json"
            }
            Method = "post"
            Body = [System.Text.Encoding]::UTF8.GetBytes($Body)
            ContentType = "application/json; charset=utf-8"
        }
    }
    process {
        (Invoke-WebRequest @PostParams).Content | ConvertFrom-Json
    }
    end {
        Write-Verbose "Ending."
    }
}