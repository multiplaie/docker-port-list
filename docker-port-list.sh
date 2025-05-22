#!/bin/bash

# 👨‍💻 Script: docker-port-list — version cinéma hacker
# Affiche les conteneurs Docker actifs regroupés par stack avec un affichage stylé vert néon

# Couleurs et effets
GREEN='\033[0;92m'
BOLD='\033[1m'
RESET='\033[0m'

# Gestion des options
STYLE=1   # 1 = hacker, 0 = no-style
JSON=0

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
    *)
      echo "Option inconnue : $1"
      exit 1
      ;;
  esac
done

# Fonction pour récupérer infos container
get_container_info() {
    local id=$1
    local name ip ports
    name=$(docker inspect -f '{{.Name}}' "$id" | cut -c2-)
    ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$id")
    ports=$(docker port "$id")
    echo "$name|$ip|$ports"
}

# Fonction affichage JSON
print_json() {
    local containers projects project
    containers=$(docker ps -q)
    declare -A ports_summary

    projects=$(for id in $containers; do
        docker inspect -f '{{ index .Config.Labels "com.docker.compose.project" }}' "$id"
    done | sort -u)

    echo "{"
    echo '  "projects": ['

    local first_proj=1
    for project in $projects; do
        [ -z "$project" ] && continue
        (( first_proj == 0 )) && echo ","
        echo "    {"
        echo "      \"name\": \"$project\","
        echo "      \"containers\": ["

        local first_cont=1
        for id in $containers; do
            project_label=$(docker inspect -f '{{ index .Config.Labels "com.docker.compose.project" }}' "$id")
            if [[ "$project_label" == "$project" ]]; then
                info=$(get_container_info "$id")
                name=$(echo "$info" | cut -d'|' -f1)
                ip=$(echo "$info" | cut -d'|' -f2)
                ports=$(echo "$info" | cut -d'|' -f3)
                ports_json=$(echo "$ports" | awk -F'->' '{print "\"" $1 "\":\"" $2 "\""}' | paste -sd "," -)
                ports_json="[${ports_json}]"
                (( first_cont == 0 )) && echo ","
                echo "        {"
                echo "          \"name\": \"$name\","
                echo "          \"ip\": \"$ip\","
                echo "          \"ports\": \"$ports\""
                echo "        }"
                first_cont=0
            fi
        done

        echo "      ]"
        echo -n "    }"
        first_proj=0
    done

    # Conteneurs sans projet
    echo ","
    echo "    {"
    echo '      "name": "no-project",'
    echo "      \"containers\": ["
    first_cont=1
    for id in $containers; do
        project_label=$(docker inspect -f '{{ index .Config.Labels "com.docker.compose.project" }}' "$id")
        if [[ -z "$project_label" ]]; then
            info=$(get_container_info "$id")
            name=$(echo "$info" | cut -d'|' -f1)
            ip=$(echo "$info" | cut -d'|' -f2)
            ports=$(echo "$info" | cut -d'|' -f3)
            (( first_cont == 0 )) && echo ","
            echo "        {"
            echo "          \"name\": \"$name\","
            echo "          \"ip\": \"$ip\","
            echo "          \"ports\": \"$ports\""
            echo "        }"
            first_cont=0
        fi
    done
    echo "      ]"
    echo "    }"

    echo "  ]"
    echo "}"
}

# Fonction affichage simple (sans style)
print_simple() {
    containers=$(docker ps -q)
    declare -A ports_summary

    projects=$(for id in $containers; do
        docker inspect -f '{{ index .Config.Labels "com.docker.compose.project" }}' "$id"
    done | sort -u)

    for project in $projects; do
        [ -z "$project" ] && continue
        echo "Project: $project"
        printf "%-30s %-15s %-30s\n" "CONTAINER" "IP INTERNE" "PORTS EXPOSES"
        echo "-------------------------------------------------------------------------------"

        for id in $containers; do
            project_label=$(docker inspect -f '{{ index .Config.Labels "com.docker.compose.project" }}' "$id")
            if [[ "$project_label" == "$project" ]]; then
                info=$(get_container_info "$id")
                name=$(echo "$info" | cut -d'|' -f1)
                ip=$(echo "$info" | cut -d'|' -f2)
                ports=$(echo "$info" | cut -d'|' -f3)
                ports_display=$(echo "$ports" | paste -sd "," -)
                printf "%-30s %-15s %-30s\n" "$name" "$ip" "${ports_display:-Aucun}"
                while IFS= read -r line; do
                    host_port=$(echo "$line" | awk -F'->' '{print $2}' | awk -F':' '{print $2}')
                    [ -n "$host_port" ] && ports_summary["$host_port"]=1
                done <<< "$ports"
            fi
        done
        echo
    done

    echo "Project: no-project"
    printf "%-30s %-15s %-30s\n" "CONTAINER" "IP INTERNE" "PORTS EXPOSES"
    echo "-------------------------------------------------------------------------------"

    for id in $containers; do
        project_label=$(docker inspect -f '{{ index .Config.Labels "com.docker.compose.project" }}' "$id")
        if [[ -z "$project_label" ]]; then
            info=$(get_container_info "$id")
            name=$(echo "$info" | cut -d'|' -f1)
            ip=$(echo "$info" | cut -d'|' -f2)
            ports=$(echo "$info" | cut -d'|' -f3)
            ports_display=$(echo "$ports" | paste -sd "," -)
            printf "%-30s %-15s %-30s\n" "$name" "$ip" "${ports_display:-Aucun}"
            while IFS= read -r line; do
                host_port=$(echo "$line" | awk -F'->' '{print $2}' | awk -F':' '{print $2}')
                [ -n "$host_port" ] && ports_summary["$host_port"]=1
            done <<< "$ports"
        fi
    done

    echo
    echo "Résumé des ports exposés :"
    for port in "${!ports_summary[@]}"; do
        echo " - $port"
    done
}

# Fonction affichage hacker (ton script de base)
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

    projects=$(for id in $containers; do
        docker inspect -f '{{ index .Config.Labels "com.docker.compose.project" }}' "$id"
    done | sort -u)

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

    echo -e "\n${BOLD}${GREEN}╔═ Résumé des ports exposés sur la machine ═══════════════════════════╗${RESET}"
    if [[ ${#ports_summary[@]} -eq 0 ]]; then
        echo -e "${GREEN}║ Aucun port exposé                                                 ║"
    else
        for port in "${!ports_summary[@]}"; do
            printf "${GREEN}║ Port %-63s ║\n" "$port"
        done | sort -n -k2
    fi
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════════╝${RESET}\n"
}

# Lancement selon mode
if [[ $JSON -eq 1 ]]; then
    print_json
elif [[ $STYLE -eq 0 ]]; then
    print_simple
else
    print_hacker
fi
