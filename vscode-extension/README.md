# Nomad Jarvis — VS Code Extension

> Your AI assistant inside VS Code. Connects to your OpenClaw instance.

## Features

- 💬 **Chat panel** — Talk to your AI without leaving your editor
- 📄 **Context awareness** — Automatically includes open files in prompts
- 🖱️ **Right-click actions** — Select code → "Ask Jarvis", "Explain code", "Review code"
- ⚡ **Streaming responses** — Real-time replies as they're generated
- 🔧 **Configurable** — Point at any OpenAI-compatible API endpoint

## Installation

### From VSIX (manual)

```bash
# In the vscode-extension directory
npm install
npm run compile
npx vsce package
# Then install the .vsix file in VS Code:
# Extensions view → ... → Install from VSIX
```

### From source (development)

```bash
cd vscode-extension
npm install
code .
# Press F5 to launch Extension Development Host
```

## Configuration

Open VS Code settings (`Ctrl+,`) and search for "nomadJarvis":

| Setting | Default | Description |
|---------|---------|-------------|
| `nomadJarvis.apiUrl` | `http://localhost:3000/api/chat` | Your OpenClaw API endpoint |
| `nomadJarvis.apiKey` | ` ` | API key if required |
| `nomadJarvis.model` | `kimi/k2p6` | Model to use |
| `nomadJarvis.includeOpenFiles` | `true` | Send open file content as context |
| `nomadJarvis.maxContextLines` | `100` | Max lines of context per file |

### Finding your OpenClaw API URL

Your OpenClaw instance needs to expose an API endpoint. Common setups:

**Local development:**
```
http://localhost:3000/api/chat
```

**Remote server:**
```
https://your-openclaw-server.com/api/chat
```

**OpenRouter (if using as proxy):**
```
https://openrouter.ai/api/v1/chat/completions
```

## Usage

### Chat panel

- `Ctrl+Shift+J` — Open Jarvis chat panel
- Type your question and press Enter
- Responses stream in real-time

### Right-click on selected code

1. Select code in editor
2. Right-click
3. Choose:
   - **Ask Jarvis about selection** — Ask a question about the code
   - **Jarvis: Explain this code** — Get an explanation
   - **Jarvis: Review this code** — Get a code review

### Keyboard shortcut

- `Ctrl+Shift+J` (macOS: `Cmd+Shift+J`) — Open chat panel

## Troubleshooting

### "Failed to connect to OpenClaw"

1. Check that your OpenClaw server is running
2. Verify the API URL in settings
3. Check if you need an API key
4. Ensure your network allows connections to the API URL

### "No response from API"

- The API endpoint might not support streaming. Try a non-streaming endpoint.
- Check the OpenClaw server logs for errors.

### Extension won't activate

- Make sure you're on VS Code 1.74 or newer
- Check the Output panel (`Ctrl+Shift+U`) → "Nomad Jarvis" for logs

## Architecture

```
VS Code Extension
├── src/extension.ts          # Entry point, commands
├── src/webviewProvider.ts    # Chat panel UI + API calls
└── package.json              # Extension manifest
```

The extension communicates with your OpenClaw instance via HTTP POST requests in OpenAI-compatible format:

```json
{
  "model": "kimi/k2p6",
  "messages": [
    {"role": "system", "content": "..."},
    {"role": "user", "content": "..."}
  ],
  "stream": true
}
```

## Requirements

- VS Code 1.74+
- An OpenClaw instance with API endpoint (or OpenRouter key)
- Node.js 16+ (for building from source)

## License

MIT — same as Nomad Dev Stack.
