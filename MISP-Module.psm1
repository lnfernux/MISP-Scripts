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

<#
.SYNOPSIS
Adds a tag to a MISP event.

.DESCRIPTION
This function adds a tag to a MISP event specified by the MISPEventID. It uses the MISP API to perform the operation.

.PARAMETER MISPUrl
The URL of the MISP instance.

.PARAMETER MISPAuthHeader
The authentication header for accessing the MISP API.

.PARAMETER MISPEventID
The ID of the MISP event to which the tag should be added.

.PARAMETER MISPTagId
The ID of the tag to be added to the MISP event.

.PARAMETER LocalOnly
Specifies whether the tag should be added locally only. If this switch is used, the tag will not be synced with other MISP instances.

.EXAMPLE
Add-MISPEventTag -MISPUrl "https://misp.example.com" -MISPAuthHeader "Bearer ABC123" -MISPEventID 12345 -MISPTagId 6789

This example adds the tag with ID 6789 to the MISP event with ID 12345.

#>
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

<#
.SYNOPSIS
Adds an attribute to an existing event in a MISP instance.

.DESCRIPTION
The Add-MISPEventAttribute function is used to add an attribute to an existing event in a MISP (Malware Information Sharing Platform) instance. It constructs the URL for the MISP API endpoint, creates a hashtable for the body of the request, and then invokes a REST method to add the attribute to the event in the MISP instance.

.PARAMETER MISPUrl
The URL of the MISP instance.

.PARAMETER MISPAuthHeader
The authentication header for the MISP instance.

.PARAMETER MISPEventID
The ID of the event to which the attribute should be added.

.PARAMETER MISPAttribute
The attribute to be added.

.PARAMETER MISPAttributeType
The type of the attribute to be added.

.PARAMETER MISPAttributeCategory
The category of the attribute to be added.

.PARAMETER MISPAttributeComment
A comment for the attribute to be added.

.EXAMPLE
Add-MISPEventAttribute -MISPUrl "https://misp.example.com" -MISPAuthHeader $AuthHeader -MISPEventID 1234 -MISPAttribute "malware" -MISPAttributeType "string" -MISPAttributeCategory "Payload delivery" -MISPAttributeComment "This is a test attribute"

This example adds an attribute with the value "malware", type "string", category "Payload delivery", and comment "This is a test attribute" to the event with ID 1234 in the MISP instance at "https://misp.example.com".

#>
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

<#
.SYNOPSIS
Creates an event in a MISP instance.

.DESCRIPTION
The Create-MISPEvent function is used to create an event in a MISP (Malware Information Sharing Platform) instance. It first checks if an event with the same name already exists in the MISP instance. If it does, it simply returns the existing event. If not, it creates a new event with the provided parameters.

.PARAMETER MISPUrl
The URL of the MISP instance.

.PARAMETER MISPAuthHeader
The authentication header for the MISP instance.

.PARAMETER MISPEventPublisher
The publisher of the event.

.PARAMETER MISPTagsId
An array of tag IDs for the event.

.PARAMETER MISPOrg
The organization ID for the event.

.PARAMETER MISPEventName
The name of the event.

.PARAMETER Publish
A switch to indicate whether the event should be published.

.PARAMETER Distribution
The distribution of the event.

.EXAMPLE
Create-MISPEvent -MISPUrl "https://misp.example.com" -MISPAuthHeader $AuthHeader -MISPEventPublisher "publisher@example.com" -MISPTagsId @("tag1", "tag2") -MISPOrg 1234 -MISPEventName "Test Event" -Publish $true -Distribution 3

This example creates an event with the name "Test Event", published by "publisher@example.com", with the tags "tag1" and "tag2", for the organization with ID 1234, and with a distribution of 3, in the MISP instance at "https://misp.example.com".

#>
function Create-MISPEvent {
  PARAM(
    $MISPUrl,
    $MISPAuthHeader,
    $MISPEventPublisher,
    [array]$MISPTagsId,
    $MISPOrg,
    $MISPEventName,
    [switch]$Publish,
    $Distribution = 0
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
    
    # Create body
    if($Publish) {
      $Publish = $true
    } else {
      $Publish = $false
    }
    $Body = @{
      info = "$MISPEventName"
      org_id = $MISPOrg
      published = $Publish
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
