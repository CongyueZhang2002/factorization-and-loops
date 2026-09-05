const action = process.argv[2];
const expected = process.argv[3] ?? "";
const replacement = process.argv[4] ?? "";

const targets = await (await fetch("http://127.0.0.1:9328/json")).json();
const target = targets.find(item => item.type === "page" &&
  /^https:\/\/chatgpt\.com\//.test(item.url || ""));
if (!target) throw new Error("ChatGPT Classic page target not found");

const socket = new WebSocket(target.webSocketDebuggerUrl);
await new Promise((resolve, reject) => {
  socket.addEventListener("open", resolve, { once: true });
  socket.addEventListener("error", reject, { once: true });
});

let nextId = 0;
const pending = new Map();
socket.addEventListener("message", event => {
  const message = JSON.parse(event.data);
  if (!message.id || !pending.has(message.id)) return;
  const item = pending.get(message.id);
  pending.delete(message.id);
  message.error ? item.reject(new Error(JSON.stringify(message.error))) :
    item.resolve(message.result || {});
});

function call(method, params = {}) {
  const id = ++nextId;
  const promise = new Promise((resolve, reject) => pending.set(id, { resolve, reject }));
  socket.send(JSON.stringify({ id, method, params }));
  return promise;
}

const expression = `(() => {
  const composer = document.querySelector('#prompt-textarea');
  if (!composer) throw new Error('composer missing');
  const read = () => composer.value ?? composer.innerText ?? composer.textContent ?? '';
  const before = read();
  const action = ${JSON.stringify(action)};
  const expected = ${JSON.stringify(expected)};
  const replacement = ${JSON.stringify(replacement)};
  if (action === 'inspect') return { before, after: before, changed: false };
  if (before !== expected) throw new Error('draft changed; refusing mutation');
  if (composer instanceof HTMLTextAreaElement || composer instanceof HTMLInputElement) {
    const prototype = composer instanceof HTMLTextAreaElement ?
      HTMLTextAreaElement.prototype : HTMLInputElement.prototype;
    Object.getOwnPropertyDescriptor(prototype, 'value').set.call(composer, replacement);
  } else if (replacement === '') {
    composer.replaceChildren();
  } else {
    const paragraph = document.createElement('p');
    paragraph.textContent = replacement;
    composer.replaceChildren(paragraph);
  }
  composer.dispatchEvent(new InputEvent('input', {
    bubbles: true,
    inputType: replacement === '' ? 'deleteContent' : 'insertText',
    data: replacement
  }));
  return { before, after: read(), changed: true };
})()`;

const response = await call("Runtime.evaluate", {
  expression,
  awaitPromise: true,
  returnByValue: true
});
if (response.exceptionDetails) throw new Error(JSON.stringify(response.exceptionDetails));
console.log(JSON.stringify(response.result?.value));
socket.close();
