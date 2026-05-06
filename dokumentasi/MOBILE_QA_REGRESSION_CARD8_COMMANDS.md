# Command Tes Card 8 - Mobile QA Regression Kompatibilitas Laravel VPS

Dokumen ini berisi command PowerShell yang digunakan untuk verifikasi Card 8:

- test login/logout/profile
- test latest/alerts/history (path + query)
- test testing location + testing history
- test error handling `401/404/422`

## 1) Regression Static Check

```powershell
cd "D:\Tugas Kuliah\Semester 6\MBKM - Magang\Mobile Apps Hera v2.0\mobile"
flutter analyze lib/core/network/backend_endpoints.dart lib/core/network/auth_interceptor.dart lib/core/services/auth_service.dart lib/core/services/sensor_service.dart lib/core/services/test_service.dart lib/screens/home_screen.dart lib/screens/history_screen.dart lib/screens/profile_view.dart lib/screens/test_location_screen.dart lib/screens/testing_history_screen.dart
```

## 2) Audit Kontrak Endpoint/Query (Fallback pengganti `rg`)

```powershell
Get-ChildItem -Path "mobile/lib/core","mobile/lib/screens" -Recurse -Filter *.dart |
  Select-String -Pattern "from_date|to_date|status|page|limit|sensor/history|sensor/latest|sensor/alerts|testing/history|testing/location|/api/mobile/profile|/api/mobile/me|/api/mobile/password" |
  ForEach-Object { "$($_.Path):$($_.LineNumber): $($_.Line.Trim())" }
```

## 3) Smoke Test `401` + `404` ke VPS

```powershell
$base='http://103.217.145.187:8000'
$tests=@(
  @{Name='profile_unauth';Method='GET';Path='/api/mobile/profile'},
  @{Name='sensor_latest_unauth';Method='GET';Path='/api/mobile/sensor/latest'},
  @{Name='sensor_history_unauth';Method='GET';Path='/api/mobile/sensor/history?limit=5&page=1'},
  @{Name='testing_history_unauth';Method='GET';Path='/api/mobile/testing/history?limit=5'},
  @{Name='unknown_404';Method='GET';Path='/api/mobile/not-found'}
)
foreach($t in $tests){
  try {
    $resp=Invoke-WebRequest -Uri ($base+$t.Path) -Method $t.Method -Headers @{Accept='application/json'} -TimeoutSec 30
    "{0} {1} -> {2}" -f $t.Method,$t.Path,$resp.StatusCode
  } catch {
    $code = if ($_.Exception.Response) { [int]$_.Exception.Response.StatusCode } else { 'NO_RESPONSE' }
    "{0} {1} -> {2}" -f $t.Method,$t.Path,$code
  }
}
```

## 4) Smoke Test `422` Validasi Login/Register

```powershell
$base='http://103.217.145.187:8000'
$tests=@(
  @{Method='POST';Path='/api/mobile/login';Body=@{email='invalid-email'}},
  @{Method='POST';Path='/api/mobile/register';Body=@{name='';email='not-an-email';password='123'}}
)
foreach($t in $tests){
  try {
    $json=($t.Body | ConvertTo-Json -Depth 5)
    $resp=Invoke-WebRequest -Uri ($base+$t.Path) -Method $t.Method -Headers @{Accept='application/json'} -ContentType 'application/json' -Body $json -TimeoutSec 30
    "{0} {1} -> {2}" -f $t.Method,$t.Path,$resp.StatusCode
  } catch {
    $code = if ($_.Exception.Response) { [int]$_.Exception.Response.StatusCode } else { 'NO_RESPONSE' }
    "{0} {1} -> {2}" -f $t.Method,$t.Path,$code
    if($_.ErrorDetails -and $_.ErrorDetails.Message){
      $_.ErrorDetails.Message.Substring(0,[Math]::Min(220,$_.ErrorDetails.Message.Length))
    }
  }
}
```

## 5) End-to-End QA (Register, Login, Profile, Sensor, Testing, Logout)

```powershell
$base='http://103.217.145.187:8000'
$ts=[DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
$name="qa_mobile_$ts"
$email="qa_mobile_$ts@example.com"
$password='QaTest12345!'

function Call-Api {
  param([string]$Method,[string]$Path,[hashtable]$Headers,[object]$Body)
  $params=@{ Uri=($base+$Path); Method=$Method; TimeoutSec=30; Headers=@{Accept='application/json'} }
  if($Headers){ foreach($k in $Headers.Keys){ $params.Headers[$k]=$Headers[$k] } }
  if($null -ne $Body){ $params.ContentType='application/json'; $params.Body=($Body | ConvertTo-Json -Depth 8) }
  try {
    $resp=Invoke-WebRequest @params
    [pscustomobject]@{ Ok=$true; Status=[int]$resp.StatusCode; Content=$resp.Content }
  } catch {
    $status = if ($_.Exception.Response) { [int]$_.Exception.Response.StatusCode } else { -1 }
    $content = if($_.ErrorDetails -and $_.ErrorDetails.Message){ $_.ErrorDetails.Message } else { '' }
    [pscustomobject]@{ Ok=$false; Status=$status; Content=$content }
  }
}

$reg = Call-Api -Method 'POST' -Path '/api/mobile/register' -Body @{name=$name; email=$email; password=$password}
"REGISTER -> $($reg.Status)"

$login = Call-Api -Method 'POST' -Path '/api/mobile/login' -Body @{email=$email; password=$password}
"LOGIN -> $($login.Status)"
if(-not $login.Ok){ $login.Content; exit }

$loginJson = $login.Content | ConvertFrom-Json
$token = $loginJson.data.token
if(-not $token){ $token = $loginJson.token }
$auth = @{ Authorization = "Bearer $token" }

$profile = Call-Api -Method 'GET' -Path '/api/mobile/profile' -Headers $auth
"PROFILE -> $($profile.Status)"

$latest = Call-Api -Method 'GET' -Path '/api/mobile/sensor/latest' -Headers $auth
"SENSOR_LATEST -> $($latest.Status)"

$alerts = Call-Api -Method 'GET' -Path '/api/mobile/sensor/alerts' -Headers $auth
"SENSOR_ALERTS -> $($alerts.Status)"

$history = Call-Api -Method 'GET' -Path '/api/mobile/sensor/history?from_date=2026-01-01&to_date=2026-12-31&status=normal&page=1&limit=5' -Headers $auth
"SENSOR_HISTORY -> $($history.Status)"

$testingLocation = Call-Api -Method 'POST' -Path '/api/mobile/testing/location' -Headers $auth -Body @{
  latitude=-6.200000; longitude=106.816666; altitude=$null; suhu_air=29.1; suhu_lingkungan=30.2;
  kelembapan=70.4; ec=1.23; tds=600.0; ph=6.8; tegangan=12.1
}
"TESTING_LOCATION -> $($testingLocation.Status)"

$testingHistory = Call-Api -Method 'GET' -Path '/api/mobile/testing/history?limit=5' -Headers $auth
"TESTING_HISTORY -> $($testingHistory.Status)"

$logout = Call-Api -Method 'POST' -Path '/api/mobile/logout' -Headers $auth
"LOGOUT -> $($logout.Status)"

$profileAfterLogout = Call-Api -Method 'GET' -Path '/api/mobile/profile' -Headers $auth
"PROFILE_AFTER_LOGOUT -> $($profileAfterLogout.Status)"
```

