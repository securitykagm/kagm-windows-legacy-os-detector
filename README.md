# Legacy Windows & Windows 10 Sürüm Tespit Scripti (Active Directory)

Bu PowerShell scripti, **Active Directory ortamında** yer alan bilgisayarları tarayarak  
**destek dışı (legacy)** veya **desteği sona ermiş / sona yaklaşmış** Windows sürümlerini tespit etmek amacıyla hazırlanmıştır.

Script **salt-okunur (read-only)** çalışır ve sistemlerde herhangi bir değişiklik yapmaz.

---

## Ne Yapar?

- Active Directory’deki **etkin bilgisayar hesaplarını** sorgular
- Aşağıdaki işletim sistemlerini tespit eder:
  - Windows 7
  - Windows 8 / 8.1
  - Windows 10 (build numarasına göre sürüm sınıflandırması)
- Windows 10 için:
  - 21H2, 22H2 vb. sürümleri **OperatingSystemVersion** üzerinden ayırt eder
  - Destek durumunu yorumlar
- İsteğe bağlı olarak:
  - Sonuçları CSV olarak dışa aktarır
---

## Gereksinimler

- Active Directory ortamı
- RSAT – ActiveDirectory PowerShell modülü  
  (Domain Controller veya RSAT yüklü yönetici bilgisayarı)
- AD bilgisayar nesnelerini okuma yetkisi

---

## Kullanım

### 1️⃣ Sadece Windows 7 / 8 / 8.1 işletim sistemlerini listelemek için 

```powershell.\Find-LegacyAndWin10Builds.ps1```

### 1️⃣ Windows 10 sürümlerini de sınıflandırarak dahil etmek için

```.\Find-LegacyAndWin10Builds.ps1 -IncludeWindows10```

### 1️⃣ Belirli bir OU altında çalıştırmak için

```.\Find-LegacyAndWin10Builds.ps1 `-SearchBase "OU=Computers,DC=domain,DC=local" `-IncludeWindows10```

### 1️⃣ Sonuçları CSV olarak dışa aktarmak için

```.\Find-LegacyAndWin10Builds.ps1 `-IncludeWindows10 `-ExportCsv `-ExportPath "C:\Temp\os_envanteri.csv"```
