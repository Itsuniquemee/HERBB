/**
 * Herb Species Reference Routes
 * Provides endpoints to fetch herb species information for auto-fill
 */

import { Router, Request, Response } from 'express';
import { db } from '../config/database-adapter';
import { logger } from '../utils/logger';

const router = Router();

/**
 * GET /api/v1/herbs/species
 * Get all herb species reference data
 */
router.get('/species', async (req: Request, res: Response) => {
  try {
    const species = await db.prepare(`
      SELECT 
        id,
        common_name,
        scientific_name,
        species,
        local_names,
        description,
        medicinal_uses,
        part_used,
        harvest_season,
        created_at
      FROM herb_species_reference
      ORDER BY common_name ASC
    `).allAsync();

    res.json({
      success: true,
      data: species,
      count: species.length
    });
  } catch (error: any) {
    logger.error('Error fetching herb species:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch herb species',
      error: error.message
    });
  }
});

/**
 * GET /api/v1/herbs/species/:commonName
 * Get specific herb species by common name
 */
router.get('/species/:commonName', async (req: Request, res: Response) => {
  try {
    const { commonName } = req.params;
    
    const species = await db.prepare(`
      SELECT 
        id,
        common_name,
        scientific_name,
        species,
        local_names,
        description,
        medicinal_uses,
        part_used,
        harvest_season,
        created_at
      FROM herb_species_reference
      WHERE LOWER(common_name) = LOWER(?)
    `).getAsync(commonName);

    if (!species) {
      return res.status(404).json({
        success: false,
        message: 'Herb species not found'
      });
    }

    res.json({
      success: true,
      data: species
    });
  } catch (error: any) {
    logger.error('Error fetching herb species:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch herb species',
      error: error.message
    });
  }
});

/**
 * GET /api/v1/herbs/species-list
 * Get simple list of herb common names for dropdown
 */
router.get('/species-list', async (req: Request, res: Response) => {
  try {
    const speciesList = await db.prepare(`
      SELECT common_name, species, scientific_name
      FROM herb_species_reference
      ORDER BY common_name ASC
    `).allAsync();

    res.json({
      success: true,
      data: speciesList.map((s: any) => ({
        label: s.common_name,
        value: s.species,
        scientificName: s.scientific_name
      }))
    });
  } catch (error: any) {
    logger.error('Error fetching herb species list:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch herb species list',
      error: error.message
    });
  }
});

/**
 * POST /api/v1/herbs/species
 * Add a new herb species (Admin only)
 */
router.post('/species', async (req: Request, res: Response) => {
  try {
    const {
      commonName,
      scientificName,
      species,
      localNames,
      description,
      medicinalUses,
      partUsed,
      harvestSeason
    } = req.body;

    if (!commonName || !scientificName || !species) {
      return res.status(400).json({
        success: false,
        message: 'Common name, scientific name, and species are required'
      });
    }

    await db.prepare(`
      INSERT INTO herb_species_reference (
        common_name, scientific_name, species, local_names,
        description, medicinal_uses, part_used, harvest_season
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    `).runAsync(
      commonName,
      scientificName,
      species,
      localNames,
      description,
      medicinalUses,
      partUsed,
      harvestSeason
    );

    res.status(201).json({
      success: true,
      message: 'Herb species added successfully'
    });
  } catch (error: any) {
    logger.error('Error adding herb species:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to add herb species',
      error: error.message
    });
  }
});

export default router;
