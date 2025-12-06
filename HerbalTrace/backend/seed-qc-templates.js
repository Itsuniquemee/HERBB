/**
 * Seed QC Test Templates
 * Creates predefined test templates for common herbal species
 */

const Database = require('better-sqlite3');
const path = require('path');
const { v4: uuidv4 } = require('uuid');

const dbPath = path.join(__dirname, 'data', 'herbaltrace.db');
console.log('Database path:', dbPath);
const db = new Database(dbPath);

const templates = [
  {
    name: 'Ashwagandha - Identity & Purity Test',
    description: 'Complete identity and purity testing for Ashwagandha (Withania somnifera)',
    category: 'IDENTITY',
    applicable_species: 'Ashwagandha',
    test_method: 'HPTLC, Microscopy, Chemical Tests',
    parameters: JSON.stringify([
      { parameter_name: 'Morphological Identification', parameter_type: 'TEXT', description: 'Visual and microscopic identification' },
      { parameter_name: 'Foreign Matter', parameter_type: 'NUMERIC', expected_max: 2.0, unit: '%', description: 'Foreign organic matter' },
      { parameter_name: 'Total Ash', parameter_type: 'NUMERIC', expected_max: 7.0, unit: '%', description: 'Total ash content' },
      { parameter_name: 'Acid Insoluble Ash', parameter_type: 'NUMERIC', expected_max: 1.0, unit: '%', description: 'Acid insoluble ash' },
      { parameter_name: 'Withanolides', parameter_type: 'NUMERIC', expected_min: 0.3, expected_max: 3.0, unit: '%', description: 'Active constituent content' }
    ]),
    acceptance_criteria: JSON.stringify({
      foreign_matter: '≤ 2%',
      total_ash: '≤ 7%',
      acid_insoluble_ash: '≤ 1%',
      withanolides: '0.3% - 3.0%'
    }),
    estimated_duration_hours: 48,
    cost: 5000,
    required_equipment: 'HPTLC system, Microscope, Muffle furnace',
    required_reagents: 'Standard withanolide markers, Solvents',
    reference_standard: 'Ayurvedic Pharmacopoeia of India'
  },
  {
    name: 'Tulsi - Microbial Contamination Test',
    description: 'Microbial testing for Tulsi (Ocimum sanctum)',
    category: 'MICROBIAL',
    applicable_species: 'Tulsi',
    test_method: 'Culture-based Enumeration',
    parameters: JSON.stringify([
      { parameter_name: 'Total Bacterial Count', parameter_type: 'NUMERIC', expected_max: 100000, unit: 'CFU/g', description: 'Total aerobic count' },
      { parameter_name: 'Total Fungal Count', parameter_type: 'NUMERIC', expected_max: 1000, unit: 'CFU/g', description: 'Yeast and mold count' },
      { parameter_name: 'E. coli', parameter_type: 'TEXT', expected_value: 'Absent', description: 'E. coli presence' },
      { parameter_name: 'Salmonella', parameter_type: 'TEXT', expected_value: 'Absent', description: 'Salmonella presence' },
      { parameter_name: 'Aflatoxins', parameter_type: 'NUMERIC', expected_max: 20, unit: 'ppb', description: 'Total aflatoxins' }
    ]),
    acceptance_criteria: JSON.stringify({
      total_bacterial_count: '≤ 10^5 CFU/g',
      total_fungal_count: '≤ 10^3 CFU/g',
      ecoli: 'Absent in 1g',
      salmonella: 'Absent in 25g',
      aflatoxins: '≤ 20 ppb'
    }),
    estimated_duration_hours: 72,
    cost: 4500,
    required_equipment: 'Incubator, Laminar flow, Autoclave',
    required_reagents: 'Culture media, Test kits',
    reference_standard: 'WHO Guidelines, API'
  },
  {
    name: 'Turmeric - Heavy Metals Test',
    description: 'Heavy metal contamination testing for Turmeric (Curcuma longa)',
    category: 'HEAVY_METALS',
    applicable_species: 'Turmeric',
    test_method: 'ICP-MS/AAS',
    parameters: JSON.stringify([
      { parameter_name: 'Lead (Pb)', parameter_type: 'NUMERIC', expected_max: 10, unit: 'ppm', description: 'Lead content' },
      { parameter_name: 'Cadmium (Cd)', parameter_type: 'NUMERIC', expected_max: 0.3, unit: 'ppm', description: 'Cadmium content' },
      { parameter_name: 'Arsenic (As)', parameter_type: 'NUMERIC', expected_max: 3, unit: 'ppm', description: 'Arsenic content' },
      { parameter_name: 'Mercury (Hg)', parameter_type: 'NUMERIC', expected_max: 1, unit: 'ppm', description: 'Mercury content' }
    ]),
    acceptance_criteria: JSON.stringify({
      lead: '≤ 10 ppm',
      cadmium: '≤ 0.3 ppm',
      arsenic: '≤ 3 ppm',
      mercury: '≤ 1 ppm'
    }),
    estimated_duration_hours: 24,
    cost: 6000,
    required_equipment: 'ICP-MS or AAS',
    required_reagents: 'Digestion acids, Standard solutions',
    reference_standard: 'WHO, FSSAI'
  },
  {
    name: 'Ginger - Moisture Content Test',
    description: 'Moisture determination for Ginger (Zingiber officinale)',
    category: 'MOISTURE',
    applicable_species: 'Ginger',
    test_method: 'Loss on Drying',
    parameters: JSON.stringify([
      { parameter_name: 'Moisture Content', parameter_type: 'NUMERIC', expected_max: 12, unit: '%', description: 'Moisture by LOD method' },
      { parameter_name: 'Volatile Oil', parameter_type: 'NUMERIC', expected_min: 1.0, unit: '% v/w', description: 'Essential oil content' }
    ]),
    acceptance_criteria: JSON.stringify({
      moisture: '≤ 12%',
      volatile_oil: '≥ 1.0% v/w'
    }),
    estimated_duration_hours: 8,
    cost: 1500,
    required_equipment: 'Moisture analyzer, Clevenger apparatus',
    required_reagents: 'None',
    reference_standard: 'API, IP'
  },
  {
    name: 'Brahmi - Pesticide Residue Test',
    description: 'Multi-residue pesticide analysis for Brahmi (Bacopa monnieri)',
    category: 'PESTICIDES',
    applicable_species: 'Brahmi',
    test_method: 'GC-MS/LC-MS',
    parameters: JSON.stringify([
      { parameter_name: 'Organochlorines', parameter_type: 'NUMERIC', expected_max: 0.05, unit: 'ppm', description: 'Organochlorine pesticides' },
      { parameter_name: 'Organophosphorus', parameter_type: 'NUMERIC', expected_max: 0.05, unit: 'ppm', description: 'Organophosphorus pesticides' },
      { parameter_name: 'Pyrethroids', parameter_type: 'NUMERIC', expected_max: 0.05, unit: 'ppm', description: 'Pyrethroid pesticides' },
      { parameter_name: 'Carbamates', parameter_type: 'NUMERIC', expected_max: 0.05, unit: 'ppm', description: 'Carbamate pesticides' }
    ]),
    acceptance_criteria: JSON.stringify({
      total_pesticides: '≤ 0.05 ppm per pesticide',
      individual_pesticide: '≤ 0.01 ppm'
    }),
    estimated_duration_hours: 48,
    cost: 8000,
    required_equipment: 'GC-MS, LC-MS',
    required_reagents: 'Solvents, Standard pesticide mixes',
    reference_standard: 'WHO, EU Regulations'
  },
  {
    name: 'Neem - Extractives Test',
    description: 'Water and alcohol extractive values for Neem (Azadirachta indica)',
    category: 'EXTRACTIVES',
    applicable_species: 'Neem',
    test_method: 'Soxhlet Extraction',
    parameters: JSON.stringify([
      { parameter_name: 'Water Soluble Extractives', parameter_type: 'NUMERIC', expected_min: 10, unit: '%', description: 'Water extractive value' },
      { parameter_name: 'Alcohol Soluble Extractives', parameter_type: 'NUMERIC', expected_min: 8, unit: '%', description: 'Alcohol extractive value' }
    ]),
    acceptance_criteria: JSON.stringify({
      water_extractives: '≥ 10%',
      alcohol_extractives: '≥ 8%'
    }),
    estimated_duration_hours: 16,
    cost: 2000,
    required_equipment: 'Soxhlet apparatus, Rotary evaporator',
    required_reagents: 'Water, Ethanol',
    reference_standard: 'API, WHO'
  },
  {
    name: 'General Herbal - Complete QC Package',
    description: 'Comprehensive quality control testing for any herbal material',
    category: 'PURITY',
    applicable_species: null, // Applicable to all
    test_method: 'Multiple methods as per pharmacopoeia',
    parameters: JSON.stringify([
      { parameter_name: 'Foreign Matter', parameter_type: 'NUMERIC', expected_max: 2, unit: '%' },
      { parameter_name: 'Total Ash', parameter_type: 'NUMERIC', expected_max: 10, unit: '%' },
      { parameter_name: 'Acid Insoluble Ash', parameter_type: 'NUMERIC', expected_max: 2, unit: '%' },
      { parameter_name: 'Moisture Content', parameter_type: 'NUMERIC', expected_max: 12, unit: '%' },
      { parameter_name: 'Total Bacterial Count', parameter_type: 'NUMERIC', expected_max: 100000, unit: 'CFU/g' },
      { parameter_name: 'Total Fungal Count', parameter_type: 'NUMERIC', expected_max: 1000, unit: 'CFU/g' },
      { parameter_name: 'Heavy Metals (Pb)', parameter_type: 'NUMERIC', expected_max: 10, unit: 'ppm' }
    ]),
    acceptance_criteria: JSON.stringify({
      overall: 'All parameters within acceptable limits as per pharmacopoeia'
    }),
    estimated_duration_hours: 120,
    cost: 15000,
    required_equipment: 'Complete analytical lab',
    required_reagents: 'As per individual tests',
    reference_standard: 'API, WHO, FSSAI'
  }
];

console.log('Seeding QC test templates...\n');

const stmt = db.prepare(`
  INSERT OR REPLACE INTO qc_test_templates (
    id, name, description, category, applicable_species, test_method,
    parameters, acceptance_criteria, estimated_duration_hours, cost,
    required_equipment, required_reagents, reference_standard, created_by, is_active
  ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
`);

let count = 0;
for (const template of templates) {
  const id = `TPL-${uuidv4()}`;
  
  stmt.run(
    id,
    template.name,
    template.description,
    template.category,
    template.applicable_species,
    template.test_method,
    template.parameters,
    template.acceptance_criteria,
    template.estimated_duration_hours,
    template.cost,
    template.required_equipment,
    template.required_reagents,
    template.reference_standard,
    'system',
    1
  );
  
  count++;
  console.log(`✅ Created: ${template.name}`);
}

db.close();

console.log(`\n✅ Successfully seeded ${count} QC test templates!`);
console.log('\nTemplates available:');
console.log('- Identity & Purity Tests');
console.log('- Microbial Testing');
console.log('- Heavy Metals Analysis');
console.log('- Moisture Content');
console.log('- Pesticide Residue');
console.log('- Extractives Values');
console.log('- Complete QC Package');
