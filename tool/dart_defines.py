#!/usr/bin/env python3
"""Inaandika faili la --dart-define-from-file kutoka environment variables.

    python3 tool/dart_defines.py build/defines.json
    flutter build apk --dart-define-from-file=build/defines.json

Vigezo: SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY (bila hivi app inajengwa kama demo), WEB_BASE_URL,
SUPPORT_EMAIL, SUPPORT_PHONE, IN_APP_PURCHASES. Thamani zenye nafasi (mf. namba ya simu) zinabaki sahihi.
"""
import json
import os
import sys

env = {k: os.environ.get(k, "").strip() for k in (
    "SUPABASE_URL", "SUPABASE_PUBLISHABLE_KEY", "WEB_BASE_URL", "SUPPORT_EMAIL", "SUPPORT_PHONE", "IN_APP_PURCHASES")}

defines = {}
if env["SUPABASE_URL"] and env["SUPABASE_PUBLISHABLE_KEY"]:
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
