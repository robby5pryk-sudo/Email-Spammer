$DefaultSmtpServer     = "smtp.gmail.com"
$DefaultSmtpPort       = 587
$DefaultSenderEmail    = "YourEmail@gmail.com"
$DefaultSenderPassword = "Your App Password"

$AppFolder        = "$env:LOCALAPPDATA\AfreldoEmailSender"
if (-not (Test-Path $AppFolder)) {
    New-Item -ItemType Directory -Path $AppFolder -Force | Out-Null
}
$CooldownFile     = "$AppFolder\.cooldown"
$UsageFile        = "$AppFolder\.daily_usage"
$ConfigChoiceFile = "$AppFolder\.choice_mode" 
$CooldownMinutes  = 5
$MaxDefaultLimit  = 2
$MaxMessageLimit  = 10 

Write-Host "=== 
███████╗██████╗  █████╗ ███╗   ███╗    ███████╗███╗   ███╗ █████╗ ██╗██╗     
██╔════╝██╔══██╗██╔══██╗████╗ ████║    ██╔════╝████╗ ████║██╔══██╗██║██║     
███████╗██████╔╝███████║██╔████╔██║    █████╗  ██╔████╔██║███████║██║██║     
╚════██║██╔═══╝ ██╔══██║██║╚██╔╝██║    ██╔══╝  ██║╚██╔╝██║██╔══██║██║██║     
███████║██║     ██║  ██║██║ ╚═╝ ██║    ███████╗██║ ╚═╝ ██║██║  ██║██║███████╗
╚══════╝╚═╝     ╚═╝  ╚═╝╚═╝     ╚═╝    ╚══════╝╚═╝     ╚═╝╚═╝  ╚═╝╚═╝╚══════╝
██████╗ ██╗   ██╗    ██████╗  ██████╗ ██████╗ ██████╗ ██╗   ██╗███████╗██████╗ ██████╗ ██╗   ██╗██╗  ██╗
██╔══██╗╚██╗ ██╔╝    ██╔══██╗██╔═══██╗██╔══██╗██╔══██╗╚██╗ ██╔╝██╔════╝██╔══██╗██╔══██╗╚██╗ ██╔╝██║ ██╔╝
██████╔╝ ╚████╔╝     ██████╔╝██║   ██║██████╔╝██████╔╝ ╚████╔╝ ███████╗██████╔╝██████╔╝ ╚████╔╝ █████╔╝ 
██╔══██╗  ╚██╔╝      ██╔══██╗██║   ██║██╔══██╗██╔══██╗  ╚██╔╝  ╚════██║██╔═══╝ ██╔══██╗  ╚██╔╝  ██╔═██╗ 
██████╔╝   ██║       ██║  ██║╚██████╔╝██████╔╝██████╔╝   ██║   ███████║██║     ██║  ██║   ██║   ██║  ██╗
╚═════╝    ╚═╝       ╚═╝  ╚═╝ ╚═════╝ ╚═════╝ ╚═════╝    ╚═╝   ╚══════╝╚═╝     ╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝
██╗   ██╗██╗███████╗██╗████████╗     ██████╗ ███╗   ██╗     ██████╗ ██╗████████╗██╗  ██╗██╗   ██╗██████╗ 
██║   ██║██║██╔════╝██║╚══██╔══╝    ██╔═══██╗████╗  ██║    ██╔════╝ ██║╚══██╔══╝██║  ██║██║   ██║██╔══██╗
██║   ██║██║███████╗██║   ██║       ██║   ██║██╔██╗ ██║    ██║  ███╗██║   ██║   ███████║██║   ██║██████╔╝
╚██╗ ██╔╝██║╚════██║██║   ██║       ██║   ██║██║╚██╗██║    ██║   ██║██║   ██║   ██╔══██║██║   ██║██╔══██╗
 ╚████╔╝ ██║███████║██║   ██║       ╚██████╔╝██║ ╚████║    ╚██████╔╝██║   ██║   ██║  ██║╚██████╔╝██████╔╝
  ╚═══╝  ╚═╝╚══════╝╚═╝   ╚═╝        ╚═════╝ ╚═╝  ╚═══╝     ╚═════╝ ╚═╝   ╚═╝   ╚═╝  ╚═╝ ╚═════╝ ╚═════╝
===" -ForegroundColor Red

function Test-Cooldown {
    if (Test-Path $CooldownFile) {
        $LastRun = [datetime](Get-Content $CooldownFile -Raw)
        $TimePassed = (Get-Date) - $LastRun
        $RemainingSeconds = ($CooldownMinutes * 60) - $TimePassed.TotalSeconds

        if ($RemainingSeconds -gt 0) {
            $MinutesLeft = [math]::Floor($RemainingSeconds / 60)
            $SecondsLeft = [math]::Floor($RemainingSeconds % 60)
            Write-Host "`n[Cooldown] Anda harus menunggu sekitar $MinutesLeft menit $SecondsLeft detik lagi sebelum bisa mengirim pesan kembali." -ForegroundColor Yellow
            return $false
        }
    }
    return $true
}

function Get-SenderCredentials {
    $Today = (Get-Date).ToString("yyyy-MM-dd")
    $UsageCount = 0

    if (Test-Path $UsageFile) {
        $SavedData = Get-Content $UsageFile -Raw | ConvertFrom-Json
        if ($SavedData.Date -eq $Today) {
            $UsageCount = [int]$SavedData.Count
        }
    }

    if ($UsageCount -ge $MaxDefaultLimit) {
        $UseCustomToday = $false
        
        if (Test-Path $ConfigChoiceFile) {
            $ChoiceData = Get-Content $ConfigChoiceFile -Raw | ConvertFrom-Json
            if ($ChoiceData.Date -eq $Today) {
                $UseCustomToday = [bool]$ChoiceData.UseCustom
            } else {

                Write-Host "`nKuota akun default telah direset." -ForegroundColor Cyan
                $Pilihan = Read-Host "Apakah Anda ingin kembali menggunakan Akun Default? (y/n) [y = Default, n = Pakai Email Sendiri]"
                if ($Pilihan -eq 'n' -or $Pilihan -eq 'N') {
                    $UseCustomToday = $true
                } else {

                    $ResetObj = [PSCustomObject]@{ Date = $Today; Count = 0 }
                    $ResetObj | ConvertTo-Json | Out-File -FilePath $UsageFile -Force
                    $UseCustomToday = $false
                }
                
                $NewChoiceData = [PSCustomObject]@{ Date = $Today; UseCustom = $UseCustomToday }
                $NewChoiceData | ConvertTo-Json | Out-File -FilePath $ConfigChoiceFile -Force
            }
        } else {
            Write-Host "`n[Batas Harian Tercapai] Kuota akun default (2x pakai) hari ini sudah habis." -ForegroundColor Yellow
            $Pilihan = Read-Host "Ingin tetap pakai Email Sendiri atau kembali ke Default? (1 = Default, 2 = Email Sendiri)"
            if ($Pilihan -eq '2') {
                $UseCustomToday = $true
            } else {
                $ResetObj = [PSCustomObject]@{ Date = $Today; Count = 0 }
                $ResetObj | ConvertTo-Json | Out-File -FilePath $UsageFile -Force
                $UseCustomToday = $false
            }
            
            $NewChoiceData = [PSCustomObject]@{ Date = $Today; UseCustom = $UseCustomToday }
            $NewChoiceData | ConvertTo-Json | Out-File -FilePath $ConfigChoiceFile -Force
        }

        if ($UseCustomToday) {
            Write-Host "Silakan masukkan kredensial email Anda sendiri (Unlimited)." -ForegroundColor Cyan
            $CustomEmail    = Read-Host "Masukkan Email Anda"
            $CustomPassword = Read-Host "Masukkan App Password Anda (BUKAN PASSWORD GMAIL)"
            
            return [PSCustomObject]@{
                Email    = $CustomEmail
                Password = $CustomPassword
                IsCustom = $true
            }
        }
    }

    $Remaining = $MaxDefaultLimit - $UsageCount
    Write-Host "`n[Info] Menggunakan akun default. Sisa kuota gratis hari ini: $Remaining kali." -ForegroundColor DarkCyan
    
    return [PSCustomObject]@{
        Email    = $DefaultSenderEmail
        Password = $DefaultSenderPassword
        IsCustom = $false
    }
}

function Register-Usage {
    $Today = (Get-Date).ToString("yyyy-MM-dd")
    $UsageCount = 0

    if (Test-Path $UsageFile) {
        $SavedData = Get-Content $UsageFile -Raw | ConvertFrom-Json
        if ($SavedData.Date -eq $Today) {
            $UsageCount = [int]$SavedData.Count
        }
    }

    $UsageCount++
    
    $DataObject = [PSCustomObject]@{
        Date  = $Today
        Count = $UsageCount
    }
    
    $DataObject | ConvertTo-Json | Out-File -FilePath $UsageFile -Force
}

do {
    if (-not (Test-Cooldown)) {
        $Choice = Read-Host "`nIngin keluar aplikasi? (y/n)"
        if ($Choice -eq 'y' -or $Choice -eq 'Y') { break }
        Start-Sleep -Seconds 5
        continue
    }

    $Creds = Get-SenderCredentials
    $SenderEmail    = $Creds.Email
    $SenderPassword = $Creds.Password

    $RecipientEmail = Read-Host "Email tujuan"
    
    do {
        $JumlahChat = [int](Read-Host "Masukkan jumlah pesan yang ingin dikirim")
        
        if (-not $Creds.IsCustom -and $JumlahChat -gt $MaxMessageLimit) {
            Write-Host "[Peringatan] Akun default hanya mengizinkan maksimal $MaxMessageLimit pesan sekali kirim. Silakan masukkan angka 1 - $MaxMessageLimit." -ForegroundColor Yellow
        } else {
            break
        }
    } while ($true)

    $SubjectPesan   = Read-Host "Masukkan subjek email"
    $BodyPesan      = Read-Host "Masukkan isi pesan"

    Write-Host "`nMemulai pengiriman $JumlahChat pesan ke $RecipientEmail..." -ForegroundColor Yellow

    for ($i = 1; $i -le $JumlahChat; $i++) {
        try {

            $EmailMessage = New-Object System.Net.Mail.MailMessage

            $EmailMessage.From = New-Object System.Net.Mail.MailAddress($SenderEmail, "")
            $EmailMessage.To.Add($RecipientEmail)
            $EmailMessage.Subject = "$SubjectPesan ($i/$JumlahChat)"
            $EmailMessage.Body = $FormattedBody

            $Client = New-Object System.Net.Mail.SmtpClient($DefaultSmtpServer, $DefaultSmtpPort)
            $Client.EnableSsl = $true
            $Client.Credentials = New-Object System.Net.NetworkCredential($SenderEmail, $SenderPassword)

            $Client.Send($EmailMessage)
            Write-Host "[Sukses] Pesan ke-$i berhasil dikirim." -ForegroundColor Green
        }
        catch {
            Write-Host "[Gagal] Pesan ke-$i gagal dikirim. Error: $_" -ForegroundColor Red
        }

        Start-Sleep -Seconds 1
    }

    if (-not $Creds.IsCustom) {
        Register-Usage
    }

    (Get-Date).ToString("yyyy-MM-dd HH:mm:ss") | Out-File -FilePath $CooldownFile -Force

    Write-Host "`nSemua proses pengiriman telah diproses." -ForegroundColor Cyan
    Write-Host "Cooldown 5 menit." -ForegroundColor Magenta

    $Ulangi = Read-Host "`nApakah Anda ingin mengulang lagi (y/n)"
    
    if ($Ulangi -ne 'y' -and $Ulangi -ne 'Y') {
        Write-Host "Terima kasih telah menggunakan program ini." -ForegroundColor Cyan
        break
    }
    
    Clear-Host
} while ($true)