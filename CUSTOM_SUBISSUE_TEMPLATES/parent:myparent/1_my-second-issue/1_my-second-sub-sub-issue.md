---
title: "1.1 - My Second Sub Sub Issue"
labels:
 - "next step"
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
            "targets": ["parent"]
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
assignees:
 - "crlgb"
milestones:
 - "MS1"
---
# My Second Sub Sub Issue

This is a template for my second issue.
The title, labels, assignees, and milestones will be set automatically, based on the values defined in the YAML front matter.
When this issue is closed, the status will be set to "done" automatically.
