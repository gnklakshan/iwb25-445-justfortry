# FinApp - Personal Finance Manage Application

 Personal Finance Manage Application –  help you track, manage, and visualize your personal finances! 
---

## Table of Contents

- [What is this Application?](#what-is-this-application)
- [Features](#features)
- [Tech Stack](#tech-stack)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Backend Setup (Ballerina)](#backend-setup-ballerina)
  - [Frontend Setup (TypeScript)](#frontend-setup-typescript)
- [Usage](#usage)
- [License](#license)

---

## What is this Application?

**Personal Finance Manage Application** is a tool designed to help individuals easily:

- Record income and expense transactions
- Categorize their financial activities
- Visualize spending and saving trends
- Set budgets and track progress
- Export and import financial data

Whether you're looking to take control of your finances, analyze your spending, or simply have a better overview of your money, this application provides a friendly and feature-rich platform to do just that.

---

## Features

- Add, edit, and delete transactions (income/expenses)
- Categorize transactions for better insights
- Set monthly or custom budgets
- Interactive dashboard and charts for visualization
- Secure and robust backend API
- Responsive frontend design

---

## Tech Stack

- **Frontend:** TypeScript, JavaScript, CSS
- **Backend:** [Ballerina](https://ballerina.io/)
- **Database:** PostgreSQL (via Docker)

---

## Getting Started

Follow these steps to set up and run the application locally.

### Prerequisites

Make sure you have the following installed:

- [Node.js](https://nodejs.org/) (v16+ recommended)
- [npm](https://www.npmjs.com/) or [yarn](https://yarnpkg.com/)
- [Ballerina](https://ballerina.io/downloads/) (v2201.8.3 or later recommended)
- [Docker](https://www.docker.com/get-started/) (for PostgreSQL)
- [Git](https://git-scm.com/)

---

### Backend Setup (Ballerina)

#### 1. Clone the Repository

```bash
git clone https://github.com/gnklakshan/iwb25-445-justfortry.git
cd iwb25-445-justfortry
```

#### 2. Set Up the Database Using Docker

Start a PostgreSQL container with Docker:

```bash
docker pull postgres:latest

# Run the PostgreSQL container (update credentials as needed)
docker run --name personal-finance-db \
  -e POSTGRES_DB=personal_finance_db \
  -e POSTGRES_USER=finance_user \
  -e POSTGRES_PASSWORD=finance_pass \
  -p 5432:5432 \
  -d postgres:latest
```

- This will start PostgreSQL on port 5432 with database `personal_finance_db`, user `finance_user`, and password `finance_pass`.

#### 3. Configure the Ballerina Backend

- Navigate to the backend directory (update the path if different):

  ```bash
  cd backend
  ```

- Update the configuration file (`Config.toml` or `config.json`) with your PostgreSQL credentials:

  ```toml
  [database]
  host = "localhost"
  port = 5432
  user = "finance_user"
  password = "finance_pass"
  database = "personal_finance_db"
  ```

#### 4. Run the Backend Service

```bash
bal run
```

- The backend should now be running at `http://localhost:8080`.

**Database Management:**
- Stop database: `docker stop personal-finance-db`
- Start database: `docker start personal-finance-db`

---

### Frontend Setup (TypeScript)

#### 1. Navigate to the Frontend Directory

```bash
cd ../frontend
```

#### 2. Install Dependencies

```bash
npm install
# or
yarn install
```

#### 3. Run the Frontend Application

```bash
npm start
# or
yarn start
```

- The frontend app will typically be available at `http://localhost:3000`.

---

## Usage

1. Open your browser and go to `http://localhost:3000`.
2. Register or log in (if authentication is enabled).
3. Start adding your income and expense transactions.
4. Explore the dashboard for insights and manage your budgets!

---


## License

This project is licensed under the MIT License.

---

> **Note:** Due to limited time I had, I asked the help of AI to write this README.
