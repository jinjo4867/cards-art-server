-- Nikke High-Tech Sector
-- ID: 99900016
local s,id=GetID()
local NIKKE_SET_ID = 0xc02

function s.initial_effect(c)
	-- 1. Activate & Search
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id+EFFECT_COUNT_CODE_OATH)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)

	-- 2. Level Modulation
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_CHANGE_LEVEL)
	e2:SetRange(LOCATION_FZONE)
	e2:SetTargetRange(LOCATION_MZONE,0)
	e2:SetTarget(s.lvfilter)
	e2:SetValue(7)
	c:RegisterEffect(e2)
	
	-- 3. Attach & Return
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_CHAINING)
	e3:SetRange(LOCATION_FZONE)
	e3:SetProperty(EFFECT_FLAG_CARD_TARGET+EFFECT_FLAG_DELAY)
	e3:SetCountLimit(1)
	e3:SetCondition(s.attachcon)
	e3:SetTarget(s.attachtg)
	e3:SetOperation(s.attachop)
	c:RegisterEffect(e3)
end

-- =======================================================================
-- [Effect 1] Search Logic
-- =======================================================================
function s.filter(c)
	return c:IsSetCard(NIKKE_SET_ID) and c:IsType(TYPE_MONSTER) and c:IsAbleToHand()
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	if not e:GetHandler():IsRelateToEffect(e) then return end
	
	local g=Duel.GetMatchingGroup(s.filter,tp,LOCATION_DECK,0,nil)
	if #g>0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
		local sg=g:Select(tp,1,1,nil)
		if #sg>0 then
			Duel.SendtoHand(sg,nil,REASON_EFFECT)
			Duel.ConfirmCards(1-tp,sg)
		end
	end
end

-- =======================================================================
-- [Effect 2] Level Filter
-- =======================================================================
function s.lvfilter(e,c)
	return c:IsSetCard(NIKKE_SET_ID) and c:GetOriginalLevel()>0 and c:GetOriginalLevel()<7
end

-- =======================================================================
-- [Effect 3] Attach & Return Logic
-- =======================================================================
function s.attachcon(e,tp,eg,ep,ev,re,r,rp)
	local rc=re:GetHandler()
	return rp==tp and rc:IsSetCard(NIKKE_SET_ID) and rc:IsType(TYPE_XYZ) and re:IsActiveType(TYPE_MONSTER) 
end

function s.attachfilter(c,rc)
	-- ต้องเป็นมอนสเตอร์ และ "ไม่ใช่ตัว Xyz ที่กำลังใช้เอฟเฟค"
	return c:IsType(TYPE_MONSTER) and c~=rc
end

function s.attachtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	local rc=re:GetHandler()
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and s.attachfilter(chkc,rc) end
	if chk==0 then return Duel.IsExistingTarget(s.attachfilter,tp,LOCATION_MZONE,LOCATION_MZONE,1,nil,rc) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	Duel.SelectTarget(tp,s.attachfilter,tp,LOCATION_MZONE,LOCATION_MZONE,1,1,nil,rc)
end

function s.attachop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	local rc=re:GetHandler()
	
	if tc and tc:IsRelateToEffect(e) and rc:IsLocation(LOCATION_MZONE) and not tc:IsImmuneToEffect(e) then
		local pos = tc:GetPosition()
		
		local og=tc:GetOverlayGroup()
		if #og>0 then Duel.Overlay(rc,og) end
		
		Duel.Overlay(rc,Group.FromCards(tc))
		
		-- ถ้าเข้า Overlay สำเร็จ ให้ตั้งเวลาดีดกลับ
		if tc:IsLocation(LOCATION_OVERLAY) then
			local e1=Effect.CreateEffect(c)
			e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
			e1:SetCode(EVENT_PHASE+PHASE_END)
			e1:SetCountLimit(1)
			e1:SetLabel(pos)
			e1:SetLabelObject(tc)
			-- [จุดสำคัญ] เพิ่ม Condition เช็คว่า "ยังอยู่ไหม"
			e1:SetCondition(s.retcon) 
			e1:SetOperation(s.retop)
			e1:SetReset(RESET_PHASE+PHASE_END)
			Duel.RegisterEffect(e1,tp)
		end
	end
end

-- [เพิ่มใหม่] เช็คเงื่อนไขก่อนดีดกลับ
function s.retcon(e,tp,eg,ep,ev,re,r,rp)
	local tc = e:GetLabelObject()
	-- ถ้าการ์ดไม่อยู่ในสภาพ Overlay Unit (เช่น โดนถอดลงสุสานไปแล้ว)
	-- ฟังก์ชันนี้จะ return false และทำให้เอฟเฟค "เงียบ" ไปเลย ไม่ทำงาน
	return tc and tc:IsLocation(LOCATION_OVERLAY)
end

function s.retop(e,tp,eg,ep,ev,re,r,rp)
	local tc = e:GetLabelObject()
	local pos = e:GetLabel()
	
	-- ทำงานแน่นอนเพราะผ่าน condition มาแล้ว
	local owner = tc:GetOwner()
	if Duel.SpecialSummonStep(tc,0,tp,owner,true,false,pos) then
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_DISABLE)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		tc:RegisterEffect(e1)
		
		local e2=Effect.CreateEffect(e:GetHandler())
		e2:SetType(EFFECT_TYPE_SINGLE)
		e2:SetCode(EFFECT_DISABLE_EFFECT)
		e2:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		tc:RegisterEffect(e2)
	end
	Duel.SpecialSummonComplete()
end