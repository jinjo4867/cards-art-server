-- Burst: Asceticism
-- ID: 99900040
local s,id=GetID()
local ID_PIONEER = 99900039 -- Pioneer Nikke Nayuta
local ID_WU_WEI = 99900041  -- Nikke Nayuta: Wu Wei

function s.initial_effect(c)
	-- 1. Activate (Target Pioneer)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetCountLimit(1,id+EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)

	-- 2. Awakening at Dawn (Mandatory Standby Phase)
	-- [CHANGE] เปลี่ยนเป็น TRIGGER_F (บังคับเกิด)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TODECK)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F) 
	e2:SetCode(EVENT_PHASE+PHASE_STANDBY)
	e2:SetRange(LOCATION_SZONE)
	e2:SetCondition(s.spcon)
	e2:SetCost(s.spcost)
	e2:SetTarget(s.sptg)
	e2:SetOperation(s.spop)
	c:RegisterEffect(e2)

	-- 3. Self-Immunity to Negation
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE)
	e3:SetCode(EFFECT_IMMUNE_EFFECT)
	e3:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e3:SetRange(LOCATION_SZONE)
	e3:SetValue(s.negate_immune_filter)
	c:RegisterEffect(e3)
end

-- ==================================================================
-- [Logic] Immunity Filter
-- ==================================================================
function s.negate_immune_filter(e,te)
	if (te:GetType() & EFFECT_TYPE_ACTIONS) ~= 0 then
		local cat = te:GetCategory()
		if (cat & CATEGORY_DISABLE)~=0 or (cat & CATEGORY_NEGATE)~=0 then
			return true
		end
	end
	local ec = te:GetCode()
	return ec==EFFECT_DISABLE or ec==EFFECT_DISABLE_EFFECT or ec==EFFECT_DISABLE_CHAIN
end

-- ==================================================================
-- (1) Entering Meditation
-- ==================================================================
function s.filter(c)
	return c:IsCode(ID_PIONEER) and c:IsFaceup()
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(tp) and s.filter(chkc) end
	if chk==0 then return Duel.IsExistingTarget(s.filter,tp,LOCATION_MZONE,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	local g=Duel.SelectTarget(tp,s.filter,tp,LOCATION_MZONE,0,1,1,nil)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if c:IsRelateToEffect(e) and tc and tc:IsRelateToEffect(e) and tc:IsFaceup() then
		c:SetCardTarget(tc)
		
		-- Template Effect
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
		e1:SetValue(1)
		e1:SetCondition(s.rcon)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		tc:RegisterEffect(e1)
		
		local e2=e1:Clone()
		e2:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
		tc:RegisterEffect(e2)
		
		local e3=e1:Clone()
		e3:SetCode(EFFECT_CANNOT_ATTACK)
		tc:RegisterEffect(e3)
		
		local e4=e1:Clone()
		e4:SetCode(EFFECT_CANNOT_BE_LINK_MATERIAL)
		tc:RegisterEffect(e4)
		local e5=e1:Clone()
		e5:SetCode(EFFECT_CANNOT_BE_FUSION_MATERIAL)
		tc:RegisterEffect(e5)
		local e6=e1:Clone()
		e6:SetCode(EFFECT_CANNOT_BE_SYNCHRO_MATERIAL)
		tc:RegisterEffect(e6)
		local e7=e1:Clone()
		e7:SetCode(EFFECT_CANNOT_BE_XYZ_MATERIAL)
		tc:RegisterEffect(e7)

		local e8=e1:Clone()
		e8:SetCode(EFFECT_UNRELEASABLE_SUMMON)
		e8:SetValue(1)
		tc:RegisterEffect(e8)
		local e9=e1:Clone()
		e9:SetCode(EFFECT_UNRELEASABLE_NONSUMMON)
		e9:SetValue(1)
		tc:RegisterEffect(e9)
	end
end

function s.rcon(e)
	return e:GetOwner():IsHasCardTarget(e:GetHandler())
end

-- ==================================================================
-- (2) Awakening at Dawn
-- ==================================================================
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	-- เช็คว่าเป็น Standby เรา และไม่ใช่เทิร์นที่เพิ่งเปิดการ์ดนี้
	return Duel.GetTurnPlayer()==tp and e:GetHandler():GetTurnID() ~= Duel.GetTurnCount()
end

function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	local tc=c:GetFirstCardTarget()
	-- เนื่องจากเป็น TRIGGER_F (บังคับ) chk==0 จะ return true เสมอถ้าเงื่อนไขพื้นฐานครบ
	if chk==0 then return true end
	
	-- 1. ส่งเวทย์(ตัวมันเอง) และเป้าหมาย(Pioneer) ลงสุสานเป็น Cost
	local g_cost = Group.FromCards(c)
	if tc then g_cost:AddCard(tc) end
	
	Duel.SendtoGrave(g_cost,REASON_COST)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end -- บังคับทำเสมอ
	Duel.SetOperationInfo(0,CATEGORY_TODECK,nil,1,tp,LOCATION_MZONE) -- แจ้งว่าจะมีการสับเข้ากอง
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
	Duel.SetChainLimit(aux.FALSE)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	-- [FIX] ย้ายการสับมอนสเตอร์อื่นมาไว้ตรงนี้ เพื่อแก้บัค และทำความสะอาดสนามก่อนเรียก Wu Wei
	local g_others = Duel.GetFieldGroup(tp,LOCATION_MZONE,0)
	if #g_others > 0 then
		Duel.SendtoDeck(g_others,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
	end
	
	-- จากนั้นค่อยเรียก Wu Wei
	if Duel.GetLocationCountFromEx(tp)<=0 then return end
	
	-- Over Deck Logic
	local tc = Duel.GetFirstMatchingCard(function(c) return c:IsCode(ID_WU_WEI) and c:IsCanBeSpecialSummoned(e,0,tp,true,false) end, tp, LOCATION_EXTRA, 0, nil)
	
	if not tc then
		tc = Duel.CreateToken(tp, ID_WU_WEI)
	end
	
	if tc then
		Duel.SpecialSummon(tc, 0, tp, tp, true, false, POS_FACEUP)
		tc:CompleteProcedure()
	end
end