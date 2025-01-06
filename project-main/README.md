# ST2DCE-PRJ-2324S9-SE1

Durant ce projet nous avons dû mettre en place un système de déploiement continue en utilisant jenkins, kubernetes et docker.


Notre objectif a été de mettre en place des tests sur notre application en go, vérifiant si l'endpoint [/whoami]() renvoie la valeur attendue. Si la valeur est correct alors le déploiement de l'application via kubernetes s'effectue. Finalement, nous avons dû mettre en place un système de monitoring pour surveiller notre déploiement.


Nous allons vous présenter de manière détaillée les actions effectuées dans les parties suivantes :

**1. [Diagram of our solution](README-diagram.md)**\
**2. [Build and deploy our application](README-jenkins.md)**\
**3. [Monitoring and logs management](README-monitoring.md)**