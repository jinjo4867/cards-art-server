-- Inner Corruption (ID: 99900004)
local s,id=GetID()
local NIKKE_SET_ID = 0xc02

function s.initial_effect(c)
	-- Activate: Negate -> Destroy Opponent's -> Destroy Own Nikke -> Protect Remaining
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_NEGATE+CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_CHAINING)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetCondition(s.condition)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

-- ==================================================================
-- Logic
-- ==================================================================

function s.nikke_filter(c)
	return c:IsFaceup() and c:IsSetCard(NIKKE_SET_ID)
end

function s.condition(e,tp,eg,ep,ev,re,r,rp)
	return rp==1-tp and Duel.IsChainNegatable(ev) 
		and Duel.IsExistingMatchingCard(s.nikke_filter,tp,LOCATION_MZONE,0,1,nil)
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(tp) and s.nikke_filter(chkc) end
	if chk==0 then return Duel.IsExistingTarget(s.nikke_filter,tp,LOCATION_MZONE,0,1,nil) end
	
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	local g=Duel.SelectTarget(tp,s.nikke_filter,tp,LOCATION_MZONE,0,1,1,nil)
	
	local g_dest = Group.FromCards(g:GetFirst())
	if re:GetHandler():IsRelateToEffect(re) then
		g_dest:AddCard(re:GetHandler())
	end
	
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g_dest,#g_dest,0,0)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	
	-- 1. Negate Activation
	if Duel.NegateActivation(ev) then
		-- 2. Destroy Opponent's Card
		if re:GetHandler():IsRelateToEffect(re) then
			Duel.Destroy(eg,REASON_EFFECT)
		end
		
		-- 3. Destroy Our Nikke (The Target)
		if tc and tc:IsRelateToEffect(e) then
			Duel.Destroy(tc,REASON_EFFECT)
		end

		-- 4. [New Buff] Protect all Nikke from targeting for the rest of turn
		-- สร้างเอฟเฟกต์สนามแบบ lingering effect (อยู่จนจบเทิร์น)
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_FIELD)
		e1:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
		e1:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE) -- กันเป้าจากทุกอย่างที่กันได้
		e1:SetTargetRange(LOCATION_MZONE,0) -- มีผลกับฝั่งเราเท่านั้น
		e1:SetTarget(aux.TargetBoolFunction(Card.IsSetCard,NIKKE_SET_ID)) -- เฉพาะเผ่า Nikke
		e1:SetValue(aux.tgoval) -- ค่ามาตรฐานที่บอกว่า "คู่แข่ง target ไม่ได้"
		e1:SetReset(RESET_PHASE+PHASE_END) -- จบเทิร์นหายไป
		Duel.RegisterEffect(e1,tp)
	end
end