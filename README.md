# Veeam DPAPI Decryptor (Forensic & Auditing Tool)

A lightweight PowerShell utility designed for system administrators, security auditors, and incident responders to verify the security architecture of **Veeam Backup & Replication** installations. 

The script allows the manual auditing of encrypted strings stored within the Veeam database (`dbo.CryptoKeys` or `dbo.Credentials`) by interacting directly with the local Windows Data Protection API (DPAPI) and the system-specific registry entropy.

## 🛡️ Security & Defensive Context
This tool visualizes how Windows DPAPI secures sensitive data by binding it to the local system context (`DataProtectionScope.LocalMachine`). 
* **Local Scope Isolation:** The decryption **only** succeeds if executed directly on the original Veeam Backup Server with local administrative privileges.
* **Audit & Hardening:** Organizations can use this tool to evaluate the exposure of stored backup encryption passwords and implement further hardening techniques (e.g., migrating to Group Managed Service Accounts (gMSA)).

---

## 🚀 Features
* **Zero Dependencies:** Uses native .NET classes (`SoapHexBinary` and `ProtectedData`). No loops or complex external modules required.
* **Auto-Entropy Extraction:** Automatically retrieves the system-specific `EncryptionSalt` from the local Windows Registry.
* **Input Auto-Cleaning:** Automatically strips prefixes (such as `0x` or hersteller-specific headers) and extracts the pure Windows DPAPI block (`01000000...`).

---

## 📋 Requirements
* **Operating System:** Windows Server 2016 / Windows 10 or newer (requires modern .NET framework capabilities).
* **Privileges:** **Local Administrator** (required to read the registry key and access the local Machine Key store).
* **PowerShell:** Compatible with Windows PowerShell 5.1 and PowerShell 7+.

---

## 🔍 How to Find and Extract Encryption Keys (Step-by-Step)

To audit specific backup encryption passwords, you first need to identify their internal database IDs using the official Veeam PowerShell module, and then retrieve the encrypted data block via SQL.

### Step 1: Identify Encryption Keys via Veeam PowerShell
Open a Veeam PowerShell console on the backup server and run the following command to list all configured encryption passwords along with their unique identifiers:

```powershell
Get-VBREncryptionKey | Select-Object Id, Description
```

*Example Output (Anonymized):*
```text
Id                                   Description
--                                   -----------
aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee Archive-Storage-Key-202X
11111111-2222-3333-4444-555555555555 Cloud-Offsite-Encryption
```

### Step 2: Query the Database using the Extracted ID
Once you have the specific `Id` of the key you wish to audit, connect to your Veeam Database (Microsoft SQL Server or PostgreSQL) and run the following SQL query to retrieve the encrypted hex value:

```sql
SELECT id, key_value, hint 
FROM dbo.CryptoKeys 
WHERE id = 'AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE';
```

*(Note: Depending on your Veeam version, the encrypted column might be named `raw_data` instead of `key_value`.)*

### Step 3: Use the Decryptor Script
Copy the long hex string from the query result (e.g., `0x566565616D...01000000...`) and paste it into this script when prompted.

---

## 💻 Usage Instructions

1. Open an elevated PowerShell prompt (**Run as Administrator**).
2. Copy and paste the script code into the window.
3. Paste the copied Hex string from the database when prompted and hit **Enter**.

### Expected Output (Anonymized)
If executed on the correct server, the script resolves the local master keys and decrypts the value:
```text
==================================================
[!] Kopiere den Hex-Wert aus dbo.CryptoKeys hier hinein:
Hex-Inhalt: 566565616D...01000000D08C9D...
==================================================
[+] Entschluesselung erfolgreich!
Klartext-Passwort: CompanyConfidentialPassword123!
```

---

## 🛠️ Code Snippet Reference

The core mechanism leverages the following .NET security structures:
```powershell
# Symmetrische Entropie aus der Registry laden
\$salt = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Veeam\Veeam Backup and Replication\Data").EncryptionSalt
\(entropy = [System.Convert]::FromBase64String(\)salt)

# DPAPI-Schnittstelle aufrufen
[System.Security.Cryptography.ProtectedData]::Unprotect(bytes, entropy, [System.Security.Cryptography.DataProtectionScope]::LocalMachine)
```

---

## 🛑 Disclaimer
This project is for educational, forensic auditing, and authorized defensive security testing purposes only. Do not run it on production environments without proper authorization.
