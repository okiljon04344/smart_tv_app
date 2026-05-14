param(
  [Parameter(Mandatory = $true)]
  [ValidateSet('add', 'update', 'delete')]
  [string]$Action,

  [Parameter(Mandatory = $true)]
  [string]$Id,

  [string]$Category = 'cat_popular',
  [string]$Title,
  [string]$Subtitle,
  [string]$Genre,
  [string]$Year,
  [string]$Rating,
  [string]$Duration,
  [string]$YoutubeUrl,
  [string]$YoutubeId,
  [long]$ColorCode = 0xFF1A237E,
  [bool]$IsNew = $false,
  [bool]$IsHD = $true
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Invoke-Firebase {
  param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Args)
  & npx firebase @Args
  if ($LASTEXITCODE -ne 0) {
    throw "Firebase command failed: npx firebase $($Args -join ' ')"
  }
}

function Get-DbJson {
  param([string]$Path)
  $raw = & npx firebase database:get $Path
  if ($LASTEXITCODE -ne 0) {
    throw "Failed to read path: $Path"
  }
  if ([string]::IsNullOrWhiteSpace($raw)) {
    return $null
  }
  return $raw | ConvertFrom-Json
}

function Set-DbJson {
  param([string]$Path, [object]$Value)
  $json = $Value | ConvertTo-Json -Depth 20 -Compress
  Invoke-Firebase database:set $Path -d $json -f
}

function Remove-DbPath {
  param([string]$Path)
  Invoke-Firebase database:remove $Path -f
}

function Resolve-YoutubeUrl {
  param([string]$YoutubeUrl, [string]$YoutubeId)
  if ($YoutubeUrl) { return $YoutubeUrl }
  if ($YoutubeId) { return "https://www.youtube.com/watch?v=$YoutubeId" }
  return $null
}

function Ensure-CategoryMembership {
  param([string]$CategoryName, [string]$VideoId)

  $catPath = "/categories/$CategoryName"
  $catNode = Get-DbJson $catPath
  if ($null -eq $catNode) {
    $catNode = [ordered]@{
      name = $CategoryName
      items = @($VideoId)
    }
    Set-DbJson $catPath $catNode
    return
  }

  $items = @()
  if ($catNode.PSObject.Properties.Name -contains 'items' -and $null -ne $catNode.items) {
    $items = @($catNode.items)
  }

  if (-not ($items -contains $VideoId)) {
    $items += $VideoId
    $catNode.items = $items
    Set-DbJson $catPath $catNode
  }
}

function Remove-FromAllCategories {
  param([string]$VideoId)

  $categories = Get-DbJson '/categories'
  if ($null -eq $categories) { return }

  foreach ($prop in $categories.PSObject.Properties) {
    $catName = $prop.Name
    $catNode = $prop.Value
    if ($null -eq $catNode) { continue }

    $items = @()
    if ($catNode.PSObject.Properties.Name -contains 'items' -and $null -ne $catNode.items) {
      $items = @($catNode.items)
    }

    $filtered = @($items | Where-Object { $_.ToString() -ne $VideoId })
    if ($filtered.Count -ne $items.Count) {
      $catNode.items = $filtered
      Set-DbJson "/categories/$catName" $catNode
    }
  }
}

$resolvedYoutube = Resolve-YoutubeUrl -YoutubeUrl $YoutubeUrl -YoutubeId $YoutubeId

switch ($Action) {
  'add' {
    if (-not $Title) { throw 'add: -Title is required' }
    if (-not $resolvedYoutube) { throw 'add: -YoutubeUrl or -YoutubeId is required' }

    $finalSubtitle = if ($Subtitle) { $Subtitle } else { 'Video' }
    $finalGenre = if ($Genre) { $Genre } else { 'General' }
    $finalYear = if ($Year) { $Year } else { '2025' }
    $finalRating = if ($Rating) { $Rating } else { '8.0' }
    $finalDuration = if ($Duration) { $Duration } else { '1:30' }

    $payload = [ordered]@{
      id = $Id
      title = $Title
      subtitle = $finalSubtitle
      genre = $finalGenre
      year = $finalYear
      rating = $finalRating
      duration = $finalDuration
      colorCode = $ColorCode
      youtubeUrl = $resolvedYoutube
      isNew = $IsNew
      isHD = $IsHD
    }

    Set-DbJson "/movies/$Id" $payload
    Ensure-CategoryMembership -CategoryName $Category -VideoId $Id
    Write-Host "Added video $Id to /movies and category $Category"
  }

  'update' {
    $existing = Get-DbJson "/movies/$Id"
    if ($null -eq $existing) { throw "update: /movies/$Id not found" }

    $payload = [ordered]@{}
    $payload.id = $Id
    $payload.title = if ($Title) { $Title } else { $existing.title }
    $payload.subtitle = if ($Subtitle) { $Subtitle } else { $existing.subtitle }
    $payload.genre = if ($Genre) { $Genre } else { $existing.genre }
    $payload.year = if ($Year) { $Year } else { $existing.year }
    $payload.rating = if ($Rating) { $Rating } else { $existing.rating }
    $payload.duration = if ($Duration) { $Duration } else { $existing.duration }
    $payload.colorCode = if ($PSBoundParameters.ContainsKey('ColorCode')) { $ColorCode } else { [int]$existing.colorCode }
    $payload.youtubeUrl = if ($resolvedYoutube) { $resolvedYoutube } else { $existing.youtubeUrl }
    $payload.isNew = if ($PSBoundParameters.ContainsKey('IsNew')) { $IsNew } else { [bool]$existing.isNew }
    $payload.isHD = if ($PSBoundParameters.ContainsKey('IsHD')) { $IsHD } else { [bool]$existing.isHD }

    Set-DbJson "/movies/$Id" $payload
    if ($Category) {
      Ensure-CategoryMembership -CategoryName $Category -VideoId $Id
    }
    Write-Host "Updated video $Id"
  }

  'delete' {
    Remove-DbPath "/movies/$Id"
    Remove-FromAllCategories -VideoId $Id
    Write-Host "Deleted video $Id and removed it from category lists"
  }
}
