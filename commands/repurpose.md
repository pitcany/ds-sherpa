
---
allowed-tools: Task, Bash(cat:*), Bash(jq:*)
description: Repurpose content into platform-native formats
---

Inputs:
- Original content and target platforms.

Required output format (strict):
```json
{
  "linkedin": "",
  "x_thread": ["..."],
  "short_video_script": "",
  "newsletter_blurb": ""
}
```
If any fields are unknown, use `null` or empty lists.

