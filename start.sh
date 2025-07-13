#!/bin/bash

# Disable Spotlight indexing (for performance)
sudo mdutil -i off -a

# Enable VNC for all users with all privileges
sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart \
  -configure -allowAccessFor -allUsers -privs -all

# Set VNC to use legacy mode (compatible with most clients)
sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart \
  -configure -clientopts -setvnclegacy -vnclegacy yes

# Set VNC password to: runnerrdp
echo runnerrdp | perl -we '
  BEGIN { @k = unpack "C*", pack "H*", "1734516E8BA8C5E2FF1C39567390ADCA" }
  $_ = <>; chomp; s/^(.{8}).*/$1/;
  @p = unpack "C*", $_;
  foreach (@k) { printf "%02X", $_ ^ (shift @p || 0) }
  print "\n"
' | sudo tee /Library/Preferences/com.apple.VNCSettings.txt

# Restart and activate the VNC service
sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -restart -agent -console
sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -activate

# Download and install Cloudflare Tunnel (cloudflared) binary
curl -LJO https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-darwin-amd64
mv cloudflared-darwin-amd64 cloudflared
chmod +x cloudflared

# Start tunnel to forward TCP port 5900 (VNC), log output
./cloudflared tunnel --url tcp://localhost:5900 --no-autoupdate --logfile tunnel.log > tunnel_output.log 2>&1 &
sleep 10

# Extract tunnel URL from logs
TUNNEL_URL=$(grep -oE 'tcp://[a-z0-9\-\.]+:[0-9]+' tunnel.log | head -n 1)

# Show the tunnel URL
echo "✅ VNC Access:"
echo "$TUNNEL_URL"
echo "::notice title=VNC Access::$TUNNEL_URL"
