winget install cURL.cURL
$packages = curl https://raw.githubusercontent.com/dungdinhmanh/windoze-auto/refs/heads/main/packages.json

winget import -i $packages --accept-source-agreements
