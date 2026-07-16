# flutter_copilot example

Interactive demo app for `flutter_copilot` using the real
`OpenAILlmAdapter`.

Create `example/.env`:

```dotenv
OPENAI_API_KEY=your_key_here
OPENAI_MODEL=gpt-4.1
OPENAI_ENDPOINT=
```

Then generate the Envied file and run:

```bash
fvm dart run build_runner build
fvm flutter run -d linux
```

For an OpenAI-compatible provider, set `OPENAI_MODEL` and `OPENAI_ENDPOINT`
in `.env`.

Try prompts such as:

- Open settings and enable dark mode
- Go to profile, set the display name and email, then save
- Open tasks and mark Write release notes as done
- Go to tasks and show only active tasks
- Open settings and enable notifications and weekly email
- Open settings and set the font scale slider high
- Add the starter kit to the cart
- Open tasks and swipe Archive old invoices away
- Open tasks, search for release, then clear the search
- Reset demo data after asking me for confirmation

The app includes tabs, forms, switches, segmented controls, a slider,
cart buttons, search, pull-to-refresh, dismiss/confirmation flows, and a live
copilot event log so you can watch the agent plan and act through Flutter
semantics.
