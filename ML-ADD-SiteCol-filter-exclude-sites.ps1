Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue

# User Account to add as Site Collection Admin
$UserAccount = "c:0+.t|contoso (adfs) - email|s-1-5-21-1888728768-5163114-3101231337-164597"

# Path to the filter file (each filter pattern on a new line)
$FilterFilePath = "D:\filter\filter.txt"

# Read filters from file
if (Test-Path $FilterFilePath) {
    $Filters = Get-Content $FilterFilePath
    Write-Host "Loaded filter patterns:" -ForegroundColor Green
    $Filters | ForEach-Object { Write-Host $_ -ForegroundColor Cyan }
} else {
    Write-Host "Filter file not found at $FilterFilePath. Exiting." -ForegroundColor Red
    return
}

# Get all site collections and filter based on file patterns
$filter = Get-SPSite -Limit "All" | Where-Object {
    $IncludeSite = $true
    foreach ($Pattern in $Filters) {
        if ($_.Url -like "*$Pattern*") {
            $IncludeSite = $false
            break
        }
    }
    $IncludeSite
}

# Check if any sites match the filter
if ($filter -and $filter.Count -gt 0) {
    $filter | ForEach-Object {
        try {
            $User = $_.RootWeb.EnsureUser($UserAccount)
            if ($User.IsSiteAdmin -ne $True) {
                $User.IsSiteAdmin = $True
                $User.Update()
                Write-Host "Added Site Collection Administrator for Site Collection:" $_.URL -ForegroundColor Green
            } else {
                Write-Host "User is already a Site Collection Administrator for Site Collection:" $_.URL -ForegroundColor Yellow
            }
        } catch {
            Write-Host "Failed to process site: $_.URL. Error: $_" -ForegroundColor Red
        }
    }
} else {
    Write-Host "No sites found matching the filter criteria." -ForegroundColor Red
}
