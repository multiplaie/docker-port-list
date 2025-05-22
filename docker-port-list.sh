#!/bin/bash

# 👨‍💻 Script: docker-port-list — version cinéma hacker
# Affiche les conteneurs Docker actifs regroupés par stack avec un affichage stylé vert néon
# Options: --no-style, --json, --hacker (par défaut), --short (affiche seulement résumé des ports)

# Couleurs et effets
GREEN='\033[0;92m'
BOLD='\033[1m'
RESET='\033[0m'

# Gestion des options
STYLE=1   # 1 = hacker, 0 = no-style
JSON=0
SHORT=0

while [[ $# -gt 0 ]]; do
  case $1 in
    --no-style)
      STYLE=0
      shift
      ;;
    --json)
      JSON=1
      STYLE=0
      shift
      ;;
    --hacker)
      STYLE=1
      JSON=0
      shift
      ;;
    --short)
      SHORT=1
      shift
      ;;
    *)
      echo "Option inconnue : $1"
      exit 1
      ;;
  esac
done

# Récupération et résumé des ports exposés
get_ports_summary() {
    local containers ports_line host_port
    containers=$(docker ps -q)
    declare -A ports_summary

    for id in $containers; do
        ports=$(docker port "$id")
        while IFS= read -r line; do
            host_port=$(echo "$line" | awk -F'->' '{print $2}' | awk -F':' '{print $2}')
            [ -n "$host_port" ] && ports_summary["$host_port"]=1
        done <<< "$ports"
    done

    echo "${!ports_summary[@]}"
}

# Affichage résumé hacker
print_summary_hacker() {
    local ports=("$@")
    echo -e "${BOLD}${GREEN}╔═ Résumé des ports exposés sur la machine ═══════════════════════════╗${RESET}"
    if [[ ${#ports[@]} -eq 0 ]]; then
        echo -e "${GREEN}║ Aucun port exposé                                                 ║"
    else
        for port in "${ports[@]}"; do
            printf "${GREEN}║ Port %-63s ║\n" "$port"
        done | sort -n -k2
    fi
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════════╝${RESET}\n"
}

# Affichage résumé simple
print_summary_simple() {
    local ports=("$@")
    echo "Résumé des ports exposés :"
    if [[ ${#ports[@]} -eq 0 ]]; then
        echo "Aucun port exposé"
    else
        for port in "${ports[@]}"; do
            echo " - $port"
        done | sort -n -k1
    fi
}

# Affichage résumé JSON
print_summary_json() {
    local ports=("$@")
    echo "{"
    echo '  "ports": ['
    local first=1
    for port in "${ports[@]}"; do
        if (( first == 0 )); then
            echo ","
        fi
        echo "    \"$port\""
        first=0
    done
    echo
    echo "  ]"
    echo "}"
}

# Fonction affichage complet hacker (version cinéma)
print_hacker() {
    echo -e "${GREEN}${BOLD}"
    echo "╔═══════════════════════════════════════════════════╗"
    echo "║             SCAN DES CONTENEURS DOCKER           ║"
    echo "╚═══════════════════════════════════════════════════╝"
    echo -ne "${RESET}"
    sleep 0.3
    for i in {1..3}; do
        echo -ne "${GREEN}> Analyse en cours"
        for dot in {1..3}; do
            echo -ne "."
            sleep 0.2
        done
        echo -ne "\r"
        sleep 0.2
    done
    echo -e "${GREEN}✔ Conteneurs détectés.${RESET}\n"
    sleep 0.5

    containers=$(docker ps -q)
    declare -A ports_summary

    # Récupération des projets docker-compose (label)
    projects=$(for id in $containers; do
        docker inspect -f '{{ index .Config.Labels "com.docker.compose.project" }}' "$id"
    done | sort -u)

    # Affichage par projet
    for project in $projects; do
        [ -z "$project" ] && continue
        echo -e "${BOLD}${GREEN}╔═ Project: $project ═════════════════════════════════════════════════╗${RESET}"
        printf "${GREEN}║ %-28s │ %-15s │ %-30s ║\n" "CONTAINER" "IP INTERNE" "PORTS EXPOSES"
        echo -e "╟──────────────────────────────────────────────────────────────────────╢"

        for id in $containers; do
            project_label=$(docker inspect -f '{{ index .Config.Labels "com.docker.compose.project" }}' "$id")
            if [[ "$project_label" == "$project" ]]; then
                name=$(docker inspect -f '{{.Name}}' "$id" | cut -c2-)
                ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$id")
                ports=$(docker port "$id")
                ports_display=$(echo "$ports" | paste -sd "," -)
                printf "${GREEN}║ %-28s │ %-15s │ %-30s ║\n" "$name" "$ip" "${ports_display:-Aucun}"
                while IFS= read -r line; do
                    host_port=$(echo "$line" | awk -F'->' '{print $2}' | awk -F':' '{print $2}')
                    [ -n "$host_port" ] && ports_summary["$host_port"]=1
                done <<< "$ports"
            fi
        done
        echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════════╝${RESET}\n"
        sleep 0.3
    done

    # Conteneurs sans label docker-compose
    echo -e "${BOLD}${GREEN}╔═ Autres conteneurs (non compose) ═════════════════════════════════════╗${RESET}"
    printf "${GREEN}║ %-28s │ %-15s │ %-30s ║\n" "CONTAINER" "IP INTERNE" "PORTS EXPOSES"
    echo -e "╟──────────────────────────────────────────────────────────────────────╢"

    for id in $containers; do
        project_label=$(docker inspect -f '{{ index .Config.Labels "com.docker.compose.project" }}' "$id")
        if [[ -z "$project_label" ]]; then
            name=$(docker inspect -f '{{.Name}}' "$id" | cut -c2-)
            ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$id")
            ports=$(docker port "$id")
            ports_display=$(echo "$ports" | paste -sd "," -)
            printf "${GREEN}║ %-28s │ %-15s │ %-30s ║\n" "$name" "$ip" "${ports_display:-Aucun}"
            while IFS= read -r line; do
                host_port=$(echo "$line" | awk -F'->' '{print $2}' | awk -F':' '{print $2}')
                [ -n "$host_port" ] && ports_summary["$host_port"]=1
            done <<< "$ports"
        fi
    done
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════════╝${RESET}"

    # Résumé final
    echo
    print_summary_hacker "${!ports_summary[@]}"
}

# Fonction affichage complet simple
print_simple() {
    containers=$(docker ps -q)
    declare -A ports_summary

    echo "SCAN DES CONTENEURS DOCKER"
    echo "------------------------------------------------------------"
    echo "CONTAINER                     IP INTERNE      PORTS EXPOSES"
    echo "------------------------------------------------------------"

    for id in $containers; do
        name=$(docker inspect -f '{{.Name}}' "$id" | cut -c2-)
        ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$id")
        ports=$(docker port "$id")
        ports_display=$(echo "$ports" | paste -sd "," -)
        printf "%-28s %-15s %s\n" "$name" "$ip" "${ports_display:-Aucun}"
        while IFS= read -r line; do
            host_port=$(echo "$line" | awk -F'->' '{print $2}' | awk -F':' '{print $2}')
            [ -n "$host_port" ] && ports_summary["$host_port"]=1
        done <<< "$ports"
    done

    echo
    echo "Résumé des ports exposés sur la machine :"
    if [[ ${#ports_summary[@]} -eq 0 ]]; then
        echo "Aucun port exposé"
    else
        for port in "${!ports_summary[@]}"; do
            echo "Port $port"
        done | sort -n -k1
    fi
}

# Fonction affichage complet JSON
print_json() {
    containers=$(docker ps -q)
    declare -A ports_summary
    echo "{"
    echo '  "containers": ['

    first_container=1
    for id in $containers; do
        if (( first_container == 0 )); then
            echo ","
        fi
        first_container=0

        name=$(docker inspect -f '{{.Name}}' "$id" | cut -c2-)
        ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$id")

        ports=$(docker port "$id")
        ports_json="[]"
        if [[ -n "$ports" ]]; then
            ports_json="["
            first_port=1
            while IFS= read -r line; do
                proto_port=$(echo "$line" | awk -F' ' '{print $1}')
                host_binding=$(echo "$line" | awk -F'->' '{print $2}' | xargs)
                ports_json+="${first_port==1?"":","}{\"proto_port\":\"$proto_port\",\"host_binding\":\"$host_binding\"}"
                first_port=0
            done <<< "$ports"
            ports_json+="]"
        fi

        printf '    {"name": "%s", "ip": "%s", "ports": %s}' "$name" "$ip" "$ports_json"

        while IFS= read -r line; do
            host_port=$(echo "$line" | awk -F'->' '{print $2}' | awk -F':' '{print $2}')
            [ -n "$host_port" ] && ports_summary["$host_port"]=1
        done <<< "$ports"
    done

    echo
    echo "  ],"
    echo '  "ports_exposes": ['

    first_port=1
    for port in "${!ports_summary[@]}"; do
        if (( first_port == 0 )); then
            echo ","
        fi
        first_port=0
        echo "    \"$port\""
    done

    echo "  ]"
    echo "}"
}

# Début logique

if [[ $SHORT -eq 1 ]]; then
    ports=($(get_ports_summary))
    if [[ $JSON -eq 1 ]]; then
        print_summary_json "${ports[@]}"
    elif [[ $STYLE -eq 0 ]]; then
        print_summary_simple "${ports[@]}"
    else
        print_summary_hacker "${ports[@]}"
    fi
else
    if [[ $JSON -eq 1 ]]; then
        print_json
    elif [[ $STYLE -eq 0 ]]; then
        print_simple
    else
        print_hacker
    fi
fi
