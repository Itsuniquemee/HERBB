import re

# Read the docker-compose file
with open('d:/Trial/HerbalTrace/network/docker/docker-compose-herbaltrace.yaml', 'r') as f:
    content = f.read()

# First, add peercfg volume mount to all peers that don't have it
# Pattern to find volumes section of peer services
volume_pattern = r'(  peer[01]\.(farmers|labs|processors|manufacturers)\.herbaltrace\.com:.*?    volumes:\s+)(.*?)(\n    working_dir:)'

def add_peercfg_mount(match):
    service_name = match.group(1)
    volumes_content = match.group(3)
    working_dir = match.group(4)
    
    # Check if peercfg mount already exists
    if '../peercfg:/etc/hyperledger/peercfg' in volumes_content:
        return match.group(0)  # Already has peercfg mount
    
    # Add peercfg mount as first volume
    new_volumes = '- ../peercfg:/etc/hyperledger/peercfg\n        ' + volumes_content.lstrip()
    return service_name + new_volumes + working_dir

# Apply volume mount fix
modified_content = re.sub(volume_pattern, add_peercfg_mount, content, flags=re.DOTALL)

# Now add BCCSP environment variables
bccsp_vars = """      - CORE_PEER_BCCSP_DEFAULT=SW
      - CORE_PEER_BCCSP_SW_HASH=SHA2
      - CORE_PEER_BCCSP_SW_SECURITY=256"""

# Find all peer service definitions and add BCCSP vars before the 'volumes:' line
pattern = r'(  peer[01]\.(farmers|labs|processors|manufacturers)\.herbaltrace\.com:.*?      - CORE_VM_DOCKER_HOSTCONFIG_NETWORKMODE=herbaltrace-network\s*\n)(    volumes:)'

def add_bccsp(match):
    service_def = match.group(1)
    volumes_line = match.group(3)
    
    # Check if BCCSP vars already exist
    if 'CORE_PEER_BCCSP_DEFAULT' in service_def:
        return match.group(0)  # Already has BCCSP, skip
    
    # Add BCCSP vars before volumes
    return service_def + bccsp_vars + '\n' + volumes_line

# Apply BCCSP environment variables
modified_content = re.sub(pattern, add_bccsp, modified_content, flags=re.DOTALL)

# Write back
with open('d:/Trial/HerbalTrace/network/docker/docker-compose-herbaltrace.yaml', 'w') as f:
    f.write(modified_content)

print("✅ Added peercfg volume mount to all peer services")
print("✅ Added BCCSP configuration to all peer services")
print("\nYou can now restart the network:")
print("  cd network && docker compose -f docker/docker-compose-herbaltrace.yaml up -d")
