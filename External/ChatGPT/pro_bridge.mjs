import crypto from "node:crypto";
import fs from "node:fs";
import path from "node:path";

const ROOT = process.cwd();
const STATE_PATH = path.join(ROOT, "Codex", "General", "ChatGPT", "pro_bridge_state.json");
const HOME_URL = "https://chatgpt.com/?window_style=main_view";
const REQUIRED_MODEL = "gpt-5-6-pro";
const command = process.argv[2];

if (process.env.PRO_BRIDGE_HOST_GUARD !== "1") {
  throw new Error("Use ProBridge.cmd so the Windows foreground guard runs first");
}

if (!["new", "send", "new-files", "send-files", "prepare-files", "resend", "status", "wait", "retrieve", "cancel"].includes(command)) {
  throw new Error(
    "Usage: pro_bridge.mjs new|send|new-files|send-files|prepare-files|resend|status|wait|retrieve|cancel [PATH] [TIMEOUT_SECONDS]"
  );
}

function readSendManifest(manifestPath) {
  const absoluteManifest = path.resolve(manifestPath);
  const directory = path.dirname(absoluteManifest);
  const manifest = JSON.parse(fs.readFileSync(absoluteManifest, "utf8"));
  if (typeof manifest.promptPath !== "string" || !Array.isArray(manifest.files)) {
    throw new Error("Upload manifest requires promptPath and files[]");
  }
  const resolveEntry = entry => path.resolve(directory, entry);
  const promptPath = resolveEntry(manifest.promptPath);
  const attachmentPaths = manifest.files.map(resolveEntry);
  for (const filePath of [promptPath, ...attachmentPaths]) {
    if (!fs.existsSync(filePath) || !fs.statSync(filePath).isFile()) {
      throw new Error(`Manifest file is missing or not a regular file: ${filePath}`);
    }
  }
  if (attachmentPaths.length !== 1) {
    throw new Error(
      "Upload manifest files[] must contain exactly one file; " +
      "use one send-files turn per source file"
    );
  }
  return { absoluteManifest, promptPath, attachmentPaths };
}

function readState() {
  if (!fs.existsSync(STATE_PATH)) throw new Error("Bridge state is missing; run 'new' first");
  return JSON.parse(fs.readFileSync(STATE_PATH, "utf8"));
}

function writeState(state) {
  fs.mkdirSync(path.dirname(STATE_PATH), { recursive: true });
  const temporary = STATE_PATH + ".tmp";
  fs.writeFileSync(temporary, JSON.stringify(state, null, 2), "utf8");
  fs.renameSync(temporary, STATE_PATH);
}

const targets = await (await fetch("http://127.0.0.1:9328/json")).json();
const target = targets.find(
  item => item.type === "page" && /^https:\/\/chatgpt\.com\//.test(item.url || "")
) || targets.find(item => item.type === "page");
if (!target) throw new Error("Classic-app CDP page target not found on port 9328");

const socket = new WebSocket(target.webSocketDebuggerUrl);
await new Promise((resolve, reject) => {
  socket.addEventListener("open", resolve, { once: true });
  socket.addEventListener("error", reject, { once: true });
});

let nextId = 0;
const pending = new Map();
let capturedRequest = null;
const responseStatuses = new Map();
let latestFileChooser = null;

function recordConversationRequest(requestId, request, postData) {
  try {
    const body = JSON.parse(postData);
    if (!body.action) return;
    const latestMessage = body.messages?.at(-1) || {};
    const serializedRequest = JSON.stringify(body);
    const attachmentPointers = [...new Set(
      [...serializedRequest.matchAll(/(?:file-service|sediment):\/\/[^\"\\]+/g)]
        .map(match => match[0])
    )];
    const metadataAttachmentCount = Array.isArray(latestMessage.metadata?.attachments)
      ? latestMessage.metadata.attachments.length : 0;
    const contentAttachmentCount = Array.isArray(latestMessage.content?.parts)
      ? latestMessage.content.parts.filter(part =>
          part && typeof part === "object" &&
          /(file|image)_asset_pointer/i.test(part.content_type || "")
        ).length : 0;
    const requestAttachmentCount = [body.attachments, body.files, body.uploads]
      .filter(Array.isArray)
      .reduce((count, items) => count + items.length, 0);
    capturedRequest = {
      requestId,
      url: request.url,
      model: body.model ?? null,
      thinkingEffort: body.thinking_effort ?? null,
      action: body.action,
      conversationId: body.conversation_id ?? null,
      messageId: body.messages?.at(-1)?.id ?? null,
      attachmentPointers,
      attachmentCount: Math.max(
        attachmentPointers.length,
        metadataAttachmentCount,
        contentAttachmentCount,
        requestAttachmentCount
      ),
      httpStatus: responseStatuses.get(requestId) ?? null,
    };
  } catch {}
}

socket.addEventListener("message", event => {
  const message = JSON.parse(event.data);
  if (message.method === "Network.requestWillBeSent") {
    const request = message.params?.request || {};
    if (/\/backend-api\/f\/conversation(?:$|\?)/.test(request.url || "")) {
      const requestId = message.params.requestId;
      if (request.postData) {
        recordConversationRequest(requestId, request, request.postData);
      } else if (request.hasPostData) {
        call("Network.getRequestPostData", { requestId })
          .then(result => recordConversationRequest(requestId, request, result.postData || ""))
          .catch(() => {});
      }
    }
  }
  if (message.method === "Network.responseReceived") {
    const requestId = message.params?.requestId;
    const status = message.params?.response?.status ?? null;
    if (requestId) responseStatuses.set(requestId, status);
    if (capturedRequest?.requestId === requestId) capturedRequest.httpStatus = status;
  }
  if (message.method === "Page.fileChooserOpened") {
    latestFileChooser = message.params || null;
  }
  if (!message.id || !pending.has(message.id)) return;
  const item = pending.get(message.id);
  pending.delete(message.id);
  message.error
    ? item.reject(new Error(JSON.stringify(message.error)))
    : item.resolve(message.result || {});
});

function call(method, params = {}) {
  const id = ++nextId;
  const promise = new Promise((resolve, reject) => pending.set(id, { resolve, reject }));
  socket.send(JSON.stringify({ id, method, params }));
  return promise;
}

async function evaluate(expression) {
  const response = await call("Runtime.evaluate", {
    expression,
    awaitPromise: true,
    returnByValue: true,
  });
  if (response.exceptionDetails) {
    throw new Error(JSON.stringify(response.exceptionDetails));
  }
  return response.result?.value;
}

async function evaluateObject(expression) {
  const response = await call("Runtime.evaluate", {
    expression,
    awaitPromise: true,
    returnByValue: false,
  });
  if (response.exceptionDetails) {
    throw new Error(JSON.stringify(response.exceptionDetails));
  }
  return response.result || {};
}

async function fileInputObjectId() {
  const result = await evaluateObject(`(() => {
    const inputs = [...document.querySelectorAll('input[type="file"]')]
      .filter(input => !input.disabled);
    return inputs.find(input => !(input.accept || '').toLowerCase().startsWith('image/')) || null;
  })()`);
  return result.subtype === "null" ? null : result.objectId || null;
}

async function clickAttachmentControl() {
  return evaluate(`(() => {
    const direct = document.querySelector(
      '[data-testid="composer-plus-btn"], button[aria-label*="Attach" i], ' +
      'button[aria-label*="Add files" i], button[aria-label*="photos & files" i]'
    );
    if (direct) {
      direct.click();
      return { clicked: true, label: direct.getAttribute('aria-label') || direct.innerText || '' };
    }
    const candidate = [...document.querySelectorAll('button')].find(element => {
      const label = ((element.getAttribute('aria-label') || '') + ' ' +
        (element.innerText || '')).trim();
      return /(attach|add|upload).*(file|photo)|(file|photo).*(attach|add|upload)/i.test(label);
    });
    if (!candidate) return { clicked: false, label: '' };
    candidate.click();
    return { clicked: true, label: candidate.getAttribute('aria-label') || candidate.innerText || '' };
  })()`);
}

async function clickUploadMenuItem() {
  return evaluate(`(() => {
    const candidate = [...document.querySelectorAll(
      '[role="menuitem"], [role="option"], button'
    )].find(element => {
      const label = ((element.getAttribute('aria-label') || '') + ' ' +
        (element.innerText || '')).trim();
      return /(upload|add|attach).*(file|photo)|(file|photo).*(upload|add|attach)/i.test(label) &&
        element.offsetParent !== null;
    });
    if (!candidate) return { clicked: false, label: '' };
    candidate.click();
    return { clicked: true, label: candidate.getAttribute('aria-label') || candidate.innerText || '' };
  })()`);
}

async function waitForUploadedFiles(attachmentPaths) {
  const names = attachmentPaths.map(filePath => path.basename(filePath));
  const deadline = Date.now() + 120_000;
  let stableSince = null;
  let last = null;
  while (Date.now() < deadline) {
    last = await evaluate(`(() => {
      const composer = document.querySelector('#prompt-textarea');
      const composerForm = composer?.closest('form');
      const region = composerForm?.parentElement || composer?.parentElement?.parentElement || document.body;
      const text = region.innerText || region.textContent || '';
      const names = ${JSON.stringify(names)};
      const found = names.filter(name => text.includes(name));
      const busy = Boolean(region.querySelector('[role="progressbar"]')) ||
        /uploading|processing file/i.test(text);
      const alerts = [...document.querySelectorAll('[role="alert"]')]
        .map(element => element.innerText || element.textContent || '')
        .filter(Boolean);
      return { found, busy, alerts };
    })()`);
    if (last.found.length === names.length && !last.busy) {
      stableSince ??= Date.now();
      if (Date.now() - stableSince >= 2000) return last;
    } else {
      stableSince = null;
    }
    if (last.alerts.some(text => /upload|file/i.test(text) && /fail|error|unsupported/i.test(text))) {
      throw new Error(`File upload failed: ${last.alerts.join(' | ')}`);
    }
    await new Promise(resolve => setTimeout(resolve, 400));
  }
  throw new Error(
    `Attached filenames did not become ready: expected=${names.join(', ')} ` +
    `found=${(last?.found || []).join(', ')}`
  );
}

async function visibleUploadedNames(attachmentPaths) {
  const current = await pageState();
  const text = current.composerRegionText || "";
  return attachmentPaths
    .map(filePath => path.basename(filePath))
    .filter(name => text.includes(name));
}

async function uploadFilesByDrop(attachmentPaths) {
  for (const filePath of attachmentPaths) {
    const name = path.basename(filePath);
    const extension = path.extname(filePath).toLowerCase();
    const mimeType = extension === ".zip" ? "application/zip" :
      extension === ".pdf" ? "application/pdf" : "application/octet-stream";
    const base64 = fs.readFileSync(filePath).toString("base64");
    const dropped = await evaluate(`(() => {
      const composer = document.querySelector('#prompt-textarea');
      if (!composer) return false;
      const binary = atob(${JSON.stringify(base64)});
      const bytes = new Uint8Array(binary.length);
      for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
      const file = new File([bytes], ${JSON.stringify(name)}, {
        type: ${JSON.stringify(mimeType)}
      });
      const data = new DataTransfer();
      data.items.add(file);
      const target = composer.closest('form') || composer;
      for (const type of ['dragenter', 'dragover', 'drop']) {
        target.dispatchEvent(new DragEvent(type, {
          bubbles: true,
          cancelable: true,
          dataTransfer: data
        }));
      }
      return true;
    })()`);
    if (!dropped) throw new Error("Composer did not accept a dropped file");
    await waitForUploadedFiles([filePath]);
  }
  return attachmentPaths.map(filePath => path.basename(filePath));
}

async function uploadFiles(attachmentPaths) {
  if (attachmentPaths.length === 0) return [];
  await call("DOM.enable");
  await call("Page.enable");
  await call("Page.setInterceptFileChooserDialog", { enabled: true });
  try {
    const requestedNames = attachmentPaths.map(filePath => path.basename(filePath));
    const existingNames = new Set(await visibleUploadedNames(attachmentPaths));
    const readyPaths = attachmentPaths.filter(
      filePath => existingNames.has(path.basename(filePath))
    );

    for (const filePath of attachmentPaths) {
      if (existingNames.has(path.basename(filePath))) continue;
      await evaluate(`(() => {
        for (const input of document.querySelectorAll('input[type="file"]')) {
          input.value = '';
          input.dispatchEvent(new Event('change', { bubbles: true }));
        }
        return true;
      })()`);
      latestFileChooser = null;
      const attachmentControl = await clickAttachmentControl();
      if (!attachmentControl.clicked) throw new Error("Attachment control was not found");
      await new Promise(resolve => setTimeout(resolve, 500));
      if (!latestFileChooser) {
        const menuItem = await clickUploadMenuItem();
        if (menuItem.clicked) await new Promise(resolve => setTimeout(resolve, 300));
      }
      let objectId = null;
      if (!latestFileChooser) {
        const chooserDeadline = Date.now() + 5000;
        while (!latestFileChooser && Date.now() < chooserDeadline) {
          await new Promise(resolve => setTimeout(resolve, 100));
          objectId = await fileInputObjectId();
          if (objectId) break;
        }
      }

      if (latestFileChooser?.backendNodeId) {
        await call("DOM.setFileInputFiles", {
          files: [filePath],
          backendNodeId: latestFileChooser.backendNodeId,
        });
        const resolved = await call("DOM.resolveNode", {
          backendNodeId: latestFileChooser.backendNodeId,
        });
        if (resolved.object?.objectId) {
          await call("Runtime.callFunctionOn", {
            objectId: resolved.object.objectId,
            functionDeclaration: `function () {
              this.dispatchEvent(new Event('input', { bubbles: true }));
              this.dispatchEvent(new Event('change', { bubbles: true }));
            }`,
          });
        }
      } else if (objectId) {
        await call("DOM.setFileInputFiles", { files: [filePath], objectId });
        await call("Runtime.callFunctionOn", {
          objectId,
          functionDeclaration: `function () {
            this.dispatchEvent(new Event('input', { bubbles: true }));
            this.dispatchEvent(new Event('change', { bubbles: true }));
          }`,
        });
      } else {
        throw new Error("File input was not exposed by the composer");
      }
      readyPaths.push(filePath);
      await waitForUploadedFiles(readyPaths);
    }

    await waitForUploadedFiles(attachmentPaths);
    return requestedNames;
  } finally {
    await call("Page.setInterceptFileChooserDialog", { enabled: false });
  }
}

async function pageState() {
  return evaluate(`(() => {
    const users = [...document.querySelectorAll('[data-message-author-role="user"]')];
    const assistants = [...document.querySelectorAll('[data-message-author-role="assistant"]')];
    const composer = document.querySelector('#prompt-textarea');
    const composerForm = composer?.closest('form');
    const composerRegion = composerForm?.parentElement || composer?.parentElement?.parentElement;
    const controls = [...document.querySelectorAll('button')].map(button =>
      ((button.getAttribute('aria-label') || '') + ' ' + (button.innerText || '')).trim()
    );
    const generating = controls.some(text =>
      /stop generating|stop answering|^stop$/i.test(text)
    );
    const latestUser = users.at(-1);
    const latestAssistant = assistants.at(-1);
    const messageId = element => element?.closest('[data-message-id]')?.getAttribute('data-message-id') ||
      element?.querySelector('[data-message-id]')?.getAttribute('data-message-id') || null;
    return {
      title: document.title,
      url: location.href,
      hasFocus: document.hasFocus(),
      visibility: document.visibilityState,
      readyState: document.readyState,
      composerFound: Boolean(composer),
      composerText: composer ? (composer.value ?? composer.innerText ?? composer.textContent ?? '') : null,
      composerRegionText: composerRegion?.innerText || composerRegion?.textContent || '',
      fileInputs: [...document.querySelectorAll('input[type="file"]')].map(input => ({
        accept: input.accept || '',
        multiple: input.multiple,
        disabled: input.disabled,
        files: [...(input.files || [])].map(file => file.name),
      })),
      proCount: [...document.querySelectorAll('button')]
        .filter(button => ['Pro', 'Extra High'].includes(
          (button.innerText || '').trim()
        )).length,
      userCount: users.length,
      assistantCount: assistants.length,
      userIds: users.map(messageId).filter(Boolean),
      assistantIds: assistants.map(messageId).filter(Boolean),
      latestUser: latestUser?.innerText || '',
      latestAssistant: latestAssistant?.innerText || '',
      latestUserId: messageId(latestUser),
      latestAssistantId: messageId(latestAssistant),
      generating,
      activeControls: controls.filter(text =>
        /stop|cancel|interrupt|continue|resume|retry|regenerate/i.test(text)
      ).slice(-12),
      alerts: [...document.querySelectorAll('[role="alert"]')]
        .map(element => element.innerText || element.textContent || '')
        .filter(Boolean)
        .slice(-4),
    };
  })()`);
}

async function requireBackground() {
  return pageState();
}

async function navigate(url) {
  let current = await requireBackground();
  if (current.url === url || (
    url.includes("/c/") && current.url.startsWith(url.split("?")[0])
  )) return current;

  await call("Page.enable");
  await call("Page.navigate", { url });
  const deadline = Date.now() + 45_000;
  while (Date.now() < deadline) {
    await new Promise(resolve => setTimeout(resolve, 400));
    current = await requireBackground();
    if (current.composerFound && current.readyState === "complete") {
      if (url === HOME_URL || current.url.startsWith(url.split("?")[0])) return current;
    }
  }
  throw new Error(`Navigation did not settle at ${url}; current=${current.url}`);
}

async function waitTrackedLoaded(tracked) {
  const deadline = Date.now() + 60_000;
  const promptPrefix = (tracked.promptPrefix || "").slice(0, 160);
  let current = null;
  while (Date.now() < deadline) {
    current = await requireBackground();
    const routeMatches = current.url.startsWith(tracked.conversationUrl);
    const sentTurnLoaded = tracked.acceptedUserId
      ? current.userIds.includes(tracked.acceptedUserId)
      : current.userCount > tracked.baseline.userCount &&
        (!promptPrefix || current.latestUser.startsWith(promptPrefix));
    const completedConversationReady = Boolean(
      tracked.completed && current.userCount > 0
    );
    if (
      routeMatches && current.composerFound &&
        (sentTurnLoaded || completedConversationReady)
    ) return current;
    await new Promise(resolve => setTimeout(resolve, 400));
  }
  throw new Error(
    `Tracked conversation did not hydrate: ${tracked.conversationId}; ` +
    `url=${current?.url || ""} users=${current?.userCount ?? -1}`
  );
}

async function waitForProSelected() {
  const deadline = Date.now() + 20_000;
  let current = null;
  while (Date.now() < deadline) {
    current = await requireBackground();
    if (current.proCount === 1) return current;
    await new Promise(resolve => setTimeout(resolve, 250));
  }
  throw new Error(
    `Pro lane did not become selected; count=${current?.proCount ?? -1}`
  );
}

async function waitForSentinelReady() {
  const deadline = Date.now() + 8 * 60_000;
  let lastReport = 0;
  let probe = null;
  while (Date.now() < deadline) {
    probe = await evaluate(`fetch('/backend-api/sentinel/ping', {
      method: 'POST',
      credentials: 'include',
      headers: { accept: 'application/json', 'content-type': 'application/json' },
      body: '{}'
    }).then(async response => ({
      status: response.status,
      contentType: response.headers.get('content-type') || '',
      body: (await response.text()).slice(0, 240)
    }))`);
    const blocked = probe.status === 403 && /text\/html/i.test(probe.contentType);
    if (!blocked) return probe;
    if (Date.now() - lastReport >= 60_000) {
      console.log(JSON.stringify({
        status: "WAITING_FOR_CHATGPT_SENTINEL",
        httpStatus: probe.status,
        checkedAt: new Date().toISOString(),
      }));
      lastReport = Date.now();
    }
    await new Promise(resolve => setTimeout(resolve, 10_000));
  }
  throw new Error(
    `ChatGPT Sentinel did not become ready: HTTP ${probe?.status ?? "unknown"}`
  );
}

async function setComposer(text) {
  return evaluate(`(() => {
    const composer = document.querySelector('#prompt-textarea');
    if (!composer) throw new Error('composer missing');
    const oldText = composer.value ?? composer.innerText ?? composer.textContent ?? '';
    if (oldText !== '') throw new Error('composer contains a draft; refusing to overwrite it');
    const text = ${JSON.stringify(text)};
    if (composer instanceof HTMLTextAreaElement || composer instanceof HTMLInputElement) {
      const prototype = composer instanceof HTMLTextAreaElement
        ? HTMLTextAreaElement.prototype : HTMLInputElement.prototype;
      Object.getOwnPropertyDescriptor(prototype, 'value').set.call(composer, text);
    } else {
      const paragraph = document.createElement('p');
      paragraph.textContent = text;
      composer.replaceChildren(paragraph);
    }
    composer.dispatchEvent(new InputEvent('input', {
      bubbles: true, inputType: 'insertText', data: text
    }));
    return composer.value ?? composer.innerText ?? composer.textContent ?? '';
  })()`);
}

async function clearOwnComposer(text) {
  return evaluate(`(() => {
    const composer = document.querySelector('#prompt-textarea');
    if (!composer) return false;
    const current = composer.value ?? composer.innerText ?? composer.textContent ?? '';
    if (current !== ${JSON.stringify(text)}) return false;
    composer.replaceChildren(document.createElement('p'));
    composer.dispatchEvent(new InputEvent('input', {
      bubbles: true, inputType: 'deleteContent', data: null
    }));
    return true;
  })()`);
}

async function clickSend() {
  return evaluate(`(() => {
    const send = document.querySelector(
      '#composer-submit-button, [data-testid="send-button"], button[aria-label*="Send"]'
    );
    if (!send || send.disabled) return false;
    send.click();
    return true;
  })()`);
}

async function stopWrongModel() {
  return evaluate(`(() => {
    const stop = [...document.querySelectorAll('button')].find(button => {
      const text = ((button.getAttribute('aria-label') || '') + ' ' + (button.innerText || '')).trim();
      return /stop generating|stop answering|^stop$/i.test(text);
    });
    if (!stop) return false;
    stop.click();
    return true;
  })()`);
}

async function sendPrompt(promptPath, isNew, resendCount = 0, attachmentPaths = [], manifestPath = null) {
  const prompt = fs.readFileSync(promptPath, "utf8").trim();
  if (!prompt) throw new Error("Prompt file is empty");

  const prior = isNew ? null : readState();
  const destination = isNew ? HOME_URL : prior.conversationUrl;
  let before = await navigate(destination);
  if (!isNew) before = await waitTrackedLoaded(prior);
  before = await waitForProSelected();
  await waitForSentinelReady();
  if (before.composerText !== "") {
    throw new Error("Composer contains a draft; refusing to overwrite it");
  }

  const uploadedNames = await uploadFiles(attachmentPaths);
  capturedRequest = null;
  const prepared = await setComposer(prompt);
  if (prepared !== prompt) throw new Error("Composer text verification failed");
  await new Promise(resolve => setTimeout(resolve, 250));
  if (!await clickSend()) {
    await clearOwnComposer(prompt);
    throw new Error("Send button was not available");
  }

  const acceptanceDeadline = Date.now() + 30_000;
  let accepted = null;
  while (Date.now() < acceptanceDeadline) {
    await new Promise(resolve => setTimeout(resolve, 400));
    const current = await pageState();
    const normalizeText = value => value.replace(/\s+/g, " ").trim();
    const promptNormalized = normalizeText(prompt);
    const latestUserNormalized = normalizeText(current.latestUser || "");
    const promptPrefix = promptNormalized.slice(0, 160);
    const promptVisible = attachmentPaths.length > 0
      ? latestUserNormalized.includes(promptPrefix)
      : latestUserNormalized === promptNormalized ||
        latestUserNormalized.startsWith(promptPrefix);
    if (promptVisible) {
      accepted = current;
      break;
    }
  }
  if (!accepted) throw new Error("Prompt was not accepted by the conversation");

  const captureDeadline = Date.now() + 10_000;
  while (!capturedRequest && Date.now() < captureDeadline) {
    await new Promise(resolve => setTimeout(resolve, 100));
  }
  if (!capturedRequest) {
    await stopWrongModel();
    throw new Error("Outgoing conversation request was not captured");
  }
  if (capturedRequest.model !== REQUIRED_MODEL) {
    await stopWrongModel();
    throw new Error(
      `Wrong model captured: ${capturedRequest.model}; required=${REQUIRED_MODEL}`
    );
  }
  if (attachmentPaths.length > 0 && capturedRequest.attachmentCount < attachmentPaths.length) {
    await stopWrongModel();
    throw new Error(
      `Outgoing turn did not contain every attachment: ` +
      `expected=${attachmentPaths.length} captured=${capturedRequest.attachmentCount}`
    );
  }
  const responseDeadline = Date.now() + 10_000;
  while (capturedRequest.httpStatus === null && Date.now() < responseDeadline) {
    await new Promise(resolve => setTimeout(resolve, 100));
  }
  if (![200, 201].includes(capturedRequest.httpStatus)) {
    await stopWrongModel();
    let responseBody = "";
    try {
      const body = await call("Network.getResponseBody", {
        requestId: capturedRequest.requestId,
      });
      responseBody = (body.body || "").slice(0, 1200);
    } catch {}
    throw new Error(
      `Conversation request failed: HTTP ${capturedRequest.httpStatus ?? "unknown"} ` +
      responseBody
    );
  }

  let finalRoute = accepted.url;
  const routeDeadline = Date.now() + 30_000;
  while (/\/c\/WEB%3A|\/c\/WEB:/i.test(finalRoute) && Date.now() < routeDeadline) {
    await new Promise(resolve => setTimeout(resolve, 250));
    finalRoute = (await pageState()).url;
  }
  const match = finalRoute.match(/\/c\/([^/?#]+)/i);
  const routeId = match ? decodeURIComponent(match[1]) : null;
  const conversationId = routeId && !routeId.startsWith("WEB:")
    ? routeId : capturedRequest.conversationId;
  if (!conversationId) throw new Error(`Conversation ID missing from ${finalRoute}`);

  const state = {
    version: 2,
    conversationId,
    conversationUrl: `https://chatgpt.com/c/${conversationId}`,
    model: capturedRequest.model,
    thinkingEffort: capturedRequest.thinkingEffort,
    requestMessageId: capturedRequest.messageId,
    requestHttpStatus: capturedRequest.httpStatus,
    sentAt: new Date().toISOString(),
    promptSha256: crypto.createHash("sha256").update(prompt).digest("hex"),
    promptPath: path.resolve(promptPath),
    manifestPath: manifestPath ? path.resolve(manifestPath) : null,
    attachmentPaths: attachmentPaths.map(filePath => path.resolve(filePath)),
    attachmentNames: uploadedNames,
    attachmentSha256: attachmentPaths.map(filePath =>
      crypto.createHash("sha256").update(fs.readFileSync(filePath)).digest("hex")
    ),
    promptPrefix: prompt.slice(0, 200),
    acceptedUserId: accepted.latestUserId,
    baseline: {
      userCount: before.userCount,
      assistantCount: before.assistantCount,
      latestAssistant: before.latestAssistant,
      latestAssistantId: before.latestAssistantId,
    },
    completed: false,
    resendCount,
  };
  writeState(state);
  console.log(JSON.stringify({
    status: "SENT",
    conversationId,
    model: state.model,
    thinkingEffort: state.thinkingEffort,
    requestMessageId: state.requestMessageId,
    requestHttpStatus: state.requestHttpStatus,
    attachments: state.attachmentNames,
    foregroundUntouched: true,
    documentFocused: accepted.hasFocus,
    stateFile: STATE_PATH,
  }, null, 2));
}

async function openTrackedConversation() {
  const state = readState();
  await navigate(state.conversationUrl);
  const current = await waitTrackedLoaded(state);
  if (state.model !== REQUIRED_MODEL) {
    throw new Error(`State model is ${state.model}; required=${REQUIRED_MODEL}`);
  }
  return { tracked: state, current };
}

function summarize(tracked, current) {
  const isNewAssistant = current.latestAssistantId
    ? current.latestAssistantId !== tracked.baseline.latestAssistantId
    : current.assistantCount > tracked.baseline.assistantCount ||
      (
        current.latestAssistant &&
        current.latestAssistant !== tracked.baseline.latestAssistant
      );
  const retryableError = isNewAssistant && !current.generating && (
    current.activeControls.some(text => /^retry$/i.test(text.trim())) ||
    /something went wrong while generating|network error|unable to generate/i
      .test(current.latestAssistant)
  );
  const emptyResponse = isNewAssistant && !current.generating &&
    current.latestAssistant.trim() === "";
  return {
    status: retryableError ? "RETRYABLE_ERROR" :
      emptyResponse ? "EMPTY_RESPONSE" :
      isNewAssistant && current.latestAssistant && !current.generating
        ? "RESPONSE_AVAILABLE" :
      current.generating ? "GENERATING" : "WAITING",
    conversationId: tracked.conversationId,
    model: tracked.model,
    thinkingEffort: tracked.thinkingEffort,
    userCount: current.userCount,
    assistantCount: current.assistantCount,
    generating: current.generating,
    responseChars: isNewAssistant ? current.latestAssistant.length : 0,
    responsePrefix: isNewAssistant ? current.latestAssistant.slice(0, 240) : "",
    responseSuffix: isNewAssistant ? current.latestAssistant.slice(-240) : "",
    latestUser: current.latestUser,
    latestUserId: current.latestUserId,
    activeControls: current.activeControls,
    alerts: current.alerts,
    composerRegionText: current.composerRegionText,
    fileInputs: current.fileInputs,
    foregroundUntouched: true,
    documentFocused: current.hasFocus,
  };
}

await call("Runtime.enable");
await call("Network.enable");

if (command === "new" || command === "send") {
  const promptPath = process.argv[3];
  if (!promptPath) throw new Error(`${command} requires a prompt file`);
  await sendPrompt(promptPath, command === "new");
} else if (command === "new-files" || command === "send-files") {
  const manifestPath = process.argv[3];
  if (!manifestPath) throw new Error(`${command} requires an upload manifest`);
  const manifest = readSendManifest(manifestPath);
  await sendPrompt(
    manifest.promptPath,
    command === "new-files",
    0,
    manifest.attachmentPaths,
    manifest.absoluteManifest
  );
} else if (command === "prepare-files") {
  const manifestPath = process.argv[3];
  if (!manifestPath) throw new Error("prepare-files requires an upload manifest");
  const manifest = readSendManifest(manifestPath);
  const tracked = readState();
  let current = await navigate(tracked.conversationUrl);
  current = await waitTrackedLoaded(tracked);
  current = await waitForProSelected();
  if (current.composerText !== "") {
    throw new Error("Composer contains a draft; refusing to overwrite it");
  }
  const names = await uploadFilesByDrop(manifest.attachmentPaths);
  current = await pageState();
  console.log(JSON.stringify({
    status: "FILES_READY",
    names,
    composerRegionText: current.composerRegionText,
  }, null, 2));
} else if (command === "status") {
  const { tracked, current } = await openTrackedConversation();
  console.log(JSON.stringify(summarize(tracked, current), null, 2));
} else if (command === "resend") {
  const { tracked, current } = await openTrackedConversation();
  const summary = summarize(tracked, current);
  if (!["RETRYABLE_ERROR", "EMPTY_RESPONSE"].includes(summary.status)) {
    throw new Error(`Conversation does not need resubmission: ${summary.status}`);
  }
  if (!tracked.promptPath || !fs.existsSync(tracked.promptPath)) {
    throw new Error("Saved prompt file is unavailable; use 'send' with the prompt path");
  }
  const attachmentPaths = Array.isArray(tracked.attachmentPaths)
    ? tracked.attachmentPaths : [];
  for (const filePath of attachmentPaths) {
    if (!fs.existsSync(filePath)) {
      throw new Error(`Saved attachment is unavailable: ${filePath}`);
    }
  }
  await sendPrompt(
    tracked.promptPath,
    false,
    (tracked.resendCount || 0) + 1,
    attachmentPaths,
    tracked.manifestPath || null
  );
} else if (command === "cancel") {
  const { tracked, current } = await openTrackedConversation();
  if (!current.generating) {
    throw new Error("Tracked conversation is not generating");
  }
  const stopped = await stopWrongModel();
  if (!stopped) throw new Error("Stop control is unavailable");
  console.log(JSON.stringify({
    status: "CANCELLED",
    conversationId: tracked.conversationId,
    foregroundUntouched: true,
  }, null, 2));
} else if (command === "retrieve") {
  const outputPath = process.argv[3];
  if (!outputPath) throw new Error("retrieve requires an output file");
  const { tracked, current } = await openTrackedConversation();
  const summary = summarize(tracked, current);
  if (summary.status !== "RESPONSE_AVAILABLE") {
    throw new Error(`No completed response is available: ${summary.status}`);
  }
  fs.writeFileSync(outputPath, current.latestAssistant, "utf8");
  tracked.completed = true;
  tracked.completedAt = new Date().toISOString();
  tracked.responseChars = current.latestAssistant.length;
  tracked.responseSha256 = crypto.createHash("sha256")
    .update(current.latestAssistant).digest("hex");
  tracked.outputPath = path.resolve(outputPath);
  writeState(tracked);
  console.log(JSON.stringify({ ...summary, outputPath: path.resolve(outputPath) }, null, 2));
} else if (command === "wait") {
  const outputPath = process.argv[3];
  const timeoutSeconds = Number(process.argv[4] || 7200);
  if (!outputPath) throw new Error("wait requires an output file");
  if (!Number.isFinite(timeoutSeconds) || timeoutSeconds <= 0) {
    throw new Error("wait timeout must be a positive number of seconds");
  }

  const tracked = readState();
  await navigate(tracked.conversationUrl);
  await waitTrackedLoaded(tracked);
  const deadline = Date.now() + timeoutSeconds * 1000;
  let latestText = "";
  let stableSince = Date.now();
  let lastProgress = 0;
  while (Date.now() < deadline) {
    const current = await pageState();
    const summary = summarize(tracked, current);
    if (["RETRYABLE_ERROR", "EMPTY_RESPONSE"].includes(summary.status)) {
      throw new Error(
        `Pro response failed with ${summary.status}; run 'resend' for a new model-verified attempt`
      );
    }
    if (current.latestAssistant !== latestText) {
      latestText = current.latestAssistant;
      stableSince = Date.now();
    }
    if (Date.now() - lastProgress >= 30_000) {
      console.log(JSON.stringify({
        checkedAt: new Date().toISOString(),
        status: summary.status,
        responseChars: summary.responseChars,
        generating: summary.generating,
        alerts: summary.alerts,
      }));
      lastProgress = Date.now();
    }
    if (
      summary.status === "RESPONSE_AVAILABLE" &&
      current.latestAssistant &&
      Date.now() - stableSince >= 12_000
    ) {
      fs.writeFileSync(outputPath, current.latestAssistant, "utf8");
      tracked.completed = true;
      tracked.completedAt = new Date().toISOString();
      tracked.responseChars = current.latestAssistant.length;
      tracked.responseSha256 = crypto.createHash("sha256")
        .update(current.latestAssistant).digest("hex");
      tracked.outputPath = path.resolve(outputPath);
      writeState(tracked);
      console.log(JSON.stringify({
        status: "RESPONSE_COMPLETE",
        responseChars: current.latestAssistant.length,
        outputPath: path.resolve(outputPath),
      }, null, 2));
      socket.close();
      process.exit(0);
    }
    await new Promise(resolve => setTimeout(resolve, 3000));
  }
  throw new Error(`Timed out after ${timeoutSeconds} seconds`);
}

socket.close();
