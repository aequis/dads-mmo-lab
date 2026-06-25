#!/bin/bash
# ============================================================
#  Dad's MMO Lab - WoW Playerbots Server Installer for macOS
#  AzerothCore WotLK + Playerbots (compiled from source)
#
#  Server-side only:
#    - No Steam Deck Gaming Mode setup
#    - No Linux package manager changes
#    - Requires Docker Desktop, Colima, or another working Docker runtime
#
#  Usage:
#    chmod +x install-wow-wotlk-macos.sh
#    ./install-wow-wotlk-macos.sh
# ============================================================

WIZARD_VERSION="1.0.0-macos"

set -o pipefail

RST='\033[0m'; BOLD='\033[1m'
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; WHITE='\033[1;37m'; CYAN='\033[0;36m'
NC='\033[0m'

SERVER_DIR="${SERVER_DIR:-$HOME/wow-server-playerbots}"
BUILD_LOG="${BUILD_LOG:-$HOME/playerbots-build.log}"
DOCKER_PLATFORM="${DADS_MMO_DOCKER_PLATFORM:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TRIAL_MODE=0

usage() {
    cat << USAGE
Usage:
  $0           Run the macOS server installer
  $0 --trial   Check macOS, Git, Docker, and Docker Compose without building
  $0 --help    Show this help
USAGE
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --trial|--check|--dry-run)
            TRIAL_MODE=1
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            usage
            exit 1
            ;;
    esac
    shift
done

print_header() {
    clear
    echo ""
    echo -e "${CYAN}==================================================${NC}"
    echo -e "${WHITE}${BOLD}        Dad's MMO Lab - WoW Playerbots${NC}"
    echo -e "${WHITE}        macOS Server Installer${NC}"
    echo -e "${BLUE}        github.com/DadsMmoLab/dads-mmo-lab${NC}"
    echo -e "${YELLOW}        Version ${WIZARD_VERSION}${NC}"
    echo -e "${CYAN}==================================================${NC}"
    echo ""
}

print_step() {
    echo ""
    echo -e "${CYAN}--------------------------------------------------${NC}"
    echo -e "${WHITE}${BOLD} $1${NC}"
    echo -e "${CYAN}--------------------------------------------------${NC}"
}

print_success() { echo -e "${GREEN}[OK] $1${NC}"; }
print_warning() { echo -e "${YELLOW}[WARN] $1${NC}"; }
print_error()   { echo -e "${RED}[ERR] $1${NC}"; }
print_info()    { echo -e "${BLUE}[INFO] $1${NC}"; }

ask_yes_no() {
    while true; do
        echo -e "${WHITE}$1 (y/n): ${NC}"
        read -r answer
        case $answer in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo "Please answer y or n.";;
        esac
    done
}

press_enter() {
    echo ""
    echo -e "${WHITE}Press ENTER to continue...${NC}"
    read -r
}

compose() {
    docker compose "$@"
}

remove_server_dir() {
    case "$SERVER_DIR" in
        "$HOME"/wow-server-playerbots|"$HOME"/wow-server-playerbots/*)
            rm -rf "$SERVER_DIR"
            ;;
        *)
            print_error "Refusing to remove unexpected SERVER_DIR: $SERVER_DIR"
            print_info "Remove it manually if you really want to start fresh."
            exit 1
            ;;
    esac
}

available_gb() {
    df -Pk "$HOME" 2>/dev/null | awk 'NR==2 {printf "%d", $4 / 1024 / 1024}'
}

check_system() {
    print_step "Checking macOS Requirements"

    if [[ "$(uname -s)" != "Darwin" ]]; then
        print_error "This installer is macOS-only."
        exit 1
    fi
    print_success "macOS detected"

    local free_gb
    free_gb="$(available_gb)"
    if [ -n "$free_gb" ] && [ "$free_gb" -lt 15 ] 2>/dev/null; then
        print_error "Not enough disk space. You have ${free_gb}GB free, need at least 15GB."
        exit 1
    fi
    print_success "Disk space OK (${free_gb:-unknown}GB available)"

    if ! ping -c 1 github.com >/dev/null 2>&1; then
        print_error "No internet connection to github.com. Please connect and try again."
        exit 1
    fi
    print_success "Internet connection OK"

    if [[ "$(uname -m)" == "arm64" ]]; then
        print_warning "Apple Silicon detected."
        print_info "This script will build using Docker's default native platform."
        print_info "If the build fails due to architecture issues, rerun with:"
        print_info "  DADS_MMO_DOCKER_PLATFORM=linux/amd64 $0"
        echo ""
    fi

    if [ -n "$DOCKER_PLATFORM" ]; then
        print_warning "Forcing Docker platform: $DOCKER_PLATFORM"
    fi
}

check_git() {
    if command -v git >/dev/null 2>&1; then
        print_success "Git found"
        return 0
    fi

    print_error "Git is not installed or not on PATH."
    print_info "Install Apple's command line tools with:"
    print_info "  xcode-select --install"
    print_info "Or install Git with Homebrew:"
    print_info "  brew install git"
    exit 1
}

try_start_docker_desktop() {
    if [ -d "/Applications/Docker.app" ]; then
        print_info "Trying to start Docker Desktop..."
        open -g -a Docker >/dev/null 2>&1 || true

        local waited=0
        while [ "$waited" -lt 90 ]; do
            if docker info >/dev/null 2>&1; then
                print_success "Docker Desktop is running"
                return 0
            fi
            printf "."
            sleep 3
            waited=$((waited + 3))
        done
        echo ""
    fi

    return 1
}

check_docker() {
    if ! command -v docker >/dev/null 2>&1; then
        print_error "Docker command not found."
        print_info "Install Docker Desktop for Mac, or install Colima plus Docker CLI."
        print_info "Then rerun this script after Docker is running."
        exit 1
    fi

    if ! docker info >/dev/null 2>&1; then
        print_warning "Docker is installed but not running."
        if ! try_start_docker_desktop; then
            print_error "Docker is not reachable."
            print_info "Start Docker Desktop or Colima, then rerun this script."
            print_info "For Colima, a common start command is:"
            print_info "  colima start --cpu 6 --memory 12 --disk 40"
            exit 1
        fi
    else
        print_success "Docker is running"
    fi

    if ! docker compose version >/dev/null 2>&1; then
        print_error "Docker Compose v2 is not available as 'docker compose'."
        print_info "Update Docker Desktop or install the Docker Compose plugin."
        exit 1
    fi
    print_success "Docker Compose found"
}

run_trial() {
    print_step "Trial Run"

    check_system
    check_git
    check_docker

    local trial_dir
    trial_dir="$(mktemp -d "${TMPDIR:-/tmp}/dads-mmo-docker-trial.XXXXXX")"
    local cleanup_done=0

    cleanup_trial() {
        if [ "$cleanup_done" -eq 0 ]; then
            cleanup_done=1
            (cd "$trial_dir" && docker compose down --remove-orphans >/dev/null 2>&1) || true
            rm -rf "$trial_dir"
        fi
    }
    trap cleanup_trial EXIT INT TERM

    cat > "$trial_dir/docker-compose.yml" << 'TRIAL_COMPOSE'
services:
  docker-trial:
    image: hello-world:latest
TRIAL_COMPOSE

    print_info "Docker server:"
    docker version --format '  Client: {{.Client.Version}} | Server: {{.Server.Version}}' || exit 1

    print_info "Docker Compose:"
    docker compose version || exit 1

    print_info "Running a tiny throwaway Compose project..."
    print_info "Docker may pull the small hello-world image if it is not cached."
    if (cd "$trial_dir" && docker compose up --abort-on-container-exit --exit-code-from docker-trial); then
        print_success "Docker Compose can pull/start a container"
    else
        print_error "Trial Compose project failed"
        print_info "The installer will not work until this is fixed."
        exit 1
    fi

    cleanup_trial
    trap - EXIT INT TERM

    echo ""
    print_success "Trial run passed. The long server build was not started."
}

show_summary() {
    print_header
    print_step "What Will Be Built"

    echo ""
    echo -e "  ${WHITE}${BOLD}Server:${NC}   ${CYAN}WoW Playerbots (AzerothCore WotLK)${NC}"
    echo -e "  ${WHITE}${BOLD}Folder:${NC}   ${CYAN}$SERVER_DIR${NC}"
    echo -e "  ${WHITE}${BOLD}Build:${NC}    ${YELLOW}Compile from source in Docker (can take hours)${NC}"
    echo -e "  ${WHITE}${BOLD}Platform:${NC} ${CYAN}${DOCKER_PLATFORM:-Docker default}${NC}"
    echo ""
    echo -e "  ${WHITE}${BOLD}This script does:${NC}"
    echo -e "    - Clone AzerothCore WotLK Playerbot branch"
    echo -e "    - Clone mod-playerbots"
    echo -e "    - Write docker-compose.override.yml"
    echo -e "    - Build and start the server containers"
    echo -e "    - Save server commands to MY_SERVER_MACOS.txt"
    echo ""
    echo -e "  ${WHITE}${BOLD}This script does not:${NC}"
    echo -e "    - Install Docker Desktop"
    echo -e "    - Create Steam Deck Gaming Mode launchers"
    echo -e "    - Configure a WoW client"
    echo ""

    if ! ask_yes_no "Ready to build the server?"; then
        echo "No problem. Run this script again when you're ready."
        exit 0
    fi
}

write_compose_override() {
    local platform_line=""
    if [ -n "$DOCKER_PLATFORM" ]; then
        platform_line="    platform: ${DOCKER_PLATFORM}"
    fi

    cat > "$SERVER_DIR/docker-compose.override.yml" << OVERRIDE
services:
  ac-worldserver:
${platform_line}
    build:
      context: .
      target: worldserver
    volumes:
      - ./modules:/azerothcore/modules
      - ./playerbot-overrides/playerbots.conf:/azerothcore/env/dist/etc/modules/playerbots.conf:ro
    environment:
      AC_PLAYERBOTS_UPDATES_ENABLE_DATABASES: "1"
      AC_QUESTS_IGNORE_AUTO_ACCEPT: "1"
  ac-authserver:
${platform_line}
    build:
      context: .
      target: authserver
  ac-db-import:
${platform_line}
    build:
      context: .
      target: db-import
  ac-client-data-init:
${platform_line}
    build:
      context: .
      target: client-data
OVERRIDE
}

install_admin_dashboard() {
    local source_dir="$REPO_ROOT/admin-dashboard"
    local target_dir="$SERVER_DIR/admin-dashboard"
    local override_file="$SERVER_DIR/docker-compose.override.yml"
    local dashboard_password

    if [ ! -d "$source_dir" ]; then
        print_warning "Admin dashboard source not found at $source_dir"
        print_info "Skipping dashboard setup."
        return 0
    fi

    rm -rf "$target_dir"
    cp -R "$source_dir" "$target_dir"
    mkdir -p "$SERVER_DIR/playerbot-overrides"
    cat > "$SERVER_DIR/playerbot-overrides/playerbots.env" << 'PLAYERBOT_ENV'
AC_AI_PLAYERBOT_RANDOM_BOT_AUTOLOGIN=1
AC_AI_PLAYERBOT_MIN_RANDOM_BOTS=1600
AC_AI_PLAYERBOT_MAX_RANDOM_BOTS=2000
AC_AI_PLAYERBOT_ADD_CLASS_ACCOUNT_POOL_SIZE=50
AC_AI_PLAYERBOT_ADD_CLASS_COMMAND=1
AC_AI_PLAYERBOT_SYNC_QUEST_WITH_PLAYER=1
AC_AI_PLAYERBOT_AUTO_DO_QUESTS=1
PLAYERBOT_ENV
    if [ -f "$SERVER_DIR/modules/mod-playerbots/conf/playerbots.conf.dist" ]; then
        cp "$SERVER_DIR/modules/mod-playerbots/conf/playerbots.conf.dist" \
           "$SERVER_DIR/playerbot-overrides/playerbots.conf"
        perl -0pi -e 's/^AiPlayerbot\.RandomBotAutologin\s*=.*/AiPlayerbot.RandomBotAutologin = 1/m' "$SERVER_DIR/playerbot-overrides/playerbots.conf"
        perl -0pi -e 's/^AiPlayerbot\.MinRandomBots\s*=.*/AiPlayerbot.MinRandomBots = 1600/m' "$SERVER_DIR/playerbot-overrides/playerbots.conf"
        perl -0pi -e 's/^AiPlayerbot\.MaxRandomBots\s*=.*/AiPlayerbot.MaxRandomBots = 2000/m' "$SERVER_DIR/playerbot-overrides/playerbots.conf"
        perl -0pi -e 's/^AiPlayerbot\.AddClassAccountPoolSize\s*=.*/AiPlayerbot.AddClassAccountPoolSize = 50/m' "$SERVER_DIR/playerbot-overrides/playerbots.conf"
        perl -0pi -e 's/^AiPlayerbot\.AddClassCommand\s*=.*/AiPlayerbot.AddClassCommand = 1/m' "$SERVER_DIR/playerbot-overrides/playerbots.conf"
        perl -0pi -e 's/^AiPlayerbot\.SyncQuestWithPlayer\s*=.*/AiPlayerbot.SyncQuestWithPlayer = 1/m' "$SERVER_DIR/playerbot-overrides/playerbots.conf"
        perl -0pi -e 's/^AiPlayerbot\.AutoDoQuests\s*=.*/AiPlayerbot.AutoDoQuests = 1/m' "$SERVER_DIR/playerbot-overrides/playerbots.conf"
    fi

    if ! grep -q "wow-admin-dashboard:" "$override_file" 2>/dev/null; then
        dashboard_password="$(LC_ALL=C tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 24)"
        dashboard_password="${dashboard_password:-ChangeMeBeforeUse}"
        cat >> "$override_file" << ADMIN_DASHBOARD
  wow-admin-dashboard:
    build:
      context: ./admin-dashboard
    depends_on:
      ac-database:
        condition: service_healthy
      ac-worldserver:
        condition: service_started
    networks:
      - ac-network
    ports:
      - "8090:8090"
    volumes:
      - ./modules/mod-playerbots/conf/playerbots.conf.dist:/playerbots.conf.dist:ro
      - ./playerbot-overrides:/playerbot-overrides
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      WOW_ADMIN_JDBC_URL: "jdbc:mysql://ac-database:3306/acore_auth?allowPublicKeyRetrieval=true&useSSL=false"
      WOW_ADMIN_DB_USER: "root"
      WOW_ADMIN_DB_PASSWORD: "password"
      WOW_ADMIN_AUTH_DB: "acore_auth"
      WOW_ADMIN_CHARACTERS_DB: "acore_characters"
      WOW_ADMIN_PLAYERBOTS_DB: "acore_playerbots"
      WOW_ADMIN_PLAYERBOTS_CONFIG_PATH: "/playerbots.conf.dist"
      WOW_ADMIN_PLAYERBOTS_OVERRIDE_ENV_PATH: "/playerbot-overrides/playerbots.env"
      WOW_ADMIN_PLAYERBOTS_GENERATED_CONFIG_PATH: "/playerbot-overrides/playerbots.conf"
      WOW_ADMIN_DOCKER_SOCKET_PATH: "/var/run/docker.sock"
      WOW_ADMIN_WORLDSERVER_CONTAINER: "ac-worldserver"
      WOW_ADMIN_DASHBOARD_USER: "admin"
      WOW_ADMIN_DASHBOARD_PASSWORD: "$dashboard_password"
      WOW_ADMIN_SOAP_URL: "http://ac-worldserver:7878/"
      WOW_ADMIN_SOAP_USER: ""
      WOW_ADMIN_SOAP_PASSWORD: ""
ADMIN_DASHBOARD
    fi

    print_success "Admin dashboard installed"
    print_info "Dashboard URL: http://127.0.0.1:8090"
    print_info "Dashboard login is admin plus the password in docker-compose.override.yml"
}

install_server() {
    print_header
    print_step "Building Playerbots Server"

    check_git
    check_docker

    if [ -d "$SERVER_DIR" ] && \
       (cd "$SERVER_DIR" && compose images 2>/dev/null | grep -qi "worldserver"); then
        print_success "Compiled images already found in $SERVER_DIR"
        print_info "Skipping compile and starting existing server."
        install_admin_dashboard
        cd "$SERVER_DIR" || exit 1
        compose up -d 2>&1 | tail -5
        return 0
    fi

    if [ -d "$SERVER_DIR" ]; then
        print_warning "Existing folder found at $SERVER_DIR, but no compiled worldserver image was found."
        if ask_yes_no "Remove it and start fresh?"; then
            compose -f "$SERVER_DIR/docker-compose.yml" down -v >/dev/null 2>&1 || true
            remove_server_dir
            print_success "Old install removed"
        else
            print_info "Keeping existing install. Exiting."
            exit 0
        fi
    fi

    print_info "Cloning AzerothCore Playerbot fork..."
    git clone \
        https://github.com/mod-playerbots/azerothcore-wotlk.git \
        --branch=Playerbot \
        "$SERVER_DIR"

    if [ ! -d "$SERVER_DIR" ]; then
        print_error "Clone failed. Check your internet connection."
        exit 1
    fi

    mkdir -p "$SERVER_DIR/modules"

    print_info "Cloning mod-playerbots module..."
    if git clone --depth 1 \
        https://github.com/mod-playerbots/mod-playerbots.git \
        --branch=master \
        "$SERVER_DIR/modules/mod-playerbots"; then
        print_success "mod-playerbots module cloned"
    else
        print_error "mod-playerbots clone failed."
        exit 1
    fi

    write_compose_override
    install_admin_dashboard
    print_success "Docker Compose override written"

    print_info "Compiling Playerbots server. This can take a long time."
    print_info "Build log: $BUILD_LOG"

    cd "$SERVER_DIR" || exit 1
    compose up -d --build 2>&1 | tee "$BUILD_LOG"

    if [ ${PIPESTATUS[0]} -ne 0 ]; then
        print_error "Compilation failed. Check $BUILD_LOG"
        if [[ "$(uname -m)" == "arm64" ]] && [ -z "$DOCKER_PLATFORM" ]; then
            print_info "On Apple Silicon, try rerunning with:"
            print_info "  DADS_MMO_DOCKER_PLATFORM=linux/amd64 $0"
        fi
        exit 1
    fi

    print_success "Playerbots server compiled and started"
}

wait_for_server() {
    print_step "Waiting For World Server"
    print_info "First launch after compilation may take 10-15 minutes."

    local timeout=1800
    local elapsed=0
    local ready=0
    local world_container=""

    while [ "$elapsed" -lt "$timeout" ]; do
        world_container=$(docker ps --format '{{.Names}}' \
            2>/dev/null | grep -i "worldserver" | head -1)

        if [ -n "$world_container" ]; then
            if docker logs "$world_container" \
                2>/dev/null | grep -q "ready\.\.\."; then
                ready=1
                break
            fi
        fi

        printf "."
        sleep 10
        elapsed=$((elapsed + 10))
    done

    echo ""
    echo ""

    if [ "$ready" -eq 1 ]; then
        print_success "Server is ready"
    else
        print_warning "Server is taking longer than expected."
        print_info "Check progress with:"
        print_info "  cd $SERVER_DIR && docker compose logs -f ac-worldserver"
    fi
}

write_server_info() {
    cat > "$SERVER_DIR/MY_SERVER_MACOS.txt" << INFO
Dad's MMO Lab - WoW Playerbots macOS Server
===========================================

SERVER:
  Folder:    ${SERVER_DIR}
  Realmlist: 127.0.0.1
  Ports:     3724 auth, 8085 world

USEFUL COMMANDS:
  Start:
    cd "${SERVER_DIR}" && docker compose up -d

  Stop:
    cd "${SERVER_DIR}" && docker compose down

  Logs:
    cd "${SERVER_DIR}" && docker compose logs -f

  Worldserver logs:
    cd "${SERVER_DIR}" && docker compose logs -f ac-worldserver

  Admin dashboard:
    http://127.0.0.1:8090

  Enable dashboard command buttons:
    Edit docker-compose.override.yml and set WOW_ADMIN_SOAP_USER / WOW_ADMIN_SOAP_PASSWORD
    on the wow-admin-dashboard service, then run docker compose up -d.

  Console:
    docker attach \$(docker ps --format '{{.Names}}' | grep worldserver | head -1)

CREATE ACCOUNTS:
  1. Attach to the worldserver console:
       docker attach \$(docker ps --format '{{.Names}}' | grep worldserver | head -1)

  2. At the AC> prompt:
       account create USERNAME PASSWORD
       account set gmlevel USERNAME 3 -1

  3. Detach safely:
       Press Ctrl+P, then Ctrl+Q
       Do not press Ctrl+C; that stops the worldserver.

CLIENT REALMLIST:
  Set realmlist.wtf to:
    set realmlist 127.0.0.1

APPLE SILICON NOTE:
  If native Docker builds fail, try rebuilding with:
    DADS_MMO_DOCKER_PLATFORM=linux/amd64 ./install-wow-wotlk-macos.sh
INFO

    print_success "Server info saved to $SERVER_DIR/MY_SERVER_MACOS.txt"
}

show_account_instructions() {
    print_step "Create Your Account"

    echo ""
    echo -e "${WHITE}Your server containers should now be running.${NC}"
    echo ""
    echo -e "${WHITE}${BOLD}1. Attach to the worldserver console:${NC}"
    echo -e "   ${CYAN}docker attach \$(docker ps --format '{{.Names}}' | grep worldserver | head -1)${NC}"
    echo ""
    echo -e "${WHITE}${BOLD}2. At the AC> prompt, create an account:${NC}"
    echo -e "   ${GREEN}account create USERNAME PASSWORD${NC}"
    echo -e "   ${GREEN}account set gmlevel USERNAME 3 -1${NC}"
    echo ""
    echo -e "${WHITE}${BOLD}3. Detach safely:${NC}"
    echo -e "   ${YELLOW}Press Ctrl+P, then Ctrl+Q${NC}"
    echo -e "   ${RED}Do not press Ctrl+C; that stops the worldserver.${NC}"
    echo ""
    echo -e "${WHITE}${BOLD}4. Set your WoW client's realmlist.wtf to:${NC}"
    echo -e "   ${GREEN}set realmlist 127.0.0.1${NC}"
    echo ""
}

show_completion() {
    print_step "Done"

    echo ""
    echo -e "${GREEN}${BOLD}WoW Playerbots server setup is complete.${NC}"
    echo ""
    echo -e "  ${WHITE}${BOLD}Server folder:${NC} ${CYAN}$SERVER_DIR${NC}"
    echo -e "  ${WHITE}${BOLD}Reference:${NC}     ${CYAN}$SERVER_DIR/MY_SERVER_MACOS.txt${NC}"
    echo ""
    echo -e "${WHITE}${BOLD}Start:${NC}"
    echo -e "  ${CYAN}cd \"$SERVER_DIR\" && docker compose up -d${NC}"
    echo ""
    echo -e "${WHITE}${BOLD}Stop:${NC}"
    echo -e "  ${CYAN}cd \"$SERVER_DIR\" && docker compose down${NC}"
    echo ""

    if ask_yes_no "Would you like to stop the server now?"; then
        print_info "Stopping server..."
        cd "$SERVER_DIR" && compose down
        print_success "Server stopped"
    else
        print_info "Server left running"
    fi
}

print_header
echo -e "${WHITE}This installer sets up only the server-side WotLK Playerbots stack on macOS.${NC}"
echo -e "${WHITE}Docker must already be installed and running, or Docker Desktop must be available.${NC}"
echo ""

if [ "$TRIAL_MODE" -eq 1 ]; then
    run_trial
    exit 0
fi

if ! ask_yes_no "Ready to begin?"; then
    echo "No problem. Run this script when you're ready."
    exit 0
fi

check_system
show_summary
install_server
wait_for_server
write_server_info
show_account_instructions
show_completion
