#!/bin/bash

# 👨‍💻 Script: docker-port-list 

# Couleurs et effets
GREEN='\033[0;92m'
BOLD='\033[1m'
RESET='\033[0m'

# Fonction d'affichage de l'aide
print_help() {
    echo -e "${BOLD}Usage:${RESET} $0 [--short] [--help]"
    echo
    echo "Options :"
    echo "  --short    Display a summary of exposed ports by project"
    echo "  --help     Display this help message"
    exit 0
}

# Check options
for arg in "$@"; do
    case "$arg" in
        --help)
            print_help
            ;;
    esac
done


SHORT_MODE=false

# Vérifie si le mode court est activé
for arg in "$@"; do
    if [[ "$arg" == "--short" || "$arg" == "-s" ]]; then
        SHORT_MODE=true
        break
    fi
done

# Liste des conteneurs
containers=$(docker ps -q)

# Récupération des projets docker-compose (label)
projects=$(for id in $containers; do
    docker inspect -f '{{ index .Config.Labels "com.docker.compose.project" }}' "$id"
done | sort -u)

# Fonction pour déterminer les ports exposés
get_ports_list() {
    local id="$1"
    local ports
    ports=$(docker port "$id")
    if [ -n "$ports" ]; then
        echo "$ports" | awk -F'[:]' '{print $NF}' | tr -d ' ' 
    fi
}

if $SHORT_MODE; then
    declare -A short_ports

    # Collecte des ports dans des tableaux par projet
    for id in $containers; do
        label=$(docker inspect -f '{{ index .Config.Labels "com.docker.compose.project" }}' "$id")
        ports=$(get_ports_list "$id")
        for port in $ports; do
            if [ -n "$label" ]; then
                short_ports["$label"]+="$port\n"
            else
                short_ports["__other__"]+="$port\n"
            fi
        done
    done

    echo -e "${BOLD}${GREEN}📊 Short list of ports by projects${RESET}"
    for project in "${!short_ports[@]}"; do
        # Nettoyage, tri et dédoublonnage
        ports_clean=$(echo -e "${short_ports[$project]}" | grep -E '^[0-9]+$' | sort -nu | paste -sd "," -)
        
        if [[ "$project" == "__other__" ]]; then
            echo -e "\n📦 ${BOLD}Others containers (non-compose):${RESET}"
        else
            echo -e "\n📦 Project : ${BOLD}$project${RESET}"
        fi

        if [ -n "$ports_clean" ]; then
            echo -e "  → ${GREEN}$ports_clean${RESET}"
        else
            echo -e "  → ${GREEN}(no port exposed)${RESET}"
        fi
    done
    echo ""
    exit 0
fi

# 🧪 Anim' hacker (mode complet)
echo -e "${GREEN}${BOLD}"
echo "╔═══════════════════════════════════════════════════╗"
echo "║             SCAN DOCKER CONTAINERS                ║"
echo "╚═══════════════════════════════════════════════════╝"
echo -ne "${RESET}"
sleep 0.3
for i in {1..3}; do
    echo -ne "${GREEN}> Searching for containers"
    for dot in {1..3}; do
        echo -ne "."
        sleep 0.2
    done
    echo -ne "\r"
    sleep 0.2
done
echo -e "${GREEN}✔ Containers found.${RESET}\n"
sleep 0.5

# Fonction d'affichage pour les ports formatés
get_ports_display() {
    local id="$1"
    local ports
    ports=$(docker port "$id")
    if [ -n "$ports" ]; then
        echo "$ports" | paste -sd "," -
    else
        local network_mode
        network_mode=$(docker inspect -f '{{.HostConfig.NetworkMode}}' "$id")
        if [[ "$network_mode" == "host" ]]; then
            echo "Default (host)"
        else
            echo "None"
        fi
    fi
}

# Affichage par projet
for project in $projects; do
    [ -z "$project" ] && continue
    echo -e "${BOLD}${GREEN}╔═ Project: $project ═════════════════════════════════════════════════╗${RESET}"
    printf "${GREEN}║ %-28s │ %-15s │ %-30s ║\n" "CONTAINER" "IP" "PORTS EXPOSED"
    echo -e "╟──────────────────────────────────────────────────────────────────────╢"

    for id in $containers; do
        project_label=$(docker inspect -f '{{ index .Config.Labels "com.docker.compose.project" }}' "$id")
        if [[ "$project_label" == "$project" ]]; then
            name=$(docker inspect -f '{{.Name}}' "$id" | cut -c2-)
            ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$id")
            ports_display=$(get_ports_display "$id")
            printf "${GREEN}║ %-28s │ %-15s │ %-30s ║\n" "$name" "$ip" "$ports_display"
        fi
    done
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════════╝${RESET}\n"
    sleep 0.3
done

# Conteneurs sans label docker-compose
echo -e "${BOLD}${GREEN}╔═ Others (non compose) ═════════════════════════════════════╗${RESET}"
printf "${GREEN}║ %-28s │ %-15s │ %-30s ║\n" "CONTAINER" "IP" "PORTS EXPOSED"
echo -e "╟──────────────────────────────────────────────────────────────────────╢"

for id in $containers; do
    project_label=$(docker inspect -f '{{ index .Config.Labels "com.docker.compose.project" }}' "$id")
    if [[ -z "$project_label" ]]; then
        name=$(docker inspect -f '{{.Name}}' "$id" | cut -c2-)
        ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$id")
        ports_display=$(get_ports_display "$id")
        printf "${GREEN}║ %-28s │ %-15s │ %-30s ║\n" "$name" "$ip" "$ports_display"
    fi
done
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════════╝${RESET}\n"
