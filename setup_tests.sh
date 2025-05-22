#!/bin/bash

# Vérifie si shunit2 est déjà cloné
if [ ! -d "./shunit2" ]; then
    echo "Clonage de shunit2 depuis GitHub..."
    git clone https://github.com/kward/shunit2.git
else
    echo "shunit2 déjà présent."
fi

# Crée le fichier test_docker_port_list.sh avec du contenu de base
cat > test_docker_port_list.sh << 'EOF'
#!/bin/bash

SCRIPT="./docker-port-list.sh"

testAffichageComplet() {
    output=$($SCRIPT)
    assertNotNull "$output"
    assertContains "$output" "→ Pour un résumé des ports exposés"
}

testResumeShort() {
    output=$($SCRIPT --short)
    assertContains "$output" "Résumé des ports exposés"
}

testJson() {
    output=$($SCRIPT --json)
    assertContains "$output" "\"containers\""
}

testResumeJson() {
    output=$($SCRIPT --json --short)
    assertContains "$output" "\"ports\""
}

testOptionInconnue() {
    output=$($SCRIPT --foo 2>&1)
    assertContains "$output" "Option inconnue"
}

. ./shunit2/shunit2
EOF

chmod +x test_docker_port_list.sh

echo
echo "-----------------------------"
echo "Installation terminée."
echo "Pour lancer les tests, tape :"
echo "    ./test_docker_port_list.sh"
echo "-----------------------------"
