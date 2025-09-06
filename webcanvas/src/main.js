import MarkdownIt from 'markdown-it'
import katexPlugin from 'markdown-it-katex'
import mermaid from 'mermaid'
import { getHighlighter } from 'shiki'
import { markdownItShiki } from '@shikijs/markdown-it'

mermaid.initialize({ startOnLoad: false, securityLevel: 'strict', theme: 'default' })

function send(type, payload) {
  try { window.webkit?.messageHandlers?.bridge?.postMessage({ type, payload }) } catch {}
}

const app = document.getElementById('app')
const bottom = document.querySelector('.scroll-bottom') || (() => { const b = document.createElement('div'); b.className = 'scroll-bottom'; app.appendChild(b); return b })()
function el(t, c) { const x = document.createElement(t); if (c) x.className = c; return x }
function clearApp() { while (app.firstChild) app.removeChild(app.firstChild); app.appendChild(bottom) }

let md
let state = { theme: 'light', streaming: null }

async function initRenderer() {
  const highlighter = await getHighlighter({ themes: ['github-light', 'github-dark'], langs: ['swift', 'python', 'javascript', 'json', 'bash', 'markdown'] })
  md = new MarkdownIt({ html: false, linkify: true, breaks: false })
    .use(markdownItShiki, { highlighter, themes: { light: 'github-light', dark: 'github-dark' } })
    .use(katexPlugin)
}

function renderMermaid(container) {
  const blocks = container.querySelectorAll('pre > code.language-mermaid')
  blocks.forEach(async code => {
    const src = code.textContent || ''
    const id = 'm' + Math.random().toString(36).slice(2)
    const wrap = code.parentElement
    const fig = document.createElement('div')
    fig.className = 'mermaid'
    try {
      const { svg } = await mermaid.render(id, src)
      fig.innerHTML = svg
      if (wrap) wrap.replaceWith(fig)
    } catch (e) { console.error('Mermaid error', e) }
  })
}

function renderMessage(m) {
  const wrap = el('div', 'msg ' + (m.role === 'assistant' ? 'assistant' : 'user'))
  if (m.role === 'assistant') {
    const html = md.render(m.content)
    const div = el('div')
    div.innerHTML = html
    wrap.appendChild(div)
    app.insertBefore(wrap, bottom)
    renderMermaid(div)
  } else {
    const pre = el('pre')
    pre.textContent = m.content
    wrap.appendChild(pre)
    app.insertBefore(wrap, bottom)
  }
}

const API = {
  async loadTranscript(messages) {
    if (!md) await initRenderer()
    clearApp()
    for (const m of messages) renderMessage(m)
    API.scrollToBottom()
  },
  async startStream(id) {
    if (!md) await initRenderer()
    state.streaming = { id, content: '' }
    const wrap = el('div', 'msg assistant'); wrap.id = 'stream-' + id
    const holder = el('div'); holder.id = 'stream-html'
    wrap.appendChild(holder)
    app.insertBefore(wrap, bottom)
    API.scrollToBottom()
  },
  appendDelta(id, delta) {
    if (!state.streaming || state.streaming.id !== id) return
    state.streaming.content += delta
    const holder = document.getElementById('stream-html')
    if (holder) {
      holder.innerHTML = md.render(state.streaming.content)
      renderMermaid(holder)
    }
    API.scrollToBottom()
  },
  endStream(id) {
    if (!state.streaming || state.streaming.id !== id) return
    state.streaming = null
    API.scrollToBottom()
  },
  setTheme(mode) {
    state.theme = mode === 'dark' ? 'dark' : 'light'
  },
  scrollToBottom() { bottom.scrollIntoView({ block: 'end' }) },
  artifact: { mount(cfg) { /* TODO */ } }
}

window.ChatCanvas = API
send('ready')

