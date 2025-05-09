---
title: "0 - My Entry Sub Issue"
labels:
 - "entry"
fields:
    automation:
      type: string # is default type, not needed
      value: |
        [{
            "trigger": "on:close",
            "action": {
                "type": "set-field",
                "field": "status",
                "value": "in progress"
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
        }]
    custom field: 
      value: value from template
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
# My Entry Sub Issue

This is a template for my entry issue.
The title, labels, assignees, and milestones will be set automatically, based on the values defined in the YAML front matter.

Based on `previous` and `next`, issues will be mentioned in the text. This will help in tracking the flow of issues and their relationships.

When this issue is closed, the status will be set to "in progress" automatically.
The `previous` and `next` fields are used to link issues together, creating a chain of related issues.
