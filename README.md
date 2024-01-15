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

#### Create-MISPEvent

```powershell
function Create-MISPEvent {
  PARAM(
    $MISPUrl,
    $MISPAuthHeader,
    $MISPEventPublisher,
    [array]$MISPTagsId,
    $MISPOrg,
    $MISPEventName,
    [switch]$Publish,
    $Distribution
  )
  # Which MISP API Endpoint we are working against
  $Endpoint = "events/add"
  Write-Host "Trying to create event with title: $($MISPEventName)"

  # Check if event already exists
  $Event = Get-MISPEvent -MISPUrl $MISPUrl -MISPAuthHeader $MISPAuthHeader -MISPEventName $MISPEventName -MISPOrg $MISPOrg
  if($Event) {
    Write-Host "Event already exists, returning event"
    # Set eventID to existing event
    $MISPEventID =  $Event.Event.Id
  } else {
    # Continue script
    Write-Host "Event does not exist, creating event $MISPEventName"
    
    # Create body, we will add tlp:green as a tag for testing
    $Body = @{
      info = "$MISPEventName"
      org_id = $MISPOrg
      published = $false
      event_creator_email = $MISPEventPublisher
      distribution = $Distribution
    }
    
    # Invoke the API to create the event
    $return = Invoke-MISPRestMethod -Uri "$MISPUrl/$Endpoint" -Header $MISPAuthHeader -Method Post -Body ($Body | ConvertTo-Json)
    
    # Get event id from return
    $MISPEventID = ($return.Content | ConvertFrom-Json).Event.Id
    
    # Add tags to event
    foreach($Tag in $MISPTagsId) {
      Add-MISPEventTag -MISPUrl $MISPUrl -MISPAuthHeader $MISPAuthHeader -MISPEventID $MISPEventID -MISPTagId $Tag
    }
  }
  # Event exists or has been created, now we can add attributes
  if($Attributes) {
    # Format of attributes is a hashtable with the following format: $HashTable = @{Attribute = "value"; Type = "type"; Category = "category"; Comment = "comment"}
    foreach($Attribute in $Attributes) {
      Add-MISPEventAttribute -MISPUrl $MISPUrl -MISPAuthHeader $MISPAuthHeader -MISPEventID $MISPEventID -MISPAttribute $Attribute.Attribute -MISPAttributeType $Attribute.Type -MISPAttributeCategory $Attribute.Category -MISPAttributeComment $Attribute.Comment
    }
  }
}
```

#### Add-MISPEventAttribute

function Add-MISPEventAttribute {
  PARAM(
    $MISPUrl,
    $MISPAuthHeader,
    $MISPEventID,
    $MISPAttribute,
    $MISPAttributeType,
    $MISPAttributeCategory,
    $MISPAttributeComment
  )
  # Which MISP API Endpoint we are working against
  $Endpoint = "attributes/add/$MISPEventID"

  # Create the body of the request
  $MISPUrl = "$MISPUrl/$Endpoint"
  $Body = @{
    value = $MISPAttribute
    type = $MISPAttributeType
    category = $MISPAttributeCategory
    comment = $MISPAttributeComment
    event_id = $MISPEventID
  }

  # Invoke the REST method
  Write-Host "Trying to add attribute $MISPAttribute to event $MISPEventID"
  $return = Invoke-MISPRestMethod -Uri $MISPUrl -Header $MISPAuthHeader -Method Post -Body ($Body |
  return $return
}
```

#### Get-MISPTags

```powershell
function Get-MISPTags {
  PARAM(
    $MISPUrl,
    $MISPAuthHeader,
    $Tag
  )
  $Endpoint = "tags/search/$Tag"
  $MISPUrl = "$MISPUrl/$Endpoint"
  Write-Host "Trying to get ID for tag: $($Tag)"
  $return = Invoke-MISPRestMethod -Uri $MISPUrl -Headers $MISPAuthHeader -Method Get
  return $return
}
```

#### Add-MISPEventTag

```powershell
function Add-MISPEventTag {
  PARAM(
    $MISPUrl,
    $MISPAuthHeader,
    $MISPEventID,
    $MISPTagId,
    [switch]$LocalOnly
  )
  # Which MISP API Endpoint we are working against
  $Endpoint = "events/addTag/$MISPEventID/$MISPTagId"

  # Create the body of the request
  $MISPUrl = "$MISPUrl/$Endpoint"

  # Check local only, add local only if true
  if($LocalOnly) {
    $MISPUrl = $MISPUrl0"/local:1"
  }

  # Invoke the REST method
  Write-Host "Trying to add tag $MISPTagId to event $MISPEventID"
  $return = Invoke-MISPRestMethod -Uri $MISPUrl -Header $MISPAuthHeader -Method Post
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
