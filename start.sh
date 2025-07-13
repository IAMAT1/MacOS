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

echo "⬇️ Downloading Playit agent..."
curl -L -o playit https://github.com/playit-cloud/playit-agent/releases/download/v0.15.5/playit-darwin-amd64
chmod +x playit

echo "📂 Writing Playit config from GitHub secret..."
mkdir -p ~/.playit
echo "$PLAYIT_CONFIG" > ~/.playit/playit.toml

echo "🚀 Starting Playit tunnel..."
./playit &

sleep 5
echo "✅ VNC server ready!"
echo "🔗 Connect using RealVNC: sell-invisible.gl.at.ply.gg::12767"
echo "🔑 Password: runnerrdp"
