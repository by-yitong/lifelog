#!/usr/bin/env python3
"""用远端视觉模型评估候选 logo（描述/文字正确性/居中/小尺寸可读性打分）。"""
import base64, json, mimetypes, os, sys, urllib.request

SKILL_CFG = os.path.expanduser("~/.agents/skills/ui-dna/config.json")
cfg = json.load(open(SKILL_CFG)) if os.path.exists(SKILL_CFG) else {}
KEY = os.environ.get("XIAOXINAI_API_KEY") or cfg.get("api_key")
BASE = os.environ.get("XIAOXINAI_BASE_URL") or cfg.get("base_url", "https://xiaoxinai.xyz/v1")
MODEL = os.environ.get("XIAOXINAI_MODEL") or cfg.get("model", "gpt-5.6-sol")

PROMPT = """你是应用图标评审。这是计数器 App「数一数」的候选 logo。请只返回一个 JSON 对象：
{"subject": "画面主体与风格(一句话)",
 "text_found": "图上出现的文字/符号原文",
 "text_correct": true/false 文字是否渲染正确无乱码,
 "centering_ok": true/false 构图是否居中平衡,
 "corner_info": "四角是什么颜色(约hex)，图标是不是圆角方块贴边",
 "bg_hex_estimate": "背景色hex",
 "small_size_ok": true/false 缩到48px后主体是否仍清晰可辨,
 "issues": ["具体问题..."],
 "score": 1-10 作为启动图标的综合分}
不要 markdown 围栏。"""

def ask(path):
    mime = mimetypes.guess_type(path)[0] or "image/png"
    b64 = base64.b64encode(open(path, "rb").read()).decode()
    body = json.dumps({
        "model": MODEL,
        "messages": [{"role": "user", "content": [
            {"type": "image_url", "image_url": {"url": f"data:{mime};base64,{b64}"}},
            {"type": "text", "text": PROMPT},
        ]}],
        "max_tokens": 800,
    }).encode()
    req = urllib.request.Request(
        f"{BASE}/chat/completions", data=body,
        headers={"Authorization": f"Bearer {KEY}", "Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=180) as r:
        reply = json.load(r)["choices"][0]["message"]["content"]
    return json.loads(reply.strip().strip("`").removeprefix("json").strip())

for p in sys.argv[1:]:
    try:
        print(f"=== {p} ===")
        print(json.dumps(ask(p), ensure_ascii=False, indent=1))
    except Exception as e:
        print(f"ERROR {p}: {e}")
