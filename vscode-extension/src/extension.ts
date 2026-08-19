// ═══════════════════════════════════════════════════════════════
//  NOMAD JARVIS — VS Code Extension
//  Brings your OpenClaw AI assistant inside VS Code.
// ═══════════════════════════════════════════════════════════════

import * as vscode from 'vscode';
import { JarvisWebviewProvider } from './webviewProvider';

let provider: JarvisWebviewProvider;

export function activate(context: vscode.ExtensionContext) {
    console.log('Nomad Jarvis extension activated');

    // Register the webview provider
    provider = new JarvisWebviewProvider(context.extensionUri);

    context.subscriptions.push(
        vscode.window.registerWebviewViewProvider(
            'nomadJarvis.chat',
            provider
        )
    );

    // Command: Open chat panel
    context.subscriptions.push(
        vscode.commands.registerCommand('nomadJarvis.openChat', () => {
            vscode.commands.executeCommand('nomadJarvis.chat.focus');
        })
    );

    // Command: Ask about selection
    context.subscriptions.push(
        vscode.commands.registerCommand('nomadJarvis.askAboutSelection', async () => {
            const editor = vscode.window.activeTextEditor;
            if (!editor) {
                vscode.window.showWarningMessage('No active editor');
                return;
            }

            const selection = editor.document.getText(editor.selection);
            if (!selection) {
                vscode.window.showWarningMessage('No text selected');
                return;
            }

            await provider.sendMessage(`I have a question about this code:\n\n\`\`\`${editor.document.languageId}\n${selection}\n\`\`\`\n\n`);
            vscode.commands.executeCommand('nomadJarvis.chat.focus');
        })
    );

    // Command: Explain code
    context.subscriptions.push(
        vscode.commands.registerCommand('nomadJarvis.explainCode', async () => {
            const editor = vscode.window.activeTextEditor;
            if (!editor) return;

            const selection = editor.document.getText(editor.selection);
            if (!selection) return;

            await provider.sendMessage(
                `Explain this code:\n\n\`\`\`${editor.document.languageId}\n${selection}\n\`\`\``
            );
            vscode.commands.executeCommand('nomadJarvis.chat.focus');
        })
    );

    // Command: Review code
    context.subscriptions.push(
        vscode.commands.registerCommand('nomadJarvis.reviewCode', async () => {
            const editor = vscode.window.activeTextEditor;
            if (!editor) return;

            const selection = editor.document.getText(editor.selection);
            if (!selection) return;

            await provider.sendMessage(
                `Review this code for bugs, style issues, and improvements:\n\n\`\`\`${editor.document.languageId}\n${selection}\n\`\`\``
            );
            vscode.commands.executeCommand('nomadJarvis.chat.focus');
        })
    );
}

export function deactivate() {
    console.log('Nomad Jarvis extension deactivated');
}
