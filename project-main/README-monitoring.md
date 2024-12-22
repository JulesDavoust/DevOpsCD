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

Créons une autre règle permettant de signaler les pods qui sont en "pending", "unknown" ou "failed" :
nano prometheus-alerts-rules.yaml :
serverFiles:
  alerting_rules.yml:
    groups:
      - name: KubernetesPodHealth
        rules:
          - alert: KubernetesPodNotHealthy
            expr: sum by (namespace, pod) (kube_pod_status_phase{phase=~"Pending|Unknown|Failed"}) > 0
            for: 15m
            labels:
              severity: critical
            annotations:
              summary: Kubernetes Pod not healthy (instance {{ $labels.instance }})
              description: "Pod {{ $labels.namespace }}/{{ $labels.pod }} has been in a non-running state for longer than 15 minutes.\n  VALUE = {{ $value }}\n  LABELS>

Vu que nous créons une nouvelle règle il va falloir l'injecter :
Exécuter cette commande :
helm upgrade --reuse-values -f alertmanager-config.yaml prometheus prometheus-community/prometheus

Il faudra reconfigurer soit le port forwarding soit le loadbalancer.

Nous allons maintenant créer deux fichiers de tests, "pending-test-pod.yaml" et "failed-test-pod.yaml" :
apiVersion: v1
kind: Pod
metadata:
  name: pending-test-pod
  namespace: monitoring
spec:
  containers:
  - name: nginx
    image: nginx:latest
    resources:
      requests:
        memory: 1Ti
        cpu: 1

apiVersion: v1
kind: Pod
metadata:
  name: failed-test-pod
  namespace: monitoring
spec:
  containers:
  - name: busybox
    image: busybox:latest
    command: ["sh", "-c", "exit 1"]

appliqué les fichiers yml avec "kubectl apply -f"

Vous pouvez aller sur prometheus vous aurez dans l'onglet "alert" la notification vous prévenant qu'un pod est en pending, au bout de 15min (quand prometheus aura passer l'alert en "firing") un mail vous sera envoyé via alertmanager

Setup loki :
Créer un fichier values.yml :
loki:
  commonConfig:
    replication_factor: 1
  schemaConfig:
    configs:
      - from: "2024-04-01"
        store: tsdb
        object_store: s3
        schema: v13
        index:
          prefix: loki_index_
          period: 24h
  pattern_ingester:
      enabled: true
  limits_config:
    allow_structured_metadata: true
    volume_enabled: true
    retention_period: 672h # 28 days retention
  compactor:
    retention_enabled: true 
    delete_request_store: s3
  ruler:
    enable_api: true

minio:
  enabled: true
      
deploymentMode: SingleBinary

singleBinary:
  replicas: 1

# Zero out replica counts of other deployment modes
backend:
  replicas: 0
read:
  replicas: 0
write:
  replicas: 0

ingester:
  replicas: 0
querier:
  replicas: 0
queryFrontend:
  replicas: 0
queryScheduler:
  replicas: 0
distributor:
  replicas: 0
compactor:
  replicas: 0
indexGateway:
  replicas: 0
bloomCompactor:
  replicas: 0
bloomGateway:
  replicas: 0

et exécutez cette commande :
helm install loki grafana/loki -f values.yaml -n monitoring

Ensuite, soit vous ouvrez en portforward :
kubectl port-forward --namespace monitoring svc/loki-gateway 3100:80

Soit vous le convertissez en loadbalancer :
kubectl patch svc loki -n monitoring -p '{"spec": {"type": "LoadBalancer"}}'
rajoutez y la connexion en ssh :
ssh -L 3000:<EXTERNAL IP Grafana>:80 -L 9090:<EXTERNAL IP Promtheus>:80 -L 9093:<EXTERNAL IP Promtheus altermanager>:9093 -L 3100:<EXTERNAL IP Loki>:3100 <USER VM>@<IP VM>

Ensuite Dans grafana il faut ajouter une data source en choisissant loki, pour l'url il faut mettre soit http://<EXTERNAL IP Loki>:3100 (si vous avez un loadbalancer) si non vous pouvez mettre http://localhost:3100

Ensuite dans le header "X-Scope-OrgID" et pour value il faut mettre "foo"

Pour tester rapidement loki, vous pouvez exécuter cette commande dans le terminal :
curl -H "Content-Type: application/json" \
     -H "X-Scope-OrgId: foo" \
     -XPOST "http://<IP Loki>:3100/loki/api/v1/push" \
     --data-raw '{"streams": [{"stream": {"job": "test"}, "values": [["'$(date +%s)000000000'", "fizzbuzz"]]}]}'

Puis cette commande :
curl -G "http://<IP Loki>:3100/loki/api/v1/query_range" \
     --data-urlencode 'query={job="test"}' \
     -H "X-Scope-OrgId: foo" | jq .data.result

Si Loki fonctionne correctement, cette commande retournera une réponse contenant vos logs (fizzbuzz).

Ensuite dans grafan directement, vous pouvez aller dans "explore" choisir "Loki" et dans select label prenez "job" puis "test", exécutez la querry, vous devriez voir votre log fizzbuzz push précédemment.


Pour ensuite pouvoir récolter les logs de différents namespace il faut installer promtail :

helm install promtail grafana/promtail -n monitoring \
  --set config.clients[0].url="http://<IP Loki>:3100/loki/api/v1/push" \
  --set config.clients[0].tenant_id="foo" \
  --set config.positions.filename="/tmp/positions.yaml" \
  --set config.scrape_configs[0].job_name="kubernetes-pods" \
  --set config.scrape_configs[0].kubernetes_sd_configs[0].role="pod" \
  --set config.scrape_configs[0].relabel_configs[0].source_labels="{__meta_kubernetes_namespace}" \
  --set config.scrape_configs[0].relabel_configs[0].target_label="namespace" \
  --set config.scrape_configs[0].relabel_configs[1].source_labels="{__meta_kubernetes_pod_name}" \
  --set config.scrape_configs[0].relabel_configs[1].target_label="pod" \
  --set config.scrape_configs[0].relabel_configs[2].source_labels="{__meta_kubernetes_container_name}" \
  --set config.scrape_configs[0].relabel_configs[2].target_label="container"

Pour ensuite tester promtail il va falloir qu'on crée le namespace production si ce n'est pas déjà fait et on va créer un fichier "error-logger.yaml" dans le namespace production :
apiVersion: v1
kind: Pod
metadata:
  name: error-logger
  namespace: production
spec:
  containers:
  - name: error-logger
    image: busybox
    command: ["sh", "-c", "while true; do echo 'error: something went wrong'; sleep 5; done"]

Ensuite il faut retourner sur grafana dans "Explore" choisir de nouveau loki et cette fois-ci vous devriez avoir plusieurs labels, différentes valeurs en fonctions des labels et plusieurs opérations possibles. Pour tester vous pouvez simplement dans un premier temps choisir dans "Select label": "namespace" et dans "Select value": "production". Exécutez la query, vous devriez voir des logs apparaître. Ou vous pouvez aussi sélectionner l'onglet "code" pour la query et y mettre la commande suivante : {namespace="production"} |= "error"
Cela va lister tous les logs avec "error"



