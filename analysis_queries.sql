-- ============================================
-- 《野蛮时代》游戏用户付费行为分析 - SQL查询集
-- ============================================

-- --------------------------------------------
-- 1. 基础取数查询（课程提供的字段提取模板）
-- --------------------------------------------

-- 游戏常规信息
SELECT
    user_id AS '用户id',
    register_time AS '注册时间',
    pvp_battle_count AS 'PVP次数',
    pay_price AS '7日付费金额',
    pay_count AS '7日付费次数',
    prediction_pay_price AS '45日预测付费金额'
FROM game;

-- 建筑登记信息
SELECT
    user_id,
    bd_training_hut_level AS "建筑：士兵小屋等级",
    bd_healing_lodge_level AS "建筑：治疗小井等级",
    bd_stronghold_level AS "建筑：要塞等级",
    bd_outpost_portal_level AS "建筑：据点传送门等级",
    bd_barrack_level AS "建筑：兵营等级",
    bd_healing_spring_level AS "建筑：治疗之泉等级",
    bd_dolmen_level AS "建筑：智慧神庙等级",
    bd_guest_cavern_level AS "建筑：联盟大厅等级",
    bd_warehouse_level AS "建筑：仓库等级",
    bd_watchtower_level AS "建筑：瞭望塔等级",
    bd_magic_coin_tree_level AS "建筑：魔法幸运树等级",
    bd_hall_of_war_level AS "建筑：战争大厅等级",
    bd_market_level AS "建筑：联盟货车等级",
    bd_hero_gacha_level AS "建筑：占卜台等级",
    bd_hero_strengthen_level AS "建筑：祭坛等级",
    bd_hero_pve_level AS "建筑：冒险传送门等级"
FROM game;


-- --------------------------------------------
-- 2. 自定义分析：构造"发展度评分"指标
--    （在课程要求之外，个人额外补充的分析部分）
-- --------------------------------------------

-- 2.1 计算每位玩家的发展度评分（15项建筑等级加总）
CREATE OR REPLACE VIEW v_user_dev_score AS
SELECT
    user_id,
    (bd_training_hut_level + bd_healing_lodge_level + bd_stronghold_level
     + bd_outpost_portal_level + bd_barrack_level + bd_healing_spring_level
     + bd_dolmen_level + bd_guest_cavern_level + bd_warehouse_level
     + bd_watchtower_level + bd_magic_coin_tree_level + bd_hall_of_war_level
     + bd_market_level + bd_hero_gacha_level + bd_hero_strengthen_level
     + bd_hero_pve_level) AS dev_score,
    pay_price,
    pay_count,
    prediction_pay_price
FROM game;


-- 2.2 按发展度评分分组（依据整体分布的四分位区间划定）
CREATE OR REPLACE VIEW v_user_dev_group AS
SELECT
    user_id,
    dev_score,
    pay_price,
    prediction_pay_price,
    CASE
        WHEN dev_score = 0 THEN '1-无建筑发展(0分)'
        WHEN dev_score BETWEEN 1 AND 5 THEN '2-低度发展(1-5分)'
        WHEN dev_score BETWEEN 6 AND 16 THEN '3-中度发展(6-16分)'
        ELSE '4-高度发展(17分以上)'
    END AS dev_group
FROM v_user_dev_score;


-- 2.3 分组统计：用户数、平均付费、付费转化率
SELECT
    dev_group AS '发展度分组',
    COUNT(*) AS '用户数',
    ROUND(AVG(pay_price), 2) AS '平均7日付费',
    ROUND(AVG(prediction_pay_price), 2) AS '平均45日预测付费',
    ROUND(SUM(CASE WHEN pay_price > 0 THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) AS '付费用户占比(%)'
FROM v_user_dev_group
GROUP BY dev_group
ORDER BY dev_group;
