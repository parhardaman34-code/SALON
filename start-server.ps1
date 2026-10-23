param(
    [int]$Port = 8080
)

$rootPath = $PSScriptRoot
if (-not $rootPath) { $rootPath = (Get-Location).Path }

$listener = New-Object System.Net.HttpListener
$prefix = "http://localhost:$Port/"
$listener.Prefixes.Add($prefix)

try {
    $listener.Start()
} catch {
    Write-Host "Failed to start on port $Port, trying port 8000..." -ForegroundColor Yellow
    $Port = 8000
    $listener = New-Object System.Net.HttpListener
    $prefix = "http://localhost:$Port/"
    $listener.Prefixes.Add($prefix)
    $listener.Start()
}

Write-Host "=========================================" -ForegroundColor Green
Write-Host " Roopsy Local Web Server is Running!" -ForegroundColor Green
Write-Host " Open in browser: $prefix" -ForegroundColor Cyan
Write-Host " Serving directory: $rootPath" -ForegroundColor Gray
Write-Host " Press Ctrl+C in this window to stop." -ForegroundColor Gray
Write-Host "=========================================" -ForegroundColor Green

$mimeTypes = @{
    ".html"  = "text/html; charset=utf-8"
    ".htm"   = "text/html; charset=utf-8"
    ".css"   = "text/css; charset=utf-8"
    ".js"    = "application/javascript; charset=utf-8"
    ".json"  = "application/json; charset=utf-8"
    ".png"   = "image/png"
    ".jpg"   = "image/jpeg"
    ".jpeg"  = "image/jpeg"
    ".gif"   = "image/gif"
    ".svg"   = "image/svg+xml"
    ".ico"   = "image/x-icon"
    ".webp"  = "image/webp"
    ".woff"  = "font/woff"
    ".woff2" = "font/woff2"
    ".ttf"   = "font/ttf"
}

try {
    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response

        $urlPath = $request.Url.LocalPath.TrimStart('/')
        $rawPath = [System.Uri]::UnescapeDataString($urlPath)
        if ([string]::IsNullOrEmpty($rawPath) -or $rawPath -eq "") {
            $rawPath = "index.html"
        }

        $localFilePath = Join-Path $rootPath $rawPath

        if (Test-Path -Path $localFilePath -PathType Leaf) {
            $ext = [System.IO.Path]::GetExtension($localFilePath).ToLower()
            $contentType = if ($mimeTypes.ContainsKey($ext)) { $mimeTypes[$ext] } else { "application/octet-stream" }
            
            $contentBytes = [System.IO.File]::ReadAllBytes($localFilePath)
            $response.ContentType = $contentType
            $response.ContentLength64 = $contentBytes.Length
            $response.StatusCode = 200
            $response.OutputStream.Write($contentBytes, 0, $contentBytes.Length)
            $response.OutputStream.Close()
            Write-Host "[$((Get-Date).ToString('HH:mm:ss'))] 200 OK: $($request.Url.LocalPath)" -ForegroundColor Green
        } else {
            $msg = [System.Text.Encoding]::UTF8.GetBytes("<h1>404 Not Found</h1><p>The requested file $($request.Url.LocalPath) was not found.</p>")
            $response.StatusCode = 404
            $response.ContentType = "text/html; charset=utf-8"
            $response.ContentLength64 = $msg.Length
            $response.OutputStream.Write($msg, 0, $msg.Length)
            $response.OutputStream.Close()
            Write-Host "[$((Get-Date).ToString('HH:mm:ss'))] 404 Not Found: $($request.Url.LocalPath)" -ForegroundColor Red
        }
    }
} finally {
    $listener.Stop()
    $listener.Close()
}
