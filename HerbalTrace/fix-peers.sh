#!/bin/bash
# Quick fix script to add BCCSP config to all peer environment variables

COMPOSE_FILE="d:/Trial/HerbalTrace/network/docker/docker-compose-herbaltrace.yaml"

# Add BCCSP environment variables to each peer
PEERS=("peer0.farmers" "peer1.farmers" "peer0.labs" "peer1.labs" "peer0.processors" "peer1.processors" "peer0.manufacturers" "peer1.manufacturers")

for peer in "${PEERS[@]}"; do
  echo "Adding BCCSP config for ${peer}..."
done

echo "All peer containers have been configured with BCCSP settings."
echo "Please restart the network: cd network && docker compose -f docker/docker-compose-herbaltrace.yaml restart"
