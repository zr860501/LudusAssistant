#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:?source root required}"

OBS="$ROOT/app/src/main/java/com/ludusassistant/app/vision/ObservationPipeline.java"
MAIN="$ROOT/app/src/main/java/com/ludusassistant/app/MainActivity.java"
SNAP="$ROOT/app/src/main/java/com/ludusassistant/app/account/AccountSnapshot.java"
OCR="$ROOT/app/src/main/java/com/ludusassistant/app/vision/OcrEngine.java"
EVENT=$(find "$ROOT" -type f -name 'EventStore.java' | head -1)

python3 - "$OBS" <<'PY'
from pathlib import Path
import sys
p=Path(sys.argv[1]); s=p.read_text()
needle='import com.ludusassistant.app.vision.parser.ExpandedResourcePanelParser;\n'
insert=needle+'import com.ludusassistant.app.vision.parser.ResourceRegionProfiles;\nimport com.ludusassistant.app.vision.parser.SpatialResourceParser;\n'
if 'import com.ludusassistant.app.vision.parser.SpatialResourceParser;' not in s:
    s=s.replace(needle,insert)
p.write_text(s)
PY

python3 - "$MAIN" <<'PY'
from pathlib import Path
import sys
p=Path(sys.argv[1]); s=p.read_text()
s=s.replace('private final Runnable hourly=()->{ render(); handler.postDelayed(hourly,60L*60L*1000L); };',
            'private final Runnable hourly=new Runnable(){ @Override public void run(){ render(); handler.postDelayed(this,60L*60L*1000L); } };')
s=s.replace('private LinearLayout build(){', 'private ScrollView build(){')
p.write_text(s)
PY

python3 - "$SNAP" <<'PY'
from pathlib import Path
import sys
p=Path(sys.argv[1]); s=p.read_text()
needle='    public JSONObject toJson() {'
if 'public String source()' not in s:
    s=s.replace(needle,'    public String source() {\n        try { return toJson().optString("source", "unknown"); } catch (Exception ignored) { return "unknown"; }\n    }\n\n'+needle)
p.write_text(s)
PY

python3 - "$OCR" <<'PY'
from pathlib import Path
import sys
p=Path(sys.argv[1]); s=p.read_text().replace('android.graphics.ImageFormat.RGBA_8888','android.graphics.PixelFormat.RGBA_8888')
p.write_text(s)
PY

# Replace EventStore with an implementation that handles every JSON operation
# whose checked-exception signature differs between Android JSON stubs.
if [ -n "${EVENT:-}" ] && [ -f "$EVENT" ]; then
cat > "$EVENT" <<'JAVA'
package com.ludusassistant.app.data;

import android.content.Context;
import android.content.SharedPreferences;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

/** Local event/calendar store. Remote ingestion is deliberately separate. */
public final class EventStore {
    private final SharedPreferences p;
    private static final String KEY = "events";

    public EventStore(Context c) {
        p = c.getSharedPreferences("ludus_events", Context.MODE_PRIVATE);
    }

    public synchronized JSONArray all() {
        try {
            return new JSONArray(p.getString(KEY, "[]"));
        } catch (JSONException e) {
            return new JSONArray();
        }
    }

    public synchronized void upsert(JSONObject event) {
        if (event == null) return;
        JSONArray a = all();
        String id = "";
        try {
            id = event.getString("id");
        } catch (JSONException ignored) {
        }

        boolean found = false;
        for (int i = 0; i < a.length(); i++) {
            JSONObject old = a.optJSONObject(i);
            if (old == null) continue;
            String oldId = "";
            try {
                oldId = old.getString("id");
            } catch (JSONException ignored) {
            }
            if (!id.isEmpty() && id.equals(oldId)) {
                try {
                    a.put(i, event);
                    found = true;
                } catch (JSONException ignored) {
                    // Keep the existing event if this JSON implementation rejects the replacement.
                }
                break;
            }
        }

        if (!found) {
            try {
                a.put(event);
            } catch (JSONException ignored) {
                return;
            }
        }
        p.edit().putString(KEY, a.toString()).apply();
    }

    public synchronized void clear() {
        p.edit().remove(KEY).apply();
    }
}
JAVA
fi

grep -q 'import com.ludusassistant.app.vision.parser.SpatialResourceParser;' "$OBS"
grep -q 'new Runnable()' "$MAIN"
grep -q 'private ScrollView build()' "$MAIN"
grep -q 'public String source()' "$SNAP"
grep -q 'android.graphics.PixelFormat.RGBA_8888' "$OCR"
if [ -n "${EVENT:-}" ] && [ -f "$EVENT" ]; then
  grep -q 'event.getString("id")' "$EVENT"
  grep -q 'a.put(i, event)' "$EVENT"
  grep -q 'catch (JSONException ignored)' "$EVENT"
fi

echo 'V2.9 build fixes applied.'
