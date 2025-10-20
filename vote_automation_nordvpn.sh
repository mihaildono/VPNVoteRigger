#!/bin/bash

# Automated Voting Script with NordVPN
# This script automates the voting process by connecting to NordVPN macOS app
#
# REQUIRED SETUP:
# 1. Install NordVPN macOS app
# 2. Start NordVPN app and log in
#
# OPTIMIZED FOR LOCKED SCREEN OPERATION:
# - Uses NordVPN URL scheme (no GUI dependencies)
# - No delays between votes for maximum speed
# - Runs continuously until manually stopped
# - Connects to fastest/nearest server
#
# TO RUN IN BACKGROUND (recommended for locked screen):
# nohup ./vote_automation_nordvpn.sh > vote_log_nordvpn.txt 2>&1 &
#
# TO STOP ALL INSTANCES:
# pkill -f vote_automation_nordvpn.sh

set -e  # Exit on any error

# Load environment variables from .env file if it exists
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

# Configuration (must be set in .env file)
POST_ID="${POST_ID}"
BASE_URL="${BASE_URL}"
REFERER_URL="${REFERER_URL}"
ORIGIN_URL="${ORIGIN_URL}"

# Default values
INSTANCE_ID=""
LOG_FILE="vote_log_nordvpn.txt"

# IP tracking files
TRIED_IPS_FILE="/tmp/tried_ips_nordvpn_${INSTANCE_ID:-default}.txt"
USED_EMAILS_FILE="/tmp/used_emails_nordvpn_${INSTANCE_ID:-default}.txt"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --instance)
            INSTANCE_ID="$2"
            shift 2
            ;;
        --log)
            LOG_FILE="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  --instance ID    Instance ID for logging (e.g., 1, 2, 3)"
            echo "  --log FILE       Log file name (default: vote_log_nordvpn.txt)"
            echo "  -h, --help       Show this help"
            echo ""
            echo "Examples:"
            echo "  $0                                    # Single instance, nearest server"
            echo "  $0 --instance 1                      # Instance 1"
            echo "  $0 --instance 2                      # Instance 2"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output with instance ID
print_status() {
    local instance_prefix=""
    if [ -n "$INSTANCE_ID" ]; then
        instance_prefix="[INST-$INSTANCE_ID] "
    fi
    echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} $instance_prefix$1"
}

print_success() {
    local instance_prefix=""
    if [ -n "$INSTANCE_ID" ]; then
        instance_prefix="[INST-$INSTANCE_ID] "
    fi
    echo -e "${GREEN}[$(date '+%H:%M:%S')] ✅ $instance_prefix$1${NC}"
}

print_error() {
    local instance_prefix=""
    if [ -n "$INSTANCE_ID" ]; then
        instance_prefix="[INST-$INSTANCE_ID] "
    fi
    echo -e "${RED}[$(date '+%H:%M:%S')] ❌ $instance_prefix$1${NC}"
}

print_warning() {
    local instance_prefix=""
    if [ -n "$INSTANCE_ID" ]; then
        instance_prefix="[INST-$INSTANCE_ID] "
    fi
    echo -e "${YELLOW}[$(date '+%H:%M:%S')] ⚠️  $instance_prefix$1${NC}"
}

# Bulgarian common names array (Latin variants) - expanded
BULGARIAN_NAMES=(
    "alexander" "anna" "boris" "vasil" "velika" "georgi" "dimitur" "elena" "zhivko" "ivan"
    "yordan" "kalin" "lyuben" "maria" "nikolay" "ognyan" "petar" "radoslav" "stoyan" "todor"
    "ulyana" "filip" "hristo" "tsvetan" "chavdar" "shishko" "yanko" "angel" "boyko" "ventzislav"
    "galina" "dancho" "emil" "george" "ivaylo" "yoan" "krasimir" "lyudmila" "mihail" "nadezhda"
    "ognyan" "plamen" "rumen" "silvia" "tanya" "ulyana" "filip" "hristo" "tsvetan" "chavdar"
    "adrian" "bogdan" "christian" "daniel" "emil" "francis" "gabriel" "henry" "ivan" "jordan"
    "kristian" "lucas" "martin" "nathan" "oliver" "peter" "quentin" "robert" "samuel" "thomas"
    "victor" "william" "xavier" "yordan" "zachary" "alexandra" "beatrice" "catherine" "diana" "elena"
    "fiona" "grace" "helen" "isabella" "julia" "katherine" "lily" "maya" "natalia" "olivia"
    "penelope" "quinn" "rose" "sophia" "taylor" "una" "vera" "wendy" "xenia" "yolanda" "zoe"
)

# Function to check if email has been used before
is_email_used() {
    local email="$1"
    if [ -f "$USED_EMAILS_FILE" ] && grep -q "^$email$" "$USED_EMAILS_FILE"; then
        return 0  # Email has been used
    else
        return 1  # Email has not been used
    fi
}

# Function to mark email as used
mark_email_used() {
    local email="$1"
    echo "$email" >> "$USED_EMAILS_FILE"
    print_status "Marked email $email as used"
}

# Function to generate random email with more variability
generate_random_email() {
    local max_attempts=50
    local attempt=1

    while [ $attempt -le $max_attempts ]; do
        # Generate more random numbers for better variability
        local random_num1=$((RANDOM % 99999))
        local random_num2=$((RANDOM % 9999))
        local random_num3=$((RANDOM % 99))

        local random_name1=${BULGARIAN_NAMES[$RANDOM % ${#BULGARIAN_NAMES[@]}]}
        local random_name2=${BULGARIAN_NAMES[$RANDOM % ${#BULGARIAN_NAMES[@]}]}
        local random_name3=${BULGARIAN_NAMES[$RANDOM % ${#BULGARIAN_NAMES[@]}]}

        # Expanded email domains
        local domains=("abv.bg" "yahoo.com" "gmail.com" "hotmail.com" "outlook.com" "mail.bg" "dir.bg" "inet.bg")
        local random_domain=${domains[$RANDOM % ${#domains[@]}]}

        # More email formats for better variability
        local format=$((RANDOM % 12))
        local email=""

        case $format in
            0)  # Name + number
                email="${random_name1}${random_num1}@${random_domain}"
                ;;
            1)  # Number + name
                email="${random_num1}${random_name1}@${random_domain}"
                ;;
            2)  # Two names
                email="${random_name1}${random_name2}@${random_domain}"
                ;;
            3)  # Name + dot + name
                email="${random_name1}.${random_name2}@${random_domain}"
                ;;
            4)  # Just name (no numbers)
                email="${random_name1}@${random_domain}"
                ;;
            5)  # Name + underscore + number
                email="${random_name1}_${random_num2}@${random_domain}"
                ;;
            6)  # Number + underscore + name
                email="${random_num2}_${random_name1}@${random_domain}"
                ;;
            7)  # Name + dash + name + number
                email="${random_name1}-${random_name2}${random_num3}@${random_domain}"
                ;;
            8)  # Three names
                email="${random_name1}${random_name2}${random_name3}@${random_domain}"
                ;;
            9)  # Name + dot + name + dot + number
                email="${random_name1}.${random_name2}.${random_num3}@${random_domain}"
                ;;
            10) # Name + year
                local year=$((1990 + RANDOM % 34))
                email="${random_name1}${year}@${random_domain}"
                ;;
            11) # Name + month + day
                local month=$((1 + RANDOM % 12))
                local day=$((1 + RANDOM % 28))
                email="${random_name1}${month}${day}@${random_domain}"
                ;;
        esac

        # Check if this email has been used before
        if ! is_email_used "$email"; then
            echo "$email"
            return 0
        fi

        ((attempt++))
    done

    # If we couldn't generate a unique email after max attempts, generate one anyway
    # This should be very rare
    local fallback_email="${random_name1}${random_num1}$(date +%s)@${random_domain}"
    echo "$fallback_email"
}

# Function to check if NordVPN app is available
check_nordvpn() {
    if ! pgrep -f "NordVPN" > /dev/null; then
        print_error "NordVPN app not found. Please install and start NordVPN."
        exit 1
    fi
    print_status "NordVPN app found"
}

# Function to check NordVPN connection status via AppleScript
check_nordvpn_status() {
    # Check if NordVPN is connected by looking at the menu bar or using system events
    local status=$(osascript -e 'tell application "System Events" to tell process "NordVPN" to get value of static text 1 of group 1 of window 1' 2>/dev/null)
    if echo "$status" | grep -q "Connected"; then
        return 0
    else
        return 1
    fi
}

# Function to check internet connectivity
check_internet_connection() {
    local max_attempts=2
    local attempt=1

    while [ $attempt -le $max_attempts ]; do
        if curl -s --connect-timeout 10 --max-time 15 ifconfig.me > /dev/null 2>&1; then
            return 0
        fi
        print_warning "Internet check attempt $attempt/$max_attempts failed"
        ((attempt++))
        sleep 2
    done

    print_error "No internet connection after $max_attempts attempts"
    return 1
}

# Function to cancel stuck VPN connection
cancel_vpn_connection() {
    print_warning "Canceling stuck VPN connection..."
    disconnect_nordvpn
    print_status "VPN connection canceled"
}

# Function to force VPN reset
force_vpn_reset() {
    print_warning "Forcing complete VPN reset..."
    disconnect_nordvpn
    sleep 5
    connect_to_nordvpn
    sleep 10
    print_status "VPN reset completed"
}

# Function to connect using NordVPN app
connect_to_nordvpn() {
    print_status "Connecting via NordVPN app..."

    local max_connect_attempts=3
    local connect_attempt=1

    while [ $connect_attempt -le $max_connect_attempts ]; do
        print_status "Connection attempt $connect_attempt/$max_connect_attempts"

        # Use NordVPN URL scheme - this will connect to the fastest/nearest server
        # Note: Will connect to fastest/nearest server
        open "nordvpn://connect" > /dev/null 2>&1

        sleep 12

        # Check if we got a new IP (connection succeeded)
        local test_ip=$(get_current_ip)
        if [ -n "$test_ip" ]; then
            # Verify it's different from a known local IP
            # If we can get an IP, connection likely succeeded
            print_status "Connection attempt completed successfully"
            return 0
        fi

        # If we get here, connection might be stuck
        print_warning "Connection appears stuck..."

        ((connect_attempt++))
        sleep 3
    done

    print_error "Failed to connect after $max_connect_attempts attempts"
    return 1
}

# Function to disconnect from NordVPN
disconnect_nordvpn() {
    print_status "Disconnecting from NordVPN..."

    # Use URL scheme to disconnect
    open "nordvpn://disconnect" > /dev/null 2>&1

    sleep 3

    print_status "Disconnect completed"
}

# Function to check if IP has been tried before
is_ip_tried() {
    local ip="$1"
    if [ -f "$TRIED_IPS_FILE" ] && grep -q "^$ip$" "$TRIED_IPS_FILE"; then
        return 0  # IP has been tried
    else
        return 1  # IP has not been tried
    fi
}

# Function to mark IP as tried
mark_ip_tried() {
    local ip="$1"
    echo "$ip" >> "$TRIED_IPS_FILE"
    print_status "Marked IP $ip as tried"
}

# Function to get current IP
get_current_ip() {
    local ip=$(curl -s --connect-timeout 5 --max-time 10 ifconfig.me 2>/dev/null)
    if [ -n "$ip" ]; then
        echo "$ip"
        return 0
    else
        return 1
    fi
}

# Function to connect to NordVPN with fail-safes
connect_to_vpn() {
    local max_attempts=2
    local attempt=1

    while [ $attempt -le $max_attempts ]; do
        print_status "VPN connection attempt $attempt/$max_attempts"

        # Check internet connection first
        if ! check_internet_connection; then
            print_warning "No internet connection, canceling stuck connection..."
            cancel_vpn_connection
            sleep 2
            if ! check_internet_connection; then
                print_error "Still no internet after canceling"
                ((attempt++))
                continue
            fi
        fi

        # Get current IP before connecting
        local old_ip=$(get_current_ip)

        # Clear cookies for fresh session
        clear_cookies

        # Connect to NordVPN (disconnect happens inside connect_to_nordvpn via Cancel button if needed)
        connect_to_nordvpn
        sleep 8

        # Get new IP and verify connection
        local new_ip=$(get_current_ip)

        if [ -n "$new_ip" ] && [ "$new_ip" != "$old_ip" ]; then
            # Check if this IP has been tried before
            if is_ip_tried "$new_ip"; then
                print_warning "IP $new_ip has been tried before, skipping..."
                ((attempt++))
                continue
            fi

            print_success "Connected to VPN (IP changed from $old_ip to $new_ip)"

            # Test internet connectivity after VPN connection
            if check_internet_connection; then
                print_status "VPN connection verified - internet working"
                print_status "Waiting 5 seconds for VPN connection to stabilize..."
                sleep 5
                return 0
            else
                print_warning "VPN connected but internet not working"
            fi
        else
            print_warning "VPN connection attempt $attempt failed (IP didn't change)"

            if [ $attempt -eq $max_attempts ]; then
                print_error "All VPN connection attempts failed, canceling and trying again..."
                cancel_vpn_connection
                sleep 2

                # Try one more time with cancel
                connect_to_nordvpn
                sleep 5

                local final_ip=$(get_current_ip)
                if [ -n "$final_ip" ] && [ "$final_ip" != "$old_ip" ]; then
                    # Check if this IP has been tried before
                    if is_ip_tried "$final_ip"; then
                        print_warning "Final attempt IP $final_ip has been tried before"
                        return 1
                    fi
                    print_success "Connected after cancel (IP: $final_ip)"
                    print_status "Waiting 5 seconds for VPN connection to stabilize..."
                    sleep 5
                    return 0
                else
                    print_error "Failed to connect even after canceling"
                    return 1
                fi
            fi
        fi

        ((attempt++))
        sleep 1
    done

    return 1
}

# Function to clear cookies for fresh session
clear_cookies() {
    local cookie_file="/tmp/cookies_nordvpn_${INSTANCE_ID:-default}.txt"
    if [ -f "$cookie_file" ]; then
        rm -f "$cookie_file"
        print_status "Cleared cookies for fresh session"
    fi
}

# Function to clean up old records (keep only last 1000 entries)
cleanup_records() {
    local max_entries=1000

    # Clean up tried IPs
    if [ -f "$TRIED_IPS_FILE" ]; then
        local tried_count=$(wc -l < "$TRIED_IPS_FILE")
        if [ "$tried_count" -gt "$max_entries" ]; then
            tail -n "$max_entries" "$TRIED_IPS_FILE" > "${TRIED_IPS_FILE}.tmp" && mv "${TRIED_IPS_FILE}.tmp" "$TRIED_IPS_FILE"
            print_status "Cleaned up tried IPs file (kept last $max_entries entries)"
        fi
    fi

    # Clean up used emails
    if [ -f "$USED_EMAILS_FILE" ]; then
        local email_count=$(wc -l < "$USED_EMAILS_FILE")
        if [ "$email_count" -gt "$max_entries" ]; then
            tail -n "$max_entries" "$USED_EMAILS_FILE" > "${USED_EMAILS_FILE}.tmp" && mv "${USED_EMAILS_FILE}.tmp" "$USED_EMAILS_FILE"
            print_status "Cleaned up used emails file (kept last $max_entries entries)"
        fi
    fi
}

# Function to make a vote request
make_vote_request() {
    local email="$1"

    print_status "Making vote request with email: $email"

    # Randomize User-Agent and headers for each request
    local user_agents=(
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36"
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36"
        "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36"
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:122.0) Gecko/20100101 Firefox/122.0"
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:122.0) Gecko/20100101 Firefox/122.0"
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36 Edg/122.0.0.0"
    )

    local platforms=("Windows" "macOS" "Linux")
    local browsers=("Chrome" "Firefox" "Safari" "Edge")

    local random_ua=${user_agents[$RANDOM % ${#user_agents[@]}]}
    local random_platform=${platforms[$RANDOM % ${#platforms[@]}]}
    local random_browser=${browsers[$RANDOM % ${#browsers[@]}]}

    print_status "Using User-Agent: $random_ua"

    local response=$(curl -s --connect-timeout 10 --max-time 30 \
        --cookie-jar /tmp/cookies_nordvpn_${INSTANCE_ID:-default}.txt \
        --cookie /tmp/cookies_nordvpn_${INSTANCE_ID:-default}.txt \
        --max-redirs 0 \
        --location-trusted \
        "$BASE_URL" \
        -H 'accept: */*' \
        -H 'accept-language: bg-BG,bg;q=0.9,en;q=0.8' \
        -H 'content-type: application/json' \
        -H "origin: $ORIGIN_URL" \
        -H 'priority: u=1, i' \
        -H "referer: $REFERER_URL" \
        -H "sec-ch-ua: \"$random_browser\";v=\"122\", \"Not?A_Brand\";v=\"8\", \"Chromium\";v=\"122\"" \
        -H 'sec-ch-ua-mobile: ?0' \
        -H "sec-ch-ua-platform: \"$random_platform\"" \
        -H 'sec-fetch-dest: empty' \
        -H 'sec-fetch-mode: cors' \
        -H 'sec-fetch-site: same-origin' \
        -H "user-agent: $random_ua" \
        -H 'x-requested-with: XMLHttpRequest' \
        -H 'cache-control: no-cache' \
        -H 'pragma: no-cache' \
        --data-raw "{\"post_id\":\"$POST_ID\",\"email\":\"$email\",\"newsletter\":0}")

    # Check if curl failed or returned empty response
    if [ $? -ne 0 ] || [ -z "$response" ]; then
        print_error "Vote request failed (timeout or connection error)"
        echo '{"success":false,"msg":"Request failed"}'
        return
    fi

    echo "$response"
}

# Function to parse vote response
parse_vote_response() {
    local response="$1"

    # Print the raw response
    print_status "Response: $response"

    # Extract success status (more robust parsing)
    local success=$(echo "$response" | grep -o '"success":[^,}]*' | cut -d':' -f2 | tr -d ' "')

    if [ "$success" = "true" ]; then
        print_success "Vote successful!"
        return 0
    else
        print_error "Vote failed"
        return 1
    fi
}

# Function to perform a single vote cycle
perform_vote_cycle() {
    local cycle_num="$1"

    print_status "=== Vote Cycle $cycle_num ==="

    # Connect to VPN
    if ! connect_to_vpn; then
        print_error "Failed to connect to VPN"
        return 1
    fi

    # Get current IP and mark it as tried
    local current_ip=$(get_current_ip)
    if [ -n "$current_ip" ]; then
        mark_ip_tried "$current_ip"
    fi

    # Generate random email
    local email=$(generate_random_email)
    print_status "Generated email: $email"

    # Mark email as used
    mark_email_used "$email"

    # Make vote request
    local response=$(make_vote_request "$email")

    # Parse and handle response
    if parse_vote_response "$response"; then
        print_success "Cycle $cycle_num completed successfully!"
        return 0
    else
        print_warning "Cycle $cycle_num failed"
        return 1
    fi
}

# Main function
main() {
    print_status "Starting automated voting process..."
    print_warning "Using NordVPN with fastest/nearest server connections"
    print_warning "Optimized for locked screen operation - uses URL scheme"
    print_warning "Press Ctrl+C to stop the script"

    # Show instance information
    if [ -n "$INSTANCE_ID" ]; then
        print_status "Running as Instance $INSTANCE_ID"
        print_status "Will connect to fastest/nearest server"
    fi

    # Check NordVPN CLI availability
    check_nordvpn

    # Show current IP
    local current_ip=$(get_current_ip)
    print_status "Current IP: $current_ip"

    # Initialize tracking files
    print_status "Tracking files:"
    print_status "  Tried IPs: $TRIED_IPS_FILE"
    print_status "  Used emails: $USED_EMAILS_FILE"

    local successful_votes=0
    local failed_votes=0
    local cycle_count=0

    # Continuous loop
    while true; do
        ((cycle_count++))

        print_status "=== Vote Cycle $cycle_count ==="

        if perform_vote_cycle "$cycle_count"; then
            ((successful_votes++))
        else
            ((failed_votes++))
        fi

        # Show progress every 10 cycles
        if [ $((cycle_count % 10)) -eq 0 ]; then
            print_status "=== Progress Update (Cycle $cycle_count) ==="
            print_success "Successful votes: $successful_votes"
            if [ $failed_votes -gt 0 ]; then
                print_error "Failed votes: $failed_votes"
            fi
            local success_rate=$((successful_votes * 100 / cycle_count))
            print_status "Success rate: $success_rate%"

            # Show tracking statistics
            local tried_count=0
            local email_count=0
            if [ -f "$TRIED_IPS_FILE" ]; then
                tried_count=$(wc -l < "$TRIED_IPS_FILE" 2>/dev/null || echo "0")
            fi
            if [ -f "$USED_EMAILS_FILE" ]; then
                email_count=$(wc -l < "$USED_EMAILS_FILE" 2>/dev/null || echo "0")
            fi
            print_status "Tracking: $tried_count IPs tried, $email_count emails used"

            # Clean up old records periodically
            cleanup_records
        fi

        # No delay - continuous operation for locked screen
        print_status "Continuing immediately to next vote..."
    done
}

# Handle script interruption
trap 'print_warning "Script interrupted. Showing final summary...";
      print_status "=== Final Summary ===";
      print_success "Total successful votes: $successful_votes";
      if [ $failed_votes -gt 0 ]; then print_error "Total failed votes: $failed_votes"; fi;
      local success_rate=$((successful_votes * 100 / cycle_count));
      print_status "Overall success rate: $success_rate%";

      # Show final tracking statistics
      local tried_count=0;
      local email_count=0;
      if [ -f "$TRIED_IPS_FILE" ]; then tried_count=$(wc -l < "$TRIED_IPS_FILE" 2>/dev/null || echo "0"); fi;
      if [ -f "$USED_EMAILS_FILE" ]; then email_count=$(wc -l < "$USED_EMAILS_FILE" 2>/dev/null || echo "0"); fi;
      print_status "Final tracking: $tried_count IPs tried, $email_count emails used";

      exit 1' INT TERM

# Run main function
main "$@"
