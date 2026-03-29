# Infrastructure & Intellectual Property - Complete Reference

## 🔧 Infrastructure Management

### Features
- ✅ Full CRUD operations (Create, Read, Update, Delete)
- ✅ Risk level tracking (Critical, High, Medium, Low)
- ✅ Replacement cost calculation
- ✅ Owner/responsibility assignment
- ✅ Type classification (Website, Domain, Social Media, Design System, Brand, Other)

### User Workflow

```
┌─────────────────────────────────────┐
│  Infrastructure Management Page     │
│         /app/infrastructure         │
└─────────────────────────────────────┘
         ↓           ↓           ↓
    [View All]   [Add New]   [Search]
         ↓
   [Infrastructure Items Table]
    ├─ Name
    ├─ Type
    ├─ Risk Level
    ├─ Replacement Cost
    ├─ Owner
    ├─ Description
    └─ [Actions: Edit | Delete]
         ↓
    ┌────────────────────┐
    │  Click Edit/Delete │
    └────────────────────┘
         ↓
    ┌────────────────────────────────────┐
    │  Modal Form (Create/Edit Mode)    │
    ├────────────────────────────────────┤
    │ [Name *]                           │
    │ [Type *]                           │
    │ [Risk Level]                       │
    │ [Replacement Cost]                 │
    │ [Owner]                            │
    │ [Description]                      │
    │ [Cancel] [Add/Update]             │
    └────────────────────────────────────┘
```

### Valid Infrastructure Types
- website
- domain
- social_media
- design_system
- brand
- other

### Valid Risk Levels
- critical
- high
- medium
- low

---

## 💼 Intellectual Property Management

### Features
- ✅ Full CRUD operations (Create, Read, Update, Delete)
- ✅ Development cost tracking
- ✅ Valuation estimation
- ✅ Revenue monitoring
- ✅ Client relationship tracking
- ✅ Monetization model classification

### User Workflow

```
┌──────────────────────────────────────┐
│  Intellectual Property Page          │
│      /app/intellectual-property      │
└──────────────────────────────────────┘
      ↓           ↓           ↓
  [View All] [Add Asset] [Metrics]
      ↓
  [IP Assets Table]
   ├─ Name
   ├─ Type
   ├─ Dev Cost
   ├─ Valuation
   ├─ Monthly Revenue
   ├─ Clients
   ├─ Status
   └─ [Actions: Edit | Delete]
      ↓
   ┌─────────────────────┐
   │ Click Edit/Delete   │
   └─────────────────────┘
      ↓
   ┌──────────────────────────────────────┐
   │  Modal Form (Create/Edit Mode)      │
   ├──────────────────────────────────────┤
   │ [Name *]                             │
   │ [Type *]                             │
   │ [Development Cost *]                 │
   │ [Valuation Estimate]                 │
   │ [Monetization Model]                 │
   │ [Monthly Revenue]                    │
   │ [Clients Count]                      │
   │ [Status]                             │
   │ [Cancel] [Create/Update]            │
   └──────────────────────────────────────┘
```

### Valid IP Types
- software
- internal_system
- licensed_ip
- brand

### Monetization Models
- license
- subscription
- product
- partnership
- (custom)

---

## 📊 Metrics & Statistics

### Infrastructure Dashboard Shows:
- **Total Replacement Cost** - Sum of all replacement costs
- **Critical Items** - Count of critical risk items
- **Total Items** - Number of active infrastructure items

### IP Dashboard Shows:
- **Total Valuation** - Sum of all valuation estimates
- **Lifetime Revenue** - Sum of all revenue generated
- **Total Assets** - Number of active IP assets

---

## 🔄 CRUD Operations Detailed

### CREATE

**Infrastructure:**
```javascript
POST /api/infrastructure
{
  "name": "My Domain",
  "infrastructure_type": "domain",
  "description": "Main domain",
  "risk_level": "medium",
  "replacement_cost": 5000,
  "owner": "CTO"
}
```

**IP Asset:**
```javascript
POST /api/intellectual-property
{
  "name": "Platform Core",
  "ip_type": "software",
  "development_cost": 100000,
  "valuation_estimate": 500000,
  "monetization_model": "license",
  "revenue_generated_monthly": 5000,
  "clients_count": 10
}
```

### READ

**List All Infrastructure:**
```
GET /api/infrastructure
```

**List All IP:**
```
GET /api/intellectual-property
```

**Get Single Item:**
```
GET /api/infrastructure/[id]
GET /api/intellectual-property/[id]
```

### UPDATE

**Edit Infrastructure:**
```
PUT /api/infrastructure/[id]
{...updated fields...}
```

**Edit IP:**
```
PUT /api/intellectual-property/[id]
{...updated fields...}
```

### DELETE

**Archive Infrastructure:**
```
DELETE /api/infrastructure/[id]
(Sets status to 'archived')
```

**Archive IP:**
```
DELETE /api/intellectual-property/[id]
(Sets status to 'deprecated')
```

---

## 🎯 State Management

### Infrastructure Component State
```javascript
const [infrastructure, setInfrastructure] = useState([])
const [loading, setLoading] = useState(true)
const [showModal, setShowModal] = useState(false)
const [editingId, setEditingId] = useState(null)

const [form, setForm] = useState({
  name: '',
  infrastructure_type: 'website',
  description: '',
  risk_level: 'medium',
  replacement_cost: '',
  recovery_procedures: '',
  owner: '',
})
```

### IP Component State
```javascript
const [ip, setIP] = useState([])
const [loading, setLoading] = useState(true)
const [showModal, setShowModal] = useState(false)
const [editingId, setEditingId] = useState(null)

const [form, setForm] = useState({
  name: '',
  ip_type: 'software',
  description: '',
  development_cost: '',
  valuation_estimate: '',
  monetization_model: 'license',
  revenue_generated_monthly: '',
  clients_count: '',
  status: 'active',
})
```

---

## 🚀 Key Functions

### Shared Pattern Across Both Pages

**Create/Update Handler:**
```javascript
const handleCreateItem = async (e) => {
  e.preventDefault()
  
  const url = editingId 
    ? `/api/endpoint/${editingId}` 
    : '/api/endpoint'
  const method = editingId ? 'PUT' : 'POST'
  
  // Send request
  if (success) {
    if (editingId) {
      // Update existing
      setItems(items.map(item => 
        item.id === editingId ? result.data : item
      ))
    } else {
      // Add new
      setItems([result.data, ...items])
    }
    handleCloseModal()
  }
}
```

**Edit Handler:**
```javascript
const handleEditItem = (item) => {
  setEditingId(item.id)
  setForm({...item})
  setShowModal(true)
}
```

**Delete Handler:**
```javascript
const handleDeleteItem = async (id) => {
  if (!confirm('Delete this item?')) return
  
  const response = await fetch(`/api/endpoint/${id}`, {
    method: 'DELETE'
  })
  
  if (success) {
    setItems(items.filter(item => item.id !== id))
  }
}
```

**Close Modal:**
```javascript
const handleCloseModal = () => {
  setShowModal(false)
  setEditingId(null)
  setForm({...defaultForm})
}
```

---

## 🎨 UI Components

### Table Structure
```html
<table>
  <thead>
    <tr>
      <th>Column 1</th>
      <th>Column 2</th>
      ...
      <th>Actions</th>
    </tr>
  </thead>
  <tbody>
    {items.map(item => (
      <tr>
        <td>{item.field}</td>
        ...
        <td>
          <button onClick={() => handleEditItem(item)}>
            <Edit />
          </button>
          <button onClick={() => handleDeleteItem(item.id)}>
            <Trash2 />
          </button>
        </td>
      </tr>
    ))}
  </tbody>
</table>
```

### Modal Structure
```html
<div className="modal">
  <h2>{editingId ? 'Edit' : 'Create'} Item</h2>
  
  <form onSubmit={handleCreateItem}>
    {/* Form fields */}
    
    <button type="button" onClick={handleCloseModal}>
      Cancel
    </button>
    <button type="submit">
      {editingId ? 'Update' : 'Create'}
    </button>
  </form>
</div>
```

---

## ✅ Validation

### Client-Side
- Required field checking
- Type validation
- Number range validation
- Confirmation dialogs for destructive actions

### Server-Side
- Field existence validation
- Type validation
- Business logic validation
- Authorization checks
- Audit logging

---

## 🔒 Security Features

- ✅ Soft delete (data not permanently removed)
- ✅ Edit ID validation (can't access others' items)
- ✅ Confirmation dialogs (prevent accidental deletion)
- ✅ Input validation (both client and server)
- ✅ Error messages (user-friendly)
- ✅ Audit logging (track all changes)

---

## 📱 Responsive Design

Both pages support:
- ✅ Desktop (full table view)
- ✅ Tablet (scrollable table)
- ✅ Mobile (modal-focused)
- ✅ Dark mode
- ✅ Light mode

---

## 🚨 Error Handling

Both pages handle:
- ✅ Missing required fields
- ✅ API connection errors
- ✅ Invalid data submissions
- ✅ Item not found errors
- ✅ Unauthorized access
- ✅ Server-side errors

---

## 📚 Database Schema Reference

### Infrastructure Table
```sql
infrastructure (
  id INTEGER PRIMARY KEY,
  name VARCHAR(255),
  infrastructure_type VARCHAR(50),
  description TEXT,
  owner_name VARCHAR(255),
  risk_level VARCHAR(50),
  replacement_cost NUMERIC,
  status VARCHAR(50),
  created_at TIMESTAMP,
  updated_at TIMESTAMP
)
```

### IP Table
```sql
intellectual_property (
  id INTEGER PRIMARY KEY,
  name VARCHAR(255),
  ip_type VARCHAR(50),
  description TEXT,
  development_cost NUMERIC,
  valuation_estimate NUMERIC,
  monetization_model VARCHAR(50),
  revenue_generated_monthly NUMERIC,
  clients_count INTEGER,
  status VARCHAR(50),
  created_at TIMESTAMP,
  updated_at TIMESTAMP
)
```

---

## 🎓 Testing Checklist

### Infrastructure
- [ ] Create new infrastructure item
- [ ] Edit existing infrastructure
- [ ] Delete infrastructure (confirm dialog)
- [ ] View all items in table
- [ ] Check metrics update
- [ ] Form validation (missing fields)
- [ ] Modal opens/closes properly
- [ ] Edit mode loads correct data
- [ ] Submit button text changes (Add/Update)

### IP Assets
- [ ] Create new IP asset
- [ ] Edit existing IP asset
- [ ] Delete IP asset (confirm dialog)
- [ ] View all items in table
- [ ] Check metrics update
- [ ] Form validation (missing fields)
- [ ] Modal opens/closes properly
- [ ] Edit mode loads correct data
- [ ] Submit button text changes (Create/Update)

---

## 💡 Tips & Best Practices

1. **Always confirm before deleting** - Both pages show confirmation dialogs
2. **Check form validation** - Required fields are marked with *
3. **Monitor metrics** - Dashboard updates in real-time
4. **Use appropriate types** - Select from predefined types for consistency
5. **Add descriptions** - Help others understand items
6. **Assign owners** - Track responsibility

---

## 🔗 Related Pages

- Infrastructure: `/app/infrastructure`
- Intellectual Property: `/app/intellectual-property`
- Valuation: `/app/valuation`
- Dashboard: `/app/dashboard`

---

**Last Updated:** December 30, 2025
**Status:** ✅ Full CRUD Operations Functional
**Errors:** ✅ None
