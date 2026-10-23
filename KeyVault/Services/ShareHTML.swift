import Foundation

/// 电脑浏览器访问时返回的上传页面（中文界面，提交后立即写入 App）
enum ShareHTML {
    static let page: String = #"""
<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>私人管家 · 从电脑上传</title>
<style>
  :root { color-scheme: light dark; }
  * { box-sizing: border-box; }
  body {
    margin: 0; padding: 24px 16px 48px;
    font-family: -apple-system, "PingFang SC", "Microsoft YaHei", sans-serif;
    background: #eef0f5; color: #1c1c1e;
  }
  .wrap { max-width: 620px; margin: 0 auto; }
  .card {
    background: #fff; border-radius: 14px; padding: 22px;
    box-shadow: 0 8px 24px rgba(0,0,0,.06); margin-bottom: 18px;
  }
  h1 { font-size: 20px; margin: 0 0 6px; }
  .sub { color: #8a8a8e; font-size: 13px; margin: 0 0 14px; }
  label { display: block; font-size: 13px; color: #6c6c70; margin: 14px 0 6px; }
  input, textarea {
    width: 100%; padding: 10px 12px; border: 1px solid #d5d5da; border-radius: 10px;
    font-size: 15px; background: #fafafa; color: inherit; outline: none;
  }
  input:focus, textarea:focus { border-color: #4a5cf0; background: #fff; }
  textarea { min-height: 88px; resize: vertical; }
  .row { display: flex; gap: 12px; }
  .actions { display: flex; gap: 12px; margin-top: 20px; }
  button.primary {
    flex: 1; padding: 12px; border: 0; border-radius: 10px; background: #4a5cf0;
    color: #fff; font-size: 15px; font-weight: 600; cursor: pointer;
  }
  button.plain {
    padding: 12px 16px; border: 1px solid #d5d5da; border-radius: 10px;
    background: transparent; color: inherit; font-size: 14px; cursor: pointer;
  }
  .msg { margin-top: 14px; font-size: 14px; min-height: 20px; }
  .msg.ok { color: #2e9e4f; }
  .msg.err { color: #d33; }
  table { width: 100%; border-collapse: collapse; font-size: 14px; }
  th, td { text-align: left; padding: 8px 6px; border-bottom: 1px solid #eee; }
  th { color: #8a8a8e; font-weight: 500; }
  td.time { color: #8a8a8e; white-space: nowrap; }
  .empty { color: #8a8a8e; font-size: 14px; padding: 8px 0; }
  @media (prefers-color-scheme: dark) {
    body { background: #101014; color: #eee; }
    .card { background: #1c1c22; box-shadow: 0 8px 24px rgba(0,0,0,.4); }
    input, textarea { background: #26262d; border-color: #3a3a42; }
    th, td { border-bottom-color: #2c2c33; }
    .sub, th, td.time, .empty { color: #98989e; }
  }
</style>
<!--PART2-->
</head>
<body>
<div class="wrap">
  <div class="card">
    <h1>从电脑上传密码记录</h1>
    <p class="sub">填写完成后点击「保存到手机」，记录会立即写入私人管家并保存在手机钥匙串。</p>
    <form id="form">
      <label>项目（必填）</label>
      <input id="project" placeholder="例如：GitHub" required>

      <label>用户名</label>
      <input id="username" placeholder="zhangsan@example.com" autocomplete="off">

      <label>密码</label>
      <div class="row">
        <div style="flex:1"><input id="password" placeholder="登录密码" autocomplete="new-password"></div>
        <div><button type="button" class="plain" onclick="genPassword()">生成随机密码</button></div>
      </div>

      <div class="row">
        <div style="flex:1">
          <label>数据1</label>
          <input id="data1" placeholder="自定义数据">
        </div>
        <div style="flex:1">
          <label>数据2</label>
          <input id="data2" placeholder="自定义数据">
        </div>
      </div>

      <label>备注</label>
      <textarea id="note" placeholder="补充说明"></textarea>

      <div class="actions">
        <button type="submit" class="primary">保存到手机</button>
        <button type="reset" class="plain">清空</button>
      </div>
      <div class="msg" id="msg"></div>
    </form>
  </div>

  <div class="card">
    <h1>手机上的现有记录</h1>
    <p class="sub">为安全起见，此处不显示密码内容。</p>
    <table>
      <thead><tr><th>项目</th><th>用户名</th><th>更新时间</th></tr></thead>
      <tbody id="tbody"></tbody>
    </table>
    <div class="empty" id="empty">加载中…</div>
  </div>

  <div class="empty" style="text-align:center">私人管家 · 局域网传输 · 数据保存在手机本机钥匙串</div>
</div>
<!--PART3-->
<script>
  const $ = (id) => document.getElementById(id);

  function esc(s) {
    const map = { '&':'&amp;', '<':'&lt;', '>':'&gt;', '"':'&quot;', "'":'&#39;' };
    return String(s == null ? '' : s).replace(/[&<>"']/g, (c) => map[c]);
  }

  function msg(text, ok) {
    const el = $('msg');
    el.textContent = text || '';
    el.className = 'msg ' + (ok ? 'ok' : 'err');
    if (text) {
      setTimeout(() => { if (el.textContent === text) { el.textContent = ''; el.className = 'msg'; } }, 4000);
    }
  }

  function genPassword() {
    const chars = 'abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789!@#$%^&*()-_=+';
    const buf = new Uint32Array(16);
    window.crypto.getRandomValues(buf);
    $('password').value = Array.from(buf, (n) => chars[n % chars.length]).join('');
  }

  async function loadItems() {
    try {
      const res = await fetch('/api/items', { cache: 'no-store' });
      const data = await res.json();
      const rows = (data.items || []).map((it) =>
        '<tr><td>' + esc(it.project) + '</td><td>' + esc(it.username) +
        '</td><td class="time">' + esc(it.updatedText) + '</td></tr>');
      $('tbody').innerHTML = rows.join('');
      const empty = $('empty');
      empty.style.display = rows.length ? 'none' : 'block';
      empty.textContent = '暂无记录';
    } catch (e) {
      $('empty').textContent = '加载失败，请确认手机 App 仍在前台运行';
    }
  }

  $('form').addEventListener('submit', async (event) => {
    event.preventDefault();
    const payload = {
      project: $('project').value,
      username: $('username').value,
      password: $('password').value,
      data1: $('data1').value,
      data2: $('data2').value,
      note: $('note').value
    };
    try {
      const res = await fetch('/api/items', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload)
      });
      if (res.ok) {
        msg('已保存「' + payload.project.trim() + '」，可在手机上查看', true);
        $('form').reset();
        loadItems();
      } else {
        const data = await res.json().catch(() => ({}));
        msg(data.error || ('保存失败（HTTP ' + res.status + '）'), false);
      }
    } catch (e) {
      msg('网络错误，请确认手机 App 仍在前台运行', false);
    }
  });

  loadItems();
</script>
</body>
</html>
"""#
}
