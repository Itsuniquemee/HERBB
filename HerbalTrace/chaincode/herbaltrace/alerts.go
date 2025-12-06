package main

import (
	"encoding/json"
	"fmt"
	"time"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

// Alert represents a system alert for violations, failures, or compliance issues
type Alert struct {
	ID               string `json:"id"`
	Type             string `json:"type"` // "Alert"
	AlertType        string `json:"alertType"` // "over_harvest", "quality_failure", "zone_violation", "season_violation", "compliance"
	Severity         string `json:"severity"` // "low", "medium", "high", "critical"
	EntityID         string `json:"entityId"` // Related batch/collection/test ID
	EntityType       string `json:"entityType"` // "Batch", "CollectionEvent", "QualityTest", "ProcessingStep", "Product"
	Species          string `json:"species,omitempty"`
	Zone             string `json:"zone,omitempty"`
	Message          string `json:"message"`
	Details          string `json:"details"`
	Timestamp        string `json:"timestamp"`
	Status           string `json:"status"` // "active", "acknowledged", "resolved"
	CreatedBy        string `json:"createdBy,omitempty"` // System or user ID
	AcknowledgedBy   string `json:"acknowledgedBy,omitempty"`
	AcknowledgedDate string `json:"acknowledgedDate,omitempty"`
	ResolvedBy       string `json:"resolvedBy,omitempty"`
	ResolvedDate     string `json:"resolvedDate,omitempty"`
	Resolution       string `json:"resolution,omitempty"`
}

// CreateAlert creates a new alert on the blockchain
func (c *HerbalTraceContract) CreateAlert(ctx contractapi.TransactionContextInterface, alertJSON string) error {
	var alert Alert
	err := json.Unmarshal([]byte(alertJSON), &alert)
	if err != nil {
		return fmt.Errorf("failed to unmarshal alert JSON: %v", err)
	}

	// Validate required fields
	if alert.ID == "" {
		return fmt.Errorf("alert ID is required")
	}
	if alert.AlertType == "" {
		return fmt.Errorf("alert type is required")
	}
	if alert.Severity == "" {
		return fmt.Errorf("severity is required")
	}
	if alert.Message == "" {
		return fmt.Errorf("message is required")
	}

	// Validate alert type
	validAlertTypes := map[string]bool{
		"over_harvest":     true,
		"quality_failure":  true,
		"zone_violation":   true,
		"season_violation": true,
		"compliance":       true,
		"system":           true,
	}
	if !validAlertTypes[alert.AlertType] {
		return fmt.Errorf("invalid alert type: %s", alert.AlertType)
	}

	// Validate severity
	validSeverities := map[string]bool{
		"low":      true,
		"medium":   true,
		"high":     true,
		"critical": true,
	}
	if !validSeverities[alert.Severity] {
		return fmt.Errorf("invalid severity: %s", alert.Severity)
	}

	// Check if alert already exists
	existingAlert, err := ctx.GetStub().GetState(alert.ID)
	if err != nil {
		return fmt.Errorf("failed to check if alert exists: %v", err)
	}
	if existingAlert != nil {
		return fmt.Errorf("alert with ID %s already exists", alert.ID)
	}

	// Set default values
	alert.Type = "Alert"
	alert.Status = "active"
	alert.Timestamp = time.Now().Format(time.RFC3339)
	if alert.CreatedBy == "" {
		alert.CreatedBy = "system"
	}

	// Save alert to ledger
	alertBytes, err := json.Marshal(alert)
	if err != nil {
		return fmt.Errorf("failed to marshal alert: %v", err)
	}

	err = ctx.GetStub().PutState(alert.ID, alertBytes)
	if err != nil {
		return fmt.Errorf("failed to save alert to ledger: %v", err)
	}

	// Emit event
	eventPayload := map[string]interface{}{
		"eventType": "AlertCreated",
		"alertId":   alert.ID,
		"alertType": alert.AlertType,
		"severity":  alert.Severity,
		"entityId":  alert.EntityID,
		"message":   alert.Message,
		"timestamp": alert.Timestamp,
	}
	eventBytes, _ := json.Marshal(eventPayload)
	ctx.GetStub().SetEvent("AlertCreated", eventBytes)

	return nil
}

// GetAlert retrieves an alert by ID
func (c *HerbalTraceContract) GetAlert(ctx contractapi.TransactionContextInterface, alertID string) (*Alert, error) {
	if alertID == "" {
		return nil, fmt.Errorf("alert ID is required")
	}

	alertBytes, err := ctx.GetStub().GetState(alertID)
	if err != nil {
		return nil, fmt.Errorf("failed to read alert from ledger: %v", err)
	}
	if alertBytes == nil {
		return nil, fmt.Errorf("alert with ID %s does not exist", alertID)
	}

	var alert Alert
	err = json.Unmarshal(alertBytes, &alert)
	if err != nil {
		return nil, fmt.Errorf("failed to unmarshal alert: %v", err)
	}

	return &alert, nil
}

// GetAlerts retrieves all alerts
func (c *HerbalTraceContract) GetAlerts(ctx contractapi.TransactionContextInterface) ([]*Alert, error) {
	queryString := `{
		"selector": {
			"type": "Alert"
		},
		"sort": [{"timestamp": "desc"}]
	}`

	return c.queryAlerts(ctx, queryString)
}

// GetAlertsByType retrieves all alerts of a specific type
func (c *HerbalTraceContract) GetAlertsByType(ctx contractapi.TransactionContextInterface, alertType string) ([]*Alert, error) {
	if alertType == "" {
		return nil, fmt.Errorf("alert type is required")
	}

	queryString := fmt.Sprintf(`{
		"selector": {
			"type": "Alert",
			"alertType": "%s"
		},
		"sort": [{"timestamp": "desc"}]
	}`, alertType)

	return c.queryAlerts(ctx, queryString)
}

// GetAlertsBySeverity retrieves all alerts of a specific severity
func (c *HerbalTraceContract) GetAlertsBySeverity(ctx contractapi.TransactionContextInterface, severity string) ([]*Alert, error) {
	if severity == "" {
		return nil, fmt.Errorf("severity is required")
	}

	queryString := fmt.Sprintf(`{
		"selector": {
			"type": "Alert",
			"severity": "%s"
		},
		"sort": [{"timestamp": "desc"}]
	}`, severity)

	return c.queryAlerts(ctx, queryString)
}

// GetActiveAlerts retrieves all active alerts (not acknowledged or resolved)
func (c *HerbalTraceContract) GetActiveAlerts(ctx contractapi.TransactionContextInterface) ([]*Alert, error) {
	queryString := `{
		"selector": {
			"type": "Alert",
			"status": "active"
		},
		"sort": [{"timestamp": "desc"}]
	}`

	return c.queryAlerts(ctx, queryString)
}

// GetAlertsByEntity retrieves all alerts for a specific entity
func (c *HerbalTraceContract) GetAlertsByEntity(ctx contractapi.TransactionContextInterface, entityID string, entityType string) ([]*Alert, error) {
	if entityID == "" {
		return nil, fmt.Errorf("entity ID is required")
	}

	queryString := fmt.Sprintf(`{
		"selector": {
			"type": "Alert",
			"entityId": "%s"`, entityID)

	if entityType != "" {
		queryString += fmt.Sprintf(`,
			"entityType": "%s"`, entityType)
	}

	queryString += `
		},
		"sort": [{"timestamp": "desc"}]
	}`

	return c.queryAlerts(ctx, queryString)
}

// AcknowledgeAlert marks an alert as acknowledged by a user
func (c *HerbalTraceContract) AcknowledgeAlert(ctx contractapi.TransactionContextInterface, alertID string, userID string) error {
	if alertID == "" {
		return fmt.Errorf("alert ID is required")
	}
	if userID == "" {
		return fmt.Errorf("user ID is required")
	}

	// Get existing alert
	alert, err := c.GetAlert(ctx, alertID)
	if err != nil {
		return err
	}

	// Check if already acknowledged or resolved
	if alert.Status != "active" {
		return fmt.Errorf("alert %s is already %s", alertID, alert.Status)
	}

	// Update alert
	alert.Status = "acknowledged"
	alert.AcknowledgedBy = userID
	alert.AcknowledgedDate = time.Now().Format(time.RFC3339)

	// Save updated alert
	alertBytes, err := json.Marshal(alert)
	if err != nil {
		return fmt.Errorf("failed to marshal alert: %v", err)
	}

	err = ctx.GetStub().PutState(alertID, alertBytes)
	if err != nil {
		return fmt.Errorf("failed to update alert: %v", err)
	}

	// Emit event
	eventPayload := map[string]interface{}{
		"eventType":       "AlertAcknowledged",
		"alertId":         alertID,
		"acknowledgedBy":  userID,
		"acknowledgedDate": alert.AcknowledgedDate,
	}
	eventBytes, _ := json.Marshal(eventPayload)
	ctx.GetStub().SetEvent("AlertAcknowledged", eventBytes)

	return nil
}

// ResolveAlert marks an alert as resolved with a resolution note
func (c *HerbalTraceContract) ResolveAlert(ctx contractapi.TransactionContextInterface, alertID string, userID string, resolution string) error {
	if alertID == "" {
		return fmt.Errorf("alert ID is required")
	}
	if userID == "" {
		return fmt.Errorf("user ID is required")
	}
	if resolution == "" {
		return fmt.Errorf("resolution is required")
	}

	// Get existing alert
	alert, err := c.GetAlert(ctx, alertID)
	if err != nil {
		return err
	}

	// Check if already resolved
	if alert.Status == "resolved" {
		return fmt.Errorf("alert %s is already resolved", alertID)
	}

	// Update alert
	alert.Status = "resolved"
	alert.ResolvedBy = userID
	alert.ResolvedDate = time.Now().Format(time.RFC3339)
	alert.Resolution = resolution

	// If not acknowledged yet, acknowledge it automatically
	if alert.AcknowledgedBy == "" {
		alert.AcknowledgedBy = userID
		alert.AcknowledgedDate = alert.ResolvedDate
	}

	// Save updated alert
	alertBytes, err := json.Marshal(alert)
	if err != nil {
		return fmt.Errorf("failed to marshal alert: %v", err)
	}

	err = ctx.GetStub().PutState(alertID, alertBytes)
	if err != nil {
		return fmt.Errorf("failed to update alert: %v", err)
	}

	// Emit event
	eventPayload := map[string]interface{}{
		"eventType":    "AlertResolved",
		"alertId":      alertID,
		"resolvedBy":   userID,
		"resolvedDate": alert.ResolvedDate,
		"resolution":   resolution,
	}
	eventBytes, _ := json.Marshal(eventPayload)
	ctx.GetStub().SetEvent("AlertResolved", eventBytes)

	return nil
}

// GetCriticalAlerts retrieves all active critical alerts
func (c *HerbalTraceContract) GetCriticalAlerts(ctx contractapi.TransactionContextInterface) ([]*Alert, error) {
	queryString := `{
		"selector": {
			"type": "Alert",
			"severity": "critical",
			"status": "active"
		},
		"sort": [{"timestamp": "desc"}]
	}`

	return c.queryAlerts(ctx, queryString)
}

// GetAlertStatistics retrieves statistics about alerts
func (c *HerbalTraceContract) GetAlertStatistics(ctx contractapi.TransactionContextInterface) (map[string]interface{}, error) {
	// Get all alerts
	allAlerts, err := c.GetAlerts(ctx)
	if err != nil {
		return nil, err
	}

	// Initialize counters
	stats := map[string]interface{}{
		"total": len(allAlerts),
		"byStatus": map[string]int{
			"active":       0,
			"acknowledged": 0,
			"resolved":     0,
		},
		"bySeverity": map[string]int{
			"low":      0,
			"medium":   0,
			"high":     0,
			"critical": 0,
		},
		"byType": map[string]int{
			"over_harvest":     0,
			"quality_failure":  0,
			"zone_violation":   0,
			"season_violation": 0,
			"compliance":       0,
			"system":           0,
		},
	}

	// Count alerts
	for _, alert := range allAlerts {
		// Count by status
		if statusMap, ok := stats["byStatus"].(map[string]int); ok {
			statusMap[alert.Status]++
		}

		// Count by severity
		if severityMap, ok := stats["bySeverity"].(map[string]int); ok {
			severityMap[alert.Severity]++
		}

		// Count by type
		if typeMap, ok := stats["byType"].(map[string]int); ok {
			typeMap[alert.AlertType]++
		}
	}

	return stats, nil
}

// queryAlerts is a helper function to execute rich queries for alerts
func (c *HerbalTraceContract) queryAlerts(ctx contractapi.TransactionContextInterface, queryString string) ([]*Alert, error) {
	resultsIterator, err := ctx.GetStub().GetQueryResult(queryString)
	if err != nil {
		return nil, fmt.Errorf("failed to execute query: %v", err)
	}
	defer resultsIterator.Close()

	var alerts []*Alert
	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()
		if err != nil {
			return nil, fmt.Errorf("failed to iterate query results: %v", err)
		}

		var alert Alert
		err = json.Unmarshal(queryResponse.Value, &alert)
		if err != nil {
			continue
		}
		alerts = append(alerts, &alert)
	}

	return alerts, nil
}
