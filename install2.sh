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
sudo apt install -y python3 python3-pip jq

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
    cat > /etc/UDPCustom/telegram_bot.py << 'EOF'
import os
import subprocess
import logging
from telegram import Update
from telegram.ext import Updater, CommandHandler, MessageHandler, Filters, CallbackContext

# Setup logging
logging.basicConfig(
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    level=logging.INFO
)
logger = logging.getLogger(__name__)

# Configuration - will be replaced by actual values
BOT_TOKEN = "YOUR_BOT_TOKEN"
ADMIN_ID = YOUR_ADMIN_ID

def authorized_only(func):
    def wrapper(update: Update, context: CallbackContext):
        if update.effective_user.id != ADMIN_ID:
            update.message.reply_text("🚫 Unauthorized access! This bot is for admin only.")
            return
        return func(update, context)
    return wrapper

@authorized_only
def start(update: Update, context: CallbackContext):
    user = update.effective_user
    welcome_text = f"""
🤖 *UDP Custom Manager Bot*

Hello {user.first_name}! 
I can help you manage your UDP Custom server remotely.

*Available Commands:*
/menu - Show main menu
/status - Check server status  
/restart - Restart UDP services
/execute <command> - Execute shell command
/logs - Show recent logs
/reboot - Reboot server
/help - Show this help message

You can also use number menu (1-8) for quick actions.
    """
    update.message.reply_text(welcome_text, parse_mode='Markdown')

@authorized_only
def help_command(update: Update, context: CallbackContext):
    help_text = """
🔧 *Available Commands:*

*Main Commands:*
/menu - Show interactive menu
/status - Server status (CPU, RAM, Disk, Services)
/restart - Restart all UDP services
/execute <command> - Run shell command
/logs - Show UDP service logs  
/reboot - Reboot server (10s delay)

*Quick Menu (send numbers):*
1 - UDP Custom Manager
2 - Tweak UDP Speed
3 - VPS Information
4 - Service Status
5 - Execute Command
6 - View Logs  
7 - Restart Services
8 - Reboot Server
    """
    update.message.reply_text(help_text, parse_mode='Markdown')

@authorized_only
def show_menu(update: Update, context: CallbackContext):
    menu_text = """
🔧 *UDP Custom Manager Menu*

*Choose an option (1-8):*

1️⃣ *UDP Custom* - Main UDP manager
2️⃣ *Tweak UDP Speed* ⚡ - Optimize speed
3️⃣ *VPS Info* ℹ️ - System information  
4️⃣ *Service Status* 📊 - Check services status
5️⃣ *Execute Command* 💻 - Run shell commands
6️⃣ *View Logs* 📋 - Service logs
7️⃣ *Restart Services* 🔄 - Restart UDP services
8️⃣ *Reboot Server* 🚀 - Reboot the server

Just send the number (1-8) for quick action!
    """
    update.message.reply_text(menu_text, parse_mode='Markdown')

@authorized_only
def server_status(update: Update, context: CallbackContext):
    try:
        update.message.reply_text("🔄 Getting server status...")
        
        # Get system info
        cpu_usage = subprocess.getoutput("top -bn1 | grep 'Cpu(s)' | awk '{print $2}' | head -1")
        ram_info = subprocess.getoutput("free -m | awk 'NR==2{printf \"%.2f%%\", $3*100/$2 }'")
        disk_usage = subprocess.getoutput("df -h / | awk 'NR==2{print $5}'")
        uptime = subprocess.getoutput("uptime -p")
        hostname = subprocess.getoutput("hostname")
        
        # Check UDP services status
        udp_service = subprocess.getoutput("systemctl is-active udp-custom")
        udpgw_service = subprocess.getoutput("systemctl is-active udpgw")
        
        # Get service status with emoji
        udp_status = "✅ Running" if udp_service == "active" else "❌ Stopped"
        udpgw_status = "✅ Running" if udpgw_service == "active" else "❌ Stopped"
        
        status_text = f"""
📊 *Server Status Report*

*System Information:*
• 🖥️ Hostname: `{hostname}`
• 💻 CPU Usage: `{cpu_usage}`
• 🧠 RAM Usage: `{ram_info}`
• 💾 Disk Usage: `{disk_usage}`
• ⏰ Uptime: `{uptime}`

*Service Status:*
• 🔧 UDP Custom: {udp_status}
• 🌐 UDP Gateway: {udpgw_status}

*Quick Actions:*
Send /restart to restart services
Send /logs to view service logs
        """
        update.message.reply_text(status_text, parse_mode='Markdown')
        
    except Exception as e:
        logger.error(f"Error getting status: {e}")
        update.message.reply_text(f"❌ Error getting server status: {str(e)}")

@authorized_only
def execute_command(update: Update, context: CallbackContext):
    if not context.args:
        update.message.reply_text("⚠️ Usage: `/execute <command>`\nExample: `/execute ls -la`", parse_mode='Markdown')
        return
    
    command = ' '.join(context.args)
    
    # Security check - prevent dangerous commands
    dangerous_commands = ['rm -rf /', 'dd if=', 'mkfs', 'fdisk', ':(){:|:&};:']
    if any(cmd in command for cmd in dangerous_commands):
        update.message.reply_text("🚫 This command is not allowed for security reasons.")
        return
        
    try:
        update.message.reply_text(f"🔄 Executing: `{command}`", parse_mode='Markdown')
        
        # Execute command with timeout
        result = subprocess.run(
            command, 
            shell=True, 
            capture_output=True, 
            text=True, 
            timeout=30
        )
        
        output = result.stdout if result.stdout else result.stderr
        
        if not output:
            output = "Command executed successfully (no output)"
            
        # Truncate if too long
        if len(output) > 3500:
            output = output[:3500] + "\n... (output truncated)"
            
        update.message.reply_text(f"✅ Result:\n```\n{output}\n```", parse_mode='Markdown')
        
    except subprocess.TimeoutExpired:
        update.message.reply_text("⏰ Command timed out after 30 seconds")
    except Exception as e:
        update.message.reply_text(f"❌ Error: {str(e)}")

@authorized_only
def show_logs(update: Update, context: CallbackContext):
    try:
        update.message.reply_text("📋 Getting recent logs...")
        
        # Get last 15 lines of udp-custom service logs
        logs = subprocess.getoutput("journalctl -u udp-custom -n 15 --no-pager")
        
        if not logs:
            logs = "No logs found for udp-custom service"
            
        if len(logs) > 3500:
            logs = logs[:3500] + "\n... (logs truncated)"
            
        update.message.reply_text(f"📄 Recent UDP Custom logs:\n```\n{logs}\n```", parse_mode='Markdown')
        
    except Exception as e:
        update.message.reply_text(f"❌ Error getting logs: {str(e)}")

@authorized_only
def restart_services(update: Update, context: CallbackContext):
    try:
        update.message.reply_text("🔄 Restarting UDP services...")
        
        # Restart services
        subprocess.run(["systemctl", "restart", "udp-custom"], check=True)
        subprocess.run(["systemctl", "restart", "udpgw"], check=True)
        
        # Check status after restart
        udp_status = subprocess.getoutput("systemctl is-active udp-custom")
        udpgw_status = subprocess.getoutput("systemctl is-active udpgw")
        
        if udp_status == "active" and udpgw_status == "active":
            update.message.reply_text("✅ Services restarted successfully and are running!")
        else:
            update.message.reply_text("⚠️ Services restarted but may not be running properly. Check /status")
            
    except Exception as e:
        update.message.reply_text(f"❌ Error restarting services: {str(e)}")

@authorized_only
def reboot_server(update: Update, context: CallbackContext):
    try:
        update.message.reply_text("🚀 Server will reboot in 10 seconds...")
        subprocess.run(["nohup", "shutdown", "-r", "+10"], check=True)
    except Exception as e:
        update.message.reply_text(f"❌ Error scheduling reboot: {str(e)}")

def handle_text_message(update: Update, context: CallbackContext):
    if update.effective_user.id != ADMIN_ID:
        update.message.reply_text("🚫 Unauthorized access! This bot is for admin only.")
        return
    
    text = update.message.text.strip()
    
    if text == '1':
        update.message.reply_text("🔧 Launching UDP Custom Manager...")
        try:
            result = subprocess.getoutput("udp")
            if len(result) > 3500:
                result = result[:3500] + "\n... (output truncated)"
            update.message.reply_text(f"```\n{result}\n```", parse_mode='Markdown')
        except Exception as e:
            update.message.reply_text(f"❌ Error: {str(e)}")
            
    elif text == '2':
        update.message.reply_text("⚡ UDP Speed Tweak feature would be executed here")
        # Add actual UDP speed tweak command
        # result = subprocess.getoutput("your-udp-speed-command")
        
    elif text == '3':
        update.message.reply_text("ℹ️ Getting VPS information...")
        try:
            result = subprocess.getoutput("neofetch --stdout")
            if not result:
                result = subprocess.getoutput("uname -a")
            if len(result) > 3500:
                result = result[:3500] + "\n... (output truncated)"
            update.message.reply_text(f"```\n{result}\n```", parse_mode='Markdown')
        except Exception as e:
            update.message.reply_text(f"❌ Error: {str(e)}")
            
    elif text == '4':
        server_status(update, context)
        
    elif text == '5':
        update.message.reply_text("💻 To execute commands, use:\n`/execute <command>`\nExample: `/execute ls -la`", parse_mode='Markdown')
        
    elif text == '6':
        show_logs(update, context)
        
    elif text == '7':
        restart_services(update, context)
        
    elif text == '8':
        reboot_server(update, context)
        
    else:
        update.message.reply_text("❓ Unknown command. Send /menu to see available options.")

def error_handler(update: Update, context: CallbackContext):
    logger.error(f"Update {update} caused error {context.error}")

def main():
    # Replace placeholders with actual values
    with open('/etc/UDPCustom/telegram_bot.py', 'r') as file:
        content = file.read()
    
    content = content.replace('BOT_TOKEN = "YOUR_BOT_TOKEN"', f'BOT_TOKEN = "{BOT_TOKEN}"')
    content = content.replace('ADMIN_ID = YOUR_ADMIN_ID', f'ADMIN_ID = {ADMIN_ID}')
    
    with open('/etc/UDPCustom/telegram_bot.py', 'w') as file:
        file.write(content)

    updater = Updater(BOT_TOKEN)
    dispatcher = updater.dispatcher

    # Add handlers
    dispatcher.add_handler(CommandHandler("start", start))
    dispatcher.add_handler(CommandHandler("help", help_command))
    dispatcher.add_handler(CommandHandler("menu", show_menu))
    dispatcher.add_handler(CommandHandler("status", server_status))
    dispatcher.add_handler(CommandHandler("execute", execute_command))
    dispatcher.add_handler(CommandHandler("logs", show_logs))
    dispatcher.add_handler(CommandHandler("restart", restart_services))
    dispatcher.add_handler(CommandHandler("reboot", reboot_server))
    dispatcher.add_handler(MessageHandler(Filters.text & ~Filters.command, handle_text_message))
    
    dispatcher.add_error_handler(error_handler)

    logger.info("Bot is starting...")
    updater.start_polling()
    updater.idle()

if __name__ == '__main__':
    main()
EOF

    # Replace placeholders in the Python script
    sed -i "s/YOUR_BOT_TOKEN/$bot_token/g" /etc/UDPCustom/telegram_bot.py
    sed -i "s/YOUR_ADMIN_ID/$admin_id/g" /etc/UDPCustom/telegram_bot.py

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
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

    chmod +x /etc/UDPCustom/telegram_bot.py
    systemctl daemon-reload
    systemctl enable telegram-udp-bot
    systemctl start telegram-udp-bot
    
    # Wait a bit for service to start
    sleep 3
    
    # Check if bot is running
    if systemctl is-active --quiet telegram-udp-bot; then
        echo "✅ Telegram Bot service is running"
    else
        echo "❌ Telegram Bot service failed to start"
        echo "Checking status..."
        systemctl status telegram-udp-bot --no-pager -l
    fi
}

# Check Ubuntu version
if [[ "$(lsb_release -rs)" =~ ^(8|9|10|11|16.04|18.04) ]]; then
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
  echo "To get your Bot Token:"
  echo "1. Open Telegram and search for @BotFather"
  echo "2. Send /newbot and follow instructions"
  echo "3. Copy the bot token"
  echo ""
  echo "To get your User ID:"
  echo "1. Search for @userinfobot in Telegram"
  echo "2. Start the bot and it will show your ID"
  echo ""
  
  read -p "Enter your Telegram Bot Token: " bot_token
  read -p "Enter your Telegram User ID: " admin_id
  
  if [ -n "$bot_token" ] && [ -n "$admin_id" ]; then
      echo ""
      print_center -ama "Installing Telegram Bot..."
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
      echo ""
      echo "🔍 Check bot status: systemctl status telegram-udp-bot"
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
      print_center -ama "${a103:-  Check bot: systemctl status telegram-udp-bot\n}"
  fi
  echo -ne "\n\033[1;31mENTER \033[1;33mpara entrar al \033[1;32mMENU!\033[0m"; read
   udp
  
fi
