# MISP-Scripts

Collection of scripts created to interact with MISP

## `MISP-Module.psm1`

The main part of this repository is the `MISP-Module` created for Powershell. In order to interact with MISP, this module works as a wrapper to call the MISP API. 

### Functions

Currently the module has three pretty simple functions.

#### New-MISPAuthHeader

This functions requires an authentication key as input and returns a hashtable with the authentication header.

```pwsh
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
```

#### Invoke-MISPRestMethod

This function requires the output from `New-MISPAuthHeader`, a method, a body and a URI as input. It then invokes the REST-method against the MISP API and returns the result. 

```pwsh
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
```

#### Get-MISPEvent

```pwsh
function Get-MISPEvent {
  param(
    $AuthHeader,
    $MISPUri,
    $MISPOrg,
    $MISPEventName,
    $MISPAttribute
  )
  # Create the body of the request
  if($MISPAttribute) {
    $Data = @{
    org = $MISPOrg
    eventinfo = $MISPEventName
    attribute = $MISPAttribute
    }
  } else {
    $Data = @{
    org = $MISPOrg
    eventinfo = $MISPEventName
    }
  }
  $return = Invoke-MISPRestMethod -Headers $AuthHeader -Method "POST" -Body ($Data | ConvertTo-Json) -Uri "$MISPUri/events/index"
  return $return
}
```

### Usage

Using the module will include dot sourcing it to be able to run, or include it as a module in your `$PROFILE`.

#### Load the module in the current pwsh session

```pwsh
. .\MISP-Module.psm1
```

#### Create a header

We ALWAYS need to create a header in order to run commands.

```pwsh
$MISPHeader = New-MISPAuthHeader -MISPAuthKey "dadada..."
```

#### Get an event

We use the `$MISPHeader` together with information about our organization, MISP event name and a attribute to check for an existing event. You can also not specify an attribute and only browse events using the MISP event name and org.

```pwsh
$MISPEvent = Get-MISPEvent -AuthHeader $MISPHeader -MISPUri https://misp.domain -MISPOrg "infernux.no" -MISPEventName "Test Event 1011" -MISPAttribute "exampleText"
```
