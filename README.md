# TinyVM Cloud

Experimental Windows 11 ARM64 VM that runs inside a GitHub Codespace and displays through noVNC in a browser.

## Start

1. Create a Codespace for this repository.
2. Wait for the setup script to finish.
3. Upload Microsoft's official Windows 11 ARM64 ISO to the repository root and name it `Windows11-arm64.iso`.
4. Run `bash scripts/start-vm.sh` in the Codespace terminal.
5. Open port **6080** from the Codespace **Ports** panel.

The virtual disk is stored at `~/tinyvm-data/windows.qcow2`. It has 64 GB virtual capacity but grows only as data is written.

## Windows Setup

If Setup reports that the PC does not meet Windows 11 requirements, press **Shift-F10** and run:

```bat
reg add HKLM\SYSTEM\Setup\LabConfig /v BypassTPMCheck /t REG_DWORD /d 1 /f
reg add HKLM\SYSTEM\Setup\LabConfig /v BypassSecureBootCheck /t REG_DWORD /d 1 /f
```

Close Command Prompt, go back one screen, and continue. Choose **I don't have a product key** if you are evaluating an unactivated installation.

## Limits

- Software emulation is extremely slow.
- Codespaces free usage and storage are monthly quotas.
- The private forwarded port requires the repository owner's GitHub login.
- Supabase and Vercel can provide a launch portal, but the VM itself runs in Codespaces.
