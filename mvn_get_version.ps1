param (
    [string]$pomPath
)

if (-not $pomPath) {
    return 
}

if (-not (Test-Path -Path $pomPath)) {
    return
}

try {
    $xml = [xml](Get-Content -Path $pomPath -Raw)

    if ($xml.project.version) {
        $version = $xml.project.version
        if ($version -eq '${revision}' -and $xml.project.properties.revision) {
            $version = $xml.project.properties.revision
        }
    }
    elseif ($xml.project.version -match '\${(.+?)}') {
        $propertyName = $Matches[1]
        $version = $xml.project.properties.$propertyName
    } else {
        return
    }

    return $version

} catch {
    return
}