# better-project-automation
 This repository contains code for an advanced form of GitHub project automation - based on PowerShell and GitHub Workflows.

## GitHub Repository Setup

### Variables

- `PROJECT_OWNER` organization or user name (string, can be found in the URL of the project)
- `PROJECT_ID` project ID (number, can be found in the URL of the project)
- `SILENT_ERRORS` flag to control error reporting (boolean), if this variable is set, errors will not be commented on the issue

### Secrets

- `APP_CLIENT_ID` GitHub App client ID (string)
- `APP_KEY` GitHub App key (private key, string)

### Labels

- `automation:on:close` label to trigger automation on issue close
- `automation:create:subissues` label to trigger sub-issue creation when issue is labeled
- `parent:%YOURPARENTIDENTIFIER%` for each parent issue type, a separate label is needed to trigger sub-issue creation for this specific parent issue type

## GitHub Project Setup

### Project Fields

- `automation` String field where json will be stored
