cd $(dirname "$0")
eval $(minikube -p minikube docker-env)
docker build -t devops-prj-webapp .
