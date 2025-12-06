package main

import (
	"encoding/json"
	"fmt"
	"time"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

// Batch represents a collection of harvested materials aggregated for processing
type Batch struct {
	ID                 string   `json:"id"`
	Type               string   `json:"type"` // "Batch"
	Species            string   `json:"species"`
	TotalQuantity      float64  `json:"totalQuantity"`
	Unit               string   `json:"unit"`
	CollectionEventIDs []string `json:"collectionEventIds"`
	AssignedProcessor  string   `json:"assignedProcessor,omitempty"`
	ProcessorName      string   `json:"processorName,omitempty"`
	Status             string   `json:"status"` // "collected", "assigned", "testing", "processing", "manufactured"
	CreatedDate        string   `json:"createdDate"`
	CreatedBy          string   `json:"createdBy"` // Farmer ID
	AssignedDate       string   `json:"assignedDate,omitempty"`
	AssignedBy         string   `json:"assignedBy,omitempty"` // Admin ID
	Timestamp          string   `json:"timestamp"`
}

// BatchHistory represents the complete timeline of a batch
type BatchHistory struct {
	BatchID    string                 `json:"batchId"`
	Batch      *Batch                 `json:"batch"`
	History    []map[string]interface{} `json:"history"`
	EventCount int                    `json:"eventCount"`
}

// CreateBatch creates a new batch on the blockchain
func (c *HerbalTraceContract) CreateBatch(ctx contractapi.TransactionContextInterface, batchJSON string) error {
	var batch Batch
	err := json.Unmarshal([]byte(batchJSON), &batch)
	if err != nil {
		return fmt.Errorf("failed to unmarshal batch JSON: %v", err)
	}

	// Validate required fields
	if batch.ID == "" {
		return fmt.Errorf("batch ID is required")
	}
	if batch.Species == "" {
		return fmt.Errorf("species is required")
	}
	if batch.TotalQuantity <= 0 {
		return fmt.Errorf("total quantity must be greater than zero")
	}
	if batch.Unit == "" {
		return fmt.Errorf("unit is required")
	}
	if batch.CreatedBy == "" {
		return fmt.Errorf("created by (farmer ID) is required")
	}

	// Check if batch already exists
	existingBatch, err := ctx.GetStub().GetState(batch.ID)
	if err != nil {
		return fmt.Errorf("failed to check if batch exists: %v", err)
	}
	if existingBatch != nil {
		return fmt.Errorf("batch with ID %s already exists", batch.ID)
	}

	// Set default values
	batch.Type = "Batch"
	batch.Status = "collected"
	batch.CreatedDate = time.Now().Format(time.RFC3339)
	batch.Timestamp = time.Now().Format(time.RFC3339)

	// Initialize collection event IDs if not provided
	if batch.CollectionEventIDs == nil {
		batch.CollectionEventIDs = []string{}
	}

	// Save batch to ledger
	batchBytes, err := json.Marshal(batch)
	if err != nil {
		return fmt.Errorf("failed to marshal batch: %v", err)
	}

	err = ctx.GetStub().PutState(batch.ID, batchBytes)
	if err != nil {
		return fmt.Errorf("failed to save batch to ledger: %v", err)
	}

	// Emit event
	eventPayload := map[string]interface{}{
		"eventType": "BatchCreated",
		"batchId":   batch.ID,
		"species":   batch.Species,
		"quantity":  batch.TotalQuantity,
		"unit":      batch.Unit,
		"createdBy": batch.CreatedBy,
		"timestamp": batch.Timestamp,
	}
	eventBytes, _ := json.Marshal(eventPayload)
	ctx.GetStub().SetEvent("BatchCreated", eventBytes)

	return nil
}

// GetBatch retrieves a batch by ID
func (c *HerbalTraceContract) GetBatch(ctx contractapi.TransactionContextInterface, batchID string) (*Batch, error) {
	if batchID == "" {
		return nil, fmt.Errorf("batch ID is required")
	}

	batchBytes, err := ctx.GetStub().GetState(batchID)
	if err != nil {
		return nil, fmt.Errorf("failed to read batch from ledger: %v", err)
	}
	if batchBytes == nil {
		return nil, fmt.Errorf("batch with ID %s does not exist", batchID)
	}

	var batch Batch
	err = json.Unmarshal(batchBytes, &batch)
	if err != nil {
		return nil, fmt.Errorf("failed to unmarshal batch: %v", err)
	}

	return &batch, nil
}

// AssignBatchToProcessor assigns a batch to a processor (admin function)
func (c *HerbalTraceContract) AssignBatchToProcessor(ctx contractapi.TransactionContextInterface, batchID string, processorID string, processorName string, adminID string) error {
	if batchID == "" {
		return fmt.Errorf("batch ID is required")
	}
	if processorID == "" {
		return fmt.Errorf("processor ID is required")
	}
	if adminID == "" {
		return fmt.Errorf("admin ID is required")
	}

	// Get existing batch
	batch, err := c.GetBatch(ctx, batchID)
	if err != nil {
		return err
	}

	// Check if already assigned
	if batch.AssignedProcessor != "" {
		return fmt.Errorf("batch %s is already assigned to processor %s", batchID, batch.AssignedProcessor)
	}

	// Update batch assignment
	batch.AssignedProcessor = processorID
	batch.ProcessorName = processorName
	batch.AssignedBy = adminID
	batch.AssignedDate = time.Now().Format(time.RFC3339)
	batch.Status = "assigned"
	batch.Timestamp = time.Now().Format(time.RFC3339)

	// Save updated batch
	batchBytes, err := json.Marshal(batch)
	if err != nil {
		return fmt.Errorf("failed to marshal batch: %v", err)
	}

	err = ctx.GetStub().PutState(batchID, batchBytes)
	if err != nil {
		return fmt.Errorf("failed to update batch: %v", err)
	}

	// Emit event
	eventPayload := map[string]interface{}{
		"eventType":    "BatchAssigned",
		"batchId":      batchID,
		"processorId":  processorID,
		"processorName": processorName,
		"assignedBy":   adminID,
		"timestamp":    batch.Timestamp,
	}
	eventBytes, _ := json.Marshal(eventPayload)
	ctx.GetStub().SetEvent("BatchAssigned", eventBytes)

	return nil
}

// UpdateBatchStatus updates the status of a batch
func (c *HerbalTraceContract) UpdateBatchStatus(ctx contractapi.TransactionContextInterface, batchID string, newStatus string) error {
	if batchID == "" {
		return fmt.Errorf("batch ID is required")
	}
	if newStatus == "" {
		return fmt.Errorf("new status is required")
	}

	// Validate status
	validStatuses := map[string]bool{
		"collected":    true,
		"assigned":     true,
		"testing":      true,
		"processing":   true,
		"manufactured": true,
	}
	if !validStatuses[newStatus] {
		return fmt.Errorf("invalid status: %s. Valid statuses: collected, assigned, testing, processing, manufactured", newStatus)
	}

	// Get existing batch
	batch, err := c.GetBatch(ctx, batchID)
	if err != nil {
		return err
	}

	// Update status
	oldStatus := batch.Status
	batch.Status = newStatus
	batch.Timestamp = time.Now().Format(time.RFC3339)

	// Save updated batch
	batchBytes, err := json.Marshal(batch)
	if err != nil {
		return fmt.Errorf("failed to marshal batch: %v", err)
	}

	err = ctx.GetStub().PutState(batchID, batchBytes)
	if err != nil {
		return fmt.Errorf("failed to update batch: %v", err)
	}

	// Emit event
	eventPayload := map[string]interface{}{
		"eventType": "BatchStatusUpdated",
		"batchId":   batchID,
		"oldStatus": oldStatus,
		"newStatus": newStatus,
		"timestamp": batch.Timestamp,
	}
	eventBytes, _ := json.Marshal(eventPayload)
	ctx.GetStub().SetEvent("BatchStatusUpdated", eventBytes)

	return nil
}

// GetBatchHistory retrieves the complete history of a batch including all transactions
func (c *HerbalTraceContract) GetBatchHistory(ctx contractapi.TransactionContextInterface, batchID string) (*BatchHistory, error) {
	if batchID == "" {
		return nil, fmt.Errorf("batch ID is required")
	}

	// Get current batch state
	batch, err := c.GetBatch(ctx, batchID)
	if err != nil {
		return nil, err
	}

	// Get history iterator
	historyIterator, err := ctx.GetStub().GetHistoryForKey(batchID)
	if err != nil {
		return nil, fmt.Errorf("failed to get batch history: %v", err)
	}
	defer historyIterator.Close()

	// Collect history
	var history []map[string]interface{}
	for historyIterator.HasNext() {
		modification, err := historyIterator.Next()
		if err != nil {
			return nil, fmt.Errorf("failed to iterate batch history: %v", err)
		}

		var historyEntry map[string]interface{}
		if modification.IsDelete {
			historyEntry = map[string]interface{}{
				"txId":      modification.TxId,
				"timestamp": time.Unix(modification.Timestamp.Seconds, int64(modification.Timestamp.Nanos)).Format(time.RFC3339),
				"isDelete":  true,
			}
		} else {
			var batchData Batch
			err = json.Unmarshal(modification.Value, &batchData)
			if err != nil {
				continue
			}
			historyEntry = map[string]interface{}{
				"txId":      modification.TxId,
				"timestamp": time.Unix(modification.Timestamp.Seconds, int64(modification.Timestamp.Nanos)).Format(time.RFC3339),
				"isDelete":  false,
				"data":      batchData,
			}
		}
		history = append(history, historyEntry)
	}

	batchHistory := &BatchHistory{
		BatchID:    batchID,
		Batch:      batch,
		History:    history,
		EventCount: len(history),
	}

	return batchHistory, nil
}

// QueryBatchesByStatus retrieves all batches with a specific status
func (c *HerbalTraceContract) QueryBatchesByStatus(ctx contractapi.TransactionContextInterface, status string) ([]*Batch, error) {
	if status == "" {
		return nil, fmt.Errorf("status is required")
	}

	// Build query
	queryString := fmt.Sprintf(`{
		"selector": {
			"type": "Batch",
			"status": "%s"
		}
	}`, status)

	return c.queryBatches(ctx, queryString)
}

// QueryBatchesByProcessor retrieves all batches assigned to a specific processor
func (c *HerbalTraceContract) QueryBatchesByProcessor(ctx contractapi.TransactionContextInterface, processorID string) ([]*Batch, error) {
	if processorID == "" {
		return nil, fmt.Errorf("processor ID is required")
	}

	// Build query
	queryString := fmt.Sprintf(`{
		"selector": {
			"type": "Batch",
			"assignedProcessor": "%s"
		}
	}`, processorID)

	return c.queryBatches(ctx, queryString)
}

// GetPendingBatches retrieves all batches that are pending assignment (status = "collected")
func (c *HerbalTraceContract) GetPendingBatches(ctx contractapi.TransactionContextInterface) ([]*Batch, error) {
	queryString := `{
		"selector": {
			"type": "Batch",
			"status": "collected",
			"assignedProcessor": {"$exists": false}
		}
	}`

	return c.queryBatches(ctx, queryString)
}

// queryBatches is a helper function to execute rich queries for batches
func (c *HerbalTraceContract) queryBatches(ctx contractapi.TransactionContextInterface, queryString string) ([]*Batch, error) {
	resultsIterator, err := ctx.GetStub().GetQueryResult(queryString)
	if err != nil {
		return nil, fmt.Errorf("failed to execute query: %v", err)
	}
	defer resultsIterator.Close()

	var batches []*Batch
	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()
		if err != nil {
			return nil, fmt.Errorf("failed to iterate query results: %v", err)
		}

		var batch Batch
		err = json.Unmarshal(queryResponse.Value, &batch)
		if err != nil {
			continue
		}
		batches = append(batches, &batch)
	}

	return batches, nil
}
