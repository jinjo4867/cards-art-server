-- Red Hood Activation
-- ID: 99900005
local s,id=GetID()
local RAPI_BASE_ID = 99900000
local RED_HOOD_ID = 99900006

function s.initial_effect(c)
	-- 1. Activate: Summon Red Hood (Effect [0])
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0)) 
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_RELEASE+CATEGORY_REMOVE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_MAIN_END+TIMING_BATTLE_START)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	-- 2. Search Effect: Add Rapi (Effect [1])
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1)) 
	e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_HAND)
	e2:SetCountLimit(1,id)
	e2:SetCondition(s.thcon)
	e2:SetCost(s.thcost)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)
end

-- ==================================================================
-- Logic 1: Summon Red Hood (Fixed Logic)
-- ==================================================================

-- Filter กลาง: เช็คตาม Location ให้ถูกต้อง
function s.mat_filter_base(c)
	-- ห้ามใช้ Red Hood เป็นวัตถุดิบ
	if c:IsCode(RED_HOOD_ID) then return false end
	
	if c:IsLocation(LOCATION_HAND+LOCATION_MZONE) then
		-- ถ้าอยู่ มือ/สนาม ต้อง Release ได้
		return c:IsReleasableByEffect()
	elseif c:IsLocation(LOCATION_GRAVE) then
		-- ถ้าอยู่ สุสาน ต้อง Banish ได้
		return c:IsAbleToRemove()
	end
	return false
end

function s.mat_rapi_filter(c)
	return c:IsCode(RAPI_BASE_ID) and s.mat_filter_base(c)
end

function s.mat_machine_filter(c)
	return c:IsRace(RACE_MACHINE) and s.mat_filter_base(c)
end

function s.sp_redhood_filter(c,e,tp)
	return c:IsCode(RED_HOOD_ID) and c:IsCanBeSpecialSummoned(e,0,tp,false,false,POS_FACEUP)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		-- ดึงกลุ่มวัตถุดิบทั้งหมด
		local g1=Duel.GetMatchingGroup(s.mat_rapi_filter,tp,LOCATION_HAND+LOCATION_MZONE+LOCATION_GRAVE,LOCATION_MZONE,nil)
		local g2=Duel.GetMatchingGroup(s.mat_machine_filter,tp,LOCATION_HAND+LOCATION_MZONE+LOCATION_GRAVE,LOCATION_MZONE,nil)
		
		-- ดึง Red Hood เป้าหมาย
		local g3=Duel.GetMatchingGroup(s.sp_redhood_filter,tp,LOCATION_HAND+LOCATION_GRAVE,0,nil,e,tp)
		
		-- ต้องมี Red Hood ให้โดด และต้องมีวัตถุดิบทั้ง 2 กลุ่ม
		if #g3 == 0 or #g1 == 0 or #g2 == 0 then return false end

		-- [จุดสำคัญ] เช็คว่ามีคู่ที่ "ไม่ใช่ใบเดียวกัน" หรือไม่ (กรณี Rapi เป็น Machine)
		-- วนลูปหาว่า: มี Rapi (c) ใบไหนไหม ที่มี Machine (m) ใบอื่น (m ~= c) ให้จับคู่ด้วย
		return g1:IsExists(function(c) 
			return g2:IsExists(function(m) return m~=c end, 1, nil)
		end, 1, nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND+LOCATION_GRAVE)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local g1=Duel.GetMatchingGroup(s.mat_rapi_filter,tp,LOCATION_HAND+LOCATION_MZONE+LOCATION_GRAVE,LOCATION_MZONE,nil)
	if #g1==0 then return end
	
	-- เลือก Rapi
	Duel.Hint(HINT_SELECTMSG,tp,aux.Stringid(id,2)) 
	local sg1=g1:Select(tp,1,1,nil)
	local tc1=sg1:GetFirst()

	-- เลือก Machine (ต้องไม่ใช่ใบที่เลือกไปแล้ว)
	local g2=Duel.GetMatchingGroup(s.mat_machine_filter,tp,LOCATION_HAND+LOCATION_MZONE+LOCATION_GRAVE,LOCATION_MZONE,nil)
	g2:RemoveCard(tc1)
	if #g2==0 then return end
	
	Duel.Hint(HINT_SELECTMSG,tp,aux.Stringid(id,3)) 
	local sg2=g2:Select(tp,1,1,nil)
	local tc2=sg2:GetFirst()

	local mat_group=Group.FromCards(tc1,tc2)
	local to_release=Group.CreateGroup()
	local to_banish=Group.CreateGroup()

	-- แยกประเภทว่าจะ Release หรือ Banish
	for tc in aux.Next(mat_group) do
		if tc:IsLocation(LOCATION_GRAVE) then
			to_banish:AddCard(tc)
		else
			to_release:AddCard(tc)
		end
	end

	-- ดำเนินการ
	local count=0
	if #to_release>0 then
		count = count + Duel.Release(to_release,REASON_EFFECT)
	end
	if #to_banish>0 then
		count = count + Duel.Remove(to_banish,POS_FACEUP,REASON_EFFECT)
	end

	-- ถ้าทำสำเร็จ ค่อยโดด Red Hood
	if count>0 then
		local g3=Duel.GetMatchingGroup(s.sp_redhood_filter,tp,LOCATION_HAND+LOCATION_GRAVE,0,nil,e,tp)
		-- ลบวัตถุดิบออกจากกลุ่มเป้าหมาย (กันเหนียว กรณีวัตถุดิบเป็น Red Hood เอง แม้จะเขียนดักไว้แล้ว)
		g3:Sub(mat_group)
		
		if #g3>0 then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
			local sc=g3:Select(tp,1,1,nil):GetFirst()
			if sc then
				Duel.BreakEffect()
				Duel.SpecialSummon(sc,0,tp,tp,true,false,POS_FACEUP)
				sc:CompleteProcedure()
			end
		end
	end
end

-- ==================================================================
-- Logic 2: Search Rapi
-- ==================================================================
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	return not Duel.IsExistingMatchingCard(Card.IsCode,tp,LOCATION_HAND,0,1,nil,RAPI_BASE_ID)
end

function s.thcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:IsAbleToGraveAsCost() end
	Duel.SendtoGrave(c,REASON_COST)
end

function s.thfilter(c)
	return c:IsCode(RAPI_BASE_ID) and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end