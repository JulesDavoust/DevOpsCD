read -p "Do you want to start minikube ? (y/n) " startMinikube
if [ $startMinikube == "y" ]
then
    minikube start
fi

cd app/scripts
ls

read -p "Do you want to launch docker-compose ? (y/n) " startDockerCompose
if [ $startDockerCompose == "y" ]
then
    bash docker.sh
fi

read -p "Do you want to launch kubernetes files ? (y/n) " startKubernetes
if [ $startKubernetes == "y" ]
then
    bash kubernetes.sh
fi

exit 0