-- Create herb species reference table in Railway PostgreSQL
-- This table provides auto-fill data for common Indian medicinal herbs

CREATE TABLE IF NOT EXISTS herb_species_reference (
  id SERIAL PRIMARY KEY,
  common_name TEXT NOT NULL UNIQUE,
  scientific_name TEXT NOT NULL,
  species TEXT NOT NULL,
  local_names TEXT,
  description TEXT,
  medicinal_uses TEXT,
  growing_conditions TEXT,
  harvest_season TEXT,
  part_used TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert default herb species data
INSERT INTO herb_species_reference 
  (common_name, scientific_name, species, local_names, description, medicinal_uses, part_used, harvest_season)
VALUES 
  ('Ashwagandha', 'Withania somnifera', 'Ashwagandha', 'Indian Ginseng, Winter Cherry', 'Adaptogenic herb known for stress relief and vitality', 'Stress relief, immune support, energy booster', 'Roots', 'October-March'),
  ('Tulsi', 'Ocimum sanctum', 'Tulsi', 'Holy Basil, Tulasi', 'Sacred herb with powerful medicinal properties', 'Respiratory health, immunity, stress relief', 'Leaves', 'Year-round'),
  ('Brahmi', 'Bacopa monnieri', 'Brahmi', 'Water Hyssop, Indian Pennywort', 'Memory-enhancing herb for cognitive support', 'Memory enhancement, cognitive function, stress relief', 'Whole plant', 'Year-round'),
  ('Neem', 'Azadirachta indica', 'Neem', 'Indian Lilac, Margosa', 'Powerful antibacterial and antifungal herb', 'Skin care, blood purification, antibacterial', 'Leaves, bark, seeds', 'Year-round'),
  ('Turmeric', 'Curcuma longa', 'Turmeric', 'Haldi, Indian Saffron', 'Golden spice with anti-inflammatory properties', 'Anti-inflammatory, antioxidant, digestive health', 'Rhizomes', 'January-March'),
  ('Ginger', 'Zingiber officinale', 'Ginger', 'Adrak, Sonth', 'Warming herb for digestion and inflammation', 'Digestive health, nausea relief, anti-inflammatory', 'Rhizomes', 'November-January'),
  ('Aloe Vera', 'Aloe barbadensis miller', 'Aloe Vera', 'Ghritkumari, Medicinal Aloe', 'Succulent plant with healing gel', 'Skin healing, digestive health, hydration', 'Leaves (gel)', 'Year-round'),
  ('Amla', 'Phyllanthus emblica', 'Amla', 'Indian Gooseberry, Amalaki', 'Vitamin C-rich fruit for immunity and vitality', 'Immunity, hair care, antioxidant', 'Fruits', 'November-February')
ON CONFLICT (common_name) DO NOTHING;

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_herb_species_common_name ON herb_species_reference(common_name);

-- Success message
SELECT 'Herb species reference table created and populated successfully!' AS status;
