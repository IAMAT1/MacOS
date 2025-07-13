#!/bin/bash

echo "🔧 Disabling Spotlight..."
sudo mdutil -i off -a

echo "🔧 Enabling Remote Management..."
sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart \
  -configure -allowAccessFor -allUsers -privs -all

sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart \
  -configure -clientopts -setvnclegacy -vnclegacy yes

echo "🔐 Setting VNC password..."
echo runnerrdp | perl -we '
  BEGIN { @k = unpack "C*", pack "H*", "1734516E8BA8C5E2FF1C39567390ADCA" }
  $_ = <>; chomp; s/^(.{8}).*/$1/;
  @p = unpack "C*", $_;
  foreach (@k) { printf "%02X", $_ ^ (shift @p || 0) }
  print "\n"
' | sudo tee /Library/Preferences/com.apple.VNCSettings.txt

echo "✅ Restarting Remote Desktop services..."
sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -restart -agent -console
sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -activate

# Download Playit client
echo "⬇️ Downloading Playit..."
curl -L -o playit https://github.com/playit-cloud/playit-agent/releases/latest/download/playit-darwin-amd64
chmod +x playit

# Write Playit config from GitHub Secret
mkdir -p ~/.playit
echo "$PLAYIT_CONFIG" > ~/.playit/playit.toml

# Run tunnel
echo "🚀 Starting Playit tunnel..."
./playit &

# Optional: show success
echo "✅ VNC server ready!"
echo "Connect via VNC to: sell-invisible.gl.at.ply.gg::12767"
