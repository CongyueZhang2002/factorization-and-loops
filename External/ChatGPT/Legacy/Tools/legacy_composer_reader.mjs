const targets = await (await fetch("http://127.0.0.1:9328/json")).json();
const target = targets.find(item => item.type === "page" &&
  /^https:\/\/chatgpt\.com\//.test(item.url || ""));
if (!target) throw new Error("ChatGPT page not found");

const socket = new WebSocket(target.webSocketDebuggerUrl);
await new Promise((resolve, reject) => {
  socket.addEventListener("open", resolve, {once: true});
  socket.addEventListener("error", reject, {once: true});
});

const response = new Promise((resolve, reject) => {
  socket.addEventListener("message", event => {
    const message = JSON.parse(event.data);
    if (message.id !== 1) return;
    if (message.error) reject(new Error(JSON.stringify(message.error)));
    else resolve(message.result.result.value);
  });
});
socket.send(JSON.stringify({
  id: 1,
  method: "Runtime.evaluate",
  params: {
    expression: `(() => {
      const composer = document.querySelector('#prompt-textarea');
      const users = [...document.querySelectorAll('[data-message-author-role="user"]')];
      const assistants = [...document.querySelectorAll('[data-message-author-role="assistant"]')];
      const controls = [...document.querySelectorAll('button')].map(button =>
        ((button.getAttribute('aria-label') || '') + ' ' +
          (button.innerText || '')).trim()
      );
      return composer ? {
        value: composer.value ?? null,
        innerText: composer.innerText ?? null,
        textContent: composer.textContent ?? null,
        innerHTML: composer.innerHTML,
        userCount: users.length,
        latestUserPrefix: (users.at(-1)?.innerText || '').slice(0, 300),
        assistantCount: assistants.length,
        latestAssistantLength: (assistants.at(-1)?.innerText || '').length,
        latestAssistantSuffix: (assistants.at(-1)?.innerText || '').slice(-300),
        controls: controls.filter(Boolean).slice(-40),
        generating: controls.some(text =>
          /stop generating|stop answering|^stop$/i.test(text)
        )
      } : null;
    })()`,
    returnByValue: true
  }
}));
console.log(JSON.stringify(await response));
socket.close();
