installer helm :
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
helm version

ajouter repo helm pour prometheus et grafana :
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

Déployer prometheus et grafana :
kubectl create namespace monitoring
helm install prometheus prometheus-community/kube-prometheus-stack --namespace monitoring
helm install grafana grafana/grafana --namespace monitoring
kubectl get pods -n monitoring


Accéder à l'interface grafana :
générer mot de passe user admin :
kubectl get secret --namespace monitoring grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo

Pour pouvoir accéder à grafana et prometheus sur une VM avec GUI, soit faire du port forward :
kubectl port-forward -n monitoring service/grafana 3000:80
kubectl port-forward -n monitoring service/prometheus-kube-prometheus-prometheus 9090:9090
kubectl port-forward -n monitoring service/prometheus-kube-prometheus-alertmanager 9093:9093


Soit utiliser un loadbalancer :
kubectl patch svc prometheus-server -n monitoring -p '{"spec": {"type": "LoadBalancer"}}'
kubectl patch svc grafana -n monitoring -p '{"spec": {"type": "LoadBalancer"}}'
kubectl patch svc prometheus-alertmanager -n monitoring -p '{"spec": {"type": "LoadBalancer"}}'

si on utilise un loadbalancer il faut faire un "minikube tunnel" pour avoir l'external IP

Sur VM server faire avec loadbalancer :
ssh -L 3000:<EXTERNAL IP Grafana>:80 -L 9090:<EXTERNAL IP Promtheus>:80 -L 9093:<EXTERNAL IP Promtheus altermanager>:9093 <USER VM>@<IP VM>

Ensuite dans grafana rechercher Data Sources -> Add Data Source -> choisir Prometheus : configurer l'url de prometheus
Pour créer un dashboard : rechercher "add dashboard" -> rentrer l'id d'un dashboard qu'on souhaite (exemple : 1860)

Créer un fichier "prometheus-alerts-rules.yaml" :
serverFiles:
  alerting_rules.yml:
    groups:
      - name: Instances
        rules:
          - alert: InstanceDown
            expr: up == 0
            for: 1m
            labels:
              severity: critical
            annotations:
              description: "{{ $labels.instance }} of job {{ $labels.job }} has been down for more than 1 minutes."
              summary: "Instance {{ $labels.instance }} down"

Puis exécuter la commande : 
helm upgrade --reuse-values -f prometheus-alerts-rules.yaml prometheus prometheus-community/prometheus

Ensuite pour configurer alertmanager et l'envoie de mail, créer un fichier "alertmanager-config.yaml" :
alertmanager:
  config:
    global:
      smtp_smarthost: 'smtp.gmail.com:587'
      smtp_from: 'ntmlff.send.notification@gmail.com'
      smtp_auth_username: 'ntmlff.send.notification@gmail.com'
      smtp_auth_password: 'qpxx mmjy vizb zeky'
      smtp_require_tls: true
    route:
      receiver: 'email-alert'
    receivers:
      - name: 'email-alert'
        email_configs:
          - to: 'jules.davoustperso@gmail.com'
            send_resolved: true

Exécuter cette commande :
helm upgrade --reuse-values -f alertmanager-config.yaml prometheus prometheus-community/prometheus

Il faudra reconfigurer soit le port forwarding soit le loadbalancer.

Pour tester la configuration supprimez "kubectl delete deployment.apps/prometheus-prometheus-pushgateway"



