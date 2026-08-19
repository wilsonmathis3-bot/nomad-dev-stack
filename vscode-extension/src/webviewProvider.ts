// ═══════════════════════════════════════════════════════════════
//  Jarvis Webview Provider
//  Manages the chat UI and communicates with OpenClaw API.
// ═══════════════════════════════════════════════════════════════

import * as vscode from 'vscode';

export class JarvisWebviewProvider implements vscode.WebviewViewProvider {
    private _view?: vscode.WebviewView;
    private _config: vscode.WorkspaceConfiguration;

    constructor(private readonly _extensionUri: vscode.Uri) {
        this._config = vscode.workspace.getConfiguration('nomadJarvis');
    }

    public resolveWebviewView(
        webviewView: vscode.WebviewView,
        _context: vscode.WebviewViewResolveContext,
        _token: vscode.CancellationToken
    ) {
        this._view = webviewView;

        webviewView.webview.options = {
            enableScripts: true,
            localResourceRoots: [this._extensionUri]
        };

        webviewView.webview.html = this._getHtmlForWebview(webviewView.webview);

        // Handle messages from the webview
        webviewView.webview.onDidReceiveMessage(
            async (message) => {
                switch (message.type) {
                    case 'sendMessage':
                        await this._handleUserMessage(message.text);
                        break;
                    case 'openSettings':
                        vscode.commands.executeCommand(
                            'workbench.action.openSettings',
                            'nomadJarvis'
                        );
                        break;
                }
            }
        );
    }

    public async sendMessage(text: string) {
        if (this._view) {
            this._view.show?.(true);
            this._view.webview.postMessage({ type: 'addUserMessage', text });
            await this._handleUserMessage(text);
        }
    }

    private async _handleUserMessage(text: string) {
        const apiUrl = this._config.get<string>('apiUrl') || 'http://localhost:3000/api/chat';
        const apiKey = this._config.get<string>('apiKey') || '';
        const model = this._config.get<string>('model') || 'kimi/k2p6';
        const includeOpenFiles = this._config.get<boolean>('includeOpenFiles') ?? true;
        const maxContextLines = this._config.get<number>('maxContextLines') || 100;

        // Build context from open files
        let context = '';
        if (includeOpenFiles) {
            const editors = vscode.window.visibleTextEditors;
            for (const editor of editors) {
                const doc = editor.document;
                const content = doc.getText();
                const lines = content.split('\n');
                const truncated = lines.slice(0, maxContextLines).join('\n');
                context += `\n\nFile: ${doc.fileName}\n\`\`\`${doc.languageId}\n${truncated}${lines.length > maxContextLines ? '\n... (truncated)' : ''}\n\`\`\``;
            }
        }

        const fullMessage = context
            ? `Context from open files:${context}\n\nUser question: ${text}`
            : text;

        // Show loading indicator
        this._view?.webview.postMessage({ type: 'setLoading', loading: true });

        try {
            const response = await fetch(apiUrl, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    ...(apiKey ? { 'Authorization': `Bearer ${apiKey}` } : {})
                },
                body: JSON.stringify({
                    model,
                    messages: [
                        {
                            role: 'system',
                            content: 'You are Jarvis, a helpful AI coding assistant. Be concise and practical.'
                        },
                        {
                            role: 'user',
                            content: fullMessage
                        }
                    ],
                    stream: true
                })
            });

            if (!response.ok) {
                throw new Error(`API error: ${response.status} ${response.statusText}`);
            }

            // Handle streaming response
            const reader = response.body?.getReader();
            if (!reader) {
                throw new Error('No response body');
            }

            let fullResponse = '';
            const decoder = new TextDecoder();

            while (true) {
                const { done, value } = await reader.read();
                if (done) break;

                const chunk = decoder.decode(value);
                const lines = chunk.split('\n');

                for (const line of lines) {
                    if (line.startsWith('data: ')) {
                        const data = line.slice(6);
                        if (data === '[DONE]') continue;

                        try {
                            const parsed = JSON.parse(data);
                            const content = parsed.choices?.[0]?.delta?.content || '';
                            fullResponse += content;

                            this._view?.webview.postMessage({
                                type: 'streamResponse',
                                text: fullResponse
                            });
                        } catch {
                            // Ignore parse errors in stream
                        }
                    }
                }
            }

            this._view?.webview.postMessage({
                type: 'finishResponse',
                text: fullResponse
            });

        } catch (error) {
            const errorMessage = error instanceof Error ? error.message : String(error);
            this._view?.webview.postMessage({
                type: 'error',
                text: `Failed to connect to OpenClaw: ${errorMessage}\n\nMake sure:\n1. Your OpenClaw server is running\n2. API URL is correct in settings (Ctrl+, → search "nomadJarvis")\n3. API key is set if required`
            });
        } finally {
            this._view?.webview.postMessage({ type: 'setLoading', loading: false });
        }
    }

    private _getHtmlForWebview(webview: vscode.Webview): string {
        return `<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Jarvis</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: var(--vscode-font-family);
            font-size: var(--vscode-font-size);
            color: var(--vscode-foreground);
            background: var(--vscode-editor-background);
            height: 100vh;
            display: flex;
            flex-direction: column;
        }
        .chat-container {
            flex: 1;
            overflow-y: auto;
            padding: 12px;
            display: flex;
            flex-direction: column;
            gap: 12px;
        }
        .message {
            padding: 10px 14px;
            border-radius: 8px;
            max-width: 90%;
            word-wrap: break-word;
        }
        .message.user {
            align-self: flex-end;
            background: var(--vscode-button-background);
            color: var(--vscode-button-foreground);
        }
        .message.assistant {
            align-self: flex-start;
            background: var(--vscode-input-background);
            border: 1px solid var(--vscode-input-border);
        }
        .message.error {
            align-self: flex-start;
            background: var(--vscode-inputValidation-errorBackground);
            border: 1px solid var(--vscode-inputValidation-errorBorder);
        }
        .message pre {
            background: var(--vscode-textCodeBlock-background);
            padding: 8px;
            border-radius: 4px;
            overflow-x: auto;
            margin-top: 8px;
        }
        .message code {
            font-family: var(--vscode-editor-font-family);
            font-size: 0.9em;
        }
        .input-container {
            padding: 12px;
            border-top: 1px solid var(--vscode-panel-border);
            display: flex;
            gap: 8px;
            align-items: flex-end;
        }
        textarea {
            flex: 1;
            background: var(--vscode-input-background);
            color: var(--vscode-input-foreground);
            border: 1px solid var(--vscode-input-border);
            border-radius: 6px;
            padding: 8px 12px;
            font-family: inherit;
            font-size: inherit;
            resize: none;
            min-height: 40px;
            max-height: 120px;
        }
        textarea:focus {
            outline: none;
            border-color: var(--vscode-focusBorder);
        }
        button {
            background: var(--vscode-button-background);
            color: var(--vscode-button-foreground);
            border: none;
            border-radius: 6px;
            padding: 8px 16px;
            cursor: pointer;
            font-size: inherit;
        }
        button:hover {
            background: var(--vscode-button-hoverBackground);
        }
        button:disabled {
            opacity: 0.5;
            cursor: not-allowed;
        }
        .loading {
            align-self: flex-start;
            color: var(--vscode-descriptionForeground);
            font-style: italic;
            padding: 8px 14px;
        }
        .toolbar {
            padding: 8px 12px;
            border-bottom: 1px solid var(--vscode-panel-border);
            display: flex;
            gap: 8px;
        }
        .toolbar button {
            padding: 4px 10px;
            font-size: 0.85em;
        }
        .empty-state {
            text-align: center;
            color: var(--vscode-descriptionForeground);
            padding: 40px 20px;
        }
    </style>
</head>
<body>
    <div class="toolbar">
        <button onclick="clearChat()">Clear</button>
        <button onclick="openSettings()">Settings</button>
    </div>
    <div class="chat-container" id="chat">
        <div class="empty-state">
            <h3>🌐 Nomad Jarvis</h3>
            <p>Your AI assistant, inside VS Code.</p>
            <p style="margin-top: 12px; font-size: 0.9em;">
                Select code → right-click → "Ask Jarvis"<br>
                or just type below.
            </p>
        </div>
    </div>
    <div class="input-container">
        <textarea id="input" placeholder="Ask Jarvis..." rows="1"
            onkeydown="handleKeyDown(event)"></textarea>
        <button id="sendBtn" onclick="sendMessage()">Send</button>
    </div>

    <script>
        const vscode = acquireVsCodeApi();
        const chat = document.getElementById('chat');
        const input = document.getElementById('input');
        const sendBtn = document.getElementById('sendBtn');
        let currentResponseDiv = null;
        let isLoading = false;

        function handleKeyDown(e) {
            if (e.key === 'Enter' && !e.shiftKey) {
                e.preventDefault();
                sendMessage();
            }
        }

        function autoResize() {
            input.style.height = 'auto';
            input.style.height = Math.min(input.scrollHeight, 120) + 'px';
        }

        input.addEventListener('input', autoResize);

        function addMessage(text, role) {
            // Remove empty state if present
            const emptyState = chat.querySelector('.empty-state');
            if (emptyState) emptyState.remove();

            const div = document.createElement('div');
            div.className = 'message ' + role;

            // Simple markdown-ish rendering
            let html = escapeHtml(text)
                .replace(/\`\`\`(\w+)?\n([\s\S]*?)\`\`\`/g, '<pre><code>$2</code></pre>')
                .replace(/\`([^\`]+)\`/g, '<code>$1</code>')
                .replace(/\n/g, '<br>');

            div.innerHTML = html;
            chat.appendChild(div);
            chat.scrollTop = chat.scrollHeight;
            return div;
        }

        function escapeHtml(text) {
            const div = document.createElement('div');
            div.textContent = text;
            return div.innerHTML;
        }

        function sendMessage() {
            const text = input.value.trim();
            if (!text || isLoading) return;

            addMessage(text, 'user');
            input.value = '';
            input.style.height = 'auto';
            currentResponseDiv = null;

            vscode.postMessage({ type: 'sendMessage', text });
        }

        function clearChat() {
            chat.innerHTML = '';
            currentResponseDiv = null;
        }

        function openSettings() {
            vscode.postMessage({ type: 'openSettings' });
        }

        // Listen for messages from extension
        window.addEventListener('message', event => {
            const message = event.data;

            switch (message.type) {
                case 'addUserMessage':
                    addMessage(message.text, 'user');
                    break;

                case 'streamResponse':
                    if (!currentResponseDiv) {
                        currentResponseDiv = addMessage(message.text, 'assistant');
                    } else {
                        let html = escapeHtml(message.text)
                            .replace(/\`\`\`(\w+)?\n([\s\S]*?)\`\`\`/g, '<pre><code>$2</code></pre>')
                            .replace(/\`([^\`]+)\`/g, '<code>$1</code>')
                            .replace(/\n/g, '<br>');
                        currentResponseDiv.innerHTML = html;
                        chat.scrollTop = chat.scrollHeight;
                    }
                    break;

                case 'finishResponse':
                    isLoading = false;
                    sendBtn.disabled = false;
                    currentResponseDiv = null;
                    break;

                case 'error':
                    isLoading = false;
                    sendBtn.disabled = false;
                    currentResponseDiv = null;
                    addMessage(message.text, 'error');
                    break;

                case 'setLoading':
                    isLoading = message.loading;
                    sendBtn.disabled = message.loading;
                    if (message.loading) {
                        const loadingDiv = document.createElement('div');
                        loadingDiv.className = 'loading';
                        loadingDiv.textContent = 'Jarvis is thinking...';
                        loadingDiv.id = 'loading-indicator';
                        chat.appendChild(loadingDiv);
                        chat.scrollTop = chat.scrollHeight;
                    } else {
                        const indicator = document.getElementById('loading-indicator');
                        if (indicator) indicator.remove();
                    }
                    break;
            }
        });
    </script>
</body>
</html>`;
    }
}
