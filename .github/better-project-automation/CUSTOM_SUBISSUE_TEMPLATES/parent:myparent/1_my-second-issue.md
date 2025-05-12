---
title: "My 2nd Sub-Issue"
labels:
 - "Level 1"
fields:
    automation:
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
                    "value": "custom value after close of 'My 2nd Sub-Issue'"
                },
                "targets": ["self", "parent", "sub-issues"]
            }]
    status:
      value: in progress
    custom field: 
      value: value from template for 'My 2nd Sub-Issue'
assignees:
 - "crlgb"
milestones:
 - "MS1"
---
# My 2nd Sub-Issue

This is a template for my 2nd Sub-Issue.
The title, labels, assignees, and milestones will be set automatically, based on the values defined in the YAML front matter.
When this issue is closed, the status will be set to "done" automatically.
The custom field will be set to "custom value after close of 'My 2nd Sub-Issue'" automatically, for both the parent and this issue, as well as all direct sub-issues.
