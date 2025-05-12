# Better Project Automation

This repository contains code for an advanced form of GitHub project automation - based on PowerShell and GitHub Workflows.

## Features

### Sub-Issue Templates

Based on a given parent issue, identified by specific labels (`automation:create:subissues` and `parent:%YOURPARENTIDENTIFIER%`), sub-issues are created automatically.

#### Template Structure

Templates are defined in the [`CUSTOM_SUBISSUE_TEMPLATES` directory](./.github/better-project-automation/CUSTOM_SUBISSUE_TEMPLATES/).

For each parent issue type, create a directory with the name of the parent issue label (e.g. `CUSTOM_SUBISSUE_TEMPLATES/parent:myparent`, see [here](.github/better-project-automation/CUSTOM_SUBISSUE_TEMPLATES/parent:myparent)).

Each template is a markdown file with a YAML front matter section (e.g. [here](.github/better-project-automation/CUSTOM_SUBISSUE_TEMPLATES/parent:myparent/0_my-entry-issue.md)).
The front matter contains the following fields:

- `title`: The title of the sub-issue (will be prefixed with the parent issue title)
- `labels`: An array of labels to apply to the sub-issue
- `assignees`: An array of assignees to apply to the sub-issue
- `milestones`: An array of milestones to apply to the sub-issue
- `fields`: An object containing the fields to set on the sub-issue
  - contains properties `value` and optional property `type`, which must be set to `date` for date fields
  - `automation`: A JSON string containing the automation rules for the sub-issue ([see below](#advanced-automation))
  - Other fields can be defined here as well, and will be set on the sub-issue (e.g. `status`)

Sub-issues are created in alphabetical order, based on the title of the template file.
It is recommended to use a prefix (e.g. `0_`, `1_`, etc.) to control the order of sub-issue creation.

#### Trigger

The trigger for this automation is the addition of the `automation:create:subissues` label to the parent issue, which can be done manually or by using issue templates.

Keep in mind that the parent issue must be part of the GitHub project defined in the variables.

#### Nesting

Nested sub-issues are supported to the extent that GitHub allows.
In order to create a sub-issue for a sub-issue, create a directory with the name of the parent issue in the directory where the parent issue template is located (see [this example](.github/better-project-automation/CUSTOM_SUBISSUE_TEMPLATES/parent:myparent/1_my-second-issue)).

### Advanced Automation

Based on project field `automation`, advanced automations can be defined for project items using a JSON format.

#### Format

The JSON format is an array of objects, each containing the following properties:

- `trigger`: The trigger for the automation (currently, only `on:close` is supported)
- `action`: The action to be performed when the trigger occurs
  - `type`: The type of action to be performed (currently, only `set-field` is supported)
  - `field`: The project field to be set
  - `field-type`: The type of the field to be set (optional, only needed for date fields)
    - set to `date` for date fields
    - if not set, the type will be inferred from the field value
  - `value`: The value to set the field to
- `targets`: An array of targets for the action (`self`, `parent` and `sub-issues` are supported)

#### Example

```json
[
    {
        "trigger": "on:close",
        "action": {
            "type": "set-field",
            "field": "status",
            "value": "done"
        },
        "targets": ["self"]
    },
    {
        "trigger": "on:close",
        "action": {
            "type": "set-field",
            "field": "custom field",
            "value": "custom value after close"
        },
        "targets": ["self", "parent"]
    },
    {
        "trigger": "on:close",
        "action": {
            "type": "set-field",
            "field": "custom date field",
            "field-type": "date",
            "value": "2025-01-01"
        },
        "targets": ["self", "sub-issues"]
    }
]
```

## GitHub Repository Setup

### GitHub App

- install [better-project-automation-bot](https://github.com/apps/better-project-automation-bot) to the repository where issues will be created and Actions will run
- this is needed since GitHub workflows cannot access organization projects directly
- you are able to review the permissions of the app

### Secrets

- `APP_CLIENT_ID` GitHub App client ID (string)
- `APP_KEY` GitHub App key (private key, string)

### Variables

- `PROJECT_OWNER` organization or user name (string, can be found in the URL of the project)
- `PROJECT_ID` project ID (number, can be found in the URL of the project)
- `SILENT_ERRORS` flag to control error reporting (boolean), if this variable is set, errors will not be commented on the issue
- `REPO_OWNER` repository owner (string, can be found in the URL of the repository)
- `REPO_NAME` repository name (string, can be found in the URL of the repository)

### Labels

- `automation:on:close` label to trigger automation on issue close
- `automation:create:subissues` label to trigger sub-issue creation when issue is labeled
- `parent:%YOURPARENTIDENTIFIER%` for each parent issue type, a separate label is needed to trigger sub-issue creation for this specific parent issue type

## GitHub Project Setup

### Project Fields

- `automation` String field where json will be stored
