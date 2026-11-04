#!/usr/bin/env python3
"""Inaandika faili la --dart-define-from-file kutoka environment variables.

    python3 tool/dart_defines.py build/defines.json
    flutter build apk --dart-define-from-file=build/defines.json

Vigezo: SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY, WEB_BASE_URL, SUPPORT_EMAIL, SUPPORT_PHONE, IN_APP_PURCHASES.
Thamani ambazo hazijawekwa zinachukuliwa kutoka config/production.json (project ya Supabase ya U'r Invente;
publishable key ni ya umma, data inalindwa na RLS). DEMO=true inajenga demo yenye data ya mfano.
Thamani zenye nafasi (mf. namba ya simu) zinabaki sahihi.
"""
import json
import os
import sys

KEYS = ("SUPABASE_URL", "SUPABASE_PUBLISHABLE_KEY", "WEB_BASE_URL", "SUPPORT_EMAIL", "SUPPORT_PHONE", "IN_APP_PURCHASES")
root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
try:
    with open(os.path.join(root, "config", "production.json"), encoding="utf-8") as f:
        production = json.load(f)
except FileNotFoundError:
    production = {}
env = {k: (os.environ.get(k, "").strip() or str(production.get(k, "")).strip()) for k in KEYS}
demo = os.environ.get("DEMO", "").strip().lower() == "true"

defines = {}
if not demo and env["SUPABASE_URL"] and env["SUPABASE_PUBLISHABLE_KEY"]:
    defines["SUPABASE_URL"] = env["SUPABASE_URL"]
    defines["SUPABASE_PUBLISHABLE_KEY"] = env["SUPABASE_PUBLISHABLE_KEY"]
else:
    defines["DEMO"] = "true"
if env["WEB_BASE_URL"]:
    base = env["WEB_BASE_URL"].rstrip("/")
    defines["WEB_BASE_URL"] = base
    defines["RSVP_BASE_URL"] = base + "/rsvp/"
for key in ("SUPPORT_EMAIL", "SUPPORT_PHONE", "IN_APP_PURCHASES"):
    if env[key]:
        defines[key] = env[key]

out = sys.argv[1] if len(sys.argv) > 1 else "build/defines.json"
os.makedirs(os.path.dirname(out) or ".", exist_ok=True)
with open(out, "w", encoding="utf-8") as f:
    json.dump(defines, f, indent=2)
mode = "demo" if "DEMO" in defines else "production"
print(f"{out}: {mode}, {', '.join(sorted(defines))}")
