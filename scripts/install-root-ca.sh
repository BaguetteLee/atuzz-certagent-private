#!/usr/bin/env bash
# ==============================================================================
# Atuzz CertAgent Private - Enterprise Root CA Linux Silent Trust Store Installer
# Compatible with: Ubuntu / Debian / CentOS / RHEL / Rocky / AlmaLinux / Alpine
# ==============================================================================

set -e

echo "============================================================"
echo "  Atuzz CertAgent Private - Root CA Trust Store Installer"
echo "============================================================"

# 1. Check root / sudo privileges
if [ "$(id -u)" -ne 0 ]; then
    echo "[-] Error: Please run this script as root or with sudo"
    echo "    Usage: sudo bash $0 [CertAgent-Hub-URL]"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_CRT="${SCRIPT_DIR}/root-ca.crt"
SERVER_URL="$1"
if [ -z "$SERVER_URL" ]; then
    INJECTED_HUB_URL="__HUB_URL_PLACEHOLDER__"
    if [ "$INJECTED_HUB_URL" != "__HUB_URL_PLACEHOLDER__" ]; then
        SERVER_URL="$INJECTED_HUB_URL"
    fi
fi

# 2. If root-ca.crt does not exist locally, download from server
if [ ! -f "$TARGET_CRT" ]; then
    if [ -z "$SERVER_URL" ]; then
        read -r -p "Please enter CertAgent Hub URL (e.g. http://192.168.1.100:3000): " SERVER_URL
    fi

    if [ -n "$SERVER_URL" ]; then
        echo "[*] Downloading Root CA from ${SERVER_URL}..."
        TMP_CRT="/tmp/certagent-root-ca.crt"
        if command -v curl >/dev/null 2>&1; then
            curl -fsSL "${SERVER_URL}/api/ca/root-cert?download=1" -o "$TMP_CRT"
        elif command -v wget >/dev/null 2>&1; then
            wget -q "${SERVER_URL}/api/ca/root-cert?download=1" -O "$TMP_CRT"
        else
            echo "[-] Error: Neither curl nor wget was found on the system. Please install one first"
            exit 1
        fi
        TARGET_CRT="$TMP_CRT"
        echo "[+] Root CA downloaded successfully"
    else
        echo "[-] Error: No root CA file provided and no server URL specified. Aborted."
        exit 1
    fi
fi

echo "[*] Detecting Linux distribution and importing to system trust store..."

if [ -d "/usr/local/share/ca-certificates" ]; then
    # Debian / Ubuntu / Alpine
    cp "$TARGET_CRT" /usr/local/share/ca-certificates/certagent-ca.crt
    if command -v update-ca-certificates >/dev/null 2>&1; then
        update-ca-certificates
        echo "[√] Debian/Ubuntu/Alpine trust store updated successfully"
    else
        echo "[-] update-ca-certificates not found. Please install ca-certificates package"
        exit 1
    fi
elif [ -d "/etc/pki/ca-trust/source/anchors" ]; then
    # CentOS / RHEL / Rocky / AlmaLinux / Fedora
    cp "$TARGET_CRT" /etc/pki/ca-trust/source/anchors/certagent-ca.crt
    if command -v update-ca-trust >/dev/null 2>&1; then
        update-ca-trust extract
        echo "[√] RHEL/CentOS/Rocky trust store updated successfully"
    else
        echo "[-] update-ca-trust not found. Please install ca-certificates package"
        exit 1
    fi
else
    echo "[-] Standard CA certificate directory not found"
    echo "    Please manually import $TARGET_CRT into system trust store"
    exit 1
fi

echo ""
echo "============================================================"
echo " [√] Enterprise Root CA installation complete!"
echo "============================================================"
echo " - Native curl/wget and system processes now fully trust internal HTTPS services."
echo ""
