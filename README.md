# TinyVM Cloud

A lightweight Linux desktop that runs in a GitHub Codespace and opens in your browser through noVNC.

## Start

1. Open or rebuild the Codespace for this repository.
2. Wait for setup to finish. The Linux desktop starts automatically.
3. Open port **6080**, or use the existing TinyVM Cloud link.
4. If noVNC shows a **Connect** button, click it.

To restart manually, run `bash scripts/start-vm.sh`.

## What changed

The project now uses XFCE Linux instead of Windows and QEMU. It does not need a Windows license, Windows ISO, or virtual disk. The existing port 6080/noVNC link is unchanged.

## Limits

- GitHub Codespaces free usage and storage are monthly quotas.
- The Codespace stops after inactivity and must be started again.
- The private desktop link may require the repository owner's GitHub sign-in.
