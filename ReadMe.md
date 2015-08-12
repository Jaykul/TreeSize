This is just a Get-TreeSize function to show (recursively) how much space (files and) folders take up.  I wrote it in a 3hr live-coding session on Floobits as an exercise for the [PowerShell virtual user group](http://PowerShell.slack.com) (for an invite visit http://slack.poshcode.org)

Anyway, there's just one function and a format file. Please enjoy.

To install:

```posh
Install-Module -Name TreeSize
```

Example usage:

```
PS> Get-Treesize

Localization\ 12021
├─ En-US\     2025
├─ En\        1339
```

```
PS> Get-Treesize -ShowFiles

Localization\           12021
├─ Localization.psd1    6698
├─ En-US\               2025
   ├─ UserSettings.psd1 1000
   ├─ Localization.psd1 958
   ├─ numbers.psd1      67
├─ UserSettings.psd1    1959
├─ En\                  1339
   ├─ UserSettings.psd1 1253
   ├─ numbers.psd1      86
```

```
PS> Get-Treesize | Format-Custom

Localization\ (11.74 KB)
├─ En-US\ (1.98 KB)
├─ En\ (1.31 KB)
```