param(
  [datetime]$Date = (Get-Date).Date
)

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$root = Split-Path -Parent $PSScriptRoot
$generator = Join-Path $root 'work\New-DailyPlanImage.ps1'
$configPath = if ($env:PUSHPLUS_CONFIG_PATH) { $env:PUSHPLUS_CONFIG_PATH } else { Join-Path $root 'pushplus-config.json' }
$outPath = Join-Path $root ('outputs\{0:yyyy-MM-dd}-daily-plan-cute.png' -f $Date)

function Invoke-JsonPostUtf8($Uri, $Payload, $Headers = @{}) {
  $json = $Payload | ConvertTo-Json -Depth 12 -Compress
  $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
  Invoke-RestMethod -Uri $Uri -Method Post -ContentType 'application/json;charset=utf-8' -Headers $Headers -Body $bytes
}

if (-not (Test-Path -LiteralPath $generator)) {
  throw "Daily plan image generator is missing: $generator"
}
& powershell -NoProfile -ExecutionPolicy Bypass -File $generator -Date $Date -OutPath $outPath | Out-Null
if (-not (Test-Path -LiteralPath $outPath)) {
  throw "Daily plan image was not created: $outPath"
}

$config = $null
if (Test-Path -LiteralPath $configPath) {
  $config = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
}
$token = if ($env:PUSHPLUS_TOKEN) { $env:PUSHPLUS_TOKEN } elseif ($config) { $config.token } else { $null }
$secretKey = if ($env:PUSHPLUS_SECRET_KEY) { $env:PUSHPLUS_SECRET_KEY } elseif ($config) { $config.secretKey } else { $null }
$endpoint = if ($env:PUSHPLUS_ENDPOINT) { $env:PUSHPLUS_ENDPOINT } elseif ($config) { $config.endpoint } else { $null }
$channel = if ($env:PUSHPLUS_CHANNEL) { $env:PUSHPLUS_CHANNEL } elseif ($config -and $config.channel) { $config.channel } else { 'wechat' }
if (-not $token) { throw 'PushPlus token is missing.' }
if (-not $secretKey) { throw 'PushPlus secretKey is missing.' }
if (-not $endpoint) { throw 'PushPlus endpoint is missing.' }

Add-Type -AssemblyName System.Net.Http
$client = [System.Net.Http.HttpClient]::new()
$form = [System.Net.Http.MultipartFormDataContent]::new()
$fileBytes = [System.IO.File]::ReadAllBytes($outPath)
$fileContent = [System.Net.Http.ByteArrayContent]::new($fileBytes)
$fileContent.Headers.ContentType = [System.Net.Http.Headers.MediaTypeHeaderValue]::Parse('image/png')
$form.Add($fileContent, 'file', [System.IO.Path]::GetFileName($outPath))

$uploadMessage = $client.PostAsync('https://tmpfiles.org/api/v1/upload', $form).GetAwaiter().GetResult()
$uploadText = $uploadMessage.Content.ReadAsStringAsync().GetAwaiter().GetResult()
if (-not $uploadMessage.IsSuccessStatusCode) {
  throw "image upload failed with HTTP $([int]$uploadMessage.StatusCode)"
}
$uploadResp = $uploadText | ConvertFrom-Json
if ($uploadResp.status -ne 'success' -or -not $uploadResp.data.url) {
  throw "image upload failed: $uploadText"
}
$uploadedUri = [Uri]$uploadResp.data.url
$imageSrc = '{0}://{1}/dl{2}' -f $uploadedUri.Scheme, $uploadedUri.Host, $uploadedUri.AbsolutePath

$dateText = '{0:yyyy-MM-dd}' -f $Date
$content = @"
<div style="font-family:Arial,'Microsoft YaHei',sans-serif;line-height:1.6;">
  <h2>$dateText 每日计划</h2>
  <p><img src="$imageSrc" style="max-width:100%;height:auto;" /></p>
</div>
"@

$sendResp = Invoke-JsonPostUtf8 -Uri $endpoint -Payload ([ordered]@{
  token = $token
  title = "$dateText Daily Plan"
  content = $content
  template = 'html'
  channel = $channel
})
if ($sendResp.code -ne 200) {
  throw "send failed: code=$($sendResp.code), msg=$($sendResp.msg)"
}

[pscustomobject]@{
  Sent = $true
  Date = $dateText
  ImagePath = $outPath
  ImageBytes = (Get-Item -LiteralPath $outPath).Length
} | ConvertTo-Json -Depth 4
