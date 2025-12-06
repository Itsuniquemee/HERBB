package main

import (
	"encoding/json"
	"fmt"
	"strconv"
	"strings"
	"time"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

// SeasonWindow represents the allowed harvest period for a species in a region
type SeasonWindow struct {
	ID         string `json:"id"`
	Type       string `json:"type"` // "SeasonWindow"
	Species    string `json:"species"`
	StartMonth int    `json:"startMonth"` // 1-12
	EndMonth   int    `json:"endMonth"`   // 1-12
	Region     string `json:"region"`
	Active     bool   `json:"active"`
	CreatedBy  string `json:"createdBy"`
	CreatedAt  string `json:"createdAt"`
	UpdatedAt  string `json:"updatedAt"`
}

// HarvestLimit represents harvest quantity limits for a species in a zone/season
type HarvestLimit struct {
	ID              string  `json:"id"`
	Type            string  `json:"type"` // "HarvestLimit"
	Species         string  `json:"species"`
	Season          string  `json:"season"` // "2025-Spring", "2025-Monsoon", "2025-Post-Monsoon", "2025-Winter"
	Zone            string  `json:"zone"`
	MaxQuantity     float64 `json:"maxQuantity"`
	CurrentQuantity float64 `json:"currentQuantity"`
	Unit            string  `json:"unit"`
	AlertThreshold  float64 `json:"alertThreshold"` // Percentage (e.g., 80.0 for 80%)
	Status          string  `json:"status"`         // "normal", "warning", "exceeded"
	CreatedBy       string  `json:"createdBy"`
	CreatedAt       string  `json:"createdAt"`
	UpdatedAt       string  `json:"updatedAt"`
}

// CreateSeasonWindow creates a new season window for a species
func (c *HerbalTraceContract) CreateSeasonWindow(ctx contractapi.TransactionContextInterface, windowJSON string) error {
	var window SeasonWindow
	err := json.Unmarshal([]byte(windowJSON), &window)
	if err != nil {
		return fmt.Errorf("failed to unmarshal season window JSON: %v", err)
	}

	// Validate required fields
	if window.ID == "" {
		return fmt.Errorf("season window ID is required")
	}
	if window.Species == "" {
		return fmt.Errorf("species is required")
	}
	if window.StartMonth < 1 || window.StartMonth > 12 {
		return fmt.Errorf("start month must be between 1 and 12")
	}
	if window.EndMonth < 1 || window.EndMonth > 12 {
		return fmt.Errorf("end month must be between 1 and 12")
	}
	if window.Region == "" {
		return fmt.Errorf("region is required")
	}

	// Check if season window already exists
	existingWindow, err := ctx.GetStub().GetState(window.ID)
	if err != nil {
		return fmt.Errorf("failed to check if season window exists: %v", err)
	}
	if existingWindow != nil {
		return fmt.Errorf("season window with ID %s already exists", window.ID)
	}

	// Set default values
	window.Type = "SeasonWindow"
	window.Active = true
	window.CreatedAt = time.Now().Format(time.RFC3339)
	window.UpdatedAt = time.Now().Format(time.RFC3339)

	// Save to ledger
	windowBytes, err := json.Marshal(window)
	if err != nil {
		return fmt.Errorf("failed to marshal season window: %v", err)
	}

	err = ctx.GetStub().PutState(window.ID, windowBytes)
	if err != nil {
		return fmt.Errorf("failed to save season window to ledger: %v", err)
	}

	// Emit event
	eventPayload := map[string]interface{}{
		"eventType":  "SeasonWindowCreated",
		"windowId":   window.ID,
		"species":    window.Species,
		"startMonth": window.StartMonth,
		"endMonth":   window.EndMonth,
		"region":     window.Region,
		"timestamp":  window.CreatedAt,
	}
	eventBytes, _ := json.Marshal(eventPayload)
	ctx.GetStub().SetEvent("SeasonWindowCreated", eventBytes)

	return nil
}

// ValidateSeasonWindow checks if a harvest date falls within the allowed season window
func (c *HerbalTraceContract) ValidateSeasonWindow(ctx contractapi.TransactionContextInterface, species string, harvestDate string, region string) (bool, error) {
	if species == "" || harvestDate == "" || region == "" {
		return false, fmt.Errorf("species, harvest date, and region are required")
	}

	// Parse harvest date
	parsedDate, err := time.Parse(time.RFC3339, harvestDate)
	if err != nil {
		return false, fmt.Errorf("invalid harvest date format: %v", err)
	}
	harvestMonth := int(parsedDate.Month())

	// Query for active season windows for this species and region
	queryString := fmt.Sprintf(`{
		"selector": {
			"type": "SeasonWindow",
			"species": "%s",
			"region": "%s",
			"active": true
		}
	}`, species, region)

	resultsIterator, err := ctx.GetStub().GetQueryResult(queryString)
	if err != nil {
		return false, fmt.Errorf("failed to query season windows: %v", err)
	}
	defer resultsIterator.Close()

	// Check if harvest month falls within any active season window
	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()
		if err != nil {
			continue
		}

		var window SeasonWindow
		err = json.Unmarshal(queryResponse.Value, &window)
		if err != nil {
			continue
		}

		// Check if harvest month is within season window
		if window.StartMonth <= window.EndMonth {
			// Normal case: e.g., April (4) to September (9)
			if harvestMonth >= window.StartMonth && harvestMonth <= window.EndMonth {
				return true, nil
			}
		} else {
			// Wrap-around case: e.g., November (11) to February (2)
			if harvestMonth >= window.StartMonth || harvestMonth <= window.EndMonth {
				return true, nil
			}
		}
	}

	// No valid season window found
	return false, nil
}

// GetSeasonWindows retrieves all season windows for a species
func (c *HerbalTraceContract) GetSeasonWindows(ctx contractapi.TransactionContextInterface, species string) ([]*SeasonWindow, error) {
	if species == "" {
		return nil, fmt.Errorf("species is required")
	}

	queryString := fmt.Sprintf(`{
		"selector": {
			"type": "SeasonWindow",
			"species": "%s"
		}
	}`, species)

	resultsIterator, err := ctx.GetStub().GetQueryResult(queryString)
	if err != nil {
		return nil, fmt.Errorf("failed to query season windows: %v", err)
	}
	defer resultsIterator.Close()

	var windows []*SeasonWindow
	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()
		if err != nil {
			continue
		}

		var window SeasonWindow
		err = json.Unmarshal(queryResponse.Value, &window)
		if err != nil {
			continue
		}
		windows = append(windows, &window)
	}

	return windows, nil
}

// UpdateSeasonWindow updates an existing season window
func (c *HerbalTraceContract) UpdateSeasonWindow(ctx contractapi.TransactionContextInterface, windowID string, windowJSON string) error {
	if windowID == "" {
		return fmt.Errorf("window ID is required")
	}

	// Get existing window
	existingBytes, err := ctx.GetStub().GetState(windowID)
	if err != nil {
		return fmt.Errorf("failed to read season window: %v", err)
	}
	if existingBytes == nil {
		return fmt.Errorf("season window with ID %s does not exist", windowID)
	}

	var updatedWindow SeasonWindow
	err = json.Unmarshal([]byte(windowJSON), &updatedWindow)
	if err != nil {
		return fmt.Errorf("failed to unmarshal season window JSON: %v", err)
	}

	// Preserve ID and type
	updatedWindow.ID = windowID
	updatedWindow.Type = "SeasonWindow"
	updatedWindow.UpdatedAt = time.Now().Format(time.RFC3339)

	// Save updated window
	windowBytes, err := json.Marshal(updatedWindow)
	if err != nil {
		return fmt.Errorf("failed to marshal season window: %v", err)
	}

	err = ctx.GetStub().PutState(windowID, windowBytes)
	if err != nil {
		return fmt.Errorf("failed to update season window: %v", err)
	}

	return nil
}

// CreateHarvestLimit creates a new harvest limit for a species/zone/season
func (c *HerbalTraceContract) CreateHarvestLimit(ctx contractapi.TransactionContextInterface, limitJSON string) error {
	var limit HarvestLimit
	err := json.Unmarshal([]byte(limitJSON), &limit)
	if err != nil {
		return fmt.Errorf("failed to unmarshal harvest limit JSON: %v", err)
	}

	// Validate required fields
	if limit.ID == "" {
		return fmt.Errorf("harvest limit ID is required")
	}
	if limit.Species == "" {
		return fmt.Errorf("species is required")
	}
	if limit.Season == "" {
		return fmt.Errorf("season is required")
	}
	if limit.Zone == "" {
		return fmt.Errorf("zone is required")
	}
	if limit.MaxQuantity <= 0 {
		return fmt.Errorf("max quantity must be greater than zero")
	}
	if limit.Unit == "" {
		return fmt.Errorf("unit is required")
	}

	// Check if harvest limit already exists
	existingLimit, err := ctx.GetStub().GetState(limit.ID)
	if err != nil {
		return fmt.Errorf("failed to check if harvest limit exists: %v", err)
	}
	if existingLimit != nil {
		return fmt.Errorf("harvest limit with ID %s already exists", limit.ID)
	}

	// Set default values
	limit.Type = "HarvestLimit"
	limit.CurrentQuantity = 0
	limit.Status = "normal"
	if limit.AlertThreshold == 0 {
		limit.AlertThreshold = 80.0 // Default 80%
	}
	limit.CreatedAt = time.Now().Format(time.RFC3339)
	limit.UpdatedAt = time.Now().Format(time.RFC3339)

	// Save to ledger
	limitBytes, err := json.Marshal(limit)
	if err != nil {
		return fmt.Errorf("failed to marshal harvest limit: %v", err)
	}

	err = ctx.GetStub().PutState(limit.ID, limitBytes)
	if err != nil {
		return fmt.Errorf("failed to save harvest limit to ledger: %v", err)
	}

	return nil
}

// TrackHarvestQuantity adds a quantity to the current harvest limit tracker
func (c *HerbalTraceContract) TrackHarvestQuantity(ctx contractapi.TransactionContextInterface, species string, zone string, season string, quantity float64) error {
	if species == "" || zone == "" || season == "" {
		return fmt.Errorf("species, zone, and season are required")
	}
	if quantity <= 0 {
		return fmt.Errorf("quantity must be greater than zero")
	}

	// Find the harvest limit for this species/zone/season
	limitID := fmt.Sprintf("limit_%s_%s_%s", 
		strings.ReplaceAll(species, " ", "_"),
		strings.ReplaceAll(zone, " ", "_"),
		strings.ReplaceAll(season, " ", "_"))

	limitBytes, err := ctx.GetStub().GetState(limitID)
	if err != nil {
		return fmt.Errorf("failed to read harvest limit: %v", err)
	}
	if limitBytes == nil {
		// No limit set for this combination - allow harvest
		return nil
	}

	var limit HarvestLimit
	err = json.Unmarshal(limitBytes, &limit)
	if err != nil {
		return fmt.Errorf("failed to unmarshal harvest limit: %v", err)
	}

	// Update current quantity
	limit.CurrentQuantity += quantity
	limit.UpdatedAt = time.Now().Format(time.RFC3339)

	// Calculate percentage used
	percentageUsed := (limit.CurrentQuantity / limit.MaxQuantity) * 100

	// Update status based on percentage
	if percentageUsed >= 100 {
		limit.Status = "exceeded"
	} else if percentageUsed >= limit.AlertThreshold {
		limit.Status = "warning"
	} else {
		limit.Status = "normal"
	}

	// Save updated limit
	limitBytes, err = json.Marshal(limit)
	if err != nil {
		return fmt.Errorf("failed to marshal harvest limit: %v", err)
	}

	err = ctx.GetStub().PutState(limitID, limitBytes)
	if err != nil {
		return fmt.Errorf("failed to update harvest limit: %v", err)
	}

	return nil
}

// ValidateHarvestLimit checks if adding a quantity would exceed the harvest limit
func (c *HerbalTraceContract) ValidateHarvestLimit(ctx contractapi.TransactionContextInterface, species string, zone string, season string, quantity float64) (bool, error) {
	if species == "" || zone == "" || season == "" {
		return false, fmt.Errorf("species, zone, and season are required")
	}
	if quantity <= 0 {
		return false, fmt.Errorf("quantity must be greater than zero")
	}

	// Find the harvest limit
	limitID := fmt.Sprintf("limit_%s_%s_%s",
		strings.ReplaceAll(species, " ", "_"),
		strings.ReplaceAll(zone, " ", "_"),
		strings.ReplaceAll(season, " ", "_"))

	limitBytes, err := ctx.GetStub().GetState(limitID)
	if err != nil {
		return false, fmt.Errorf("failed to read harvest limit: %v", err)
	}
	if limitBytes == nil {
		// No limit set - allow harvest
		return true, nil
	}

	var limit HarvestLimit
	err = json.Unmarshal(limitBytes, &limit)
	if err != nil {
		return false, fmt.Errorf("failed to unmarshal harvest limit: %v", err)
	}

	// Check if adding this quantity would exceed the limit
	newTotal := limit.CurrentQuantity + quantity
	if newTotal > limit.MaxQuantity {
		return false, nil
	}

	return true, nil
}

// GetHarvestStatistics retrieves the current harvest statistics for a species/zone/season
func (c *HerbalTraceContract) GetHarvestStatistics(ctx contractapi.TransactionContextInterface, species string, zone string, season string) (*HarvestLimit, error) {
	if species == "" || zone == "" || season == "" {
		return nil, fmt.Errorf("species, zone, and season are required")
	}

	limitID := fmt.Sprintf("limit_%s_%s_%s",
		strings.ReplaceAll(species, " ", "_"),
		strings.ReplaceAll(zone, " ", "_"),
		strings.ReplaceAll(season, " ", "_"))

	limitBytes, err := ctx.GetStub().GetState(limitID)
	if err != nil {
		return nil, fmt.Errorf("failed to read harvest limit: %v", err)
	}
	if limitBytes == nil {
		return nil, fmt.Errorf("harvest limit for %s/%s/%s does not exist", species, zone, season)
	}

	var limit HarvestLimit
	err = json.Unmarshal(limitBytes, &limit)
	if err != nil {
		return nil, fmt.Errorf("failed to unmarshal harvest limit: %v", err)
	}

	return &limit, nil
}

// ResetSeasonalLimits resets the current quantities for all limits of a given season
func (c *HerbalTraceContract) ResetSeasonalLimits(ctx contractapi.TransactionContextInterface, season string) error {
	if season == "" {
		return fmt.Errorf("season is required")
	}

	queryString := fmt.Sprintf(`{
		"selector": {
			"type": "HarvestLimit",
			"season": "%s"
		}
	}`, season)

	resultsIterator, err := ctx.GetStub().GetQueryResult(queryString)
	if err != nil {
		return fmt.Errorf("failed to query harvest limits: %v", err)
	}
	defer resultsIterator.Close()

	resetCount := 0
	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()
		if err != nil {
			continue
		}

		var limit HarvestLimit
		err = json.Unmarshal(queryResponse.Value, &limit)
		if err != nil {
			continue
		}

		// Reset current quantity and status
		limit.CurrentQuantity = 0
		limit.Status = "normal"
		limit.UpdatedAt = time.Now().Format(time.RFC3339)

		// Save updated limit
		limitBytes, err := json.Marshal(limit)
		if err != nil {
			continue
		}

		err = ctx.GetStub().PutState(limit.ID, limitBytes)
		if err != nil {
			continue
		}

		resetCount++
	}

	// Emit event
	eventPayload := map[string]interface{}{
		"eventType":  "SeasonalLimitsReset",
		"season":     season,
		"resetCount": resetCount,
		"timestamp":  time.Now().Format(time.RFC3339),
	}
	eventBytes, _ := json.Marshal(eventPayload)
	ctx.GetStub().SetEvent("SeasonalLimitsReset", eventBytes)

	return nil
}

// GetHarvestLimitAlerts retrieves all harvest limits with warning or exceeded status
func (c *HerbalTraceContract) GetHarvestLimitAlerts(ctx contractapi.TransactionContextInterface) ([]*HarvestLimit, error) {
	queryString := `{
		"selector": {
			"type": "HarvestLimit",
			"status": {
				"$in": ["warning", "exceeded"]
			}
		}
	}`

	resultsIterator, err := ctx.GetStub().GetQueryResult(queryString)
	if err != nil {
		return nil, fmt.Errorf("failed to query harvest limit alerts: %v", err)
	}
	defer resultsIterator.Close()

	var alerts []*HarvestLimit
	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()
		if err != nil {
			continue
		}

		var limit HarvestLimit
		err = json.Unmarshal(queryResponse.Value, &limit)
		if err != nil {
			continue
		}
		alerts = append(alerts, &limit)
	}

	return alerts, nil
}

// getCurrentSeason is a helper function to determine the current season based on date
func getCurrentSeason() string {
	now := time.Now()
	year := strconv.Itoa(now.Year())
	month := int(now.Month())

	// Define seasons based on Indian climate
	// Spring: March-May (3-5)
	// Monsoon: June-September (6-9)
	// Post-Monsoon: October-November (10-11)
	// Winter: December-February (12, 1, 2)

	if month >= 3 && month <= 5 {
		return year + "-Spring"
	} else if month >= 6 && month <= 9 {
		return year + "-Monsoon"
	} else if month >= 10 && month <= 11 {
		return year + "-Post-Monsoon"
	} else {
		return year + "-Winter"
	}
}
