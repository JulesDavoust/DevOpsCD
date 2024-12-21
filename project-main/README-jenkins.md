install :
-> Git Plugin (pas forcément obligé)
-> Docker Pipeline Plugin
-> Credentials Plugin (pas forcément obligé)

Config :
Tableau de bord > Administrer Jenkins > Identifiants

- Setup un credential en mode "nom utilisateur et mdp" pour son GitHub.
- Générer un access token de son GitHub : cocher "repo", "read:org" et "user:email"

- Setup un credential en mode "nom utilisateur et mdp" pour son DockerHub.
- Générer un access token de son DockerHub

- Setup un credential en mode "SSH Username with private key" pour autoriser la connexion à jenkins sur notre VM, pour la transformer en slave.
- Copier coller la clé privée générée

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
- Sélectionnez 'Pipeline script from SCM'
- SCM : Git
- Repository URL : URL du repo
- Credentials : sélectionnez le credential que vous avez créé pour GitHub
- Branches to build : main
- Script Path : path/to/Jenkinsfile
- Enregistrez
- Build Now

