SSHD_CONFIG="/etc/ssh/sshd_config"
BACKUP_CONFIG="/etc/ssh/sshd_config.bak"

wget https://go.dev/dl/go1.23.4.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.23.4.linux-amd64.tar.gz

echo "export PATH=\$PATH:/usr/local/go/bin" >> ~/.bashrc
source ~/.bashrc
go version


container_status=$(docker inspect -f '{{.State.Status}}' jenkins 2>/dev/null)

if [ "$container_status" == "running" ]; then
    echo "Jenkins container is already running."
elif [ "$container_status" == "exited" ]; then
    sudo docker start jenkins
else
    echo "Jenkins container is not created. Starting a new container..."
    sudo docker run -d -p 8080:8080 -p 50000:50000 --name jenkins --restart unless-stopped jenkins/jenkins:lts-jdk17
    sudo docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword >>/tmp/jenkins_password
    sudo echo "Jenkins initial password is saved in /tmp/jenkins_password"
    sudo cat /tmp/jenkins_password
fi

if [ ! -d "/home/jenkins" ]; then
    echo "Jenkins home directory does not exist. Creating it..."
    sudo mkdir -p /home/jenkins
    chown -R jenkins:jenkins /home/jenkins
    chmod 755 /home/jenkins
else
    echo "Jenkins home directory already exists."
fi

if [ ! -d "/home/jenkins/.ssh" ] || [ -z "$(ls -A /home/jenkins/.ssh)" ]; then
    echo "Jenkins .ssh directory does not exist or is empty. Creating it and generating keypair..."
    sudo mkdir -p /home/jenkins/.ssh
    ssh-keygen -t rsa -b 2048 -f /home/jenkins/.ssh/id_rsa -C "jenkins-agent" -N ""
    cat /home/jenkins/.ssh/id_rsa.pub > /home/jenkins/.ssh/authorized_keys
    chmod 600 /home/jenkins/.ssh/authorized_keys
    chmod 600 /home/jenkins/.ssh/id_rsa
    chmod 644 /home/jenkins/.ssh/id_rsa.pub
    chmod 700 /home/jenkins/.ssh
    chown -R jenkins:jenkins ~/.ssh
else
    echo "Jenkins .ssh directory already exists and is not empty."
fi

if ! java -version 2>&1 | grep -q "openjdk 17"; then
    echo "openjdk-17-jdk is not installed. Installing it..."
    sudo apt-get update
    sudo apt-get install -y openjdk-17-jdk -y
else
    echo "openjdk-17-jdk is already installed."
fi

java -version

echo "Creating a backup of the SSH configuration..."
sudo cp "$SSHD_CONFIG" "$BACKUP_CONFIG"

echo "Updating SSH configuration..."
sudo sed -i 's/^#*PubkeyAuthentication.*/PubkeyAuthentication yes/' "$SSHD_CONFIG"
sudo sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication no/' "$SSHD_CONFIG"

echo "Restarting SSH service..."
sudo systemctl restart ssh

echo "=============================================
Si ce n'est pas déjà fait il vous reste :
Install plugin :

-> Git Plugin (pas forcément obligé)
-> Docker Pipeline Plugin
-> Credentials Plugin (pas forcément obligé)

- restart jenkins (docker restart jenkins)

Config credentials Jenkins :
Tableau de bord > Administrer Jenkins > Identifiants

- Setup un credential en mode 'nom utilisateur et mdp' pour son GitHub.
- Générer un access token de son GitHub : cocher 'repo', 'read:org' et 'user:email'

- Setup un credential en mode 'nom utilisateur et mdp' pour son DockerHub.
- Générer un access token de son DockerHub

- Setup un credential en mode 'SSH Username with private key' pour autoriser la connexion à jenkins sur notre VM, pour la transformer en slave.
- Copiez collez la clé privée générée

Config agent jenkins :
Tableau de bord > Nœuds > New node

- Nommez le node
- Sélectionnez 'Permanent Agent'
- Ajoutez les labels 'docker' et 'jenkins'
- Mettez comme répertoire de travail '/home/jenkins'
- Méthode de lanceur d'agent : 'Launch agent via SSH'
- Host : adresse IP de la VM
- Credentials : sélectionnez le credential que vous avez créé pour la connexion SSH
- Host Key Verification Strategy : 'Non verifying Verification Strategy'

Créer la pipeline :
Tableau de bord > Nouvel élément > Pipeline
- Nommez la pipeline
- Sélectionnez 'Pipeline script from SCM'"
