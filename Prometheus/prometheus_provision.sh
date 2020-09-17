#!/bin/bash
#Variables
homedir="/home/prometheus"
node_ip="${node_ip}:9100"
url="http://`curl v4.ifconfig.co`:9090"
change="{DS_PROMETHEUS}"

#install docker and docker-compose
sudo yum install -y yum-utils
sudo yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo
sudo yum install -y docker-ce docker-ce-cli containerd.io docker-compose
sudo systemctl enable docker
sudo systemctl start docker 

#create home directory for prometheus 
sudo mkdir $homedir
#create docker-compose file, thats will crete container with prometheus,alertmanager,grafana & blackbox
sudo tee $homedir/docker-compose.yml <<EOF
version: '3'
volumes:
    prometheus_data: {}
    grafana_data: {}
services:
  prometheus:
    image: prom/prometheus:latest
    volumes:
      - ./prometheus/:/etc/prometheus/
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/usr/share/prometheus/console_libraries'
      - '--web.console.templates=/usr/share/prometheus/consoles'
    ports:
      - 9090:9090
    links:
      - alertmanager:alertmanager
      - blackbox-exporter:blackbox-exporter
    restart: always
#    deploy:
#      placement:
#        constraints:
#          - node.hostname == prometheus
#  node-exporter:
#    image: prom/node-exporter
#    volumes:
#      - /proc:/host/proc:ro
#      - /sys:/host/sys:ro
#      - /:/rootfs:ro
#    command: 
#      - '--path.procfs=/host/proc' 
#      - '--path.sysfs=/host/sys'
#      - --collector.filesystem.ignored-mount-points
#            - "^/(sys|proc|dev|host|etc|rootfs/var/lib/docker/containers|rootfs/var/lib/docker/overlay2|rootfs/run/docker/netns|rootfs/var/lib/docker/aufs)(1321|/)"
#    ports:
#      - 9100:9100
#    restart: always
#    deploy:
#      mode: global

  alertmanager:
    image: prom/alertmanager
    ports:
      - 9093:9093
    volumes:
      - ./alertmanager/:/etc/alertmanager/
    restart: always
    command:
      - '--config.file=/etc/alertmanager/config.yml'
      - '--storage.path=/alertmanager'
#    deploy:
#      placement:
#        constraints:
#          - node.hostname == prometheus
  grafana:
    image: grafana/grafana
    user: "472"
    depends_on:
      - prometheus
    ports:
      - 3000:3000
    volumes:
      - grafana_data:/var/lib/grafana
      - ./grafana/provisioning/:/etc/grafana/provisioning/
    restart: always

  blackbox-exporter:
   image: prom/blackbox-exporter
   container_name: blackbox
   restart: unless-stopped
   ports:
     - "9115:9115"
EOF

#create folders for configs
sudo mkdir $homedir/prometheus
sudo mkdir $homedir/alertmanager
sudo mkdir -p $homedir/grafana/provisioning

#create prometheus config
sudo tee $homedir/prometheus/prometheus.yml <<EOF
# my global config
rule_files:
  - 'alert.rules'
alerting:
  alertmanagers:
  - scheme: http
    static_configs:
    - targets:
      - "alertmanager:9093"
scrape_configs:
  - job_name: node
    static_configs:
         - targets: ['$node_ip']

  - job_name: 'blackbox_web'
    metrics_path: /probe
    params:
      module: [http_2xx]
    static_configs:
      - targets:
          - https://onliner.by
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - source_labels: []
        regex: .*
        target_label: __address__
        replacement: blackbox-exporter:9115
EOF

#create alert rule
sudo tee $homedir/prometheus/alert.rules <<EOF
groups:
- name: example
  rules:

  # Alert for any instance that is unreachable for >2 minutes.
  - alert: service_down
    expr: up == 0
    for: 2m
    labels:
      severity: page
    annotations:
      summary: "Instance {{ \$labels.instance }} down"
      description: "{{ \$labels.instance }} of job {{ \$labels.job }} has been down for more than 2 minutes."

  - alert: high_load
    expr: node_load1 > 0.5
    for: 2m
    labels:
      severity: page
    annotations:
      summary: "Instance {{ \$labels.instance }} under high load"
      description: "{{ \$labels.instance }} of job {{ \$labels.job }} is under high load."
EOF

#create alertmanager config
sudo tee $homedir/alertmanager/config.yml <<EOF
 route:
     receiver: 'slack'

 receivers:
     - name: 'slack'
#       slack_configs:
#           - send_resolved: true
#             username: '<username>'
#             channel: '#<channel-name>'
#             api_url: '<incomming-webhook-url>'
EOF

#create folders for creating datasources and dashboards
sudo mkdir $homedir/grafana/provisioning/dashboards
sudo mkdir $homedir/grafana/provisioning/datasources

#create datasource   
sudo tee $homedir/grafana/provisioning/datasources/datasource.yml <<EOF
apiVersion: 1
deleteDatasources:
  - name: Prometheus
datasources:
- name: Prometheus
  type: prometheus
  access: proxy
  url: $url
  basicAuth: false
  isDefault: true
  editable: true
EOF

#config dashboards
sudo tee $homedir/grafana/provisioning/dashboards/dashboard.yaml <<EOF
apiVersion: 1

providers:
- name: "Prometheus"
  orgId: 1
  folder: ''
  type: file
  disableDeletion: false
  editable: true
  options:
    path: /etc/grafana/provisioning/dashboards
EOF

#download and install dashboards
sudo curl -o $homedir/grafana/provisioning/dashboards/linux.json https://grafana.com/api/dashboards/10180/revisions/1/download
sudo curl -o $homedir/grafana/provisioning/dashboards/http.json https://grafana.com/api/dashboards/4859/revisions/1/download
sudo sed -i "s/\$$change/Prometheus/g" $homedir/grafana/provisioning/dashboards/*.json 

#docker up
sudo docker-compose -f $homedir/docker-compose.yml up -d