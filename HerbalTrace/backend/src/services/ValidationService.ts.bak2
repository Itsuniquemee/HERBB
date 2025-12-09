import { logger } from '../utils/logger';

/**
 * Validation Service for HerbalTrace
 * Handles season windows, harvest limits, geofence validation, and business rules
 */

export interface SeasonWindow {
  species: string;
  startMonth: number; // 1-12
  endMonth: number; // 1-12
  startDay?: number; // 1-31
  endDay?: number; // 1-31
  regions?: string[]; // Optional regional restrictions
}

export interface HarvestLimit {
  species: string;
  maxQuantityPerDay: number; // kg
  maxQuantityPerMonth: number; // kg
  maxQuantityPerYear: number; // kg
  unit: string;
}

export interface GeofenceZone {
  name: string;
  species: string[];
  boundaries: {
    minLat: number;
    maxLat: number;
    minLng: number;
    maxLng: number;
  };
  altitude?: {
    min: number;
    max: number;
  };
}

export interface ValidationResult {
  valid: boolean;
  message?: string;
  violations?: string[];
  warnings?: string[];
}

class ValidationService {
  // Demo season windows (can be moved to database later)
  private seasonWindows: SeasonWindow[] = [
    { species: 'Ashwagandha', startMonth: 10, endMonth: 3 }, // Oct-Mar
    { species: 'Tulsi', startMonth: 1, endMonth: 12 }, // Year-round
    { species: 'Turmeric', startMonth: 1, endMonth: 3 }, // Jan-Mar
    { species: 'Senna', startMonth: 10, endMonth: 2 }, // Oct-Feb
    { species: 'Brahmi', startMonth: 1, endMonth: 12 }, // Year-round
    { species: 'Neem', startMonth: 1, endMonth: 12 }, // Year-round
  ];

  // Demo harvest limits (regulatory compliance)
  private harvestLimits: HarvestLimit[] = [
    { species: 'Ashwagandha', maxQuantityPerDay: 100, maxQuantityPerMonth: 1000, maxQuantityPerYear: 10000, unit: 'kg' },
    { species: 'Tulsi', maxQuantityPerDay: 50, maxQuantityPerMonth: 500, maxQuantityPerYear: 5000, unit: 'kg' },
    { species: 'Turmeric', maxQuantityPerDay: 200, maxQuantityPerMonth: 3000, maxQuantityPerYear: 30000, unit: 'kg' },
    { species: 'Senna', maxQuantityPerDay: 75, maxQuantityPerMonth: 750, maxQuantityPerYear: 7500, unit: 'kg' },
    { species: 'Brahmi', maxQuantityPerDay: 30, maxQuantityPerMonth: 300, maxQuantityPerYear: 3000, unit: 'kg' },
  ];

  // Demo geofence zones (protected areas)
  private geofenceZones: GeofenceZone[] = [
    {
      name: 'Kerala Protected Forest',
      species: ['Ashwagandha', 'Brahmi', 'Tulsi'],
      boundaries: { minLat: 8.0, maxLat: 12.8, minLng: 74.8, maxLng: 77.4 },
      altitude: { min: 500, max: 2500 }
    },
    {
      name: 'Karnataka Biodiversity Zone',
      species: ['Turmeric', 'Neem', 'Senna'],
      boundaries: { minLat: 11.5, maxLat: 18.5, minLng: 74.0, maxLng: 78.5 }
    }
  ];

  /**
   * Validate if harvest date falls within allowed season window
   */
  validateSeasonWindow(species: string, harvestDate: string): ValidationResult {
    const seasonWindow = this.seasonWindows.find(sw => sw.species.toLowerCase() === species.toLowerCase());
    
    if (!seasonWindow) {
      logger.warn(`No season window defined for species: ${species}`);
      return {
        valid: true,
        warnings: [`No seasonal restrictions defined for ${species}`]
      };
    }

    const date = new Date(harvestDate);
    const month = date.getMonth() + 1; // 0-11 to 1-12
    const day = date.getDate();

    let isInSeason = false;

    // Handle season windows that cross year boundary (e.g., Oct-Mar: 10-3)
    if (seasonWindow.startMonth <= seasonWindow.endMonth) {
      // Simple range (e.g., Mar-May: 3-5)
      isInSeason = month >= seasonWindow.startMonth && month <= seasonWindow.endMonth;
    } else {
      // Crosses year boundary (e.g., Oct-Mar: 10-3)
      isInSeason = month >= seasonWindow.startMonth || month <= seasonWindow.endMonth;
    }

    if (!isInSeason) {
      return {
        valid: false,
        message: `Harvest date outside permitted season for ${species}`,
        violations: [
          `${species} can only be harvested between month ${seasonWindow.startMonth} and ${seasonWindow.endMonth}. ` +
          `Harvest date: ${harvestDate} (month ${month}) is outside this window.`
        ]
      };
    }

    return {
      valid: true,
      message: `Harvest date within permitted season for ${species}`
    };
  }

  /**
   * Validate harvest quantity against daily, monthly, and yearly limits
   * Requires database access to check previous harvests
   */
  async validateHarvestLimit(
    farmerId: string,
    species: string,
    quantity: number,
    harvestDate: string,
    db: any // SQLite database instance
  ): Promise<ValidationResult> {
    const limit = this.harvestLimits.find(hl => hl.species.toLowerCase() === species.toLowerCase());

    if (!limit) {
      logger.warn(`No harvest limit defined for species: ${species}`);
      return {
        valid: true,
        warnings: [`No harvest limits defined for ${species}`]
      };
    }

    const violations: string[] = [];
    const date = new Date(harvestDate);

    try {
      // Calculate daily total
      const startOfDay = new Date(date);
      startOfDay.setHours(0, 0, 0, 0);
      const endOfDay = new Date(date);
      endOfDay.setHours(23, 59, 59, 999);

      const dailyTotal = db.prepare(`
        SELECT COALESCE(SUM(quantity), 0) as total
        FROM collection_events_cache
        WHERE farmer_id = ?
          AND species = ?
          AND harvest_date >= ?
          AND harvest_date <= ?
          AND sync_status != 'failed'
      `).get(farmerId, species, startOfDay.toISOString(), endOfDay.toISOString());

      const newDailyTotal = (dailyTotal?.total || 0) + quantity;
      if (newDailyTotal > limit.maxQuantityPerDay) {
        violations.push(
          `Daily harvest limit exceeded: ${newDailyTotal}${limit.unit} > ${limit.maxQuantityPerDay}${limit.unit} ` +
          `(limit for ${species}). Current collection: ${quantity}${limit.unit}, Previous today: ${dailyTotal?.total || 0}${limit.unit}`
        );
      }

      // Calculate monthly total
      const startOfMonth = new Date(date.getFullYear(), date.getMonth(), 1);
      const endOfMonth = new Date(date.getFullYear(), date.getMonth() + 1, 0, 23, 59, 59, 999);

      const monthlyTotal = db.prepare(`
        SELECT COALESCE(SUM(quantity), 0) as total
        FROM collection_events_cache
        WHERE farmer_id = ?
          AND species = ?
          AND harvest_date >= ?
          AND harvest_date <= ?
          AND sync_status != 'failed'
      `).get(farmerId, species, startOfMonth.toISOString(), endOfMonth.toISOString());

      const newMonthlyTotal = (monthlyTotal?.total || 0) + quantity;
      if (newMonthlyTotal > limit.maxQuantityPerMonth) {
        violations.push(
          `Monthly harvest limit exceeded: ${newMonthlyTotal}${limit.unit} > ${limit.maxQuantityPerMonth}${limit.unit} ` +
          `(limit for ${species}). Current collection: ${quantity}${limit.unit}, Previous this month: ${monthlyTotal?.total || 0}${limit.unit}`
        );
      }

      // Calculate yearly total
      const startOfYear = new Date(date.getFullYear(), 0, 1);
      const endOfYear = new Date(date.getFullYear(), 11, 31, 23, 59, 59, 999);

      const yearlyTotal = db.prepare(`
        SELECT COALESCE(SUM(quantity), 0) as total
        FROM collection_events_cache
        WHERE farmer_id = ?
          AND species = ?
          AND harvest_date >= ?
          AND harvest_date <= ?
          AND sync_status != 'failed'
      `).get(farmerId, species, startOfYear.toISOString(), endOfYear.toISOString());

      const newYearlyTotal = (yearlyTotal?.total || 0) + quantity;
      if (newYearlyTotal > limit.maxQuantityPerYear) {
        violations.push(
          `Yearly harvest limit exceeded: ${newYearlyTotal}${limit.unit} > ${limit.maxQuantityPerYear}${limit.unit} ` +
          `(limit for ${species}). Current collection: ${quantity}${limit.unit}, Previous this year: ${yearlyTotal?.total || 0}${limit.unit}`
        );
      }

      if (violations.length > 0) {
        return {
          valid: false,
          message: `Harvest limit violations detected for ${species}`,
          violations
        };
      }

      return {
        valid: true,
        message: `Harvest quantity within permitted limits for ${species}`
      };

    } catch (error: any) {
      logger.error('Error validating harvest limits:', error);
      return {
        valid: false,
        message: 'Failed to validate harvest limits',
        violations: [error.message]
      };
    }
  }

  /**
   * Validate GPS coordinates against geofence zones
   */
  validateGeofence(
    species: string,
    latitude: number,
    longitude: number,
    altitude?: number
  ): ValidationResult {
    const violations: string[] = [];

    for (const zone of this.geofenceZones) {
      // Check if species is restricted in this zone
      if (!zone.species.some(s => s.toLowerCase() === species.toLowerCase())) {
        continue;
      }

      // Check if coordinates fall within zone boundaries
      const inZone = 
        latitude >= zone.boundaries.minLat &&
        latitude <= zone.boundaries.maxLat &&
        longitude >= zone.boundaries.minLng &&
        longitude <= zone.boundaries.maxLng;

      if (inZone) {
        // Check altitude if specified
        if (zone.altitude && altitude !== undefined) {
          if (altitude < zone.altitude.min || altitude > zone.altitude.max) {
            violations.push(
              `Collection in restricted zone "${zone.name}" with invalid altitude: ${altitude}m. ` +
              `Allowed range: ${zone.altitude.min}m - ${zone.altitude.max}m`
            );
          } else {
            violations.push(
              `Collection in protected/restricted zone: "${zone.name}". ` +
              `Coordinates: (${latitude}, ${longitude}). Please ensure proper permits are obtained.`
            );
          }
        } else {
          violations.push(
            `Collection in protected/restricted zone: "${zone.name}". ` +
            `Coordinates: (${latitude}, ${longitude}). Please ensure proper permits are obtained.`
          );
        }
      }
    }

    if (violations.length > 0) {
      return {
        valid: false,
        message: 'Geofence violations detected',
        violations
      };
    }

    return {
      valid: true,
      message: 'Location coordinates validated'
    };
  }

  /**
   * Validate GPS coordinate accuracy
   */
  validateGPSAccuracy(latitude: number, longitude: number, accuracy?: number): ValidationResult {
    const violations: string[] = [];

    // Validate latitude range (-90 to 90)
    if (latitude < -90 || latitude > 90) {
      violations.push(`Invalid latitude: ${latitude}. Must be between -90 and 90`);
    }

    // Validate longitude range (-180 to 180)
    if (longitude < -180 || longitude > 180) {
      violations.push(`Invalid longitude: ${longitude}. Must be between -180 and 180`);
    }

    // Warn if accuracy is poor (>50 meters)
    const warnings: string[] = [];
    if (accuracy && accuracy > 50) {
      warnings.push(`GPS accuracy is low: ${accuracy}m. Recommended: <50m for reliable tracking`);
    }

    if (violations.length > 0) {
      return {
        valid: false,
        message: 'Invalid GPS coordinates',
        violations,
        warnings
      };
    }

    return {
      valid: true,
      message: 'GPS coordinates validated',
      warnings
    };
  }

  /**
   * Check for duplicate collection events (idempotency for offline sync)
   * Prevents duplicate submissions from mobile app offline queue
   */
  async checkDuplicateCollection(
    farmerId: string,
    species: string,
    quantity: number,
    harvestDate: string,
    latitude: number,
    longitude: number,
    db: any,
    timeWindowMinutes: number = 30
  ): Promise<ValidationResult> {
    try {
      const harvestTime = new Date(harvestDate);
      const windowStart = new Date(harvestTime.getTime() - timeWindowMinutes * 60 * 1000);
      const windowEnd = new Date(harvestTime.getTime() + timeWindowMinutes * 60 * 1000);

      // Check for similar collections within time window
      const duplicate = db.prepare(`
        SELECT id, harvest_date, quantity, latitude, longitude
        FROM collection_events_cache
        WHERE farmer_id = ?
          AND species = ?
          AND ABS(quantity - ?) < 0.1
          AND harvest_date >= ?
          AND harvest_date <= ?
          AND ABS(latitude - ?) < 0.001
          AND ABS(longitude - ?) < 0.001
        LIMIT 1
      `).get(
        farmerId,
        species,
        quantity,
        windowStart.toISOString(),
        windowEnd.toISOString(),
        latitude,
        longitude
      );

      if (duplicate) {
        return {
          valid: false,
          message: 'Duplicate collection event detected',
          violations: [
            `Similar collection already recorded: ID ${duplicate.id}. ` +
            `This appears to be a duplicate submission (same farmer, species, quantity, location, and time).`
          ]
        };
      }

      return {
        valid: true,
        message: 'No duplicate detected'
      };

    } catch (error: any) {
      logger.error('Error checking duplicate collection:', error);
      // Don't block submission on duplicate check errors
      return {
        valid: true,
        warnings: ['Could not verify duplicate status']
      };
    }
  }

  /**
   * Comprehensive validation for collection event
   */
  async validateCollectionEvent(
    data: {
      farmerId: string;
      species: string;
      quantity: number;
      unit: string;
      latitude: number;
      longitude: number;
      altitude?: number;
      accuracy?: number;
      harvestDate: string;
    },
    db: any
  ): Promise<ValidationResult> {
    const allViolations: string[] = [];
    const allWarnings: string[] = [];

    // 1. Validate GPS coordinates
    const gpsValidation = this.validateGPSAccuracy(
      data.latitude,
      data.longitude,
      data.accuracy
    );
    if (!gpsValidation.valid) {
      allViolations.push(...(gpsValidation.violations || []));
    }
    if (gpsValidation.warnings) {
      allWarnings.push(...gpsValidation.warnings);
    }

    // 2. Validate season window
    const seasonValidation = this.validateSeasonWindow(data.species, data.harvestDate);
    if (!seasonValidation.valid) {
      allViolations.push(...(seasonValidation.violations || []));
    }
    if (seasonValidation.warnings) {
      allWarnings.push(...seasonValidation.warnings);
    }

    // 3. Validate harvest limits
    const limitValidation = await this.validateHarvestLimit(
      data.farmerId,
      data.species,
      data.quantity,
      data.harvestDate,
      db
    );
    if (!limitValidation.valid) {
      allViolations.push(...(limitValidation.violations || []));
    }
    if (limitValidation.warnings) {
      allWarnings.push(...limitValidation.warnings);
    }

    // 4. Validate geofence
    const geofenceValidation = this.validateGeofence(
      data.species,
      data.latitude,
      data.longitude,
      data.altitude
    );
    if (!geofenceValidation.valid) {
      allViolations.push(...(geofenceValidation.violations || []));
    }

    // 5. Check for duplicates
    const duplicateValidation = await this.checkDuplicateCollection(
      data.farmerId,
      data.species,
      data.quantity,
      data.harvestDate,
      data.latitude,
      data.longitude,
      db
    );
    if (!duplicateValidation.valid) {
      allViolations.push(...(duplicateValidation.violations || []));
    }
    if (duplicateValidation.warnings) {
      allWarnings.push(...duplicateValidation.warnings);
    }

    if (allViolations.length > 0) {
      return {
        valid: false,
        message: `Validation failed with ${allViolations.length} violation(s)`,
        violations: allViolations,
        warnings: allWarnings.length > 0 ? allWarnings : undefined
      };
    }

    return {
      valid: true,
      message: 'All validations passed',
      warnings: allWarnings.length > 0 ? allWarnings : undefined
    };
  }

  /**
   * Get season windows for a species (for frontend display)
   */
  getSeasonWindow(species: string): SeasonWindow | undefined {
    return this.seasonWindows.find(sw => sw.species.toLowerCase() === species.toLowerCase());
  }

  /**
   * Get harvest limits for a species (for frontend display)
   */
  getHarvestLimit(species: string): HarvestLimit | undefined {
    return this.harvestLimits.find(hl => hl.species.toLowerCase() === species.toLowerCase());
  }

  /**
   * Get all available species with their regulations
   */
  getAllSpeciesInfo(): Array<{ species: string; seasonWindow?: SeasonWindow; harvestLimit?: HarvestLimit }> {
    const allSpecies = new Set([
      ...this.seasonWindows.map(sw => sw.species),
      ...this.harvestLimits.map(hl => hl.species)
    ]);

    return Array.from(allSpecies).map(species => ({
      species,
      seasonWindow: this.getSeasonWindow(species),
      harvestLimit: this.getHarvestLimit(species)
    }));
  }
}

export default new ValidationService();
