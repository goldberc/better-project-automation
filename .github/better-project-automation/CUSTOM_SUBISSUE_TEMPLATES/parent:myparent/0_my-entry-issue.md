---
title: "My 1st Sub-Issue"
labels:
 - "Level 1"
fields:
    automation:
      type: string # is default type, not needed
      value: |
        [{
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
                "value": "custom value after close of 'My 1st Sub-Issue'"
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
            "targets": ["self", "parent"]
        }]
    custom field: 
      value: value from template for 'My 1st Sub-Issue'
    custom date field:
      value: 2023-10-01
      type: date
    status:
      value: Custom status
      type: selection # this is also inferred automatically for selection fields
assignees:
 - "crlgb"
milestones:
 - "MS1"
---
# My 1st Sub-Issue

This is a template for my entry issue.
The title, labels, assignees, and milestones will be set automatically, based on the values defined in the YAML front matter.
The field custom date field will be set to 2023-10-01 automatically.

When this issue is closed, the status will be set to "done" automatically. The custom field will be set to "custom value after close of 'My 1st Sub-Issue'" automatically, for both the parent and this issue.
