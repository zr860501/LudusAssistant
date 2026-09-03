#!/usr/bin/env bash
set -euo pipefail
ROOT="${1:?source root required}"
OBS="$ROOT/app/src/main/java/com/ludusassistant/app/vision/ObservationPipeline.java"
MAIN="$ROOT/app/src/main/java/com/ludusassistant/app/MainActivity.java"
SNAP="$ROOT/app/src/main/java/com/ludusassistant/app/account/AccountSnapshot.java"
OCR="$ROOT/app/src/main/java/com/ludusassistant/app/vision/OcrEngine.java"
EVENT="$ROOT/app/src/main/java/com/ludusassistant/app/data/EventStore.java"
STORE="$ROOT/app/src/main/java/com/ludusassistant/app/data/AppStore.java"
GUIDE="$ROOT/app/src/main/java/com/ludusassistant/app/data/GuideRepository.java"
OBSENG="$ROOT/app/src/main/java/com/ludusassistant/app/data/ObservationEngine.java"
CAPTURE="$ROOT/app/src/main/java/com/ludusassistant/app/capture/CaptureService.java"
SCREEN="$ROOT/app/src/main/java/com/ludusassistant/app/vision/parser/ScreenTextParser.java"
RECEIVER="$ROOT/app/src/main/java/com/ludusassistant/app/data/RefreshReceiver.java"
GRADLE="$ROOT/app/build.gradle"
TESTDIR="$ROOT/app/src/test/java/com/ludusassistant/app"

python3 - "$OBS" <<'PY'
from pathlib import Path
import sys
p=Path(sys.argv[1]); s=p.read_text(); needle='import com.ludusassistant.app.vision.parser.ExpandedResourcePanelParser;\n'; insert=needle+'import com.ludusassistant.app.vision.parser.ResourceRegionProfiles;\nimport com.ludusassistant.app.vision.parser.SpatialResourceParser;\n'
if 'import com.ludusassistant.app.vision.parser.SpatialResourceParser;' not in s:s=s.replace(needle,insert)
p.write_text(s)
PY

python3 - "$MAIN" <<'PY'
from pathlib import Path
import sys
p=Path(sys.argv[1]); s=p.read_text(); s=s.replace('private final Runnable hourly=()->{ render(); handler.postDelayed(hourly,60L*60L*1000L); };','private final Runnable hourly=new Runnable(){ @Override public void run(){ render(); handler.postDelayed(this,60L*60L*1000L); } };').replace('private LinearLayout build(){','private ScrollView build(){').replace('攻略周期 60 分钟','攻略刷新检查周期 60 分钟').replace('数据原则：游戏状态以本机观测为主；攻略目标刷新周期 60 分钟；网络中断时继续使用本地缓存。','数据原则：游戏状态以本机观测为主；攻略刷新检查周期 60 分钟；网络中断时继续使用本地缓存；只有成功同步后才更新缓存时间。')
if 'import com.ludusassistant.app.vision.resource.LudusResourceCatalog;' not in s:s=s.replace('import com.ludusassistant.app.shop.ShopAdvisor;','import com.ludusassistant.app.shop.ShopAdvisor;\nimport com.ludusassistant.app.vision.resource.LudusResourceCatalog;')
old='JSONObject r=store.resources(); resources.setText("💎 钻石  "+val(r,"diamonds")+"\\n🟢 祖母绿  "+val(r,"emeralds")+"\\n🪙 金币  "+val(r,"gold")+"\\n🎟 代币  "+val(r,"tokens"));'
new='JSONObject r=store.resources(); StringBuilder resourceText=new StringBuilder(); for(LudusResourceCatalog.Definition d:LudusResourceCatalog.definitions()){ resourceText.append("• ").append(d.labels.get(0)).append("：").append(val(r,d.key)).append("\\n"); } resources.setText(resourceText.toString().trim());'
if old in s:s=s.replace(old,new)
s=s.replace('''        if (!pid.isEmpty() && snap.observedAt == 0) {\n            snapshots.save(com.ludusassistant.app.data.AccountSnapshotBuilder.fromObserved(pid, store, snap), "local-observation", conf);\n            snap = snapshots.get();\n        }''','')
p.write_text(s)
PY

python3 - "$SNAP" <<'PY'
from pathlib import Path
import sys
p=Path(sys.argv[1]); s=p.read_text(); needle='    public JSONObject toJson() {'
if 'public String source()' not in s:s=s.replace(needle,'    public String source() {\n        try { return toJson().optString("source", "unknown"); } catch (Exception ignored) { return "unknown"; }\n    }\n\n'+needle)
p.write_text(s)
PY

python3 - "$OCR" <<'PY'
from pathlib import Path
import sys
p=Path(sys.argv[1]); s=p.read_text().replace('android.graphics.ImageFormat.RGBA_8888','android.graphics.PixelFormat.RGBA_8888').replace('image.getFormat() != android.graphics.PixelFormat.RGBA_8888 && image.getPlanes().length == 0','image.getFormat() != android.graphics.PixelFormat.RGBA_8888 || image.getPlanes().length == 0'); p.write_text(s)
PY

cat > "$EVENT" <<'JAVA'
package com.ludusassistant.app.data;
import android.content.Context;
import android.content.SharedPreferences;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;
public final class EventStore {
 private final SharedPreferences p; private static final String KEY="events";
 public EventStore(Context c){p=c.getSharedPreferences("ludus_events",Context.MODE_PRIVATE);}
 public synchronized JSONArray all(){try{return new JSONArray(p.getString(KEY,"[]"));}catch(JSONException e){return new JSONArray();}}
 public synchronized void upsert(JSONObject event){if(event==null)return;JSONArray a=all();String id="";try{id=event.getString("id");}catch(JSONException ignored){}boolean found=false;for(int i=0;i<a.length();i++){JSONObject old=a.optJSONObject(i);if(old==null)continue;String oldId="";try{oldId=old.getString("id");}catch(JSONException ignored){}if(!id.isEmpty()&&id.equals(oldId)){try{a.put(i,event);found=true;break;}catch(JSONException ignored){return;}}}if(!found)a.put(event);p.edit().putString(KEY,a.toString()).apply();}
 public synchronized void clear(){p.edit().remove(KEY).apply();}
}
JAVA

python3 - "$STORE" <<'PY'
from pathlib import Path
import sys
p=Path(sys.argv[1]); s=p.read_text().replace('before.put(key,value); p.edit().putString(RES,before.toString()).apply();','before.put(key,value);').replace('JSONArray log=resourceLog(); log.put(row); while(log.length()>1000) log.remove(0); p.edit().putString(LOG,log.toString()).apply();','JSONArray log=resourceLog(); log.put(row); while(log.length()>1000) log.remove(0); p.edit().putString(RES,before.toString()).putString(LOG,log.toString()).apply();'); p.write_text(s)
PY

python3 - "$GUIDE" <<'PY'
from pathlib import Path
import sys
p=Path(sys.argv[1]); s=p.read_text().replace('p.edit().putString("items",items.toString()).putString("version",gameVersion==null?"unknown":gameVersion).putLong("updated",System.currentTimeMillis()).apply();','p.edit().putString("items",items==null?new JSONArray().toString():items.toString()).putString("version",gameVersion==null?"unknown":gameVersion).putLong("updated",System.currentTimeMillis()).putBoolean("refresh_due",false).apply();'); p.write_text(s)
PY

python3 - "$OBSENG" <<'PY'
from pathlib import Path
import sys
p=Path(sys.argv[1]); s=p.read_text();
if 'import com.ludusassistant.app.vision.resource.LudusResourceCatalog;' not in s:s=s.replace('import org.json.JSONObject;','import org.json.JSONObject;\nimport com.ludusassistant.app.vision.resource.LudusResourceCatalog;')
old='''String[] keys={"diamonds","emeralds","gold","tokens"};\n        for(String k:keys){\n            if(snapshot.has(k) && !snapshot.isNull(k)){\n                long v=snapshot.optLong(k,Long.MIN_VALUE);\n                if(v!=Long.MIN_VALUE) store.observe(k,v,source);\n            }\n        }'''
new='''for(LudusResourceCatalog.Definition definition:LudusResourceCatalog.definitions()){\n            String k=definition.key;\n            if(snapshot.has(k) && !snapshot.isNull(k)){\n                long v=snapshot.optLong(k,Long.MIN_VALUE);\n                if(v!=Long.MIN_VALUE) store.observe(k,v,source);\n            }\n        }'''
if old in s:s=s.replace(old,new)
p.write_text(s)
PY

python3 - "$CAPTURE" <<'PY'
from pathlib import Path
import sys
p=Path(sys.argv[1]); s=p.read_text();
if 'import com.ludusassistant.app.data.AccountSnapshotBuilder;' not in s:s=s.replace('import com.ludusassistant.app.data.AppStore;','import com.ludusassistant.app.data.AppStore;\nimport com.ludusassistant.app.data.AccountSnapshotBuilder;\nimport com.ludusassistant.app.account.AccountSnapshotStore;\nimport com.ludusassistant.app.account.PlayerIdStore;')
s=s.replace('    private AppStore store;','    private AppStore store;\n    private AccountSnapshotStore snapshots;\n    private PlayerIdStore playerIds;').replace('store = new AppStore(this); ocr = new OcrEngine();','store = new AppStore(this); snapshots = new AccountSnapshotStore(this); playerIds = new PlayerIdStore(this); ocr = new OcrEngine();')
needle='''                        for (java.util.Map.Entry<String, String> field : obs.text.entrySet()) {\n                            try {\n                                long value = Long.parseLong(field.getValue());\n                                long old = store.resources().optLong(field.getKey(), Long.MIN_VALUE);\n                                if (old == Long.MIN_VALUE || old != value) {\n                                    store.observe(field.getKey(), value, result.tokens.isEmpty() ? "ocr" : "ocr+spatial");\n                                }\n                            } catch (NumberFormatException ignored) { }\n                        }'''
if 'snapshots.save(AccountSnapshotBuilder.fromObserved' not in s:s=s.replace(needle,needle+'''\n                        String playerId = playerIds == null ? "" : playerIds.get();\n                        if (PlayerIdStore.isValid(playerId)) {\n                            com.ludusassistant.app.account.AccountSnapshot previous = snapshots.get();\n                            snapshots.save(AccountSnapshotBuilder.fromObserved(playerId, store, previous), "local-observation", obs.confidence);\n                        }''')
p.write_text(s)
PY

python3 - "$SCREEN" <<'PY'
from pathlib import Path
import sys
p=Path(sys.argv[1]); s=p.read_text(); s=s.replace('''if (containsAny(s, "play now", "立即游戏", "广告", "ad", "sponsored")) return GamePage.ADVERTISEMENT;\n        if (containsAny(s, "安装", "install", "clash of clans", "google play")) return GamePage.EXTERNAL_APP_INSTALL;''','''if (containsAny(s, "安装", "install", "clash of clans", "google play")) return GamePage.EXTERNAL_APP_INSTALL;\n        if (containsAny(s, "play now", "立即游戏", "广告", "sponsored") || containsWord(s, "ad")) return GamePage.ADVERTISEMENT;''')
if 'private static boolean containsWord' not in s:s=s.replace('''private static boolean containsAny(String value, String... terms) {\n        for (String term : terms) if (value.contains(term)) return true;\n        return false;\n    }''','''private static boolean containsAny(String value, String... terms) {\n        for (String term : terms) if (value.contains(term)) return true;\n        return false;\n    }\n    private static boolean containsWord(String value, String word) {\n        int from=0; while(from<value.length()){ int i=value.indexOf(word,from); if(i<0)return false; boolean left=i==0||!Character.isLetterOrDigit(value.charAt(i-1)); int end=i+word.length(); boolean right=end>=value.length()||!Character.isLetterOrDigit(value.charAt(end)); if(left&&right)return true; from=end; } return false;\n    }''')
p.write_text(s)
PY

python3 - "$RECEIVER" <<'PY'
from pathlib import Path
import sys
p=Path(sys.argv[1]); s=p.read_text(); old='''GuideRepository g=new GuideRepository(c);\n        if(g.due()){\n            AppStore s=new AppStore(c); s.markSync();\n        }'''; new='''GuideRepository g=new GuideRepository(c);\n        if(g.due()){\n            c.getSharedPreferences("ludus_guides", Context.MODE_PRIVATE).edit().putBoolean("refresh_due", true).apply();\n        }'''; p.write_text(s.replace(old,new))
PY

python3 - "$GRADLE" <<'PY'
from pathlib import Path
import sys
p=Path(sys.argv[1]); s=p.read_text();
if "testImplementation 'junit:junit:4.13.2'" not in s:s=s.replace('dependencies {','dependencies {\n    testImplementation \'junit:junit:4.13.2\'')
p.write_text(s)
PY

mkdir -p "$TESTDIR/automation" "$TESTDIR/vision/parser"
cat > "$TESTDIR/automation/AutomationPlannerTest.java" <<'JAVA'
package com.ludusassistant.app.automation;
import org.junit.Test; import java.util.Arrays; import java.util.List; import static org.junit.Assert.*;
public final class AutomationPlannerTest {
 @Test public void plannerHonorsPriorityApprovalAndMatchBlocking(){long now=1_000_000L;List<AutomationTask> plan=AutomationPlanner.buildDailyPlan(false,true,true,true,true,true,true,now);assertEquals(TaskType.DAILY_LOGIN,plan.get(0).type);assertEquals(7,plan.size());AutomationPlanner.approve(plan,Arrays.asList("free-reward","event-task","token-task","pvp"));assertEquals(TaskState.APPROVED,plan.get(1).state);AutomationTask duringMatch=AutomationPlanner.nextRunnable(plan,now,0,true);assertNotNull(duringMatch);assertNotEquals(TaskType.AD_REWARD,duringMatch.type);assertEquals(TaskState.WAITING_FOR_AD,AutomationPlanner.stateAfterMatch(true));}
 @Test public void adCooldownIsEnforced(){long now=1_000_000L;AutomationTask ad=new AutomationTask("ad",TaskType.AD_REWARD,"ad",50,true,now,60_000);ad.state=TaskState.APPROVED;assertFalse(ad.eligible(now+30_000,now,false));assertTrue(ad.eligible(now+60_000,now,false));}
}
JAVA
cat > "$TESTDIR/vision/parser/VisionParserTest.java" <<'JAVA'
package com.ludusassistant.app.vision.parser;
import com.ludusassistant.app.vision.OcrToken; import com.ludusassistant.app.vision.resource.LudusResourceCatalog; import com.ludusassistant.app.vision.model.GamePage; import org.junit.Test; import java.util.*; import static org.junit.Assert.*;
public final class VisionParserTest {
 @Test public void expandedPanelUsesNearbyNumber(){List<OcrToken> t=Arrays.asList(new OcrToken("祖母绿",.95f,100,100,160,130),new OcrToken("12345",.98f,110,145,180,170),new OcrToken("999",.98f,700,900,760,930),new OcrToken("金币",.95f,300,300,340,330),new OcrToken("54321",.97f,305,345,380,370));Map<String,Long> o=new ExpandedResourcePanelParser().parse(t);assertEquals(Long.valueOf(12345),o.get("emeralds"));assertEquals(Long.valueOf(54321),o.get("gold"));assertFalse(o.containsValue(999L));}
 @Test public void installStateWinsAndAdKeywordIsBounded(){assertEquals(GamePage.EXTERNAL_APP_INSTALL,ScreenTextParser.classify("Clash of Clans Install"));assertEquals(GamePage.ADVERTISEMENT,ScreenTextParser.classify("Sponsored Play Now"));assertEquals(GamePage.HOME,ScreenTextParser.classify("address book"));}
 @Test public void catalogHasSixteenCanonicalResources(){assertEquals(16,LudusResourceCatalog.definitions().size());Set<String> keys=new HashSet<>();for(LudusResourceCatalog.Definition d:LudusResourceCatalog.definitions())assertTrue(keys.add(d.key));}
}
JAVA

echo 'V2.9 audited compatibility fixes applied.'
