#!/usr/bin/env bash
set -euo pipefail
ROOT="${1:?source root required}"
# Overlay expanded knowledge without replacing the user's V2.9 source archive.
cp "$GITHUB_WORKSPACE/.github/ci/DefaultKnowledge.java" "$ROOT/app/src/main/java/com/ludusassistant/app/data/DefaultKnowledge.java"
cp "$GITHUB_WORKSPACE/.github/ci/HeroRepository.java" "$ROOT/app/src/main/java/com/ludusassistant/app/hero/HeroRepository.java"
python3 - "$ROOT/app/src/main/java/com/ludusassistant/app/data/EventStore.java" "$ROOT/app/src/main/java/com/ludusassistant/app/data/GuideRepository.java" "$ROOT/app/src/main/java/com/ludusassistant/app/capture/CaptureService.java" "$ROOT/app/src/main/java/com/ludusassistant/app/vision/OcrEngine.java" <<'PY'
from pathlib import Path
import sys
p=Path(sys.argv[1]); s=p.read_text().replace('p.getString(KEY,"[]")','p.getString(KEY,DefaultKnowledge.events().toString())'); p.write_text(s)
p=Path(sys.argv[2]); s=p.read_text().replace('p.getString("items",defaultGuides().toString())','p.getString("items",DefaultKnowledge.guides().toString())'); p.write_text(s)
p=Path(sys.argv[3]); s=p.read_text().replace('if (now - lastFrameNs < 250_000_000L) return;','if (now - lastFrameNs < 500_000_000L) return;'); p.write_text(s)
p=Path(sys.argv[4]); s=p.read_text();
s=s.replace('InputImage input = InputImage.fromBitmap(bitmap, 0);','''Bitmap work = bitmap;\n        int maxW = 720;\n        if (bitmap.getWidth() > maxW) {\n            int h = Math.max(1, Math.round(bitmap.getHeight() * (maxW / (float) bitmap.getWidth())));\n            work = Bitmap.createScaledBitmap(bitmap, maxW, h, true);\n            bitmap.recycle();\n        }\n        InputImage input = InputImage.fromBitmap(work, 0);''')
s=s.replace('finish(bitmap, ch, callback)','finish(work, ch, callback)').replace('finish(bitmap, result, callback)','finish(work, result, callback)').replace('finish(bitmap, null, callback, e)','finish(work, null, callback, e)')
s=s.replace('image.getFormat() != android.graphics.ImageFormat.RGBA_8888 && image.getPlanes().length == 0','image.getFormat() != android.graphics.PixelFormat.RGBA_8888 || image.getPlanes().length == 0')
p.write_text(s)
PY
