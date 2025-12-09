import sys
import json

data = json.load(sys.stdin)
collections = data['data']

print('\n=== Data Upload Status ===')
print(f'Total records: {len(collections)}\n')

# Group by species
species = {}
for c in collections:
    s = c.get('species', 'Unknown')
    species[s] = species.get(s, 0) + 1

print('By Species:')
for k, v in sorted(species.items()):
    print(f'  - {k}: {v} collections')

# Sync status
print(f'\nSync Status:')
synced = sum(1 for c in collections if c.get('syncStatus') == 'synced')
failed = sum(1 for c in collections if c.get('syncStatus') == 'failed')
pending = sum(1 for c in collections if c.get('syncStatus') == 'pending')
print(f'  ✅ Synced to blockchain: {synced}')
print(f'  ❌ Failed to sync: {failed}')
print(f'  ⏳ Pending: {pending}')

# Recent uploads
print(f'\nMost Recent Uploads:')
sorted_collections = sorted(collections, key=lambda x: x.get('timestamp', ''), reverse=True)
for i, c in enumerate(sorted_collections[:5], 1):
    print(f'  {i}. {c["species"]} - {c["quantity"]} {c["unit"]} - {c["timestamp"][:19]}')
