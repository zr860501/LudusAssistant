#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:?source root required}"

OBS="$ROOT/app/src/main/java/com/ludusassistant/app/vision/ObservationPipeline.java"
MAIN="$ROOT/app/src/main/java/com/ludusassistant/app/MainActivity.java"
SNAP="$ROOT/app/src/main/java/com/ludusassistant/app/account/AccountSnapshot.java"
OCR="$ROOT/app/src/main/java/com/ludusassistant/app/vision/OcrEngine.java"
EVENT=$(find "$ROOT" -type f -name 'EventStore.java' | head -1)

# Fix missing imports introduced by the V2.9 source packaging.
python3 - "$OBS" <<'PY'
from pathlib import Path
p=Path(__import__('sys').argv[1])
s=p.read_text()
needle='import com.ludusassistant.app.vision.parser.ExpandedResourcePanelParser;\n'
insert=needle+'import com.ludusassistant.app.vision.parser.ResourceRegionProfiles;\nimport com.ludusassistant.app.vision.parser.SpatialResourceParser;\n'
if 'import com.ludusassistant.app.vision.parser.SpatialResourceParser;' not in s:
    s=s.replace(needle, insert)
p.write_text(s)
PY

# Java does not allow a lambda initializer to self-reference the field being initialized.
python3 - "$MAIN" <<'PY'
from pathlib import Path
p=Path(__import__('sys').argv[1])
s=p.read_text()
s=s.replace('private final Runnable hourly=()->{ render(); handler.postDelayed(hourly,60L*60L*1000L); };',
            'private final Runnable hourly=new Runnable(){ @Override public void run(){ render(); handler.postDelayed(this,60L*60L*1000L); } };')
s=s.replace('private LinearLayout build(){', 'private ScrollView build(){')
p.write_text(s)
PY

# AccountSnapshot is intentionally a data model; expose a source() method because the UI reads it.
python3 - "$SNAP" <<'PY'
from pathlib import Path
p=Path(__import__('sys').argv[1])
s=p.read_text()
needle='    public JSONObject toJson() {'
if 'public String source()' not in s:
    s=s.replace(needle, '    public String source() {\n        try { return toJson().optString("source", "unknown"); } catch (Exception ignored) { return "unknown"; }\n    }\n\n'+needle)
p.write_text(s)
PY

# ImageFormat has no RGBA_8888 constant; PixelFormat does.
python3 - "$OCR" <<'PY'
from pathlib import Path
p=Path(__import__('sys').argv[1])
s=p.read_text().replace('android.graphics.ImageFormat.RGBA_8888', 'android.graphics.PixelFormat.RGBA_8888')
p.write_text(s)
PY

# EventStore: Android's JSON implementation may expose optString through a checked
# JSONException signature. Keep persistence robust by routing the affected lookup
# through a local safe helper instead of leaking a checked exception into callers.
if [ -n "${EVENT:-}" ] && [ -f "$EVENT" ]; then
python3 - "$EVENT" <<'PY'
from pathlib import Path
import re, sys
p=Path(sys.argv[1])
s=p.read_text()
needle='old.optString("id")'
if needle in s and 'safeEventOptString' not in s:
    s=s.replace(needle, 'safeEventOptString(old, "id")')
    # Insert helper immediately before the final class brace.
    pos=s.rfind('}')
    helper='''\n    private static String safeEventOptString(org.json.JSONObject object, String key) {\n        try {\n            return object.optString(key);\n        } catch (org.json.JSONException ignored) {\n            return "";\n        }\n    }\n'''
    if pos >= 0:
        s=s[:pos]+helper+s[pos:]
    p.write_text(s)
PY
fi

# Verify the intended fixes are present before Gradle starts.
grep -q 'import com.ludusassistant.app.vision.parser.SpatialResourceParser;' "$OBS"
grep -q 'new Runnable()' "$MAIN"
grep -q 'private ScrollView build()' "$MAIN"
grep -q 'public String source()' "$SNAP"
grep -q 'android.graphics.PixelFormat.RGBA_8888' "$OCR"
if [ -n "${EVENT:-}" ] && [ -f "$EVENT" ]; then
  grep -q 'safeEventOptString' "$EVENT"
fi

echo 'V2.9 build fixes applied.'
