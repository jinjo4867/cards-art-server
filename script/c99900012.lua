-- Tactical Nikke Emma
-- ID: 99900012
local s,id=GetID()
local TACTICAL_FLAG_ID = 99900009 

function s.initial_effect(c)
	c:EnableReviveLimit()
	
	-- 1. Retrieve + Optional SS (เหมือนเดิม)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)

	-- 2. Auto-Negate OR Heal (แก้ไข Condition ให้แม่นยำที่สุด)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,2))
	e2:SetCategory(CATEGORY_NEGATE+CATEGORY_RECOVER+CATEGORY_ATKCHANGE)
	e2:SetType(EFFECT_TYPE_QUICK_F) -- บังคับใช้
	e2:SetCode(EVENT_CHAINING)
	e2:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DAMAGE_CAL)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,EFFECT_COUNT_CODE_CHAIN)
	e2:SetCondition(s.combined_con)
	e2:SetTarget(s.combined_tg)
	e2:SetOperation(s.combined_op)
	c:RegisterEffect(e2)
end

-- ==================================================================
-- Logic 1: Retrieve + SS from GY
-- ==================================================================
function s.thfilter(c)
	return c:IsSetCard(0xc02) and c:IsAbleToHand()
end

function s.spfilter(c,e,tp)
	return c:IsSetCard(0xc02) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_GRAVE) and chkc:IsControler(tp) and s.thfilter(chkc) end
	if chk==0 then return Duel.IsExistingTarget(s.thfilter,tp,LOCATION_GRAVE,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectTarget(tp,s.thfilter,tp,LOCATION_GRAVE,0,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,g,1,0,0)
	
	local can_ss = Duel.GetLocationCount(tp,LOCATION_MZONE)>0 
				   and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_GRAVE,0,1,nil,e,tp)
	if Duel.GetFlagEffect(tp,TACTICAL_FLAG_ID)>0 and can_ss then
		Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_GRAVE)
	end
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc:IsRelateToEffect(e) then
		if Duel.SendtoHand(tc,nil,REASON_EFFECT)~=0 then
			Duel.ConfirmCards(1-tp,tc)
			if Duel.GetFlagEffect(tp,TACTICAL_FLAG_ID)>0 
				and Duel.GetLocationCount(tp,LOCATION_MZONE)>0 
				and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_GRAVE,0,1,nil,e,tp) 
				and Duel.SelectYesNo(tp,aux.Stringid(id,3)) then
				Duel.BreakEffect()
				Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
				local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_GRAVE,0,1,1,nil,e,tp)
				if #g>0 then
					Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
				end
			end
		end
	end
end

-- ==================================================================
-- Logic 2: Combined Decision (Negate OR Heal) - Final Fix
-- ==================================================================

function s.combined_con(e,tp,eg,ep,ev,re,r,rp)
	-- 1. ต้องเป็นอีกฝ่ายใช้
	if rp == tp then return false end

	-- 2. ดึงตำแหน่งที่ Activate มาเช็ค
	local loc = re:GetActivateLocation()
	
	-- กรองทิ้ง 1: ถ้ามาจาก สุสาน(0x10), เด็ค(0x01), หรือ Banish(0x20) -> ไม่เอาเลย
	if (loc & (LOCATION_GRAVE+LOCATION_DECK+LOCATION_REMOVED)) ~= 0 then
		return false
	end

	-- กรองทิ้ง 2: ถ้ามาจาก มือ(0x02)
	if (loc & LOCATION_HAND) ~= 0 then
		-- ถ้าเป็น Monster Effect ในมือ (Hand Trap) -> ไม่เอา
		if re:GetHandler():IsType(TYPE_MONSTER) then
			return false
		end
		-- ถ้าเป็น Spell/Trap จากมือ -> ผ่าน (เพราะถือว่า Activate เพื่อลงสนาม)
	end

	-- นอกเหนือจากนั้น (MZONE, SZONE, FZONE, PZONE) -> ผ่านหมด
	return true
end

function s.combined_tg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_RECOVER,nil,0,tp,500)
end

function s.combined_op(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	
	-- เงื่อนไข Negate: 
	-- Spell/Trap + เป็นการ Activate การ์ด + Negate ได้ + LP > 2000
	local is_spell_trap = re:IsActiveType(TYPE_SPELL+TYPE_TRAP)
	local is_activation = re:IsHasType(EFFECT_TYPE_ACTIVATE) 
	local can_negate = Duel.IsChainNegatable(ev)
	local enough_lp = Duel.GetLP(tp) > 2000

	if is_spell_trap and is_activation and can_negate and enough_lp then
		-- [[ โหมด Negate ]]
		Duel.PayLPCost(tp,1000)
		Duel.NegateActivation(ev) -- ไม่ทำลาย
	else
		-- [[ โหมด Heal & Buff ]]
		Duel.Hint(HINT_CARD,0,id)
		Duel.Recover(tp,500,REASON_EFFECT)
		
		if c:IsRelateToEffect(e) and c:IsFaceup() then
			local e1=Effect.CreateEffect(c)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_UPDATE_ATTACK)
			e1:SetValue(300)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD)
			c:RegisterEffect(e1)
		end
	end
end