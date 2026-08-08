---
name: c2-server
description: Publish large or HTML report deliverables through Serenity's C2 HTTP server.
---

# C2 Server

`/c2-server` is served read-only over the network at `http://serenity:8088/`.

Use it when:

1. The deliverable is an HTML report.
2. A deliverable is too large to send through Discord.

Write files under `/c2-server`. Use a clear, URL-safe filename or subdirectory.
After writing the file, give the user its network URL in this exact form:

`http://serenity:8088/<path>`

Never give `localhost`, `127.0.0.1`, or a container-local URL. Confirm the file exists before sharing its URL. Do not publish secrets, credentials, private keys, or other sensitive material through this server.
