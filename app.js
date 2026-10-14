/* ============================================================
   Browser Bridge 落地页 — 语言切换 + 复制命令
   文案在 index.html 上以 data-i18n 标注，词条集中在此
   ============================================================ */

const I18N = {
  zh: {
    "lang_attr": "zh-CN",
    "title": "Browser Bridge · 让你的浏览器成为任何 Agent 的工具",
    "skip": "跳到主要内容",
    "nav_token": "Token 效率",
    "nav_memory": "站点记忆",
    "nav_safety": "安全审核",
    "nav_entry": "接入方式",
    "hero_kicker": "开源 · MIT · 只在本机运行",
    "hero_title": "让你的浏览器，<br>成为任何 Agent 的工具",
    "hero_sub": "一条 bridge 协议，CLI / MCP / Skill 任意入口——装上 Skill，你正在用的 Agent 就能开浏览器。免云浏览器、免重新登录，会话与凭证留在本机。",
    "hero_cta": "在 GitHub 上查看",
    "hero_cta2": "安装方式",
    "hero_cap": "Agent 操作 Chrome",
    "hero_alt": "Agent 通过 Browser Bridge 打开 Gmail 并读取收件箱的画面",
    "p1_name": "Token 效率",
    "p1_title": "整页 324,078 字符，Agent 只读 546 个。",
    "p1_text": "snapshot 先给出一份页面地图：有哪些可点的元素、哪些标题、正文大概在哪。Agent 据此只读需要的那一块，而不是把整页塞进上下文。超限的结果会被拒绝，不浪费 token。",
    "p1_ratio1": "信噪比",
    "p1_ratio2": "GMAIL 收件箱 · 登录态 CHROME<br>2026-09-15 实测",
    "p1_table_cap": "三个真实页面的信噪比实测",
    "p1_th1": "页面",
    "p1_th2": "整页 HTML",
    "p1_th3": "实际信号",
    "p1_th4": "信噪比",
    "p1_row1": "Gmail 收件箱",
    "p1_row2": "GitHub 通知",
    "p1_row3": "Eastmoney 文章",
    "p1_foot": "按字符数统计，2026-09-15 实测。snapshot 是每次读取前的那份页面地图，本身要花 3–8K 字符。",
    "p2_name": "站点记忆",
    "p2_title": "越用越聪明。",
    "p2_text": "你在哪个站点操作过，它就记住哪个站点：哪些步骤失败过、正文在哪个位置、哪条路径走得通。下次 Agent 回到同一个站点，这些经验直接跟着一起过去——不用再从头摸索一遍。",
    "p2_cap": "bridge memory show mail.example.com",
    "p2_p1": "记住的是页面的形状，不是你看过的东西。",
    "p2_p2": "存在你本机，不上传。",
    "p3_name": "安全审核",
    "p3_title": "Agent 做的每一件事，都要过你这一关。",
    "p3_text": "Agent 想去没批准的站点、想填密码或信用卡、想提交表单，都会先停下来问你。你说了算：只放行这一次、以后都信任，还是拒绝。随时一个开关就能把浏览器整个拿回来。",
    "p3_text2": "审批在侧边栏排成一队，不打断你手上的事。",
    "p3_l1": "站点只批一次，之后就不再问。",
    "p3_l2": "想接管随时按一下开关，Agent 立刻停手。",
    "p3_l3": "不装云浏览器，用的就是你日常那个浏览器。",
    "p3_cap": "扩展侧边栏 · 审批队列",
    "p3_alt": "Browser Bridge 扩展侧边栏示意：Takeover 开关、Approvals 审批队列、Pairing 状态",
    "p4_name": "接入方式",
    "p4_title": "CLI / MCP / Skill，任意入口。",
    "p4_text": "在终端里直接调，接到支持 MCP 的客户端，或者装一个 Skill 让你的 Agent 学会开浏览器——挑你顺手的那个。",
    "p4_e1": "终端里直接用，开标签页、点按钮、读页面，一整套命令。",
    "p4_e2": "Claude Desktop、Cursor、Codex 这些客户端，填一段配置就能连上。",
    "p4_e3": "装上 Skill，你正在用的 Agent 就有了开浏览器的能力。",
    "final_note": "装好后，在 Chrome 里把 ~/Browser-Bridge/extension/ 作为解压缩的扩展加载。需要 Chrome 114 或更高版本。",
    "copy_idle": "复制",
    "copy_done": "已复制",
    "final_title": "现在开始，为 Agent 连接你的浏览器",
    "final_meta2": "Chrome 114+",
    "final_meta3": "Go · TypeScript",
  },

  en: {
    "lang_attr": "en",
    "title": "Browser Bridge · Turn your local Chrome into a tool for any agent",
    "skip": "Skip to main content",
    "nav_token": "Token efficiency",
    "nav_memory": "Site memory",
    "nav_safety": "Approvals",
    "nav_entry": "Interfaces",
    "hero_kicker": "OPEN SOURCE · MIT · RUNS ON YOUR MACHINE",
    "hero_title": "Your browser becomes<br>a tool any agent can drive",
    "hero_sub": "One bridge protocol, reached from the CLI, an MCP client, or a skill. Install the skill and whichever agent you already use can drive the browser. No cloud browser, no second login — your sessions stay on your machine.",
    "hero_cta": "View on GitHub",
    "hero_cta2": "How to install",
    "hero_cap": "AGENT DRIVING CHROME",
    "hero_alt": "An agent opening Gmail through Browser Bridge and reading the inbox",
    "p1_name": "TOKEN EFFICIENCY",
    "p1_title": "The page is 324,078 characters. The agent reads 546.",
    "p1_text": "A snapshot gives the agent a map of the page first: what is clickable, what the headings are, roughly where the content sits. It then reads only the piece it needs instead of pushing the whole page into context. Oversized results are rejected outright.",
    "p1_ratio1": "Signal-to-noise",
    "p1_ratio2": "GMAIL INBOX · LOGGED-IN CHROME<br>MEASURED 2026-09-15",
    "p1_table_cap": "Measured signal-to-noise on three real pages",
    "p1_th1": "Page",
    "p1_th2": "Full HTML",
    "p1_th3": "Signal needed",
    "p1_th4": "Ratio",
    "p1_row1": "Gmail inbox",
    "p1_row2": "GitHub notifications",
    "p1_row3": "Eastmoney article",
    "p1_foot": "Counted in characters, measured 2026-09-15. A snapshot is the map of the page the agent sees before reading; that map itself costs 3–8K characters.",
    "p2_name": "SITE MEMORY",
    "p2_title": "It gets smarter with use.",
    "p2_text": "Work through a site once and it remembers that site: which steps failed, where the content lives, which route worked. Next time an agent lands there, everything it learned comes along — no starting over.",
    "p2_cap": "bridge memory show mail.example.com",
    "p2_p1": "It remembers the shape of a page, not what you were reading.",
    "p2_p2": "Kept on your machine. Nothing is uploaded.",
    "p3_name": "APPROVALS",
    "p3_title": "Everything your agent does goes through you.",
    "p3_text": "Before it opens a site you have not approved, types into a password or card field, or submits a form, the agent stops and asks. You decide: allow this once, trust it from now on, or refuse. A single switch hands the whole browser back to you at any time.",
    "p3_text2": "Approvals wait in the sidebar instead of interrupting what you are doing.",
    "p3_l1": "Approve a site once and it stops asking.",
    "p3_l2": "Flip the takeover switch and the agent stops mid-step.",
    "p3_l3": "No cloud browser — it drives the one you use every day.",
    "p3_cap": "EXTENSION SIDEBAR · APPROVAL QUEUE",
    "p3_alt": "An illustration of the Browser Bridge extension sidebar: the Takeover switch, the Approvals queue, and pairing status",
    "p4_name": "INTERFACES",
    "p4_title": "CLI, MCP, or skill — take your pick.",
    "p4_text": "Drive it from your terminal, plug it into any MCP client, or install a skill and let your agent learn to use the browser. Whichever fits how you already work.",
    "p4_e1": "Run it straight from your terminal — open tabs, click, read pages, the full command set.",
    "p4_e2": "Claude Desktop, Cursor, Codex: add a block of config and you are connected.",
    "p4_e3": "Install the skill and whichever agent you use can open a browser.",
    "final_note": "After it runs, load ~/Browser-Bridge/extension/ as an unpacked extension in Chrome. Requires Chrome 114 or later.",
    "copy_idle": "Copy",
    "copy_done": "Copied",
    "final_title": "Connect your browser to your agent now",
    "final_meta2": "Chrome 114+",
    "final_meta3": "Go · TypeScript",
  },
};

/* 需要写入富文本（含 <br>、<code>）的 key 走 innerHTML，其余走 textContent */
const RICH_KEYS = new Set(["hero_title", "p1_ratio2"]);

const INSTALL_CMD =
  "curl -fsSL https://github.com/dkisser/browser-bridge/releases/latest/download/install.sh | bash";

const root = document.documentElement;
const nodes = document.querySelectorAll("[data-i18n]");
const langButtons = document.querySelectorAll("[data-set-lang]");

function applyLang(lang) {
  const dict = I18N[lang] || I18N.zh;

  root.setAttribute("data-lang", lang);
  root.setAttribute("lang", dict.lang_attr);
  document.title = dict.title;

  nodes.forEach((node) => {
    const value = dict[node.dataset.i18n];
    if (value === undefined) return;
    if (RICH_KEYS.has(node.dataset.i18n)) node.innerHTML = value;
    else node.textContent = value;
  });

  langButtons.forEach((btn) => {
    btn.classList.toggle("is-active", btn.dataset.setLang === lang);
  });

  try {
    localStorage.setItem("bb-lang", lang);
  } catch (_) {
    /* 隐私模式下 localStorage 不可用，忽略即可，页面仍正常显示 */
  }
}

langButtons.forEach((btn) => {
  btn.addEventListener("click", () => applyLang(btn.dataset.setLang));
});

function initialLang() {
  try {
    const saved = localStorage.getItem("bb-lang");
    if (saved === "zh" || saved === "en") return saved;
  } catch (_) {
    /* 忽略 */
  }
  return navigator.language && navigator.language.toLowerCase().startsWith("en") ? "en" : "zh";
}

applyLang(initialLang());

/* ---------- 复制安装命令 ---------- */
const copyBtn = document.getElementById("copy-btn");
const copyLabel = copyBtn && copyBtn.querySelector(".copy-label");
const cmdEl = document.getElementById("install-cmd-text");
let copyTimer;

function announceCopied() {
  if (!copyBtn || !copyLabel) return;
  copyBtn.classList.add("is-done");
  copyLabel.textContent = I18N[root.dataset.lang].copy_done;
  clearTimeout(copyTimer);
  copyTimer = setTimeout(() => {
    copyBtn.classList.remove("is-done");
    copyLabel.textContent = I18N[root.dataset.lang].copy_idle;
  }, 1800);
}

async function copyInstallCommand() {
  const text = cmdEl ? cmdEl.textContent.trim() : INSTALL_CMD;
  try {
    await navigator.clipboard.writeText(text);
    announceCopied();
  } catch (_) {
    // 剪贴板 API 不可用（非安全上下文 / 权限被拒）时退回手动选中
    if (cmdEl) {
      const range = document.createRange();
      range.selectNodeContents(cmdEl);
      const sel = window.getSelection();
      sel.removeAllRanges();
      sel.addRange(range);
    }
  }
}

if (copyBtn) copyBtn.addEventListener("click", copyInstallCommand);

/* ---------- 动效偏好：静帧替换动态录屏 ---------- */
if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) {
  const demo = document.getElementById("hero-demo");
  if (demo && demo.dataset.poster) demo.src = demo.dataset.poster;
}