<#
.SYNOPSIS
Creates an authentication header for MISP API.

.DESCRIPTION
The New-MISPAuthHeader function creates an authentication header for interacting with the MISP API. It takes an authentication key as input and returns a hashtable with the authentication header.

.PARAMETER MISPAuthKey
The authentication key to be used for the MISP API.

.EXAMPLE
$MISPHeader = New-MISPAuthHeader -MISPAuthKey "YOUR_API_KEY"
#>
function New-MISPAuthHeader {
  param(
    $MISPAuthKey
  )
  $Headers = @{
    Authorization = $MISPAuthKey
    Accept = 'application/json'
    'Content-Type' = 'application/json'
  }
  return $Headers
}

<#
.SYNOPSIS
Invokes a REST method against a MISP (Malware Information Sharing Platform) instance.

.DESCRIPTION
The Invoke-MISPRestMethod function is used to send HTTP requests to a MISP instance. It takes in the necessary parameters such as headers, HTTP method, request body, and URI, and returns the response from the MISP server.

.PARAMETER Headers
The headers to be included in the HTTP request.

.PARAMETER Method
The HTTP method to be used for the request (e.g., GET, POST, PUT, DELETE).

.PARAMETER Body
The body of the HTTP request.

.PARAMETER URI
The URI of the MISP endpoint to send the request to.

.EXAMPLE
$Headers = New-MISPAuthHeader -MISPAuthKey "YOUR_API_KEY"
$URI = "https://misp-instance/events"
$Data = @{
    test = Test
}
Invoke-MISPRestMethod -Headers $Headers -Method GET -Body ($Data | ConvertTo-Json) -Uri $URI

.NOTES
This function requires the Invoke-WebRequest cmdlet, which is available in PowerShell 3.0 and later.
#>
function Invoke-MISPRestMethod {
  param(
    $Headers,
    $Method,
    $Body,
    $URI
  )
  try {
    # Run the query against MISP
    $Result = Invoke-WebRequest -Headers $Headers -Method $Method -Body $Body -Uri $URI
  }
  catch {
    $errorReturn = $_ | ConvertFrom-Json
    if($errorReturn.Errors.Value -eq "A similar attribute already exists for this event") {
      Write-Host "Attribute already exists"
    }
    else {
      Write-Host "Error: $($_)"
    }
  }
  return $Result
}

<#
.SYNOPSIS
This function retrieves a MISP event.

.DESCRIPTION
The Get-MISPEvent function is used to retrieve a MISP event from a specified MISP instance. It requires authentication headers, MISP URI, MISP organization, MISP event name, and MISP attribute as input parameters.

.PARAMETER AuthHeader
The authentication header to be used for the MISP API request.

.PARAMETER MISPUri
The URI of the MISP instance.

.PARAMETER MISPOrg
The organization name in MISP.

.PARAMETER MISPEventName
The name of the MISP event to retrieve.

.PARAMETER MISPAttribute
The attribute of the MISP event to retrieve.

.EXAMPLE
$Headers = New-MISPAuthHeader -MISPAuthKey "YOUR_API_KEY"
$MISPUri = "https://misp.domain"
$MISPOrg = "MyOrg"
$MISPEventName = "Event123"
$MISPAttribute = "Attribute1"

Get-MISPEvent -AuthHeader $Headers -MISPUri $MISPUri -MISPOrg $MISPOrg -MISPEventName $MISPEventName -MISPAttribute $MISPAttribute
#>
function Get-MISPEvent {
  param(
    $AuthHeader,
    $MISPUri,
    $MISPOrg,
    $MISPEventName,
    $MISPAttribute
  )
  # Create the body of the request
  $Data = @{
    org = $MISPOrg
    eventinfo = $MISPEventName
    attribute = $MISPAttribute
  }
  $return = Invoke-MISPRestMethod -Headers $AuthHeader -Method "POST" -Body ($Data | ConvertTo-Json) -Uri "$MISPUri/events/index"
  return $return
}
