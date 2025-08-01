-- Function to auto-update updatedAt column on row update
CREATE OR REPLACE FUNCTION update_updatedAt_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updatedAt = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- users table
CREATE TABLE users (
    id TEXT PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    name TEXT,
    hashedPassword TEXT NOT NULL,
    createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TRIGGER update_users_updatedAt
BEFORE UPDATE ON users
FOR EACH ROW
EXECUTE FUNCTION update_updatedAt_column();

-- accounts table
CREATE TABLE accounts (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    accountType TEXT NOT NULL,
    balance DECIMAL(65,30) NOT NULL DEFAULT 0,
    isDefault BOOLEAN NOT NULL DEFAULT FALSE,
    userId TEXT NOT NULL,
    createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT accounts_userId_fkey FOREIGN KEY (userId) REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TRIGGER update_accounts_updatedAt
BEFORE UPDATE ON accounts
FOR EACH ROW
EXECUTE FUNCTION update_updatedAt_column();

-- TransactionType enum
CREATE TYPE TransactionType AS ENUM ('INCOME', 'EXPENSE');

-- TransactionStatus enum
CREATE TYPE TransactionStatus AS ENUM ('PENDING', 'COMPLETED', 'FAILED');

-- RecurringInterval enum
CREATE TYPE RecurringInterval AS ENUM ('DAILY', 'WEEKLY', 'MONTHLY', 'YEARLY');

-- transactions table
CREATE TABLE transactions (
    id TEXT PRIMARY KEY,
    transactionType TransactionType NOT NULL,
    amount DECIMAL(65,30) NOT NULL,
    description TEXT,
    date TIMESTAMP NOT NULL,
    receiptUrl TEXT,
    isRecurring BOOLEAN NOT NULL DEFAULT FALSE,
    recurringInterval RecurringInterval,
    nextRecurringDate TIMESTAMP,
    status TransactionStatus NOT NULL DEFAULT 'COMPLETED',
    userId TEXT NOT NULL,
    accountId TEXT NOT NULL,
    category TEXT NOT NULL,
    createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    lastProcessed TIMESTAMP,
    CONSTRAINT transactions_userId_fkey FOREIGN KEY (userId) REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT transactions_accountId_fkey FOREIGN KEY (accountId) REFERENCES accounts(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TRIGGER update_transactions_updatedAt
BEFORE UPDATE ON transactions
FOR EACH ROW
EXECUTE FUNCTION update_updatedAt_column();

-- budgets table
CREATE TABLE budgets (
    id TEXT PRIMARY KEY,
    amount DECIMAL(65,30) NOT NULL,
    userId TEXT NOT NULL,
    createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    lastAlertSent TIMESTAMP,
    CONSTRAINT budgets_userId_fkey FOREIGN KEY (userId) REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TRIGGER update_budgets_updatedAt
BEFORE UPDATE ON budgets
FOR EACH ROW
EXECUTE FUNCTION update_updatedAt_column();

-- Indexes
CREATE UNIQUE INDEX users_email_key ON users(email);
CREATE INDEX accounts_userId_idx ON accounts(userId);
CREATE INDEX transactions_userId_idx ON transactions(userId);
CREATE INDEX transactions_accountId_idx ON transactions(accountId);
CREATE INDEX budgets_userId_idx ON budgets(userId);
CREATE UNIQUE INDEX budgets_userId_key ON budgets(userId);
