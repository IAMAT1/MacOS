#!/bin/bash

# Disable Spotlight indexing
sudo mdutil -i off -a

# Enable VNC for all users with full privileges
sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart \
  -configure -allowAccessFor -allUsers -privs -all

# Set VNC to use legacy connection mode
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

# Restart and activate Remote Management agent
sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart \
  -restart -agent -console
sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart \
  -activate

# Download cloudflared binary (correct one for GitHub macOS runner)
curl -L -o cloudflared https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-darwin-amd64
chmod +x cloudflared

# Start Cloudflare Tunnel to expose TCP port 5900 (VNC)
./cloudflared tunnel --url tcp://localhost:5900 --no-autoupdate --logfile tunnel.log > tunnel_output.log 2>&1 &
sleep 10

# Extract and print the public TCP URL
TUNNEL_URL=$(grep -oE 'tcp://[a-z0-9\-\.]+:[0-9]+' tunnel.log | head -n 1)

echo "✅ VNC Access:"
echo "$TUNNEL_URL"
echo "::notice title=VNC Access::$TUNNEL_URL"
