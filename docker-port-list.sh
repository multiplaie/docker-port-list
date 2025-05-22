#!/bin/bash

# 👨‍💻 Script: docker-port-list — version cinéma hacker
# Affiche les conteneurs Docker actifs regroupés par stack avec un affichage stylé vert néon
# Options:
#   --short : n'affiche que le résumé des ports exposés
#   --json  : affiche en JSON (compatible avec --short)
#   --no-style : style simple (vert basique)

GREEN='\033[0;92m'
BOLD='\033[1m'
RESET='\033[0m'

SHORT=0
JSON=0
STYLE=1

# Parse options
for arg in "$@"; do
    case "$arg" in
        --short) SHORT=1 ;;
        --json) JSON=1 ;;
        --no-style) STYLE=0 ;;
        *) echo "Option inconnue : $arg"; exit 1 ;;
    esac
done

# Récupère tous les containers actifs
containers=$(docker ps -q)

declare -A ports_summary

get_ports_summary() {
    local ports_array=()
    for id in $containers; do
        ports=$(docker port "$id")
        while IFS= read -r line; do
            host_port=$(echo "$line" | awk -F'->' '{print $2}' | awk -F':' '{print $2}')
            if [ -n "$host_port" ]; then
                ports_summary["$host_port"]=1
            fi
        done <<< "$ports"
    done
    for port in "${!ports_summary[@]}"; do
        ports_array+=("$port")
    done
    echo "${ports_array[@]}"
}

print_summary_hacker() {
    local ports=("$@")
    echo -e "${BOLD}${GREEN}╔═ Résumé des ports exposés sur la machine ═══════════════════════════╗${RESET}"
    if [[ ${#ports[@]} -eq 0 ]]; then
        echo -e "${GREEN}║ Aucun port exposé                                                 ║${RESET}"
    else
        for port in "${ports[@]}"; do
            printf "${GREEN}║ Port %-63s ║\n" "$port"
        done | sort -n -k2
    fi
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════════╝${RESET}\n"
}

print_summary_simple() {
    local ports=("$@")
    echo "Résumé des ports exposés sur la machine :"
    if [[ ${#ports[@]} -eq 0 ]]; then
        echo "Aucun port exposé"
    else
        for port in "${ports[@]}"; do
            echo "- Port $port"
        done | sort -n -k2
    fi
    echo
}

print_summary_json() {
    local ports=("$@")
    echo -n '{ "ports": ['
    local first=1
    for port in "${ports[@]}"; do
        if [[ $first -eq 1 ]]; then
            first=0
        else
            echo -n ', '
        fi
        echo -n "\"$port\""
    done
    echo '] }'
}

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

    # Récupération des projets docker-compose (label)
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

    echo -e "${BOLD}${GREEN}→ Pour un résumé des ports exposés, lance : ./docker-port-list.sh --short${RESET}\n"
}

print_simple() {
    echo "Scan des conteneurs Docker actifs :"
    echo "-------------------------------"
    sleep 0.3

    # Récupération des projets docker-compose (label)
    projects=$(for id in $containers; do
        docker inspect -f '{{ index .Config.Labels "com.docker.compose.project" }}' "$id"
    done | sort -u)

    for project in $projects; do
        [ -z "$project" ] && continue
        echo "Project : $project"
        printf "%-28s | %-15s | %-30s\n" "CONTAINER" "IP INTERNE" "PORTS EXPOSES"
        echo "--------------------------------------------------------------------"

        for id in $containers; do
            project_label=$(docker inspect -f '{{ index .Config.Labels "com.docker.compose.project" }}' "$id")
            if [[ "$project_label" == "$project" ]]; then
                name=$(docker inspect -f '{{.Name}}' "$id" | cut -c2-)
                ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$id")
                ports=$(docker port "$id")
                ports_display=$(echo "$ports" | paste -sd "," -)
                printf "%-28s | %-15s | %-30s\n" "$name" "$ip" "${ports_display:-Aucun}"
                while IFS= read -r line; do
                    host_port=$(echo "$line" | awk -F'->' '{print $2}' | awk -F':' '{print $2}')
                    [ -n "$host_port" ] && ports_summary["$host_port"]=1
                done <<< "$ports"
            fi
        done
        echo
    done

    echo "Autres conteneurs (non compose) :"
    printf "%-28s | %-15s | %-30s\n" "CONTAINER" "IP INTERNE" "PORTS EXPOSES"
    echo "--------------------------------------------------------------------"

    for id in $containers; do
        project_label=$(docker inspect -f '{{ index .Config.Labels "com.docker.compose.project" }}' "$id")
        if [[ -z "$project_label" ]]; then
            name=$(docker inspect -f '{{.Name}}' "$id" | cut -c2-)
            ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$id")
            ports=$(docker port "$id")
            ports_display=$(echo "$ports" | paste -sd "," -)
            printf "%-28s | %-15s | %-30s\n" "$name" "$ip" "${ports_display:-Aucun}"
            while IFS= read -r line; do
                host_port=$(echo "$line" | awk -F'->' '{print $2}' | awk -F':' '{print $2}')
                [ -n "$host_port" ] && ports_summary["$host_port"]=1
            done <<< "$ports"
        fi
    done

    echo -e "\n→ Pour un résumé des ports exposés, lance : ./docker-port-list.sh --short\n"
}

print_json() {
    echo '{'
    echo '  "containers": {'

    projects=$(for id in $containers; do
        docker inspect -f '{{ index .Config.Labels "com.docker.compose.project" }}' "$id"
    done | sort -u)

    first_project=1
    for project in $projects; do
        [ -z "$project" ] && continue
        if [[ $first_project -eq 0 ]]; then
            echo ','
        fi
        first_project=0
        echo -n "    \"$project\": ["
        first_cont=1
        for id in $containers; do
            project_label=$(docker inspect -f '{{ index .Config.Labels "com.docker.compose.project" }}' "$id")
            if [[ "$project_label" == "$project" ]]; then
                if [[ $first_cont -eq 0 ]]; then
                    echo ','
                fi
                first_cont=0
                name=$(docker inspect -f '{{.Name}}' "$id" | cut -c2-)
                ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$id")
                ports=$(docker port "$id" | awk '{print $0}' ORS=';')
                ports=${ports%;} # remove last ;
                echo -n "      {\"container\": \"$name\", \"ip\": \"$ip\", \"ports\": \"$ports\"}"
                while IFS= read -r line; do
                    host_port=$(echo "$line" | awk -F'->' '{print $2}' | awk -F':' '{print $2}')
                    [ -n "$host_port" ] && ports_summary["$host_port"]=1
                done <<< "$ports"
            fi
        done
        echo -n "]"
    done

    # Autres conteneurs sans label
    other_containers=()
    for id in $containers; do
        project_label=$(docker inspect -f '{{ index .Config.Labels "com.docker.compose.project" }}' "$id")
        if [[ -z "$project_label" ]]; then
            other_containers+=("$id")
            ports=$(docker port "$id")
            while IFS= read -r line; do
                host_port=$(echo "$line" | awk -F'->' '{print $2}' | awk -F':' '{print $2}')
                [ -n "$host_port" ] && ports_summary["$host_port"]=1
            done <<< "$ports"
        fi
    done

    if [[ ${#other_containers[@]} -gt 0 ]]; then
        if [[ $first_project -eq 0 ]]; then
            echo ','
        fi
        echo '    "other": ['
        first_other=1
        for id in "${other_containers[@]}"; do
            if [[ $first_other -eq 0 ]]; then
                echo ','
            fi
            first_other=0
            name=$(docker inspect -f '{{.Name}}' "$id" | cut -c2-)
            ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$id")
            ports=$(docker port "$id" | awk '{print $0}' ORS=';')
            ports=${ports%;}
            echo -n "      {\"container\": \"$name\", \"ip\": \"$ip\", \"ports\": \"$ports\"}"
        done
        echo
        echo '    ]'
    fi

    echo
    echo '  }'
    echo "  // Astuce : ./docker-port-list.sh --short pour résumé des ports exposés"
    echo '}'
}

print_summary_hacker_wrapper() {
    ports=($(get_ports_summary))
    print_summary_hacker "${ports[@]}"
}

print_summary_simple_wrapper() {
    ports=($(get_ports_summary))
    print_summary_simple "${ports[@]}"
}

print_summary_json_wrapper() {
    ports=($(get_ports_summary))
    print_summary_json "${ports[@]}"
}

# MAIN

if [[ $SHORT -eq 1 ]]; then
    if [[ $JSON -eq 1 ]]; then
        print_summary_json_wrapper
    elif [[ $STYLE -eq 0 ]]; then
        print_summary_simple_wrapper
    else
        print_summary_hacker_wrapper
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
