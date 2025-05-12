---
title: "My 2nd Nested Sub-Issue"
labels:
 - "Level 2"
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
                "value": "custom value after close of 'My 2nd Nested Sub-Issue'"
            },
            "targets": ["self", "parent"]
        }]
    status:
        value: todo
    custom field: 
      value: value from template for 'My 2nd Nested Sub-Issue'
assignees:
 - "crlgb"
milestones:
 - "MS1"
---
# My 2nd Nested Sub-Issue

This is a template for my second nested sub-issue.
The title, labels, assignees, and milestones will be set automatically, based on the values defined in the YAML front matter.
When this issue is closed, the status will be set to "done" automatically.
The custom field will be set to "custom value after close of 'My 2nd Nested Sub-Issue'" automatically, for both the parent and this issue.
