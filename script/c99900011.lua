-- Absolute TACTICAL!
-- ID: 99900011
local s,id=GetID()
local TACTICAL_FLAG_ID = 99900009 -- รหัสของ Nikke TACTICAL!
local NIKKE_SET_ID = 0xc02

function s.initial_effect(c)
	-- 1. Activate: Fusion Summon (Shuffle from Hand/Field/GY)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_FUSION_SUMMON+CATEGORY_TODECK)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_MAIN_END)
	
	-- Count Limit สำหรับการ Activate การ์ด (ID ตัวเอง: 99900011)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)

	-- 2. GY Effect: Recycle (Shuffle Self -> Add 1 from GY to Hand)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TODECK+CATEGORY_TOHAND)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_GRAVE)
	
	-- [แก้ไข] เปลี่ยนเป็น id+100 (99900111) เพื่อไม่ให้ชนกับการ์ดใบอื่น
	e2:SetCountLimit(1,id+100) 
	
	e2:SetCondition(s.gycon)
	e2:SetTarget(s.gytg)
	e2:SetOperation(s.gyop)
	c:RegisterEffect(e2)
end

-- =======================================================================
-- [Effect 1] Fusion Summon Logic
-- =======================================================================
function s.ex_filter(c,e,tp)
	return c:IsType(TYPE_FUSION) and c:IsSetCard(NIKKE_SET_ID) 
		and c:IsLevel(7)
		and c:IsAttribute(ATTRIBUTE_FIRE)
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_FUSION,tp,false,false)
end

function s.mat_filter(c)
	return c:IsSetCard(NIKKE_SET_ID) and c:IsType(TYPE_MONSTER) and c:IsAbleToDeck()
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		-- รวมโซนที่จะหาวัตถุดิบ (มือ + สนาม + สุสาน ได้เลย)
		local loc = LOCATION_HAND + LOCATION_MZONE + LOCATION_GRAVE
		
		-- ต้องมีวัตถุดิบอย่างน้อย 2 ใบ
		local mat_count = Duel.GetMatchingGroupCount(s.mat_filter, tp, loc, 0, nil)
		-- ต้องมีตัวฟิวชั่นเป้าหมาย
		local ex_ok = Duel.IsExistingMatchingCard(s.ex_filter, tp, LOCATION_EXTRA, 0, 1, nil, e, tp)
		
		return mat_count >= 2 and ex_ok
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
	Duel.SetOperationInfo(0,CATEGORY_TODECK,nil,2,tp,LOCATION_HAND+LOCATION_MZONE+LOCATION_GRAVE)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	-- หาวัตถุดิบจากทุกที่
	local loc = LOCATION_HAND + LOCATION_MZONE + LOCATION_GRAVE
	local mg = Duel.GetMatchingGroup(s.mat_filter, tp, loc, 0, nil)
	
	if #mg < 2 then return end
	
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local sg = Duel.SelectMatchingCard(tp,s.ex_filter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp)
	
	if #sg > 0 then
		local tc = sg:GetFirst()
		
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
		-- เลือกวัตถุดิบ 2 ใบ
		local mat = mg:Select(tp,2,2,nil)
		
		if #mat > 0 then
			tc:SetMaterial(mat)
			-- สับเข้าเด็ค
			Duel.SendtoDeck(mat,nil,SEQ_DECKSHUFFLE,REASON_EFFECT+REASON_MATERIAL+REASON_FUSION)
			Duel.BreakEffect()
			-- อัญเชิญ
			Duel.SpecialSummon(tc,SUMMON_TYPE_FUSION,tp,tp,false,false,POS_FACEUP)
			tc:CompleteProcedure()
		end
	end
end

-- =======================================================================
-- [Effect 2] GY Recursion Logic
-- =======================================================================
function s.gycon(e,tp,eg,ep,ev,re,r,rp)
	-- เงื่อนไข: ต้องมีการใช้ Nikke TACTICAL! (99900009) ไปแล้วในเทิร์นนี้
	return Duel.GetFlagEffect(tp,TACTICAL_FLAG_ID) > 0
end

function s.gytg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_GRAVE) and chkc:IsControler(tp) and chkc:IsAbleToHand() and chkc~=e:GetHandler() end
	if chk==0 then return e:GetHandler():IsAbleToDeck()
		and Duel.IsExistingTarget(Card.IsAbleToHand,tp,LOCATION_GRAVE,0,1,e:GetHandler()) end
	
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	-- เลือกการ์ด 1 ใบในสุสาน (อะไรก็ได้ ยกเว้นตัวเอง)
	local g=Duel.SelectTarget(tp,Card.IsAbleToHand,tp,LOCATION_GRAVE,0,1,1,e:GetHandler())
	
	Duel.SetOperationInfo(0,CATEGORY_TODECK,e:GetHandler(),1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,g,1,0,0)
end

function s.gyop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	
	-- 1. เอาตัวเองกลับเข้า Deck ก่อน
	if c:IsRelateToEffect(e) and Duel.SendtoDeck(c,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)>0 then
		-- 2. ถ้าเข้าเด็คสำเร็จ ค่อยเอาเป้าหมายขึ้นมือ
		if tc:IsRelateToEffect(e) then
			Duel.SendtoHand(tc,nil,REASON_EFFECT)
			Duel.ConfirmCards(1-tp,tc)
		end
	end
end