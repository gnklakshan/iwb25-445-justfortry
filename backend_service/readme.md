# Backend APIs and there Structure

## Accounts API

### `GET /accounts`

Retrieves all accounts for a given user.

<!-- **Request Body:**

```json
{
  "userId": "string"
}
``` -->

**Response:**

```json
[
  {
    "id": "string",
    "name": "string",
    "AccountType": "string",
    "balance": "number",
    "isDefault": "boolean",
    "userId": "string",
    "createdAt": "string",
    "updatedAt": "string"
  }
]
```

### `GET /accounts/:id`

Retrieves a single account with its transactions.

**Request Body:**

```json
{
  "userId": "string"
}
```

**Response:**

```json
{
  "id": "string",
  "name": "string",
  "type": "string",
  "balance": "number",
  "isDefault": "boolean",
  "userId": "string",
  "createdAt": "string",
  "updatedAt": "string",
  "transactions": [
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

### `PUT /accounts/:id/default`

Updates the default account for a user.

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
  "data": {
    "id": "string",
    "name": "string",
    "type": "string",
    "balance": "number",
    "isDefault": "boolean",
    "userId": "string",
    "createdAt": "string",
    "updatedAt": "string"
  }
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
  ]
}
```

### `GET /transactions/:id`

Retrieves a single transaction.

**Request Body:**

```json
{
  "userId": "string"
}
```

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
  "userId": "string",
  "type": "string",
  "amount": "number",
  "description": "string",
  "date": "string",
  "category": "string",
  "isRecurring": "boolean",
  "recurringInterval": "string"
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

### `PUT /transactions/:id`

Updates a transaction.

**Request Body:**

```json
{
  "userId": "string",
  "type": "string",
  "amount": "number",
  "description": "string",
  "date": "string",
  "category": "string",
  "isRecurring": "boolean",
  "recurringInterval": "string"
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
  "budget": {
    "id": "string",
    "amount": "number",
    "lastAlertSent": "string",
    "userId": "string",
    "createdAt": "string",
    "updatedAt": "string"
  },
  "currentExpenses": "number"
}
```

### `PUT /budgets`

Updates the budget for a user.

**Request Body:**

```json
{
  "userId": "string",
  "amount": "number"
}
```

**Response:**

```json
{
  "success": "boolean",
  "data": {
    "id": "string",
    "amount": "number",
    "lastAlertSent": "string",
    "userId": "string",
    "createdAt": "string",
    "updatedAt": "string"
  }
}
```
