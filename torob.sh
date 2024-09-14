#!/bin/bash

# Check if the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   sleep 1
   exit 1
fi


# just press key to continue
press_key(){
 read -p "Press any key to continue..."
}


# Define a function to colorize text
colorize() {
    local color="$1"
    local text="$2"
    local style="${3:-normal}"
    
    # Define ANSI color codes
    local black="\033[30m"
    local red="\033[31m"
    local green="\033[32m"
    local yellow="\033[33m"
    local blue="\033[34m"
    local magenta="\033[35m"
    local cyan="\033[36m"
    local white="\033[37m"
    local reset="\033[0m"
    
    # Define ANSI style codes
    local normal="\033[0m"
    local bold="\033[1m"
    local underline="\033[4m"
    # Select color code
    local color_code
    case $color in
        black) color_code=$black ;;
        red) color_code=$red ;;
        green) color_code=$green ;;
        yellow) color_code=$yellow ;;
        blue) color_code=$blue ;;
        magenta) color_code=$magenta ;;
        cyan) color_code=$cyan ;;
        white) color_code=$white ;;
        *) color_code=$reset ;;  # Default case, no color
    esac
    # Select style code
    local style_code
    case $style in
        bold) style_code=$bold ;;
        underline) style_code=$underline ;;
        normal | *) style_code=$normal ;;  # Default case, normal text
    esac

    # Print the colored and styled text
    echo -e "${style_code}${color_code}${text}${reset}"
}


install_gamingvpn() {
    # Define the directory and files
    DEST_DIR="/root/gamingvpn"
    FILE="/root/gamingvpn/gamingvpn"
    URL_X86="https://github.com/aliashtab77/torob/raw/main/core/gamingvpn_amd64"
    URL_ARM="https://github.com/aliashtab77/torob/raw/main/core/gamingvpn_arm"              
      
    echo
    if [ -f "$FILE" ]; then
	    colorize green "torob vpn core installed already." bold
	    return 1
    fi
    
    if ! [ -d "$DEST_DIR" ]; then
    	mkdir "$DEST_DIR" &> /dev/null
    fi
    
    # Detect the system architecture
    ARCH=$(uname -m)
    if [ "$ARCH" = "x86_64" ]; then
        URL=$URL_X86
    elif [ "$ARCH" = "armv7l" ] || [ "$ARCH" = "aarch64" ]; then
        URL=$URL_ARM
    else
        colorize red "Unsupported architecture: $ARCH\n" bold
        sleep 2
        return 1
    fi


    colorize yellow "Installing torob vpn Core..." bold
    echo
    curl -L $URL -o $FILE &> /dev/null
	chmod +x $FILE 
    if [ -f "$FILE" ]; then
        colorize green "torob vpn core installed successfully...\n" bold
        sleep 1
        return 0
    else
        colorize red "Failed to install torob vpn core...\n" bold
        return 1
    fi
}
install_gamingvpn

# Function to install jq if not already installed
install_jq() {
    if ! command -v jq &> /dev/null; then
        # Check if the system is using apt package manager
        if command -v apt-get &> /dev/null; then
            echo -e "${RED}jq is not installed. Installing...${NC}"
            sleep 1
            sudo apt-get update
            sudo apt-get install -y jq
        else
            echo -e "${RED}Error: Unsupported package manager. Please install jq manually.${NC}\n"
            read -p "Press any key to continue..."
            exit 1
        fi
    fi
}

# Install jq
install_jq


# Fetch server country
SERVER_COUNTRY=$(curl -sS "http://ipwhois.app/json/$SERVER_IP" | jq -r '.country')

# Fetch server isp 
SERVER_ISP=$(curl -sS "http://ipwhois.app/json/$SERVER_IP" | jq -r '.isp')

# Function to display ASCII logo
display_logo() {   
    echo -e "${CYAN}"
    cat << "EOF"
  __                     ___.                           
_/  |_  ___________  ____\_ |__   ___  ________   ____  
\   __\/  _ \_  __ \/  _ \| __ \  \  \/ /\____ \ /    \ 
 |  | (  <_> )  | \(  <_> ) \_\ \  \   / |  |_> >   |  \
 |__|  \____/|__|   \____/|___  /   \_/  |   __/|___|  /
                              \/         |__|        \/                  
EOF
    echo -e "${NC}${CYAN}"
    echo -e "Version: ${YELLOW}0.6${CYAN}"
    echo -e "Github: ${YELLOW}Github.com/aliashtab77${CYAN}"
    echo -e "Telegram Channel: ${YELLOW}@torob_shop${NC}"
}

# Function to display server location and IP
display_server_info() {
    echo -e "\e[93m═════════════════════════════════════════════\e[0m"  
 	#	Hidden for security issues   
    #echo -e "${CYAN}IP Address:${NC} $SERVER_IP"
    echo -e "${CYAN}Location:${NC} $SERVER_COUNTRY "
    echo -e "${CYAN}Datacenter:${NC} $SERVER_ISP"
}

CONFIG_DIR='/root/gamingvpn'
SERVICE_FILE='/etc/systemd/system/gamingvpn.service'
# Function to display Rathole Core installation status
display_gamingvpn_status() {
    if [[ -f "${CONFIG_DIR}/gamingvpn" ]]; then
        echo -e "${CYAN}torob vpn:${NC} ${GREEN}Installed${NC}"
    else
        echo -e "${CYAN}torob vpn:${NC} ${RED}Not installed${NC}"
    fi
    echo -e "\e[93m═════════════════════════════════════════════\e[0m"  
}

configure_server(){
    # Check if service or config file exisiting and returnes
    echo 
    if [ -f "$SERVICE_FILE" ]; then
    	colorize red "GamingVPN service is running, please remove it first to configure it again." bold
    	sleep 2
    	return 1
    fi
    
    
    #Clear and title
    clear
    colorize cyan "Configure server for GamingVPN" bold
        
    echo
    
    # Tunnel Port
    echo -ne "[-] Tunnel Port (default 4096): "
    read -r PORT
    if [ -z "$PORT" ]; then
    	colorize yellow "Tunnel port 4096 selected by default."
        PORT=4096
    fi
    
    echo
    
    # FEC Value
    echo -ne "[-] FEC value (with x:y format, default 2:1, enter 0 to disable): "
    read -r FEC
    if [ -z "$FEC" ]; then
    	colorize yellow "FEC set to 2:1"
        FEC="-f2:1"
    elif [[ "$FEC" == "0" ]];then
   	    colorize yellow "FEC is disabled"
    	FEC="--disable-fec"
	else
		FEC="-f${FEC}"
    fi
  
    echo
    
    # Subnet address 
    echo -ne "[-] Subnet Address (default 10.22.22.0): "
    read -r SUBNET
    if [ -z "$SUBNET" ]; then
	    colorize yellow "Subnet address 10.22.22.0 selected by default"
        SUBNET="10.22.22.0"
    fi
    
    echo
    
    # Mode
    echo -ne "[-] Mode (0 for non-game usage, 1 for game usage): "
    read -r MODE
    if [ -z "$MODE" ]; then
    	colorize yellow "Optimized for gaming usage by default."
        MODE="--mode 1  --timeout 1"
    elif [[ "$MODE" = "0" ]]; then
    	colorize yellow "Optimized for non-gaming usage."
    	   MODE="--mode 0  --timeout 4"
    else
       	colorize yellow "Optimized for gaming usage."
        MODE="--mode 1  --timeout 1"   	
    fi
    
    
    # Final command
    COMMAND="-s -l[::]:$PORT $FEC --sub-net $SUBNET  $MODE --tun-dev gamingvpn --disable-obscure"
    
        # Create the systemd service unit file
    cat << EOF > "$SERVICE_FILE"
[Unit]
Description=GamingVPN Server
After=network.target

[Service]
Type=simple
ExecStart=$CONFIG_DIR/gamingvpn $COMMAND
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

	systemctl daemon-reload &> /dev/null
	systemctl enable gamingvpn &> /dev/null
	systemctl start gamingvpn &> /dev/null
	
	echo
	colorize green "GamingVPN server started successfully." bold
	echo
	press_key
}

configure_client(){
    # Check if service or config file exisiting and returnes
    echo 
    if [ -f "$SERVICE_FILE" ]; then
    	colorize red "GamingVPN service is running, please remove it first to configure it again." bold
    	sleep 2
    	return 1
    fi
   
    #Clear and title
    clear
    colorize cyan "Configure client for GamingVPN" bold
        
    echo
    
    # Remote Server Address
    echo -ne "[*] Remote server address (in IPv4 or [IPv6] format): "
    read -r IP
    if [ -z "$IP" ]; then
        colorize red "Enter a valid IP address..." bold
        sleep 2
        return 1
    fi
    
    echo
    
    # Tunnel Port
    echo -ne "[-] Tunnel Port (default 4096): "
    read -r PORT
    if [ -z "$PORT" ]; then
    	colorize yellow "Tunnel port 4096 selected by default."
        PORT=4096
    fi
    
    echo
    
    # FEC Value
    echo -ne "[-] FEC value (with x:y format, default 2:1, enter 0 to disable): "
    read -r FEC
    if [ -z "$FEC" ]; then
    	colorize yellow "FEC set to 2:1"
        FEC="-f2:1"
    elif [[ "$FEC" == "0" ]];then
   	    colorize yellow "FEC is disabled"
    	FEC="--disable-fec"
	else
		FEC="-f${FEC}"
    fi

    echo
    
    # Subnet address 
    echo -ne "[-] Subnet Address (default 10.22.22.0): "
    read -r SUBNET
    if [ -z "$SUBNET" ]; then
    	colorize yellow "Subnet address 10.22.22.0 selected by default"
        SUBNET="10.22.22.0"
    fi
    
    echo
    
    # Mode
    echo -ne "[-] Mode (0 for non-game usage, 1 for game usage): "
    read -r MODE
    if [ -z "$MODE" ]; then
    	colorize yellow "Optimized for gaming usage by default."
        MODE="--mode 1  --timeout 1"
    elif [[ "$MODE" = "0" ]]; then
    	colorize yellow "Optimized for non-gaming usage."
    	   MODE="--mode 0  --timeout 4"
    else
       	colorize yellow "Optimized for gaming usage."
        MODE="--mode 1  --timeout 1"   	
    fi
    
    # Final command
    COMMAND="-c -r${IP}:${PORT} $FEC --sub-net $SUBNET $MODE --tun-dev gamingvpn --keep-reconnect --disable-obscure"

    # Create the systemd service unit file
    cat << EOF > "$SERVICE_FILE"
[Unit]
Description=GamingVPN Client
After=network.target

[Service]
Type=simple
ExecStart=$CONFIG_DIR/gamingvpn $COMMAND
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

	systemctl daemon-reload &> /dev/null
	systemctl enable gamingvpn &> /dev/null
	systemctl start gamingvpn &> /dev/null
	
	echo
	colorize green "GamingVPN client started successfully." bold
	echo
	press_key
}

check_service_status(){
	echo
    if ! [ -f "$SERVICE_FILE" ]; then
    	colorize red "GamingVPN service is not found" bold
    	sleep 2
    	return 1
    fi
    clear
    systemctl status gamingvpn.service
    
    echo
    press_key
}

view_logs(){
	echo
    if ! [ -f "$SERVICE_FILE" ]; then
    	colorize red "GamingVPN service is not found" bold
    	sleep 2
    	return 1
    fi
    clear
    journalctl -xeu gamingvpn.service
    
    echo
    
    press_key

}
remove_service(){
	echo
    if ! [ -f "$SERVICE_FILE" ]; then
		colorize red "GamingVPN service not found." bold
		sleep 2
		return 1
    fi
	
	systemctl disable gamingvpn &> /dev/null
	systemctl stop gamingvpn &> /dev/null
	rm -rf "$SERVICE_FILE"
	systemctl daemon-reload &> /dev/null
	
	colorize green "GamingVPN service stopped and deleted successfully." bold
	sleep 2

}

remove_core(){
	echo
	if ! [ -d "$CONFIG_DIR" ]; then
		colorize red "Gaming VPN directory not found"
		sleep 2
		return 1
	fi
	
    if [ -f "$SERVICE_FILE" ]; then
    	colorize red "GamingVPN service is running, please remove it first and then remove then core." bold
    	sleep 2
    	return 1
    fi
	
	rm -rf "$CONFIG_DIR"
	colorize green "GamingVPN directory deleted successfully." bold
	sleep 2
}

restart_service(){
	echo
    if ! [ -f "$SERVICE_FILE" ]; then
    	colorize red "GamingVPN service is not found" bold
    	sleep 2
    	return 1
    fi
    
    systemctl restart gamingvpn.service &> /dev/null
    colorize green "GamingVPN service restarted successfully." bold
	sleep 2

}
# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\e[36m'
MAGENTA="\e[95m"
NC='\033[0m' # No Color


# Function to display menu
display_menu() {
    clear
    display_logo
    display_server_info
    display_gamingvpn_status
    echo
    colorize green " 1. Configure for server" bold
    colorize cyan " 2. Configure for client" bold
    colorize magenta " 3. Check service status" 
    colorize yellow " 4. View logs"
    colorize yellow " 5. Restart service" 
    colorize red " 6. Remove service"
    colorize red " 7. Remove core files"
    echo -e " 0. Exit"
    echo
    echo "-------------------------------"
}

# Function to read user input
read_option() {
    read -p "Enter your choice [0-7]: " choice
    case $choice in
        1) configure_server ;;
        2) configure_client ;;
        3) check_service_status ;;
	    4) view_logs;;
	    5) restart_service;;
        6) remove_service ;;
        7) remove_core;;
        0) exit 0 ;;
        *) echo -e "${RED} Invalid option!${NC}" && sleep 1 ;;
    esac
}

# Main script
while true
do
    display_menu
    read_option
done
