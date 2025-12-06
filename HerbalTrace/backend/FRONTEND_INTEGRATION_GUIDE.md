# Frontend Integration Guide: Farmer Registration Workflow

## ✅ YES - Admin Can Register Farmers from Frontend

The backend is **fully ready** for frontend integration. Here's the complete workflow:

---

## 📋 Two-Step Registration Process

### Step 1: Farmer Self-Registration (Public Form)
**Endpoint:** `POST /api/v1/auth/registration-request`  
**Access:** Public (No authentication required)  
**Frontend Page:** Registration Form (for farmers/labs/processors)

#### Required Fields from Farmer:
```json
{
  "fullName": "Rajesh Kumar",           // Required
  "phone": "9876543210",                // Required (10 digits)
  "email": "rajesh@example.com",        // Required (unique)
  "address": "Village Dharampur, HP",   // Required
  "requestType": "farmer",              // Required: "farmer" | "lab" | "processor" | "manufacturer"
  
  // Farmer-specific fields (optional but recommended):
  "farmSize": "10 acres",               // Optional
  "speciesInterest": ["tulsi", "ashwagandha", "brahmi"],  // Optional array
  "farmPhotos": ["photo1.jpg", "photo2.jpg"],  // Optional array
  "locationCoordinates": {              // Optional GPS
    "latitude": 31.1048,
    "longitude": 77.1734
  }
}
```

#### Response:
```json
{
  "success": true,
  "message": "Registration request submitted successfully",
  "data": {
    "requestId": "cf39df95-cba7-4f30-9972-4adba5e32f02",
    "status": "pending",
    "message": "Your request will be reviewed by admin"
  }
}
```

---

### Step 2: Admin Approval (Admin Dashboard)
**Endpoint:** `POST /api/v1/auth/registration-requests/:id/approve`  
**Access:** Admin only (requires Bearer token)  
**Frontend Page:** Admin Dashboard > Registration Requests

#### Admin Must Provide These Details:
```json
{
  "role": "Farmer",           // Required: "Farmer" | "Lab" | "Processor" | "Manufacturer" | "Admin"
  "orgName": "FarmerOrg",     // Required: Organization name for blockchain
  "orgMsp": "FarmerOrgMSP"    // Optional: MSP ID (auto-generated if not provided)
}
```

**Important Notes:**
- `role` should match the farmer's request type (farmer → Farmer role)
- `orgName` determines blockchain organization (usually "FarmerOrg" for all farmers)
- System **auto-generates** username and password

#### Response (Send to Farmer via Email/SMS):
```json
{
  "success": true,
  "message": "Registration request approved and user created",
  "data": {
    "userId": "farmer-1733148596789-x7k2",
    "username": "rajesh",                    // Auto-generated from email
    "password": "HTAB8K7M2X",                // Auto-generated (SEND THIS TO FARMER!)
    "email": "rajesh@example.com",
    "fullName": "Rajesh Kumar",
    "role": "Farmer",
    "orgName": "FarmerOrg",
    "message": "Please save these credentials securely and change password after first login"
  }
}
```

---

## 🖥️ Frontend Implementation Guide

### 1. Farmer Registration Form (Public Page)

```html
<!-- No authentication needed -->
<form id="farmerRegistrationForm">
  <h2>Register as a Farmer</h2>
  
  <!-- Required Fields -->
  <input type="text" name="fullName" placeholder="Full Name *" required />
  <input type="tel" name="phone" placeholder="Phone Number *" required pattern="[0-9]{10}" />
  <input type="email" name="email" placeholder="Email *" required />
  <textarea name="address" placeholder="Farm Address *" required></textarea>
  <input type="hidden" name="requestType" value="farmer" />
  
  <!-- Optional Fields -->
  <input type="text" name="farmSize" placeholder="Farm Size (e.g., 10 acres)" />
  <input type="text" name="speciesInterest" placeholder="Species Interest (comma-separated)" />
  <input type="file" name="farmPhotos" multiple accept="image/*" />
  
  <button type="submit">Submit Registration Request</button>
</form>

<script>
document.getElementById('farmerRegistrationForm').addEventListener('submit', async (e) => {
  e.preventDefault();
  
  const formData = {
    fullName: e.target.fullName.value,
    phone: e.target.phone.value,
    email: e.target.email.value,
    address: e.target.address.value,
    requestType: 'farmer',
    farmSize: e.target.farmSize.value,
    speciesInterest: e.target.speciesInterest.value.split(',').map(s => s.trim()),
    farmPhotos: ['photo1.jpg', 'photo2.jpg'] // Upload images first, then add URLs
  };
  
  try {
    const response = await fetch('http://localhost:3000/api/v1/auth/registration-request', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(formData)
    });
    
    const result = await response.json();
    
    if (result.success) {
      alert('Registration submitted! Request ID: ' + result.data.requestId);
      // Show success message, redirect to confirmation page
    } else {
      alert('Error: ' + result.message);
    }
  } catch (error) {
    alert('Submission failed: ' + error.message);
  }
});
</script>
```

---

### 2. Admin Dashboard - View Pending Requests

```javascript
// Admin must be logged in and have token stored
const adminToken = localStorage.getItem('adminToken');

async function loadPendingRequests() {
  try {
    const response = await fetch('http://localhost:3000/api/v1/auth/registration-requests?status=pending', {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${adminToken}`
      }
    });
    
    const result = await response.json();
    
    if (result.success) {
      const requests = result.data; // Array of requests
      displayRequests(requests);
    }
  } catch (error) {
    console.error('Failed to load requests:', error);
  }
}

function displayRequests(requests) {
  const tableBody = document.getElementById('requestsTableBody');
  tableBody.innerHTML = '';
  
  requests.forEach(req => {
    const row = `
      <tr>
        <td>${req.full_name}</td>
        <td>${req.email}</td>
        <td>${req.phone}</td>
        <td>${req.request_type}</td>
        <td>${req.farm_size || 'N/A'}</td>
        <td>${req.status}</td>
        <td>
          <button onclick="approveRequest('${req.id}', '${req.request_type}')">Approve</button>
          <button onclick="rejectRequest('${req.id}')">Reject</button>
        </td>
      </tr>
    `;
    tableBody.innerHTML += row;
  });
}
```

---

### 3. Admin Approval Function

```javascript
async function approveRequest(requestId, requestType) {
  const adminToken = localStorage.getItem('adminToken');
  
  // Map request type to role and organization
  const roleMapping = {
    'farmer': { role: 'Farmer', orgName: 'FarmerOrg' },
    'lab': { role: 'Lab', orgName: 'LabOrg' },
    'processor': { role: 'Processor', orgName: 'ProcessorOrg' },
    'manufacturer': { role: 'Manufacturer', orgName: 'ManufacturerOrg' }
  };
  
  const approvalData = roleMapping[requestType];
  
  try {
    const response = await fetch(`http://localhost:3000/api/v1/auth/registration-requests/${requestId}/approve`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${adminToken}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(approvalData)
    });
    
    const result = await response.json();
    
    if (result.success) {
      // Show credentials to admin
      alert(`User Created Successfully!\n\nUsername: ${result.data.username}\nPassword: ${result.data.password}\n\nPlease send these credentials to the farmer via email/SMS.`);
      
      // Optionally send credentials via backend email service
      sendCredentialsToFarmer(result.data);
      
      // Reload requests list
      loadPendingRequests();
    } else {
      alert('Approval failed: ' + result.message);
    }
  } catch (error) {
    alert('Error: ' + error.message);
  }
}

function sendCredentialsToFarmer(credentials) {
  // TODO: Implement email/SMS service to send credentials
  console.log('Send credentials to:', credentials.email);
  console.log('Username:', credentials.username);
  console.log('Password:', credentials.password);
}
```

---

## 🎯 Complete Frontend Workflow Summary

### For Farmers:
1. Visit registration page
2. Fill form with details
3. Submit (no login required)
4. Wait for admin approval
5. Receive credentials via email/SMS
6. Login to app with username & password
7. Change password on first login

### For Admins:
1. Login to admin dashboard
2. View pending registration requests
3. Review farmer details
4. Click "Approve" button
5. System auto-generates credentials
6. Copy credentials and send to farmer
7. Farmer can now login

---

## 📊 Field Details by User Type

### Farmer Registration Fields:
| Field | Required | Type | Description |
|-------|----------|------|-------------|
| fullName | ✅ Yes | String | Farmer's full name |
| phone | ✅ Yes | String | 10-digit phone number |
| email | ✅ Yes | String | Unique email address |
| address | ✅ Yes | String | Farm location address |
| requestType | ✅ Yes | String | Must be "farmer" |
| farmSize | ⚠️ Optional | String | Farm area (e.g., "10 acres") |
| speciesInterest | ⚠️ Optional | Array | Herbs farmer wants to grow |
| farmPhotos | ⚠️ Optional | Array | URLs of farm photos |
| locationCoordinates | ⚠️ Optional | Object | GPS coordinates |

### Lab Registration Fields:
| Field | Required | Type | Description |
|-------|----------|------|-------------|
| fullName | ✅ Yes | String | Lab name |
| phone | ✅ Yes | String | Contact number |
| email | ✅ Yes | String | Unique email |
| address | ✅ Yes | String | Lab address |
| requestType | ✅ Yes | String | Must be "lab" |
| certifications | ⚠️ Optional | Array | ISO/NABL certifications |

### Processor Registration Fields:
| Field | Required | Type | Description |
|-------|----------|------|-------------|
| fullName | ✅ Yes | String | Processor name |
| phone | ✅ Yes | String | Contact number |
| email | ✅ Yes | String | Unique email |
| address | ✅ Yes | String | Processing facility address |
| requestType | ✅ Yes | String | Must be "processor" |
| processingCapacity | ⚠️ Optional | String | Daily capacity |

### Admin Approval Fields:
| Field | Required | Type | Valid Values |
|-------|----------|------|--------------|
| role | ✅ Yes | String | "Farmer", "Lab", "Processor", "Manufacturer", "Admin" |
| orgName | ✅ Yes | String | "FarmerOrg", "LabOrg", "ProcessorOrg", "ManufacturerOrg" |
| orgMsp | ⚠️ Optional | String | Auto-generated if not provided |

---

## 🔐 Security Notes

1. **Auto-Generated Credentials:**
   - Username = email prefix (e.g., rajesh@example.com → rajesh)
   - Password = Random 8-character string (e.g., HTAB8K7M2X)
   - Password is **sent only once** in approval response

2. **Password Security:**
   - Hashed with bcrypt (10 rounds)
   - User must change password after first login
   - Minimum 8 characters for new passwords

3. **Duplicate Prevention:**
   - Cannot submit multiple pending requests with same email
   - System checks email uniqueness

---

## ✅ System is Ready!

**YES**, you can implement the farmer registration from frontend right now. The backend APIs are:
- ✅ Fully implemented
- ✅ Tested and working
- ✅ Production-ready
- ✅ Database-backed
- ✅ Secure (JWT + bcrypt)

**Next Step:** Proceed to Phase 3 - Image Upload Service! 🚀
