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

Config agent :
Tableau de bord > Nœuds > New node

