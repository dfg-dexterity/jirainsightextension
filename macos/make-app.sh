#!/usr/bin/env bash
# Compila e empacota o Jira Quick Ticket como aplicativo (.app) de barra de menus.
# Uso: ./make-app.sh   (na pasta macos/; requer Xcode Command Line Tools)
set -euo pipefail
cd "$(dirname "$0")"

swift build -c release

APP=dist/JiraQuickTicket.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp .build/release/JiraQuickTicket "$APP/Contents/MacOS/JiraQuickTicket"

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>Jira Quick Ticket</string>
  <key>CFBundleDisplayName</key><string>Jira Quick Ticket</string>
  <key>CFBundleIdentifier</key><string>br.com.dexterity.jiraquickticket</string>
  <key>CFBundleExecutable</key><string>JiraQuickTicket</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>1.0.0</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
  <key>LSUIElement</key><true/>
  <key>NSHumanReadableCopyright</key><string>Dexterity IT Solutions</string>
</dict>
</plist>
PLIST

# Assinatura ad-hoc: mantém a permissão de Acessibilidade estável entre rebuilds.
codesign --force --deep -s - "$APP"

echo
echo "Gerado: macos/$APP"
echo "Arraste para /Applications e abra. Na primeira captura, autorize o app em"
echo "Ajustes do Sistema → Privacidade e Segurança → Acessibilidade."
