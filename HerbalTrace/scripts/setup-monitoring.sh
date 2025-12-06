#!/bin/bash

# Monitoring configuration script
# Sets up Prometheus and Grafana for network monitoring

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/.."

echo "Setting up monitoring infrastructure..."

# Create monitoring directory
mkdir -p "$PROJECT_ROOT/monitoring"

# Create Prometheus configuration
cat > "$PROJECT_ROOT/monitoring/prometheus.yml" << 'EOF'
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'fabric-orderers'
    static_configs:
      - targets:
        - 'orderer.herbaltrace.com:8443'
        - 'orderer2.herbaltrace.com:8443'
        - 'orderer3.herbaltrace.com:8443'

  - job_name: 'fabric-peers-farmerscoop'
    static_configs:
      - targets:
        - 'peer0.farmerscoop.herbaltrace.com:9443'
        - 'peer1.farmerscoop.herbaltrace.com:9443'

  - job_name: 'fabric-peers-testinglabs'
    static_configs:
      - targets:
        - 'peer0.testinglabs.herbaltrace.com:9443'
        - 'peer1.testinglabs.herbaltrace.com:9443'

  - job_name: 'fabric-peers-processors'
    static_configs:
      - targets:
        - 'peer0.processors.herbaltrace.com:9443'
        - 'peer1.processors.herbaltrace.com:9443'

  - job_name: 'fabric-peers-manufacturers'
    static_configs:
      - targets:
        - 'peer0.manufacturers.herbaltrace.com:9443'
        - 'peer1.manufacturers.herbaltrace.com:9443'
EOF

# Create Grafana datasource
cat > "$PROJECT_ROOT/monitoring/grafana-datasource.yml" << 'EOF'
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
    editable: true
EOF

# Create Grafana dashboard for Fabric
cat > "$PROJECT_ROOT/monitoring/fabric-dashboard.json" << 'EOF'
{
  "dashboard": {
    "title": "HerbalTrace Fabric Network",
    "panels": [
      {
        "title": "Transaction Throughput",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(fabric_endorser_successful_proposals[5m])"
          }
        ]
      },
      {
        "title": "Block Height",
        "type": "graph",
        "targets": [
          {
            "expr": "fabric_ledger_blockchain_height"
          }
        ]
      },
      {
        "title": "Endorsement Duration",
        "type": "graph",
        "targets": [
          {
            "expr": "fabric_endorser_proposal_duration_sum / fabric_endorser_proposal_duration_count"
          }
        ]
      }
    ]
  }
}
EOF

# Create Docker Compose for monitoring
cat > "$PROJECT_ROOT/monitoring/docker-compose-monitoring.yaml" << 'EOF'
version: '3.7'

networks:
  herbaltrace:
    external: true

services:
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
    ports:
      - "9090:9090"
    networks:
      - herbaltrace

  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    volumes:
      - grafana_data:/var/lib/grafana
      - ./grafana-datasource.yml:/etc/grafana/provisioning/datasources/datasource.yml
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
      - GF_USERS_ALLOW_SIGN_UP=false
    ports:
      - "3000:3000"
    networks:
      - herbaltrace
    depends_on:
      - prometheus

volumes:
  prometheus_data:
  grafana_data:
EOF

echo "✅ Monitoring configuration created"
echo "Start monitoring stack: cd monitoring && docker-compose -f docker-compose-monitoring.yaml up -d"
echo "Access Grafana at: http://localhost:3000 (admin/admin)"
echo "Access Prometheus at: http://localhost:9090"
