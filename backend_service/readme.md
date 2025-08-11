# Backend APIs and there Structure

## Auth API

### `POST /`

Create New User Account

## Accounts API

### `GET /accounts`

Retrieves all accounts for a given user.

**Request Body:**

```json
{
  "userId": "string"
}
```

**Response:**

```json
[
  {
    "id": "string",
    "name": "string",
    "type": "string",
    "balance": "number",
    "isDefault": "boolean",
    "userId": "string",
    "createdAt": "string",
    "updatedAt": "string"
  }
]
```

### `GET /accounts/{accountId}`

Retrieves a single account with its transactions.

**Request Body:**

<!-- ```json
{
  "userId": "string"
}
``` -->

**Response:**

```json
{
  "id": "string",
  "name": "string",
  "type": "string",
  "balance": "number",
  "isDefault": "boolean",
  "userId": "string",
  "transactions": [
    {
      "id": "string",
      "transactionType": "string",
      "amount": "number",
      "description": "string",
      "date": "string",
      "category": "string",
      "receiptUrl": "string",
      "isRecurring": "boolean",
      "recurringInterval": "string",
      "nextRecurringDate": "string",
      "lastProcessed": "string",
      "status": "string",
      "userId": "string",
      "accountId": "string",
      "createdAt": "string",
      "updatedAt": "string"
    }
  ]
}
```

### `POST /accounts/create`

Creates a new account.

**Request Body:**

```json
{
  "name": "string",
  "accountType": "string",
  "balance": "number",
  "isDefault": "boolean"
}
```

**Response:**

```json
{
  "success": "boolean",
  "data": {
    "id": "string",
    "name": "string",
    "accountType": "string",
    "balance": "number",
    "isDefault": "boolean",
    "userId": "string",
    "createdAt": "string",
    "updatedAt": "string"
  }
}
```

### `PATCH /accounts/{accountId}??isDefault={value}`

Updates the default account for a user.

**Response:**

```json
{
  "success": "boolean",
  "message": "string"
}
```

### `DELETE /accounts/transactions`

Deletes multiple transactions.

**Request Body:**

```json
{
  "userId": "string",
  "transactionIds": ["string"]
}
```

**Response:**

```json
{
  "success": "boolean"
}
```

### `get /accounts/summary?date-range={range}`

get accounts summerized details for requested time period.

**Response:**

```json
{
  "success": "boolean"
  "data":[
    {
      "id": "string",
      "name": "string",
      "accountType": "string",
      "balance": "number",
      "income": "number",
      "expenses": "number",
    }
  ]
}
```

---

## Transactions API

### `GET /transactions`

Retrieves all transactions for a given user.

**Request Body:**

```json
{
  "userId": "string"
}
```

**Response:**

```json
{
  "success": "boolean",
  "data": [
    {
      "id": "string",
      "transactionType": "string",
      "amount": "number",
      "description": "string",
      "date": "string",
      "category": "string",
      "receiptUrl": "string",
      "isRecurring": "boolean",
      "recurringInterval": "string",
      "nextRecurringDate": "string",
      "lastProcessed": "string",
      "status": "string",
      "userId": "string",
      "accountId": "string",
      "createdAt": "string",
      "updatedAt": "string"
    }
  ]
}
```

### `GET /transactions/:id`

Retrieves a single transaction.

**Response:**

```json
{
  "id": "string",
  "type": "string",
  "amount": "number",
  "description": "string",
  "date": "string",
  "category": "string",
  "receiptUrl": "string",
  "isRecurring": "boolean",
  "recurringInterval": "string",
  "nextRecurringDate": "string",
  "lastProcessed": "string",
  "status": "string",
  "userId": "string",
  "accountId": "string",
  "createdAt": "string",
  "updatedAt": "string"
}
```

### `POST /transactions`

Creates a new transaction.

**Request Body:**

```json
{
  "accountId": "string",
  "transactionType": "string",
  "amount": "number",
  "description": "string",
  "date": "string",
  "category": "string",
  "isRecurring": "boolean",
  "recurringInterval": "DAILY"|"WEEKLY"|"MONTHLY"|"YEARLY"
  "receiptUrl":"string",
  "lastProcessed":"date"
  "transactionStatus": 'PENDING'| 'COMPLETED'|'FAILED'
}
```

**Response:**

```json
{
  "success": "boolean",
  "data": {
    "id": "string",
    "type": "string",
    "amount": "number",
    "description": "string",
    "date": "string",
    "category": "string",
    "receiptUrl": "string",
    "isRecurring": "boolean",
    "recurringInterval": "string",
    "nextRecurringDate": "string",
    "lastProcessed": "string",
    "status": "string",
    "userId": "string",
    "accountId": "string",
    "createdAt": "string",
    "updatedAt": "string"
  }
}
```

### `PATCH /transactions/{transaction ID}`

Updates a transaction.

**Request Body:**

```json
{
  "transactionType": "string",
  "amount": "number",
  "description": "string",
  "date": "string",
  "category": "string",
  "isRecurring": "boolean",
  "recurringInterval": "DAILY"|"WEEKLY"|"MONTHLY"|"YEARLY",
  "transactionStatus": "PENDING"|"COMPLETED"|"FAILED",
  "lastProcessed":"string",
  "receiptUrl":"string"
}
```

**Response:**

```json
{
  "success": "boolean",
  "data": {
    "id": "string",
    "type": "string",
    "amount": "number",
    "description": "string",
    "date": "string",
    "category": "string",
    "receiptUrl": "string",
    "isRecurring": "boolean",
    "recurringInterval": "string",
    "nextRecurringDate": "string",
    "lastProcessed": "string",
    "status": "string",
    "userId": "string",
    "accountId": "string",
    "createdAt": "string",
    "updatedAt": "string"
  }
}
```

---

## Budgets API

### `GET /budgets`

Retrieves the current budget for a user.

**Request Body:**

```json
{
  "userId": "string",
  "accountId": "string"
}
```

**Response:**

```json
{
  "success": "boolean",
  "data": {
    "accountName": "string",
    "initialBudget": "number",
    "lastAlertSent": "string",
    "userId": "string",
    "currentExpenses": "number"
  }
}
```

### `PUT /budgets`

Updates the budget for a default account.

**Request Body:**

```json
{
  "amount": "number"
}
```

**Response:**

```json
{
  "success": "boolean",
  "data": {
    "accountName": "string",
    "initialBudget": "number",
    "lastAlertSent": "string",
    "userId": "string",
    "currentExpenses": "number"
  }
}
```
