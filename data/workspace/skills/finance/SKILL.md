# Finance Skill

## Description
Financial operations for multi-tenant SaaS ERP: invoicing, P&L, cash flow analysis, budgeting, tenant billing, and financial reporting.

## When to Use
- Generating financial reports (P&L, balance sheet, cash flow)
- Analyzing revenue, expenses, or profitability per tenant
- Invoice reconciliation and payment tracking
- Budget planning and variance analysis
- Subscription billing and revenue forecasting

## Capabilities
- Query accounting tables (journal_entries, journal_entry_lines, accounts, fiscal_periods)
- Analyze payments_transactions and payment_accounts
- Track tenant subscription revenue (tenant_subscriptions, tenant_packages)
- Generate expense reports from expense_transactions
- Calculate receivables/payables from contacts table

## Key Tables
- `accounts`, `account_books`, `account_types`
- `journal_entries`, `journal_entry_lines`
- `fiscal_periods`
- `payments_transactions`, `payment_accounts`
- `expense_transactions`, `expense_reports`
- `currencies`

## Rules
- Always specify currency and time period
- Show calculations — don't just present totals
- Flag discrepancies between expected and actual
- Never mix tenant financial data in multi-tenant queries
- Round to appropriate decimal places per currency setting
