#!/bin/bash

# Run as root
[[ "$(whoami)" != "root" ]] && {
    echo -e "\033[1;33m[\033[1;31mErro\033[1;33m] \033[1;37m- \033[1;33myou need to run as root\033[0m"
    rm /home/ubuntu/install.sh &>/dev/null
    exit 0
}

#=== setup ===
cd 
rm -rf /root/udp
mkdir -p /root/udp
rm -rf /etc/UDPCustom
mkdir -p /etc/UDPCustom
sudo touch /etc/UDPCustom/udp-custom
udp_dir='/etc/UDPCustom'
udp_file='/etc/UDPCustom/udp-custom'

sudo apt update -y
sudo apt upgrade -y
sudo apt install -y wget
sudo apt install -y curl
sudo apt install -y dos2unix
sudo apt install -y neofetch
sudo apt install -y python3 python3-pip

# Install Python Telegram Bot
pip3 install python-telegram-bot requests

source <(curl -sSL 'https://raw.githubusercontent.com/http-custom/udp-custom/main/module/module')

time_reboot() {
  print_center -ama "${a92:-System/Server Reboot In} $1 ${a93:-Seconds}"
  REBOOT_TIMEOUT="$1"

  while [ $REBOOT_TIMEOUT -gt 0 ]; do
    print_center -ne "-$REBOOT_TIMEOUT-\r"
    sleep 1
    : $((REBOOT_TIMEOUT--))
  done
  rm /home/ubuntu/install.sh &>/dev/null
  rm /root/install.sh &>/dev/null
  echo -e "\033[01;31m\033[1;33m More Updates, Follow Us On \033[1;31m(\033[1;36mTelegram\033[1;31m): \033[1;37m@voltssh\033[0m"
  reboot
}

# Function to setup Telegram Bot
setup_telegram_bot() {
    local bot_token="$1"
    local admin_id="$2"
    
    # Create Telegram bot script
    cat > /etc/UDPCustom/telegram_bot.py << EOF
import os
import subprocess
import telegram
from telegram import Update
from telegram.ext import Updater, CommandHandler, MessageHandler, Filters, CallbackContext

# Configuration
BOT_TOKEN = "$bot_token"
ADMIN_ID = $admin_id

def authorized_only(func):
    def wrapper(update: Update, context: CallbackContext):
        if update.effective_user.id != ADMIN_ID:
            update.message.reply_text("🚫 Unauthorized access!")
            return
        return func(update, context)
    return wrapper

@authorized_only
def start(update: Update, context: CallbackContext):
    update.message.reply_text(
        "🤖 UDP Custom Manager Bot\\n"
        "Available commands:\\n"
        "/menu - Show main menu\\n"
        "/status - Check server status\\n"
        "/restart - Restart UDP services\\n"
        "/execute <command> - Execute shell command\\n"
        "/logs - Show recent logs\\n"
        "/reboot - Reboot server"
    )

@authorized_only
def show_menu(update: Update, context: CallbackContext):
    menu_text = """
🔧 UDP Custom Manager Menu

1️⃣ UDP Custom
2️⃣ Tweak UDP Speed ⚡
3️⃣ VPS Info ℹ️
4️⃣ Service Status 📊
5️⃣ Execute Command 💻
6️⃣ View Logs 📋
7️⃣ Restart Services 🔄
8️⃣ Reboot Server 🚀
    """
    update.message.reply_text(menu_text)

@authorized_only
def server_status(update: Update, context: CallbackContext):
    try:
        # Get system info
        cpu_usage = subprocess.getoutput("top -bn1 | grep 'Cpu(s)' | awk '{print \$2}'")
        ram_usage = subprocess.getoutput("free -m | awk 'NR==2{printf \"%.2f%%\", \$3*100/\$2 }'")
        disk_usage = subprocess.getoutput("df -h | awk '\$NF==\"/\"{printf \"%s\", \$5}'")
        uptime = subprocess.getoutput("uptime -p")
        
        # Check UDP services status
        udp_service = subprocess.getoutput("systemctl is-active udp-custom")
        udpgw_service = subprocess.getoutput("systemctl is-active udpgw")
        
        status_text = f"""
📊 Server Status

💻 CPU Usage: {cpu_usage}
🧠 RAM Usage: {ram_usage}
💾 Disk Usage: {disk_usage}
⏰ Uptime: {uptime}

🔧 Services:
• UDP Custom: {udp_service}
• UDP Gateway: {udpgw_service}
        """
        update.message.reply_text(status_text)
    except Exception as e:
        update.message.reply_text(f"❌ Error getting status: {str(e)}")

@authorized_only
def execute_command(update: Update, context: CallbackContext):
    if not context.args:
        update.message.reply_text("⚠️ Usage: /execute <command>")
        return
    
    command = ' '.join(context.args)
    try:
        result = subprocess.getoutput(command)
        if len(result) > 4000:
            result = result[:4000] + "\\n... (truncated)"
        update.message.reply_text(f"✅ Command executed:\\n```\\n{result}\\n```", parse_mode='Markdown')
    except Exception as e:
        update.message.reply_text(f"❌ Error: {str(e)}")

@authorized_only
def show_logs(update: Update, context: CallbackContext):
    try:
        logs = subprocess.getoutput("journalctl -u udp-custom -n 20 --no-pager")
        if len(logs) > 4000:
            logs = logs[:4000] + "\\n... (truncated)"
        update.message.reply_text(f"📋 Recent logs:\\n```\\n{logs}\\n```", parse_mode='Markdown')
    except Exception as e:
        update.message.reply_text(f"❌ Error getting logs: {str(e)}")

@authorized_only
def restart_services(update: Update, context: CallbackContext):
    try:
        update.message.reply_text("🔄 Restarting UDP services...")
        subprocess.run(["systemctl", "restart", "udp-custom"], check=True)
        subprocess.run(["systemctl", "restart", "udpgw"], check=True)
        update.message.reply_text("✅ Services restarted successfully!")
    except Exception as e:
        update.message.reply_text(f"❌ Error restarting services: {str(e)}")

@authorized_only
def reboot_server(update: Update, context: CallbackContext):
    try:
        update.message.reply_text("🚀 Server will reboot in 10 seconds...")
        subprocess.run(["shutdown", "-r", "+10"], check=True)
    except Exception as e:
        update.message.reply_text(f"❌ Error scheduling reboot: {str(e)}")

def handle_message(update: Update, context: CallbackContext):
    if update.effective_user.id != ADMIN_ID:
        return
    
    text = update.message.text
    
    if text == '1':
        result = subprocess.getoutput("udp")
        update.message.reply_text(f"🔧 UDP Custom output:\\n```\\n{result}\\n```", parse_mode='Markdown')
    elif text == '2':
        update.message.reply_text("⚡ Tweak UDP Speed feature")
        # Add your UDP speed tweak command here
    elif text == '3':
        result = subprocess.getoutput("neofetch --stdout")
        update.message.reply_text(f"ℹ️ VPS Info:\\n```\\n{result}\\n```", parse_mode='Markdown')
    elif text == '4':
        server_status(update, context)
    elif text == '5':
        update.message.reply_text("💻 Use /execute <command> to run shell commands")
    elif text == '6':
        show_logs(update, context)
    elif text == '7':
        restart_services(update, context)
    elif text == '8':
        reboot_server(update, context)

def main():
    updater = Updater(BOT_TOKEN)
    dispatcher = updater.dispatcher

    # Add handlers
    dispatcher.add_handler(CommandHandler("start", start))
    dispatcher.add_handler(CommandHandler("menu", show_menu))
    dispatcher.add_handler(CommandHandler("status", server_status))
    dispatcher.add_handler(CommandHandler("execute", execute_command))
    dispatcher.add_handler(CommandHandler("logs", show_logs))
    dispatcher.add_handler(CommandHandler("restart", restart_services))
    dispatcher.add_handler(CommandHandler("reboot", reboot_server))
    dispatcher.add_handler(MessageHandler(Filters.text & ~Filters.command, handle_message))

    updater.start_polling()
    updater.idle()

if __name__ == '__main__':
    main()
EOF

    # Create systemd service for Telegram bot
    cat > /etc/systemd/system/telegram-udp-bot.service << EOF
[Unit]
Description=UDP Custom Telegram Bot
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/etc/UDPCustom
ExecStart=/usr/bin/python3 /etc/UDPCustom/telegram_bot.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

    chmod +x /etc/UDPCustom/telegram_bot.py
    systemctl daemon-reload
    systemctl enable telegram-udp-bot
    systemctl start telegram-udp-bot
}

# Check Ubuntu version
if [ "$(lsb_release -rs)" = "8*|9*|10*|11*|16.04*|18.04*" ]; then
  clear
  print_center -ama -e "\e[1m\e[31m=====================================================\e[0m"
  print_center -ama -e "\e[1m\e[33m${a94:-this script is not compatible with your operating system}\e[0m"
  print_center -ama -e "\e[1m\e[33m ${a95:-Use Ubuntu 20 or higher}\e[0m"
  print_center -ama -e "\e[1m\e[31m=====================================================\e[0m"
  rm /home/ubuntu/install.sh
  exit 1
else
  clear
  echo ""
  print_center -ama "A Compatible OS/Environment Found"
  print_center -ama " ⇢ Installation begins...! <"
  sleep 3

  # [change timezone to UTC +0]
  echo ""
  echo " ⇢ Binary Core official ePro Dev Team"
  echo " ⇢ UDP Custom + Telegram Bot"
  sleep 3

  # [+clean up+]
  rm -rf $udp_file &>/dev/null
  rm -rf /etc/UDPCustom/udp-custom &>/dev/null
  rm -rf /etc/limiter.sh &>/dev/null
  rm -rf /etc/UDPCustom/limiter.sh &>/dev/null
  rm -rf /etc/UDPCustom/module &>/dev/null
  rm -rf /usr/bin/udp &>/dev/null
  rm -rf /etc/UDPCustom/udpgw.service &>/dev/null
  rm -rf /etc/udpgw.service &>/dev/null
  systemctl stop udpgw &>/dev/null
  systemctl stop udp-custom &>/dev/null

 # [+get files ⇣⇣⇣+]
  source <(curl -sSL 'https://raw.githubusercontent.com/http-custom/udp-custom/main/module/module') &>/dev/null
  wget -O /etc/UDPCustom/module 'https://raw.githubusercontent.com/http-custom/udp-custom/main/module/module' &>/dev/null
  chmod +x /etc/UDPCustom/module

  wget "https://raw.github.com/http-custom/udp-custom/main/bin/udp-custom-linux-amd64" -O /root/udp/udp-custom &>/dev/null
  chmod +x /root/udp/udp-custom

  wget -O /etc/limiter.sh 'https://raw.githubusercontent.com/http-custom/udp-custom/main/module/limiter.sh'
  cp /etc/limiter.sh /etc/UDPCustom
  chmod +x /etc/limiter.sh
  chmod +x /etc/UDPCustom
  
  # [+udpgw+]
  wget -O /etc/udpgw 'https://raw.github.com/http-custom/udp-custom/main/module/udpgw'
  mv /etc/udpgw /bin
  chmod +x /bin/udpgw

  # [+service+]
  wget -O /etc/udpgw.service 'https://raw.githubusercontent.com/http-custom/udp-custom/main/config/udpgw.service'
  wget -O /etc/udp-custom.service 'https://raw.githubusercontent.com/http-custom/udp-custom/main/config/udp-custom.service'
  
  mv /etc/udpgw.service /etc/systemd/system
  mv /etc/udp-custom.service /etc/systemd/system

  chmod 640 /etc/systemd/system/udpgw.service
  chmod 640 /etc/systemd/system/udp-custom.service
  
  systemctl daemon-reload &>/dev/null
  systemctl enable udpgw &>/dev/null
  systemctl start udpgw &>/dev/null
  systemctl enable udp-custom &>/dev/null
  systemctl start udp-custom &>/dev/null

  # [+config+]
  wget "https://raw.githubusercontent.com/http-custom/udp-custom/main/config/config.json" -O /root/udp/config.json &>/dev/null
  chmod +x /root/udp/config.json

  # [+menu+]
  wget -O /usr/bin/udp 'https://raw.githubusercontent.com/http-custom/udp-custom/main/module/udp' 
  chmod +x /usr/bin/udp
  ufw disable &>/dev/null
  sudo apt-get remove --purge ufw firewalld -y
  apt remove netfilter-persistent -y

  # Setup Telegram Bot
  clear
  echo ""
  print_center -ama "🤖 Telegram Bot Setup"
  echo ""
  read -p "Enter your Telegram Bot Token: " bot_token
  read -p "Enter your Telegram User ID: " admin_id
  
  if [ -n "$bot_token" ] && [ -n "$admin_id" ]; then
      setup_telegram_bot "$bot_token" "$admin_id"
      echo ""
      print_center -ama "✅ Telegram Bot installed successfully!"
      echo ""
      echo "🤖 Bot Commands:"
      echo "  /start - Start the bot"
      echo "  /menu - Show main menu"
      echo "  /status - Check server status"
      echo "  /execute - Run shell commands"
      echo "  /logs - View service logs"
      echo "  /restart - Restart UDP services"
      echo "  /reboot - Reboot server"
      echo ""
      echo "📱 You can also use number menu (1-8) in the bot"
      sleep 5
  else
      echo ""
      print_center -ama "⚠️ Telegram Bot setup skipped"
      sleep 2
  fi

  clear
  echo ""
  echo ""
  print_center -ama "${a103:-setting up, please wait...}"
  sleep 6
  title "${a102:-Installation Successful}"
  print_center -ama "${a103:-  To show menu type: \nudp\n}"
  if [ -n "$bot_token" ] && [ -n "$admin_id" ]; then
      print_center -ama "${a103:-  Or use Telegram Bot for remote management\n}"
  fi
  echo -ne "\n\033[1;31mENTER \033[1;33mpara entrar al \033[1;32mMENU!\033[0m"; read
   udp
  
fi
