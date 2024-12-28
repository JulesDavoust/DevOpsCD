# Monitoring and logs management

In this section, we will set up a monitoring system using Prometheus, Grafana, and Loki. This will enable us to monitor our pods, deployments, and Minikube services, identify issues, and address them quickly and effectively.

First, we will cover the installation of Prometheus and Grafana, focusing on their configuration as well as the setup of Alert Manager. Finally, we will conclude with the installation and configuration of Loki.

## Prometheus et Grafana

### Getting Started

First, we needed to install Helm to use Prometheus and Grafana. We did this by running the following command:
```sh
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
helm version
```

The `helm version` command allows us to verify that Helm was installed correctly:\
![alt text](/images_README/monitoring/image.png)

After installing Helm, we added Prometheus and Grafana to our Helm repository using these commands:
```sh
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
```

The `helm repo update` command ensures that our Helm repository is updated and that Prometheus and Grafana are recognized.

This concludes the [Premiers pas](#premiers-pas) section. We can now move on to the [Configuration](#configuration) of Grafana and Prometheus.

### Configuration

In this section, we will cover:
- [How to Deploy Prometheus and Grafana](#comment-déployer-prometheus-et-grafana)
- [Accessing the Grafana and Prometheus Interfaces](#accéder-à-linterface-grafana-et-prometheus)
- [Configuring Grafana with Prometheus](#configurer-grafana-avec-prometheus)

#### How to Deploy Prometheus and Grafana

To deploy Prometheus and Grafana, we first created a dedicated *namespace* to centralize all monitoring resources:
```sh
kubectl create namespace monitoring
```
This command creates the "monitoring" namespace, ensuring that all monitoring resources are organized in a specific namespace:\
![alt text](/images_README/monitoring/image-1.png)

After creating the namespace, we installed Prometheus and Grafana within it using the Helm repository we configured earlier:
```sh
helm install prometheus prometheus-community/kube-prometheus-stack --namespace monitoring
helm install grafana grafana/grafana --namespace monitoring
```

To verify the installation, we ran the following command:
```sh
kubectl get pods -n monitoring
```
![alt text](/images_README/monitoring/image-3.png)
![alt text](/images_README/monitoring/image-2.png)

As shown above, the installation was successful. We can now proceed to access Grafana and Prometheus.

#### Accessing the Grafana and Prometheus Interfaces

Before accessing the Grafana interface, we needed to generate and retrieve the password for the Grafana *admin* user:
```sh
kubectl get secret --namespace monitoring grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
```
This command generates a password:
![alt text](/images_README/monitoring/image-4.png)
We will need this password later when logging in to Grafana.

There are multiple ways to access Grafana and Prometheus, depending on whether you have a "Graphic User Interface" (GUI) or not.\
If you have a GUI, the process is simple:\
You just need to set up port forwarding by executing these commands:
```sh
kubectl port-forward -n monitoring service/grafana 3000:80
kubectl port-forward -n monitoring service/prometheus-kube-prometheus-prometheus 9090:9090
kubectl port-forward -n monitoring service/prometheus-kube-prometheus-alertmanager 9093:9093
```

After that, you can access the services by navigating to the following URLs:
- http://localhost:3000 for Grafana
- http://localhost:9090 for Prometheus
- http://localhost:9093 for Alert Manager

Alternatively, you can reconfigure the Grafana, Prometheus, and Alert Manager services to use a LoadBalancer instead of ClusterIP. However, this is only necessary if you're working on a command-line VM without a GUI. To make this change, execute the following commands:

```sh
kubectl patch svc prometheus-server -n monitoring -p '{"spec": {"type": "LoadBalancer"}}'
kubectl patch svc grafana -n monitoring -p '{"spec": {"type": "LoadBalancer"}}'
kubectl patch svc prometheus-alertmanager -n monitoring -p '{"spec": {"type": "LoadBalancer"}}'
```

Then, run the `minikube tunnel` command to assign external IPs to the services:\
![alt text](/images_README/monitoring/image-9.png)
![alt text](/images_README/monitoring/image-6.png)
![alt text](/images_README/monitoring/image-7.png)
![alt text](/images_README/monitoring/image-8.png)

Afterward, open a command prompt on your local machine (host) and execute the following SSH tunneling command:
```
ssh -L 3000:<EXTERNAL IP Grafana>:80 -L 9090:<EXTERNAL IP Promtheus>:80 -L 9093:<EXTERNAL IP Promtheus altermanager>:9093 <USER VM>@<IP VM>
```
![alt text](/images_README/monitoring/image-10.png)

This connects you to your VM over SSH:
![alt text](/images_README/monitoring/image-11.png)
You can now access Grafana, Prometheus, and Alert Manager from your local machine using the following URLs:
- http://localhost:3000 for Grafana
- http://localhost:9090 for Prometheus
- http://localhost:9093 for Alert Manager

![alt text](/images_README/monitoring/image-12.png)
![alt text](/images_README/monitoring/image-13.png)
![alt text](/images_README/monitoring/image-14.png)

As shown in the taskbar, we are now on the host machine running Windows.

Finally, when accessing Grafana for the first time, you must enter the username admin and the password generated earlier.

#### Configuring Grafana with Prometheus

Now that we have access to Grafana, we can configure it to work with Prometheus.\

To start, search for [Data sources](http://localhost:3000/connections/datasources) in the search bar. Then, click on [Add data source](http://localhost:3000/connections/datasources/new) and select "Prometheus":
![alt text](/images_README/monitoring/image-15.png)

Next, provide a name for your data source:
![alt text](/images_README/monitoring/image-16.png)
Configure its URL. In this case, it will be the URL of our Prometheus service. If you're using port forwarding, enter http://localhost. If you're using a LoadBalancer, use the external IP address:
![alt text](/images_README/monitoring/image-18.png)

We don’t specify a port because the goal is for the Grafana service running in Kubernetes to access the Prometheus service, also running in Kubernetes. Thus, we only need the external IP address of the Prometheus service without specifying a port, as the service operates on port 80 internally. The ports 9090 (for Prometheus) and 3000 (for Grafana) are for our use on the host machine to distinguish the services during access.

Finally, test the connection by clicking "Save & test." You should see the following confirmation that the connection has been established successfully:\
![alt text](/images_README/monitoring/image-19.png)

This setup enables Grafana to work seamlessly with Prometheus.

To conclude, we’ll add a dashboard to Grafana using Prometheus. Search for [import dashboard](http://localhost:3000/dashboard/import). You’ll see multiple options for importing a dashboard: via a JSON file, a JSON model, or a dashboard ID:\
![alt text](/images_README/monitoring/image-23.png)

We chose to use a dashboard ID and searched for one on https://grafana.com/grafana/dashboards/. We selected the dashboard with the ID 1860. Click "Load":\
![alt text](/images_README/monitoring/image-24.png)

You’ll then be prompted to name the dashboard and select the Prometheus data source configured earlier:\
![alt text](/images_README/monitoring/image-25.png)
Click "Import," and you will be taken directly to the newly created dashboard:\
![alt text](/images_README/monitoring/image-27.png)
![alt text](/images_README/monitoring/image-26.png)

This dashboard allows you to monitor the resources consumed by your Kubernetes services.

Now that Grafana has been configured with Prometheus, we will proceed to the configuration of Alert Manager.

### Alert Manager Configuration

Alert Manager allows us to send alert notifications to our email based on various conditions, such as if an instance has been down for more than a minute.

The first step was to create a file, [prometheus-alerts-rules.yaml](/project-main/kubernetes/prometheus-alert-rules.yml), with an alert rule for Prometheus Alert Manager:
![alt text](/images_README/monitoring/image-28.png)
This file defines an alert rule to monitor the health of Kubernetes pods. It triggers a critical alert if a pod remains in a non-operational state (e.g., Pending, Unknown, or Failed) for more than 15 minutes, providing information about the pod and its namespace.

To ensure Prometheus applied this new alert rule without altering existing configurations, we used the following command:
```sh
helm upgrade --reuse-values -f prometheus-alerts-rules.yaml prometheus prometheus-community/prometheus
```

Next, to allow Alert Manager to send email notifications when the rule triggers an alert, we created an [alertmanager.yml](/project-main/kubernetes/alertmanager.yml) configuration file:
![alt text](/images_README/monitoring/image-29.png)
This file configures Alert Manager to send email notifications via Gmail's SMTP server. Alerts are sent to the specified recipient (jules.davoustperso@gmail.com) from the sender address ntmlff.send.notification@gmail.com.

We applied this configuration using the same command as before:
```sh
helm upgrade --reuse-values -f alertmanager-config.yaml prometheus prometheus-community/prometheus
```

After creating and applying these configuration files, we reconfigured the LoadBalancer (or port forwarding, depending on the setup). We repeated the steps outlined in the section [Accéder à l'interface Grafana et Prometheus](#accéder-à-linterface-grafana-et-prometheus) to reconfigure the services for LoadBalancer access from our local machine.

By navigating to the "Alerts" tab in Prometheus, we verified that our rule was applied correctly:\
![alt text](/images_README/monitoring/image-40.png)

**Testing the Configuration**\
To test the configuration, we created two test files:\

1. [pending-test-pod.yml](/project-main/kubernetes/pending-test-pod.yml) : This file attempts to create a pod requesting more resources than the VM can provide, leaving the pod in a "Pending" state.\
![alt text](/images_README/monitoring/image-31.png)

2. [failed-test-pod.yml](/project-main/kubernetes/failed-test-pod.yml) : This file deliberately causes a pod to fail upon launch.\
![alt text](/images_README/monitoring/image-36.png)

We applied these files with the following commands:
```sh
kubectl apply -f /project-main/kubernetes/failed-test-pod.yml -n monitoring
kubectl apply -f /project-main/kubernetes/pending-test-pod.yml -n monitoring
```
![alt text](/images_README/monitoring/image-33.png)
![alt text](/images_README/monitoring/image-34.png)
![alt text](/images_README/monitoring/image-35.png)

Prometheus displayed two alerts: one for the "Pending" pod and another for the "Failed" pod. Prometheus waited 15 minutes before escalating the alerts to "Firing," triggering email notifications via Alert Manager.

In the Prometheus "Alerts" tab, we observed the notifications indicating that one pod was in "Pending" state and another in "Failed" state:\
![alt text](/images_README/monitoring/image-37.png)
![alt text](/images_README/monitoring/image-38.png)
After 15 minutes, these alerts transitioned to "Firing" status:\
![alt text](/images_README/monitoring/image-54.png)

At this point, we confirmed that Alert Manager successfully processed the alerts:\
![alt text](/images_README/monitoring/image-51.png)
Both alerts were displayed as expected.

Finally, we verified that two emails were sent to the recipient address specified in the [alertmanager.yml](/project-main/kubernetes/alertmanager.yml) file. These emails detailed the critical alerts:\
![alt text](/images_README/monitoring/image-49.png)
![alt text](/images_README/monitoring/image-50.png)
The emails were sent from the configured sender address and included details about the "Pending" and "Failed" pods.

With the configuration of Alert Manager complete, we can now proceed to configure Loki.

## Configuring Loki

Loki is a log management tool designed to centralize and manage logs. It collects, stores, and queries logs from applications and infrastructure. When integrated with Grafana, Loki enables seamless log visualization and analysis, aiding in troubleshooting, application monitoring, and overall observability.

### Step 1: Create the Loki Configuration File
The first step is to create a [values.yml](/project-main/kubernetes/values.yml) file:
![alt text](/images_README/monitoring/image-41.png)

This file defines custom configurations for deploying Loki and simplifies its usage.

### Step 2: Install Loki
Next, install Loki from Grafana's official Helm repository using the custom [values.yml](/project-main/kubernetes/values.yml) configuration file. This will deploy Loki in the Kubernetes "monitoring" namespace with the parameters defined in the configuration file:
```sh
helm install loki grafana/loki -f values.yaml -n monitoring
```

### Step 3: Expose the Loki Service
Now, expose Loki to allow access from your local machine. You can do this in one of two ways:
1. **Port Forwarding**\
Use port forwarding to forward traffic from your local machine to Loki:
```sh
kubectl port-forward --namespace monitoring svc/loki-gateway 3100:80
```
2. **LoadBalancer Configuration**\
Change the Loki service type to LoadBalancer to assign an external IP:
```sh
kubectl patch svc loki -n monitoring -p '{"spec": {"type": "LoadBalancer"}}'
```
### Step 4: Assign External IP via Minikube
If you opted for the LoadBalancer configuration, run the following command to assign an external IP to the Loki service:
`minikube tunnel`
![alt text](/images_README/monitoring/image-44.png)

### Configuring Loki in Grafana

Next, we proceed to Grafana to add a new [data source](http://localhost:3000/connections/datasources). Click on [Add data source](http://localhost:3000/connections/datasources/new), scroll down, and select "Loki":\
![alt text](/images_README/monitoring/image-45.png)

We name our data source:\
![alt text](/images_README/monitoring/image-46.png)

For the URL, enter either [http://EXTERNAL_IP_Loki:3100]() (if using a LoadBalancer) or http://localhost:3100 if using port forwarding.
![alt text](/images_README/monitoring/image-47.png)

#### Adding HTTP Headers for Loki Configuration
To finalize the configuration of the Loki data source, we need to add specific values in the headers section:\
![alt text](/images_README/monitoring/image-48.png)
- Open the dropdown menu "HTTP headers" and click on "+ Add header."
- Add "X-Scope-OrgID" as the Header and "foo" as the Value.
This ensures proper configuration of the data source, allowing Grafana to interact with Loki seamlessly.

![alt text](/images_README/monitoring/image-55.png)

After completing these steps, click "Save & test":\
![alt text](/images_README/monitoring/image-56.png)
You should see a confirmation indicating that the Loki data source is working correctly.

### Testing Loki

To quickly test Loki, we executed the following command on our VM:
```sh
curl -H "Content-Type: application/json" \
     -H "X-Scope-OrgId: foo" \
     -XPOST "http://<IP Loki>:3100/loki/api/v1/push" \
     --data-raw '{"streams": [{"stream": {"job": "test"}, "values": [["'$(date +%s)000000000'", "fizzbuzz"]]}]}'
```
![alt text](/images_README/monitoring/image-52.png)
This command sends custom logs to Loki via its API, specifying a job named "test" and a log message "fizzbuzz" with the current timestamp.

Next, we ran the following command to query Loki:
```sh
curl -G "http://<IP Loki>:3100/loki/api/v1/query_range" \
     --data-urlencode 'query={job="test"}' \
     -H "X-Scope-OrgId: foo" | jq .data.result
```
This command queries Loki to retrieve logs associated with the job "test" over a specific time range, using the /loki/api/v1/query_range endpoint.

If Loki is functioning correctly, the command will return a response containing the logs (e.g., "fizzbuzz").
![alt text](/images_README/monitoring/image-53.png)
As shown above, Loki successfully returned the logs, confirming that it is working correctly.

#
**Configuring Loki in Grafana**\
To manage logs directly within Grafana, go to [explore](http://localhost:3000/explore) from the Grafana sidebar. In the top-left dropdown menu, select "Loki," the data source configured earlier:\
![alt text](/images_README/monitoring/image-57.png)\
Next, select "job" as the label and "test" as the value. Executing the query will display the "fizzbuzz" log sent earlier:\
![alt text](/images_README/monitoring/image-58.png)\
![alt text](/images_README/monitoring/image-59.png)

At this point, only "job" and "test" are available as labels. To manage logs more comprehensively, we need to install Promtail using the following command:
```sh
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
```
Promtail is a log agent used to collect logs from applications, such as Kubernetes pods. It sends logs to Loki for storage and analysis. The above command:

- Configures Promtail to send logs to the specified Loki URL.
- Sets a tenant ID (foo).
- Tracks log positions to avoid duplication.
- Scrapes logs from Kubernetes pods (kubernetes-pods job).
- Extracts metadata (e.g., namespace, pod, container) and uses it as log labels.

**Testing Promtail**\
To test Promtail, ensure the production namespace exists with: `kubectl create namespace production`.Then create and apply an [error-logger.yml](/project-main/kubernetes/error-logger.yml) file in the production namespace: `kuebctl apply -f /project-main/kubernetes/error-logger.yml`.\
![alt text](/images_README/monitoring/image-60.png)\
This file creates a pod that generates error logs periodically, allowing us to test Loki with Grafana.


Return to Grafana’s [Explore](http://localhost:3000/explore) section. Select "Loki" as the data source. You should now see multiple labels, values for each label, and various operations available:\
![alt text](/images_README/monitoring/image-61.png)
![alt text](/images_README/monitoring/image-62.png)

Start by selecting "namespace" as the label and "production" as the value:\
![alt text](/images_README/monitoring/image-63.png)

Execute the query to display all logs within the production namespace:\
![alt text](/images_README/monitoring/image-64.png)
Ce sont tous nos logs dans le namespace "production".

For advanced queries, switch to the "code" tab at the top-right:\
![alt text](/images_README/monitoring/image-65.png)\
Manually enter a query such as : {namespace="production"} |= "error"
![alt text](/images_README/monitoring/image-66.png)
This query lists all logs containing the word "error" in the "production" namespace:\
![alt text](/images_README/monitoring/image-67.png)

## Conclusion

In this section, we explored setting up a monitoring system within Kubernetes using Grafana, Prometheus, and Loki.

Prometheus enabled the collection and storage of metrics from Kubernetes resources while allowing us to configure alerts based on specific thresholds or events. It also facilitated email notifications for critical alerts. Grafana provided an intuitive visual interface for displaying these metrics through dashboards, making it easier to monitor performance and detect anomalies.

Finally, Loki complemented the system by ensuring centralized log management, enabling the identification of errors or issues directly alongside the metrics.


