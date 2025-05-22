#!/bin/bash

# 👨‍💻 Script: docker-port-list — version cinéma hacker
# Affiche les conteneurs Docker actifs regroupés par stack avec un affichage stylé vert néon

# Couleurs et effets
GREEN='\033[0;92m'
BOLD='\033[1m'
RESET='\033[0m'

# Anim' hacker
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

# Liste des conteneurs
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
echo -e "\n${BOLD}${GREEN}╔═ Résumé des ports exposés sur la machine ═══════════════════════════╗${RESET}"
if [[ ${#ports_summary[@]} -eq 0 ]]; then
    echo -e "${GREEN}║ Aucun port exposé                                                 ║"
else
    for port in "${!ports_summary[@]}"; do
        printf "${GREEN}║ Port %-63s ║\n" "$port"
    done | sort -n -k2
fi
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════════╝${RESET}\n"
