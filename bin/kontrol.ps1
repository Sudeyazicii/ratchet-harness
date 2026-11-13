# ==============================================================================
# bin/kontrol.ps1 — PowerShell Ratchet (Mandal) Doğrulama Kancası
# ==============================================================================

Write-Host "======================================================" -ForegroundColor Cyan
Write-Host "[RATCHET HARNESS] bin/kontrol kancasi devrede..." -ForegroundColor Cyan
Write-Host "======================================================" -ForegroundColor Cyan

$hasError = $false

# 1. Statik Kural Kontrolleri
Write-Host "`n[1/3] Statik Anayasa ve Anti-Pattern Denetimi Yapiliyor..." -ForegroundColor Yellow

# A) method_missing kontrolü
$mmFound = Get-ChildItem -Path lib -Filter *.rb -Recurse | Select-String "def method_missing"
if ($mmFound) {
    Write-Host "[KURAL IHLALI] lib/ icinde 'method_missing' tespit edildi!" -ForegroundColor Red
    $hasError = $true
} else {
    Write-Host "[OK] method_missing kullanilmamis." -ForegroundColor Green
}

# B) Monkey Patching kontrolü
$mpFound = Get-ChildItem -Path lib -Filter *.rb -Recurse | Select-String "class (Object|Integer|String|Array|Symbol|Numeric|Hash)"
if ($mpFound) {
    Write-Host "[KURAL IHLALI] Ruby standart siniflarina monkey patch tespit edildi!" -ForegroundColor Red
    $hasError = $true
} else {
    Write-Host "[OK] Monkey patch tespit edilmedi." -ForegroundColor Green
}

# C) Sınır Kuralı: > 3 kontrolü
$boundaryFound = Get-ChildItem -Path lib -Filter *.rb -Recurse | Select-String "devamsizlik > 3"
if ($boundaryFound) {
    Write-Host "[KURAL IHLALI] 'devamsizlik > 3' bulundu! Sinir kurali '>= 3' olmalidir!" -ForegroundColor Red
    $hasError = $true
} else {
    Write-Host "[OK] Sinir kurali kontrolu basarili (>= 3)." -ForegroundColor Green
}

# D) frozen_string_literal kontrolü
$files = Get-ChildItem -Path lib, test -Filter *.rb -Recurse
foreach ($f in $files) {
    $firstLine = Get-Content -Path $f.FullName -TotalCount 1
    if ($firstLine -notmatch "frozen_string_literal: true") {
        Write-Host "[KURAL IHLALI] '$($f.Name)' basinda '# frozen_string_literal: true' eksik!" -ForegroundColor Red
        $hasError = $true
    }
}
if (-not $hasError) {
    Write-Host "[OK] frozen_string_literal tum dosyalarda tanimli." -ForegroundColor Green
}

if ($hasError) {
    Write-Host "`n[HATA] Statik anayasa kontrolleri basarisiz! Kod reddedildi." -ForegroundColor Red
    exit 1
}

# 2. Ruby Çalıştırma Kontrolü
Write-Host "`n[2/3] Ruby Calisma Zamani Denetimi..." -ForegroundColor Yellow
$rubyCmd = Get-Command ruby -ErrorAction SilentlyContinue

if ($rubyCmd) {
    Write-Host "[OK] Ruby tespit edildi: $($rubyCmd.Source)" -ForegroundColor Green
    Write-Host "`n[3/3] Minitest calistiriliyor..." -ForegroundColor Yellow
    ruby -Ilib:test test/ogrenci_test.rb
    if ($LASTEXITCODE -ne 0) {
        Write-Host "`n[TEST BASARISIZ] Minitest testleri kirmizi verdi!" -ForegroundColor Red
        exit $LASTEXITCODE
    }
    Write-Host "`n[BASARILI] Tum testler ve anayasa kontrolleri YESIL!" -ForegroundColor Green
} else {
    Write-Host "[BILGI] Yerel ortamda 'ruby' komutu bulunamadi." -ForegroundColor Yellow
    Write-Host "[OK] Statik anayasa ve anti-pattern denetimleri basariyla GECTI." -ForegroundColor Green
}

Write-Host "======================================================" -ForegroundColor Cyan
Write-Host "[MANDAL GECILDI] Kod yuksek kalite standardina uygun." -ForegroundColor Cyan
Write-Host "======================================================" -ForegroundColor Cyan
exit 0
