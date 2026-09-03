package com.ludusassistant.app.data;
import org.json.JSONArray; import org.json.JSONObject;
/** Conservative built-in knowledge seeded from public/current references; exact live values are verified in-game. */
public final class DefaultKnowledge {
 private DefaultKnowledge(){}
 public static JSONArray events(){ JSONArray a=new JSONArray(); try{
  a.put(new JSONObject().put("id","daily").put("title","每日奖励/广告").put("type","daily").put("priority","高").put("status","按游戏实际刷新时间执行"));
  a.put(new JSONObject().put("id","tournament").put("title","Tournament / Tournament Race").put("type","tournament").put("priority","高").put("status","按客户端当前赛程"));
  a.put(new JSONObject().put("id","contest").put("title","Clan Contest / Contest Rush").put("type","clan").put("priority","高").put("status","按客户端当前赛程"));
  a.put(new JSONObject().put("id","clanwar").put("title","Clan War").put("type","clan_war").put("priority","高").put("status","按客户端当前赛程"));
  a.put(new JSONObject().put("id","battlepass").put("title","Battle Pass").put("type","pass").put("priority","中").put("status","按当前赛季"));
  a.put(new JSONObject().put("id","astral").put("title","Astral Rift").put("type","astral").put("priority","高").put("status","按当前开放周期"));
  a.put(new JSONObject().put("id","ad_gold").put("title","A Treasure Hoard 广告金币").put("type","ad").put("priority","中").put("status","每次观看150金币；15次额外5000金币（官方帮助说明）"));
 }catch(Exception ignored){} return a; }
 public static JSONArray guides(){ JSONArray a=new JSONArray(); try{
  a.put(g("核心循环：召唤→合并→利用 Battle Prowess→释放 Super Merge 能力","高","公开攻略"));
  a.put(g("同英雄+同合并等级才能合并；4级且 Battle Prowess 达20才进入 Super Merge","高","官方帮助"));
  a.put(g("阵容：5张英雄卡；根据敌方阵容、站位、协同和法术动态调整","高","公开攻略"));
  a.put(g("资源：Gold用于英雄/Perk成长；Tournament、Contest Rush、广告、Battle Pass、PvP均可获得","高","官方帮助"));
  a.put(g("Astral Hero：Astral Impulse期间全阵营属性并获得额外强化；周期结束后回归自身阵营","高","官方帮助"));
  a.put(g("PVP：记录对手法术、Super Merge、Battle Prowess和合并节奏，再决定后续回合","高","策略建议"));
  a.put(g("广告：检测外部广告/安装页，比赛中不抢占执行窗口，返回游戏后再验证奖励","高","助手执行规则"));
 }catch(Exception ignored){} return a; }
 private static JSONObject g(String t,String p,String s)throws Exception{return new JSONObject().put("title",t).put("priority",p).put("source",s).put("confidence","medium");}
}
