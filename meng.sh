#!/bin/bash
set -euo pipefail

# ============================================================================
# MENG - Server Management Script
# A unified interface for deployment, SSH, and server management
# ============================================================================

# ###### #
# CONFIG #
# ###### #

# DEFINE YOUR ALIASES HERE
declare -A aliases=(
[myserver]="user@192.168.1.100:/path/to/deploy/"
[staging]="deploy@staging.company.com:/var/www/"
[production]="admin@prod.company.com:/opt/apps/"
)
##########

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

#vars
readonly DEFAULT_FILE="" #If you dont set -file it will default to this file, very handy for testing
readonly VERSION="0.1.0"

# ################# #
# UTILITY FUNCTIONS #
# ################# #

log_info() {
echo -e "${BLUE}i${NC} $1"
}
log_success() {
echo -e "${GREEN}✓${NC} $1"
}
log_warning() {
echo -e "${YELLOW}⚠${NC} $1"
}
log_error() {
echo -e "${RED}✗${NC} $1" >&2
}

usage() {
printf "%b\n" \
"${BLUE}MENG${NC} - Server Management Script v${VERSION}" \
"${YELLOW}USAGE:${NC}" \
"$0 -alias <alias> -action <action> [-file <filename>] [options]" \
"${YELLOW}ACTIONS:${NC}" \
"${GREEN}scp${NC} Copy file to server" \
"${GREEN}ssh${NC} Connect to server via SSH" \
"${GREEN}deploy${NC} Build (if needed) and deploy file" \
"${GREEN}list${NC} Show all available server aliases" \
"${YELLOW}OPTIONS:${NC}" \
"-alias <name> Server alias (required for most actions)" \
"-action <action> Action to perform (required)" \
"-file <filename> File to copy/deploy (required for scp/deploy)" \
"-v, --verbose Enable verbose output" \
"-h, --help Show this help message" \
"--version Show version information" \
"${YELLOW}EXAMPLES:${NC}" \
"$0 -alias ubproxy -action ssh" \
"$0 -alias ubproxy -action deploy -file mazarin" \
"$0 -action list" 
}

show_version() {
    echo "MENG v${VERSION}"
    echo "Server Management Script"
}

build_go() {
    if go build -o "$FILE"; then
        log_success "Build completed successfully"
    else
        log_error "Build failed"
        exit 1
    fi
}

validate_alias() {
    if [[ -z "${aliases[$ALIAS]+_}" ]]; then
        log_error "Unknown alias '$ALIAS'"
        log_info "Available aliases:"
        action_list_aliases
        exit 1
    fi
}

validate_file() {
    if [[ ! -f "$FILE" ]]; then
        log_error "File '$FILE' not found"
        exit 1
    fi
}


# ########## #
# MAIN LOGIC #
# ########## #

parse_alias() {
    validate_alias
    local alias_full="${aliases[$ALIAS]}"
    USER_HOST="${alias_full%%:*}"  # %%:* = "Remove the longest match of :* from the end"
    REMOTE_PATH="${alias_full#*:}" # #*: = "Remove the shortest match of *: from the beginning"
    USER="${USER_HOST%@*}"         # %@* = "Remove the shortest match of @* from the end"
    HOST="${USER_HOST#*@}"         # #*@ = "Remove the shortest match of *@ from the beginning"
    if [[ "$VERBOSE" == true ]]; then
        log_info "Parsed alias '$ALIAS':"
        echo " User: $USER"
        echo " Host: $HOST"
        echo " Remote Path: $REMOTE_PATH"
    fi
}

parse_arguments() {
    ALIAS=""
    ACTION=""
    FILE=""
    VERBOSE=false
    while [[ $# -gt 0 ]]; do
        case $1 in
            -alias)
                ALIAS="$2"
                shift 2
                ;;
            -action)
                ACTION="$2"
                shift 2
                ;;
            -file)
                FILE="$2"
                shift 2
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            --version)
                show_version
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done
}

# ####### #
# ACTIONS #
# ####### #

action_scp() {
    if [ -z "${FILE}" ]; then
        FILE="$DEFAULT_FILE"
        log_warning "No file specified for scp, using DEFAULT_FILE fallback: $DEFAULT_FILE"
    fi
    validate_file
    log_info "Copying '$FILE' to $USER@$HOST:$REMOTE_PATH"
    if scp "$FILE" "$USER@$HOST:$REMOTE_PATH"; then
        log_success "File copied successfully"
    else
        log_error "SCP failed"
        exit 1
    fi
}

action_ssh() {
    log_info "Connecting to $USER@$HOST..."
    ssh "$USER@$HOST"
}

action_deploy() {
    if [ -z "${FILE}" ]; then
        FILE="$DEFAULT_FILE"
        log_warning "No file specified for scp, using DEFAULT_FILE fallback: $DEFAULT_FILE"
    fi
    build_go
    log_info "Deploying '$FILE' to $ALIAS ($USER@$HOST)"
    if scp "$FILE" "$USER@$HOST:$REMOTE_PATH"; then
        log_success "Deployment completed successfully! "
    else
        log_error "Deployment failed"
        exit 1
    fi
}


action_list_aliases() {
    echo -e "${YELLOW}Available server aliases:${NC}"
    for alias in "${!aliases[@]}"; do
        local alias_info="${aliases[$alias]}"
        local user_host="${alias_info%%:*}"
        local path="${alias_info#*:}"
        echo -e " ${GREEN}$alias${NC} -> $user_host:$path"
    done
}

# ############## #
# MAIN EXECUTION #
# ############## #

main(){
    parse_arguments "$@"

    # Validate required arguments
    if [[ -z "$ACTION" ]]; then
        log_error "Action is required"
        usage
        exit 1
    fi

    if [[ "$ACTION" != "list" && -z "$ALIAS" ]]; then
        log_error "Alias is required for action '$ACTION'"
        usage
        exit 1
    fi

    case $ACTION in
        ssh)
            parse_alias
            action_ssh
            ;;
        scp)
            parse_alias
            action_scp
            ;;
        deploy)
            parse_alias
            action_deploy
            ;;
        list)
            action_list_aliases
            ;;
        *)
            log_error "Unknown action: $ACTION"
            usage
            exit 1
            ;;
    esac
}

main "$@"