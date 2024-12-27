# Build and deploy our application

Dans cette partie nous allons voir comment nous avons utilisé kubernetes, docker et jenkins pour créer build et un déploiement continue.

Nous allons dans un premier temps voir comment nous avons mis en place le test de notre application en go, pour que l'endpoint [/whoami]() retourne la valeur que l'on souhaite.

## Test de l'application en GO

Vous pouvez retrouver le code de notre application dans le fichier [main.go](webapi/main.go) et le test de l'API dans le fichier [main_test.go](webapi/main_test.go).

La première étape a été de nous acclimater avec le langage de programmation go et de comprendre le code déjà présent pour ensuite pouvoir le modifier pour rajouter nos noms, prénoms et groupe de classe à l'endpoint [/whoami]().

### Modification des types

Nous avons été à modifier le fichier [main.go](webapi/main.go), en rajoutant des types et en modifiant la fonction `whoAmI()` et la fonction `request1()`.

Le seul type qu'il y avait auparavant était le suivant :\
![alt text](/images_README/image-bis.png)

Nous avons été amené à en rajouter deux autres et à supprimer l'ancien :\
![alt text](/images_README/image.png)


Nous avons supprimé l'ancien type car il ne correspondait plus à notre besoin, en rajoutant notre classe et nos prénoms et noms nous devions créer un type `ClassInfo` qui allait stocker notre classe et nos informations. Pour stocker nos informations personnelles nous avons dû créer un type `Student` permettant de stocker nos prénoms et noms.

### Modification des fonctions

Pour finir avec ce fichier, nous avons dû modifier deux fonctions comme dit précédemment, la fonction `whoAmI()` et `request1()`.


L'ancienne fonction whoAmI ressemblait à ça :\
![alt text](/images_README/image-1.png)

Cependant, en modifiant les types nous avons donc aussi dû modifier la fonction whoAmI :\
![alt text](/images_README/image-2.png)

Les prinpaux changement se passent surtout au niveau de la structure de la variable who, comme on peut le constater, où nous avons dû jouer avec les différents types créés.


Finalement, nous avons fait un dernier petit changement au niveau de la fonction request1() où nous avons modifier le port de l'API en le passant de 8080 à 9090, étant donné que le port 8080 est déjà utilisé par jenkins.\

![alt text](/images_README/image-3.png) ![alt text](/images_README/image-4.png)


## Configuration de Kubernetes et docker

## Configuration de jenkins

La partie finale du build and deploy a été la configuration de jenkins. Ce dernier va permettre d'exécuter une pipeline nous permettant d'exécuter des actions tels que le build des images, le déploiement de l'application dans l'environnement de développement pour la tester, puis si le test est passé de la déployer en production.

Avant de créer la pipeline il nous a fallu, comme je l'ai dit précédemment, configurer jenkins, pour qu'il puisse se connecter à notre VM pour l'utiliser en tant que slave, pour qu'il puisse accéder à notre repository github, à notre dockerhub (pour push les images). 

Nous avons d'abord installé l'image de jenkins sur notre VM :
```sh
sudo docker run -d -p 8080:8080 -p 50000:50000 --name jenkins --restart unless-stopped jenkins/Jenkins:lts-jdk17
```

Ensuite nous avons récupéré nos identifiants jenkins pour nous y connecter:
```sh
sudo docker exec Jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

Nous allons maintenant voir plus dans le détail ce que nous avons fait pour configuré jenkins.

### Installation des plugins

La première chose que nous avons fait c'est installer les plugins suivant (parfois il y en a pas besoin et ils sont déjà installés) :

- Git Plugin
- Docker Pipeline
- Credentials Plugin

Pour cela, on s'est rendu dans cette partie :\
[Tableau de bord > Administrer jenkins > Plugins](http://localhost:8080/manage/pluginManager/available)

Puis dans plugins disponible et ensuite on a cherché les plugins ci-dessus.

### Configuration des credentials

Ensuite, ce que nous avons fait c'est : configurer les credentials dont nous allions avoir besoin pour mener à bien ce projet. C'est-à-dire les credentials de notre repository GitHub, celui de notre DockerHub et de notre VM.

#### GitHub credentials

Pour configurer le credential de notre compte GitHub il nous a fallu générer un token d'accès avec des droits bien précis. Pour cela nous nous sommes rendus dans :\
[settings > Developer settings > Personal access tokens > Tokens (classic)](https://github.com/settings/tokens)

Ensuite, nous avons généré un nouveau token classic avec les permissions suivantes :\
![alt text](/images_README/image-5.png)
![alt text](/images_README/image-6.png)
![alt text](/images_README/image-7.png)

On a ensuite notre token qui est généré :\
![alt text](/images_README/image-8.png)

On le récupére et on va venir créer un credential dans nos identifiants globaux:\
[Tableau de bord > Administrer jenkins > Identifiants > System > Identifiants globaux (illimité)](http://localhost:8080/manage/credentials/store/system/domain/_/)

On va ajouter un nouveau credentials en choisissant "Nom d'utilisateur et mot de passe":\
![alt text](/images_README/image-9.png)

Nous rentrons notre nom d'utilisateur GitHub et notre token généré précdemment :\
![alt text](/images_README/image-10.png)

Nous cliquons sur "Create" et c'est bon notre credentials GitHub est configuré !\
![alt text](/images_README/image-13.png)

#### DockerHub credentials

Pour configurer le credential de notre compte DockerHub il nous a aussi fallu générer un token d'accès. Pour cela nous nous sommes rendus dans :\
[Account settings > Personal access tokens > Generate new token](https://app.docker.com/settings/personal-access-tokens/create)

Puis nous avons configuré notre token de cette façon :\
![alt text](/images_README/image-11.png)

Notre token nous est alors donné et on peut constater qu'il a bien été créé :\
![alt text](/images_README/image-12.png)

Pour finir nous nous rendons sur jenkins pour configurer notre credentials DockerHub (même endroit que pour celui de GitHub) :
[Tableau de bord > Administrer jenkins > Identifiants > System > Identifiants globaux (illimité)](http://localhost:8080/manage/credentials/store/system/domain/_/)

Globalement c'est la même démarche que pour celui de GitHub, simplement nous allons mettre votre nom d'utilisateur DockerHub et le token que nous venons de générer :\
![alt text](/images_README/image-14.png)

Nous choisissons "Create" et c'est bon notre credentials DockerHub est configuré !\
![alt text](/images_README/image-15.png)

#### VM credentials

Pourquoi devons-nous configurer un credentials pour notre VM ? Tout simplement car nous allons autoriser jenkins à utiliser notre VM comme esclave, c'est-à-dire qu'elle va être utilisé par jenkins pour qu'il puisse exécuter les actions de la pipeline.

Pour cela nous allons devoir générer une clé RSA sur notre VM. Avant cela, nous allons créer un dossier "jenkins" :\
![alt text](/images_README/image-17.png)

Nous allons maintenant autoriser l'utilisateur jenkins à accéder à ce dossier, pour cela il va falloir créer l'utilisateur et l'ajouter en exécutant ces commandes :
```sh
sudo adduser jenkins
chown -R jenkins:jenkins /home/jenkins
chmod 700 /home/jenkins
```
![alt text](/images_README/image-18.png)


Ensuite, dans le dossier "jenkins" nous allons créer un dossier ".ssh" :\
![alt text](/images_README/image-16.png)

C'est dans ce dossier que nous allons déplacer notre paire de clé RSA après sa génération :
```sh
ssh-keygen -t rsa -b 2048 -C "jenkins-agent"
```
![alt text](/images_README/image-19.png)\
On peut voir que nos clés se sont bien créées.

Nous allons rajouter notre clé publique dans un fichier "authorized_keys" via cette commande :
```sh
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
```
![alt text](/images_README/image-42.png)

Nous devons faire ça pour indiquer à la VM que nous autorisons les personnes possédant la clé en question à se connecter.

Pour finir nous allons déplacer les clés que nous avons généré dans le dossier .ssh du dossier "jenkins" :
```sh
cp ~/.ssh/id_rsa /home/jenkins/.ssh/
cp ~/.ssh/id_rsa.pub /home/jenkins/.ssh/
cp ~/.ssh/authorized_keys /home/jenkins/.ssh/
```

Cela va permettre à jenkins de se connecter à notre VM.

On va maintenant devoir modifier les autorisations au niveau des fichiers et des dossier en exécutant ces commandes :
```sh
chmod 600 /home/jenkins/.ssh/authorized_keys
chmod 600 /home/jenkins/.ssh/id_rsa
chmod 644 /home/jenkins/.ssh/id_rsa.pub
chmod 700 /home/jenkins/.ssh
chown -R jenkins:jenkins /home/jenkins/.ssh
```
![alt text](/images_README/image-21.png)\
Cela va nous permettre de bien configurer nos clés et d'éviter les problèmes de connexions entre jenkins et notre VM.

Enfin, pour finir la configuration du credential de notre VM nous allons devoir nous rendre dans ce fichier :
```sh
nano /etc/ssh/sshd_config
```
Pour y modifier cette ligne :\
![alt text](/images_README/image-22.png)\
En remplaçant "no" par "yes".

Et cette ligne :\
![alt text](/images_README/image-23.png)\
En remplaçant "yes" par "no".
Et nous allons maintenant redémarrer notre système ssh en exécutant cette commande :
```sh
sudo systemctl restart ssh
```


Nous sauvegardons, et pour finir nous allons copier notre clé privée RSA :
```sh
cat /home/jenkins/.ssh/id_rsa
```
![alt text](/images_README/image-24.png)

Nous allons nous rendre au même endroit que précédemment pour configurer des credentials sur jenkins :\
[Tableau de bord > Administrer jenkins > Identifiants > System > Identifiants globaux (illimité)](http://localhost:8080/manage/credentials/store/system/domain/_/)

Sauf que cette fois-ci nous allons choisir "SSH Username withe private key":\
![alt text](/images_README/image-25.png)

Nous allons ensuite rentrer un ID, une description et un username :\
![alt text](/images_README/image-34.png)

Dans "Username" il faut bien mettre le nom du groupe que nous avons ajouté juste avant, pour nous c'est "jenkins", sinon ça ne marchera pas.

Finalement, nous allons choisir "Enter directly" pour "Private key" et nous allons y coller notre clé privée :\
![alt text](/images_README/image-27.png)

En cliquant sur "Create" nous pourrons constater que notre credentials a bien été configuré !\
![alt text](/images_README/image-28.png)


Tous nos credentials ont bien été créé :\
![alt text](/images_README/image-29.png)

Nous allons maintenant pouvoir passer à la création de notre agent jenkins.

### Création d'un agent jenkins

L'agent jenkins va utiliser notre VM pour exécuter les actions de notre pipeline.

Donc, avant de s'attarder à la partie directement sur jenkins nous avons dû nous rendre sur notre VM pour installer l'openjdk-17 car c'est celui qu'utilise notre jenkins (cela va lui permettre d'exécuter les actions qu'il doit réaliser) :
```sh
sudo apt-get update
sudo apt-get install -y openjdk-17-jdk -y
``` 

Ensuite, pour créer notre agent nous avons dû nous rendre dans cette partie :\
[Tableau de bord > Administrer jenkins > Nœuds > New Node](http://localhost:8080/manage/computer/new)

La première étape est de rentrer un nom pour notre node :
![alt text](/images_README/image-30.png)
On clique ensuite sur "Permanent Agent" puis "Create".

Nous allons devoir maintenant configurer quelques paramétres importants de notre agent :\
![alt text](/images_README/image-31.png)
Nous allons venir rentrer le chemin du dossier "jenkins" que nous avons créé précédemment.

Ensuite, dans "Méthode de lancement" nous allons choisir l'option "Launch agent via SSH":\
![alt text](/images_README/image-32.png)

Pour finir, nous allons avoir plusieurs options à configurer :\
![alt text](/images_README/image-33.png)
Dans "Host" nous avons dû rentrer l'IP de la VM, cependant, tout dépend de la configuration de la VM à la base (si nous avons une interface graphique ou non on pourra mettre "localhost").

Ensuite dans "Credentials" nous choisissons le credentials "jenkins" que nous avons créé auparavant, celui qui va nous permettre d'établir la connexion entre jenkins et notre VM. Et pour finir on choisit "Non verifying Verification Startegy" pour "Host Key Verification Startegy" pour nous éviter les problèmes de connexion, de plus comme nous ne sommes pas dans un contexte d'entreprise ce n'est pas critique de choisir cette option. Et nous cliquons sur "Enregistrer".
![alt text](/images_README/image-35.png)

Comme on peut le voir l'agent s'est correctement lancé.

### Création de la pipeline

Suite à la création de l'agent nous nous sommes attaqués à la configuration de la pipeline.

#### Configuration du fichier jenkins.build
Dans un premier temps nous avons créer un fichier de [build jenkins](Jenkins.build), ce fichier permet à indiquer à jenkins les actions à exécuter lors de la pipeline.

Notre fichier se découpe en 6 parties, en 6 "stage". Juste avant d'écrire les stages nous avons préciser à notre pipeline quel agent nous voulions utiliser : "vm-agent".

**1er stage :**
![alt text](/images_README/image-36.png)
Ce stage va nous permettre de cloner le code source depuis notre dépôt GitHub. Il spécifie la branche main, utilise les identifiants github-credential pour s'authentifier, et récupère le dépôt situé à l'URL fournie. Cela permet de donner au pipeline les fichiers nécessaires pour exécuter les étapes suivantes.

**2ème stage :**
![alt text](/images_README/image-37.png)
Via ce stage nous construisons une image Docker pour le service webapi. Jenkins va se placer dans le répertoire project-main/webapi et va utiliser le fichier Dockerfile présent dans ce répertoire pour créer l'image nommée thedevgods/devopsproject:1. Cette étape va nous permettre de préparer l'image containerisée pour être utilisée dans le futur.

**3ème stage :**
![alt text](/images_README/image-38.png)
Ce stage pousse l'image Docker créée précédemment vers un registre Docker distant. Il utilise les credentials docker-credential pour s'authentifier auprès du registre. Une fois l'image poussée, elle devient disponible pour d'autres environnements, tels que des clusters Kubernetes (ce que l'on va utiliser dans les futurs stages), pour des déploiements futurs.

**4ème stage :**
![alt text](/images_README/image-39.png)
Ensuite, ce stage déploie l'application dans l'environnement de développement (development) sur Kubernetes. Il applique d'abord le fichier [namespace-development.yml](/project-main/kubernetes/namespace-development.yml) pour configurer le namespace, puis utilise le fichier [webapi-deployment.yml](/project-main/kubernetes/webapi-deployment.yml) pour déployer l'application. Enfin, la commande `kubectl get pods -n development` affiche l'état des pods déployés dans le namespace development. Cela vérifie que le déploiement s'est effectué correctement.

**5ème stage :**
![alt text](/images_README/image-40.png)
Celui-ci va vérifier que l'application déployée dans l'environnement de développement fonctionne correctement. Il effectue une requête curl vers l'endpoint [/whoami](http://localhost:9090/whoami) du service déployé et compare la réponse obtenue avec une réponse attendue définie dans le script. Si la réponse correspond à l'attendu, le test réussit avec un message de validation ; sinon, il déclenche une erreur et affiche la réponse réelle pour permettre le diagnostic.

**6ème stage :**
![alt text](/images_README/image-41.png)
Finalenement, ce stage déploie l'application dans l'environnement de production si les étapes précédentes se sont terminées avec succès. Il applique le fichier [namespace-production.yml](/project-main/kubernetes/namespace-production.yml) pour configurer le namespace de production, puis déploie l'application en utilisant le fichier [webapi-deployment.yml](/project-main/kubernetes/webapi-deployment.yml) pour la production. Enfin, la commande `kubectl get pods -n production` affiche l'état des pods déployés dans le namespace de production pour valider que tout fonctionne correctement.

#### Configuration du pipeline

Une fois cela fait nous avons commencé à paramétré le pipeline sur jenkins, pour cela nous nous sommes rendu à cette section :\
[Tableau de bord > Tous > Nouveau Item ](http://localhost:8080/view/all/newJob)\
![alt text](/images_README/image-44.png)
Nous rentrons un nom pour notre pipeline, choisissons "Pipeline" et cliquons sur "OK".

Nous sommes ensuite allés directement dans la partie "Pipeline" pour y choisir "Pipeline script from SCM" :\
![alt text](/images_README/image-45.png)

Ensuite pour le type de "SCM" nous avons choisi "Git" :\
![alt text](/images_README/image-46.png)
Nous avons renseigné l'URL de notre repository GitHub qui posséde le code de notre application avec tous les fichiers de configurations. Et nous avons sélectionné les credentials que nous avons créé pour notre repository GitHub, permettant ainsi à jenkins de récupérer le code source se trouvant dans un repository privé (c'est pour cela que nous avons besoin de renseigner nos credentials).

Pour finir nous indiquons la branche que nous souhaitons cibler dans notre repository, en l'occurrence, nous, nous avons mis "main" :\
![alt text](/images_README/image-48.png)
Et nous indiquons le chemin pour pouvoir accéder à notre fichier [jenkins.build](Jenkins.build)

On clique sur "Sauvegarder" et ensuite nous avons lancé un build pour tester si tout fonctionnait correctement.
![alt text](/images_README/image-49.png)



install :
-> Git Plugin (pas forcément obligé)
-> Docker Pipeline Plugin
-> Credentials Plugin (pas forcément obligé)

Config :
Tableau de bord > Administrer jenkins > Identifiants

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
- Script Path : path/to/jenkinsfile
- Enregistrez
- Build Now