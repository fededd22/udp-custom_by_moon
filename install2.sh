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

# Install specific version of python-telegram-bot
pip3 install python-telegram-bot==13.7

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
    
    # Create a simple and working Telegram bot script
    cat > /etc/UDPCustom/telegram_bot.py << EOF
#!/usr/bin/env python3
import subprocess
import logging
from telegram import Update
from telegram.ext import Updater, CommandHandler, MessageHandler, Filters, CallbackContext

# Set up logging
logging.basicConfig(
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    level=logging.INFO
)
logger = logging.getLogger(__name__)

# Bot configuration
BOT_TOKEN = "$bot_token"
ADMIN_ID = $admin_id

def start(update: Update, context: CallbackContext):
    """Send a message when the command /start is issued."""
    user = update.effective_user
    if user.id != ADMIN_ID:
        update.message.reply_text('🚫 Unauthorized! This bot is for admin only.')
        return
        
    welcome_text = f'''
🤖 *UDP Custom Manager Bot*

Hello {user.first_name}! 
I can help you manage your UDP Custom server remotely.

*Available Commands:*
/start - Start the bot
/menu - Show main menu
/status - Check server status  
/restart - Restart UDP services
/execute - Run shell command
/logs - Show service logs
/reboot - Reboot server
/help - Show help

*Quick Menu (send numbers):*
1 - UDP Custom Manager
2 - VPS Information  
3 - Service Status
4 - Restart Services
5 - View Logs
6 - Reboot Server
'''
    update.message.reply_text(welcome_text, parse_mode='Markdown')

def help_command(update: Update, context: CallbackContext):
    """Send a message when the command /help is issued."""
    if update.effective_user.id != ADMIN_ID:
        return
    help_text = '''
🔧 *Available Commands:*

/start - Start the bot
/menu - Show interactive menu
/status - Server status
/restart - Restart UDP services
/execute <command> - Run shell command
/logs - Show service logs  
/reboot - Reboot server
/help - This help message

*Number Menu:*
1 - UDP Custom Manager
2 - VPS Info
3 - Service Status
4 - Restart Services
5 - View Logs
6 - Reboot Server
'''
    update.message.reply_text(help_text, parse_mode='Markdown')

def menu(update: Update, context: CallbackContext):
    """Show the main menu."""
    if update.effective_user.id != ADMIN_ID:
        return
    menu_text = '''
🔧 *UDP Custom Manager Menu*

*Choose an option:*

1️⃣ *UDP Custom* - Main UDP manager
2️⃣ *VPS Info* ℹ️ - System information  
3️⃣ *Service Status* 📊 - Check services
4️⃣ *Restart Services* 🔄 - Restart UDP
5️⃣ *View Logs* 📋 - Service logs
6️⃣ *Reboot Server* 🚀 - Reboot server

Send the number (1-6) for quick action!
'''
    update.message.reply_text(menu_text, parse_mode='Markdown')

def status(update: Update, context: CallbackContext):
    """Get server status."""
    if update.effective_user.id != ADMIN_ID:
        return
        
    try:
        # Get basic system info
        hostname = subprocess.getoutput('hostname')
        uptime = subprocess.getoutput('uptime -p')
        cpu_usage = subprocess.getoutput("top -bn1 | grep 'Cpu(s)' | awk '{print \$2}' | head -1")
        memory = subprocess.getoutput('free -m | awk "NR==2{printf \"%.2f%%\", \$3*100/\$2 }"')
        disk = subprocess.getoutput('df -h / | awk "NR==2{print \$5}"')
        
        # Service status
        udp_status = subprocess.getoutput('systemctl is-active udp-custom')
        udpgw_status = subprocess.getoutput('systemctl is-active udpgw')
        
        status_text = f'''
📊 *Server Status*

*System Info:*
• Hostname: `{hostname}`
• Uptime: `{uptime}`
• CPU Usage: `{cpu_usage}`
• Memory Usage: `{memory}`
• Disk Usage: `{disk}`

*Services:*
• UDP Custom: `{udp_status}`
• UDP Gateway: `{udpgw_status}`
'''
        update.message.reply_text(status_text, parse_mode='Markdown')
    except Exception as e:
        update.message.reply_text(f'❌ Error: {str(e)}')

def execute(update: Update, context: CallbackContext):
    """Execute shell commands."""
    if update.effective_user.id != ADMIN_ID:
        return
        
    if not context.args:
        update.message.reply_text('Usage: /execute <command>')
        return
        
    command = ' '.join(context.args)
    try:
        result = subprocess.getoutput(command)
        if len(result) > 3000:
            result = result[:3000] + '\\n... (truncated)'
        update.message.reply_text(f'✅ Result:\\n```\\n{result}\\n```', parse_mode='Markdown')
    except Exception as e:
        update.message.reply_text(f'❌ Error: {str(e)}')

def logs(update: Update, context: CallbackContext):
    """Show service logs."""
    if update.effective_user.id != ADMIN_ID:
        return
        
    try:
        logs_output = subprocess.getoutput('journalctl -u udp-custom -n 10 --no-pager')
        if len(logs_output) > 3000:
            logs_output = logs_output[:3000] + '\\n... (truncated)'
        update.message.reply_text(f'📋 Logs:\\n```\\n{logs_output}\\n```', parse_mode='Markdown')
    except Exception as e:
        update.message.reply_text(f'❌ Error: {str(e)}')

def restart(update: Update, context: CallbackContext):
    """Restart UDP services."""
    if update.effective_user.id != ADMIN_ID:
        return
        
    try:
        update.message.reply_text('🔄 Restarting UDP services...')
        subprocess.run(['systemctl', 'restart', 'udp-custom'], check=True)
        subprocess.run(['systemctl', 'restart', 'udpgw'], check=True)
        update.message.reply_text('✅ Services restarted successfully!')
    except Exception as e:
        update.message.reply_text(f'❌ Error: {str(e)}')

def reboot(update: Update, context: CallbackContext):
    """Reboot the server."""
    if update.effective_user.id != ADMIN_ID:
        return
        
    try:
        update.message.reply_text('🚀 Server will reboot in 10 seconds...')
        subprocess.run(['shutdown', '-r', '+10'], check=True)
    except Exception as e:
        update.message.reply_text(f'❌ Error: {str(e)}')

def handle_message(update: Update, context: CallbackContext):
    """Handle text messages."""
    if update.effective_user.id != ADMIN_ID:
        update.message.reply_text('🚫 Unauthorized!')
        return
        
    text = update.message.text.strip()
    
    if text == '1':
        try:
            result = subprocess.getoutput('udp')
            if len(result) > 3000:
                result = result[:3000] + '\\n... (truncated)'
            update.message.reply_text(f'🔧 UDP Manager:\\n```\\n{result}\\n```', parse_mode='Markdown')
        except Exception as e:
            update.message.reply_text(f'❌ Error: {str(e)}')
            
    elif text == '2':
        try:
            result = subprocess.getoutput('neofetch --stdout')
            if not result:
                result = subprocess.getoutput('uname -a')
            if len(result) > 3000:
                result = result[:3000] + '\\n... (truncated)'
            update.message.reply_text(f'ℹ️ VPS Info:\\n```\\n{result}\\n```', parse_mode='Markdown')
        except Exception as e:
            update.message.reply_text(f'❌ Error: {str(e)}')
            
    elif text == '3':
        status(update, context)
        
    elif text == '4':
        restart(update, context)
        
    elif text == '5':
        logs(update, context)
        
    elif text == '6':
        reboot(update, context)
        
    else:
        update.message.reply_text('❓ Unknown command. Send /menu for options.')

def main():
    """Start the bot."""
    logger.info("Starting UDP Telegram Bot...")
    
    # Create the Updater and pass it your bot's token.
    updater = Updater(BOT_TOKEN)

    # Get the dispatcher to register handlers
    dispatcher = updater.dispatcher

    # Register command handlers
    dispatcher.add_handler(CommandHandler("start", start))
    dispatcher.add_handler(CommandHandler("help", help_command))
    dispatcher.add_handler(CommandHandler("menu", menu))
    dispatcher.add_handler(CommandHandler("status", status))
    dispatcher.add_handler(CommandHandler("execute", execute))
    dispatcher.add_handler(CommandHandler("logs", logs))
    dispatcher.add_handler(CommandHandler("restart", restart))
    dispatcher.add_handler(CommandHandler("reboot", reboot))
    
    # Register message handler
    dispatcher.add_handler(MessageHandler(Filters.text & ~Filters.command, handle_message))

    # Start the Bot
    updater.start_polling()

    # Run the bot until you press Ctrl-C
    logger.info("Bot is now running...")
    updater.idle()

if __name__ == '__main__':
    main()
EOF

    # Create systemd service for the bot
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

    # Set permissions and start service
    chmod +x /etc/UDPCustom/telegram_bot.py
    systemctl daemon-reload
    systemctl enable telegram-udp-bot
    systemctl start telegram-udp-bot
    
    # Wait and check status
    sleep 5
    echo "🔍 Checking bot status..."
    if systemctl is-active --quiet telegram-udp-bot; then
        echo "✅ Telegram Bot service is running successfully!"
        echo "📝 Check logs with: journalctl -u telegram-udp-bot -f"
    else
        echo "❌ Telegram Bot service failed to start"
        systemctl status telegram-udp-bot --no-pager -l
    fi
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

  echo ""
  echo " ⇢ Binary Core official ePro Dev Team"
  echo " ⇢ UDP Custom + Telegram Bot"
  sleep 3

  # Clean up
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

  # Get UDP files
  source <(curl -sSL 'https://raw.githubusercontent.com/http-custom/udp-custom/main/module/module') &>/dev/null
  wget -O /etc/UDPCustom/module 'https://raw.githubusercontent.com/http-custom/udp-custom/main/module/module' &>/dev/null
  chmod +x /etc/UDPCustom/module

  wget "https://raw.github.com/http-custom/udp-custom/main/bin/udp-custom-linux-amd64" -O /root/udp/udp-custom &>/dev/null
  chmod +x /root/udp/udp-custom

  wget -O /etc/limiter.sh 'https://raw.githubusercontent.com/http-custom/udp-custom/main/module/limiter.sh'
  cp /etc/limiter.sh /etc/UDPCustom
  chmod +x /etc/limiter.sh
  chmod +x /etc/UDPCustom
  
  # udpgw
  wget -O /etc/udpgw 'https://raw.github.com/http-custom/udp-custom/main/module/udpgw'
  mv /etc/udpgw /bin
  chmod +x /bin/udpgw

  # services
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

  # config
  wget "https://raw.githubusercontent.com/http-custom/udp-custom/main/config/config.json" -O /root/udp/config.json &>/dev/null
  chmod +x /root/udp/config.json

  # menu
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
  echo "📝 Get your Bot Token from @BotFather on Telegram"
  echo "📝 Get your User ID from @userinfobot on Telegram"
  echo ""
  
  read -p "Enter your Telegram Bot Token: " bot_token
  read -p "Enter your Telegram User ID: " admin_id
  
  if [ -n "$bot_token" ] && [ -n "$admin_id" ]; then
      echo ""
      print_center -ama "Installing Telegram Bot..."
      setup_telegram_bot "$bot_token" "$admin_id"
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
      echo ""
      echo "🤖 Bot Commands:"
      echo "  /start - Start the bot"
      echo "  /menu - Show main menu"
      echo "  /status - Check server status"
      echo "  /execute <command> - Run shell commands"
      echo "  /logs - View service logs"
      echo "  /restart - Restart UDP services"
      echo "  /reboot - Reboot server"
      echo ""
      echo "🔍 Check bot status: systemctl status telegram-udp-bot"
  fi
  echo -ne "\n\033[1;31mENTER \033[1;33mpara entrar al \033[1;32mMENU!\033[0m"; read
  udp
fi
