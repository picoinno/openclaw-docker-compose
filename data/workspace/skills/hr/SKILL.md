# HR Skill

## Description
Human resources operations: employee records, roles, permissions, personal info management, and organizational structure.

## When to Use
- Managing employee/user records and profiles
- Role and permission assignments
- Reviewing organizational structure (locations, departments)
- Onboarding checklists and access provisioning
- Leave tracking and payroll data support

## Capabilities
- Query business_users, personal_infos, roles, permissions
- Manage role_permissions assignments
- Track user access by location (access_location_ids)
- Review activity_logs for user actions
- Analyze login patterns via sessions table

## Key Tables
- `business_users`, `personal_infos`
- `roles`, `permissions`, `role_permissions`, `features`
- `business_locations` (org structure)
- `activity_logs`
- `sessions`

## Rules
- Employee data is confidential — never expose in group contexts
- Verify role changes against existing permission structure
- Log all access changes with reason
- For payroll-related queries: flag for human review, never auto-approve
- Respect soft-delete patterns — check is_active and deleted_at
