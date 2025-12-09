# Herb Species Auto-Fill Feature

## Overview

A new reference table has been created to auto-fill species data when farmers select an herb during collection event creation.

## Database Table

**Table:** `herb_species_reference`

**Columns:**
- `common_name` - Display name (e.g., "Ashwagandha")
- `scientific_name` - Botanical name (e.g., "Withania somnifera")
- `species` - Species identifier
- `local_names` - Regional names
- `medicinal_uses` - Health benefits
- `part_used` - Harvested part (roots, leaves, etc.)
- `harvest_season` - Best harvest time

## Supported Herbs

1. **Ashwagandha** (Withania somnifera) - Roots - October-March
2. **Tulsi** (Ocimum sanctum) - Leaves - Year-round
3. **Brahmi** (Bacopa monnieri) - Whole plant - Year-round
4. **Neem** (Azadirachta indica) - Leaves, bark, seeds - Year-round
5. **Turmeric** (Curcuma longa) - Rhizomes - January-March
6. **Ginger** (Zingiber officinale) - Rhizomes - November-January
7. **Aloe Vera** (Aloe barbadensis miller) - Leaves (gel) - Year-round
8. **Amla** (Phyllanthus emblica) - Fruits - November-February

## API Endpoints

### 1. Get All Species (Dropdown Options)
```bash
GET /api/v1/herbs/species-list
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "label": "Ashwagandha",
      "value": "Ashwagandha",
      "scientificName": "Withania somnifera"
    },
    ...
  ]
}
```

### 2. Get Species Details (Auto-fill Data)
```bash
GET /api/v1/herbs/species/Ashwagandha
```

**Response:**
```json
{
  "success": true,
  "data": {
    "common_name": "Ashwagandha",
    "scientific_name": "Withania somnifera",
    "species": "Ashwagandha",
    "local_names": "Indian Ginseng, Winter Cherry",
    "medicinal_uses": "Stress relief, immune support, energy booster",
    "part_used": "Roots",
    "harvest_season": "October-March"
  }
}
```

### 3. Get All Species (Full Details)
```bash
GET /api/v1/herbs/species
```

## Railway Setup

Run this SQL in Railway PostgreSQL to create the table:

```bash
# Option 1: Via Railway CLI
cat create-herb-species-table.sql | railway run psql $DATABASE_URL

# Option 2: Via TablePlus/DBeaver
# Open create-herb-species-table.sql and execute
```

## Flutter Integration Example

```dart
// 1. Load species dropdown options
Future<List<HerbSpecies>> loadHerbSpecies() async {
  final response = await http.get(
    Uri.parse('https://herbal-trace-production.up.railway.app/api/v1/herbs/species-list'),
  );
  
  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    return (data['data'] as List)
        .map((item) => HerbSpecies.fromJson(item))
        .toList();
  }
  throw Exception('Failed to load herb species');
}

// 2. Auto-fill when species selected
Future<void> onSpeciesSelected(String commonName) async {
  final response = await http.get(
    Uri.parse('https://herbal-trace-production.up.railway.app/api/v1/herbs/species/$commonName'),
  );
  
  if (response.statusCode == 200) {
    final data = json.decode(response.body)['data'];
    
    setState(() {
      // Auto-fill form fields
      speciesController.text = data['species'];
      scientificNameController.text = data['scientific_name'];
      commonNameController.text = data['common_name'];
      partCollectedController.text = data['part_used'];
      // Optional: Show harvest season info
      harvestSeasonInfo = data['harvest_season'];
    });
  }
}

// 3. Widget implementation
DropdownButtonFormField<String>(
  decoration: InputDecoration(labelText: 'Select Herb'),
  items: herbSpeciesList.map((herb) {
    return DropdownMenuItem(
      value: herb.commonName,
      child: Text(herb.label),
    );
  }).toList(),
  onChanged: (value) {
    if (value != null) {
      onSpeciesSelected(value);
    }
  },
)
```

## Testing

### Test API Endpoints

```bash
# Get species list
curl https://herbal-trace-production.up.railway.app/api/v1/herbs/species-list

# Get Ashwagandha details
curl https://herbal-trace-production.up.railway.app/api/v1/herbs/species/Ashwagandha

# Get Tulsi details
curl https://herbal-trace-production.up.railway.app/api/v1/herbs/species/Tulsi

# Get all species
curl https://herbal-trace-production.up.railway.app/api/v1/herbs/species
```

## Benefits

✅ **Consistent Data** - No typos in species names
✅ **Faster Data Entry** - Auto-fill scientific names
✅ **User Friendly** - Dropdown selection instead of typing
✅ **Educational** - Shows medicinal uses and harvest seasons
✅ **Extensible** - Easy to add more herbs via API

## Adding New Herbs

```bash
curl -X POST https://herbal-trace-production.up.railway.app/api/v1/herbs/species \
  -H "Content-Type: application/json" \
  -d '{
    "commonName": "Haritaki",
    "scientificName": "Terminalia chebula",
    "species": "Haritaki",
    "localNames": "Kadukkai, Harad",
    "medicinalUses": "Digestive health, detoxification",
    "partUsed": "Fruits",
    "harvestSeason": "December-February"
  }'
```

## Files Created

- ✅ `backend/src/routes/herb-species.routes.ts` - API routes
- ✅ `backend/src/config/database-adapter.ts` - Table schema updated
- ✅ `create-herb-species-table.sql` - Railway SQL script
- ✅ `backend/src/index.ts` - Routes registered

## Deployment Status

✅ Code pushed to GitHub
✅ Railway auto-deploy triggered
⏳ Waiting for Railway deployment
🔧 Need to run SQL in Railway PostgreSQL

## Next Steps

1. **Create table in Railway** - Run `create-herb-species-table.sql`
2. **Test API** - Verify endpoints respond correctly
3. **Update Flutter app** - Integrate dropdown and auto-fill
4. **Add validation** - Ensure selected species matches reference data
