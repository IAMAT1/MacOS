#!/bin/bash

# Disable Spotlight indexing
sudo mdutil -i off -a

# Enable VNC with full access for all users
sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart \
  -configure -allowAccessFor -allUsers -privs -all

# Enable legacy VNC protocol for compatibility
sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart \
  -configure -clientopts -setvnclegacy -vnclegacy yes

# Set VNC password to "runnerrdp"
echo runnerrdp | perl -we '
  BEGIN { @k = unpack "C*", pack "H*", "1734516E8BA8C5E2FF1C39567390ADCA" }
  $_ = <>; chomp; s/^(.{8}).*/$1/;
  @p = unpack "C*", $_;
  foreach (@k) { printf "%02X", $_ ^ (shift @p || 0) }
  print "\n"
' | sudo tee /Library/Preferences/com.apple.VNCSettings.txt

# Restart and activate VNC service
sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -restart -agent -console
sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -activate

# Download cloudflared from Cloudflare's static binary CDN (macOS x86_64)
curl -L -o cloudflared https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/install-cloudflared/static-binaries/cloudflared-darwin-amd64
chmod +x cloudflared

# Start tunnel to VNC (port 5900)
./cloudflared tunnel --url tcp://localhost:5900 --no-autoupdate --logfile tunnel.log > tunnel_output.log 2>&1 &
sleep 10

# Extract and display the public tunnel URL
TUNNEL_URL=$(grep -oE 'tcp://[a-z0-9\-\.]+:[0-9]+' tunnel.log | head -n 1)
echo "✅ VNC Access:"
echo "$TUNNEL_URL"
echo "::notice title=VNC Access::$TUNNEL_URL"
