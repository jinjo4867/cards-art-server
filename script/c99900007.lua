-- Burst: Power of Inheritance (ID: 99900007)
local s,id=GetID()
function c99900007.initial_effect(c)
	-- Activate
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_ATKCHANGE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH) -- Hard Once Per Turn
	e1:SetCondition(c99900007.condition)
	e1:SetTarget(c99900007.target)
	e1:SetOperation(c99900007.activate)
	c:RegisterEffect(e1)
end

-- ==================================================================
-- Constants
-- ==================================================================
local RED_HOOD_ID = 99900006	 -- รหัส Nikke Rapi: Red Hood
local NIKKE_SET_ID = 0xc02	   -- รหัสธีม Nikke

-- ==================================================================
-- Filters
-- ==================================================================

-- Filter 1: หา Red Hood บนสนาม
function c99900007.redhood_filter(c)
	return c:IsFaceup() and c:IsCode(RED_HOOD_ID)
end

-- Filter 2: หา Nikke บนสนาม
function c99900007.nikke_filter(c)
	return c:IsFaceup() and c:IsSetCard(NIKKE_SET_ID)
end

-- Filter 3: หาเป้าหมายที่จะดูดพลัง (ต้องมีพลัง > 0)
function c99900007.target_filter(c)
	return c:IsFaceup() and c:GetAttack()>0
end

-- ==================================================================
-- Logic
-- ==================================================================

function c99900007.condition(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(c99900007.redhood_filter,tp,LOCATION_MZONE,0,1,nil)
end

function c99900007.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and c99900007.target_filter(chkc) end
	if chk==0 then return Duel.IsExistingTarget(c99900007.target_filter,tp,LOCATION_MZONE,LOCATION_MZONE,1,nil) end
	
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	Duel.SelectTarget(tp,c99900007.target_filter,tp,LOCATION_MZONE,LOCATION_MZONE,1,1,nil)
end

function c99900007.activate(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	
	-- ใช้ nikke_filter ที่เขียนเอง
	local g=Duel.GetMatchingGroup(c99900007.nikke_filter,tp,LOCATION_MZONE,0,nil)
	
	if tc and tc:IsRelateToEffect(e) and tc:IsFaceup() and #g>0 then
		local atk=tc:GetAttack()
		
		-- ใช้ Loop แบบดั้งเดิม (เสถียรกว่า)
		local sc=g:GetFirst()
		while sc do
			-- 1. เพิ่มพลังโจมตี (Reset เมื่อจบเทิร์น)
			local e1=Effect.CreateEffect(e:GetHandler())
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_UPDATE_ATTACK)
			e1:SetValue(atk)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
			sc:RegisterEffect(e1)
			
			-- 2. Piercing Damage (ตีทะลุ)
			local e2=Effect.CreateEffect(e:GetHandler())
			e2:SetType(EFFECT_TYPE_SINGLE)
			e2:SetCode(EFFECT_PIERCE)
			e2:SetValue(1) -- **สำคัญ: ต้องใส่ค่า 1 เพื่อเปิดใช้งาน**
			e2:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
			sc:RegisterEffect(e2)
			
			sc=g:GetNext()
		end
	end
end