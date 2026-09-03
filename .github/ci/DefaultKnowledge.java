package com.ludusassistant.app.data;
import org.json.JSONArray;
import org.json.JSONObject;
/** Built-in LUDUS knowledge seed. Dates and live event availability are dynamic when the client is authoritative. */
public final class DefaultKnowledge {
 private DefaultKnowledge(){}
 public static JSONArray events(){JSONArray a=new JSONArray();try{
  a.put(e("daily_free","每日免费奖励","daily","高","每日/每周","官方商店公开页；以客户端领取状态为准"));
  a.put(e("weekly_faction","每周阵营加成","weekly","高","每周轮换","公开攻略；当前具体阵营必须从客户端确认"));
  a.put(e("grand_hunt","Grand Hunt / 大狩猎","seasonal","高","24小时一场；每周最多4场","公开更新说明；当前开放状态以客户端确认"));
  a.put(e("divisions","Divisions / 象限赛季","seasonal","高","赛季循环","公开报道：20+人分组、前5晋级、6-15保级；当前周期以客户端确认"));
  a.put(e("goldmine","Goldmine Hero Race / 金币矿场英雄竞速","race","高","限时活动","1.34更新后改版；当前开放状态以客户端确认"));
  a.put(e("sorcerous","Sorcerous Tournament / 魔法锦标赛","tournament","高","限时活动","1.36.x版本历史；当前开放状态以客户端确认"));
  a.put(e("astral_rift","Astral Rift / 星界裂隙","seasonal","高","限时周期","当前主题/英雄以客户端确认"));
  a.put(e("clan_contest","Clan Contest / 公会竞赛","clan","高","周期活动","当前规则以客户端确认"));
  a.put(e("clan_war","Clan War / 公会战","clan_war","高","赛季/周期","当前规则以客户端确认"));
  a.put(e("battle_pass","Battle Pass / 战斗通行证","pass","中","赛季","当前奖励轨道以客户端确认"));
  a.put(e("hunt_seals","Hunt Seals / 狩猎印章","seasonal","中","Grand Hunt期间","免费线与付费封印线分开记录"));
  a.put(e("sidekicks","Sidekicks / 助手英雄","system","中","常驻系统","1.35更新引入；主牌组英雄可配对另一高等级英雄"));
  a.put(e("pantheon","Pantheon / 万神殿","system","中","常驻系统","1.35更新引入"));
  a.put(e("jokers","Jokers / 百搭牌","system","中","常驻系统","1.35更新引入"));
 }catch(Exception ignored){}return a;}
 private static JSONObject e(String id,String title,String type,String priority,String cadence,String source)throws Exception{return new JSONObject().put("id",id).put("title",title).put("type",type).put("priority",priority).put("cadence",cadence).put("status","动态").put("source",source);}
 public static JSONArray guides(){JSONArray a=new JSONArray();try{
  a.put(g("版本基线","当前公开版本基线：1.37.0；1.36.x记录公会战力筛选/阈值与魔法锦标赛；1.37.0版本历史显示扶董天王星界裂隙再现。","高","应用商店版本历史","1.37.0"));
  a.put(g("核心战斗","5张英雄牌组；召唤、合并、站位、Battle Prowess、Super Merge共同决定战斗节奏。","高","公开攻略","1.36.x+"));
  a.put(g("合并规则","同英雄且同合并等级才能合并；高等级合并进入更强能力阶段。","高","公开攻略","1.36.x+"));
  a.put(g("经济","公开攻略记录默认每回合16能量、每次召唤消耗3；击破石块可获得额外资源/能量。","高","公开攻略","待客户端复核"));
  a.put(g("阵容原则","入门结构可从2坦克/前排+2输出+1辅助开始，再按对手、阵营加成和法术调整。","高","公开攻略","1.36.x+"));
  a.put(g("碎岩与合并","不要为了即时合并破坏有效的Battle Prowess覆盖；必要时延迟一次合并以保持整体板面收益。","高","公开攻略","1.36.x+"));
  a.put(g("英雄升级","提升英雄永久等级会提升总体Might；优先核心卡，同时逐步提升其他卡。","高","公开攻略","1.36.x+"));
  a.put(g("Grand Hunt","每场24小时；胜利获得Axes；公开更新说明称每周最多参加4场，并有Heroes Seal/Runes Seal奖励线。","高","版本更新说明","1.32+"));
  a.put(g("Divisions","公开报道记录20+人分组、前5晋级、6-15保级，并通过Victories Gauge推进赛季奖励。","高","公开报道","2026"));
  a.put(g("Goldmine Hero Race","1.34更新记录Goldmine Hero Race改版；开始/结束时间必须以游戏内倒计时为准。","高","版本历史","1.34+"));
  a.put(g("Sorcerous Tournament","1.36.0-1.36.3版本历史持续标注Sorcerous Tournament；助手应显示活动状态而非假定固定日期。","高","版本历史","1.36.x"));
  a.put(g("Sidekicks","1.35引入Sidekicks：主牌组常规英雄可配对另一高等级英雄并在战斗中召唤。","高","官方商店更新说明","1.35+"));
  a.put(g("Pantheon与Jokers","1.35引入Pantheon与Jokers，并伴随新的战斗加成稀有度与卡牌界面改版。","高","官方商店更新说明","1.35+"));
  a.put(g("广告任务","检测广告→外部安装/商店页→返回游戏→奖励核验；比赛中不抢占广告执行窗口。","高","助手执行规则","Assistant"));
  a.put(g("资源核验","资源优先采用OCR+空间位置；低置信度数值标记待确认，不写入高置信度账本。","高","助手数据规则","Assistant"));
  a.put(g("攻略刷新","每小时作为刷新检查周期；没有新版本/新资料时不得伪造已更新。","高","助手数据规则","Assistant"));
  a.put(g("商店","官方Web Shop包含免费商品、Battle Pass、Ethereal Crystals、Spells、Runes、Golden Runes、Dice of Fortune、Gold、Emeralds等；税费与最终支付报价以结算页为准。","高","官方Web Shop","当前公开页"));
 }catch(Exception ignored){}return a;}
 private static JSONObject g(String title,String text,String priority,String source,String version)throws Exception{return new JSONObject().put("title",title).put("text",text).put("priority",priority).put("source",source).put("version",version).put("confidence","verified_or_client_check");}
}
