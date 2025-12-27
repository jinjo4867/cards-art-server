-- Burst: Missile Container Online (ID: 99900015)
local s,id=GetID()
local VESTI_ID = 99900014
local TACTICAL_FLAG_ID = 99900009

function s.initial_effect(c)
	-- Activate
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_ATKCHANGE+CATEGORY_DESTROY+CATEGORY_TODECK)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetCondition(s.condition)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

function s.vesti_filter(c)
	return c:IsCode(VESTI_ID) and c:IsFaceup()
end

function s.condition(e,tp,eg,ep,ev,re,r,rp)
	-- เงื่อนไขเดียว: ต้องมี Vesti ยืนอยู่
	return Duel.IsExistingMatchingCard(s.vesti_filter,tp,LOCATION_MZONE,0,1,nil)
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	-- [แก้ไข] กดใช้ได้เสมอ (return true) ไม่ต้องเช็คมอนสเตอร์ฝ่ายตรงข้าม
	if chk==0 then return true end
	
	-- Set Info ไว้โชว์เฉยๆ (ถ้ามีเป้าให้โดน)
	local g=Duel.GetMatchingGroup(Card.IsFaceup,tp,0,LOCATION_MZONE,nil)
	if #g>0 then
		Duel.SetOperationInfo(0,CATEGORY_ATKCHANGE,g,#g,0,-2000)
		Duel.SetOperationInfo(0,CATEGORY_DESTROY,nil,0,1-tp,LOCATION_MZONE)
	end
	
	if Duel.GetFlagEffect(tp,TACTICAL_FLAG_ID)>0 then
		Duel.SetOperationInfo(0,CATEGORY_TODECK,nil,0,1-tp,LOCATION_HAND+LOCATION_SZONE)
	end
end

-- Filter Functions
function s.hand_filter(c)
	return c:IsType(TYPE_MONSTER) and c:GetAttack()<=2000 and c:IsAbleToDeck()
end
function s.backrow_filter(c)
	return c:IsType(TYPE_SPELL+TYPE_TRAP) and c:IsAbleToDeck()
end

-- Immediate Nuke Function
function s.apply_immediate_nuke(tp, value, reason_effect)
	local g=Duel.GetMatchingGroup(Card.IsFaceup,tp,0,LOCATION_MZONE,nil)
	if #g>0 then
		for tc in aux.Next(g) do
			local e1=Effect.CreateEffect(reason_effect)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_UPDATE_ATTACK)
			e1:SetValue(-value)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD)
			tc:RegisterEffect(e1)
		end
		-- ทำลายพวกที่พลัง <= 1000 (หลังจากลดแล้ว)
		local dg=g:Filter(function(c) return c:GetAttack()<=1000 end, nil)
		if #dg>0 then
			Duel.BreakEffect()
			Duel.Destroy(dg,REASON_EFFECT)
		end
	end
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	
	-- 1. Immediate Effect (ทำงานเฉพาะถ้ามีมอนสเตอร์)
	s.apply_immediate_nuke(tp, 2000, c)
	
	-- 2. Lingering Effect (Shared Ammo Mode)
	-- สร้างระบบนับจำนวนกระสุน 3 นัด โดยใช้ Dummy Effect
	local ammo_counter = Effect.CreateEffect(c)
	ammo_counter:SetType(EFFECT_TYPE_FIELD) -- เป็น Field Effect เพื่อให้เกาะอยู่กับ Duel
	ammo_counter:SetCode(0) -- ไม่ต้องมี Code จริงๆ แค่เอาไว้เก็บ Label
	ammo_counter:SetLabel(3) -- เริ่มต้น 3 นัด
	-- หมายเหตุ: ไม่ใส่ Reset เพื่อให้มันอยู่ไปเรื่อยๆ จนกว่ากระสุนจะหมด (หรือจบดูเอล)
	Duel.RegisterEffect(ammo_counter,tp)
	
	-- ฟังก์ชันสร้างตัวจับการอัญเชิญ
	local function slifer_curse(event_code)
		local e2=Effect.CreateEffect(c)
		e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		e2:SetCode(event_code)
		e2:SetLabelObject(ammo_counter) -- ผูกกับตัวนับกระสุน
		e2:SetCondition(s.slifer_con)
		e2:SetOperation(s.slifer_op)
		Duel.RegisterEffect(e2,tp)
	end
	
	-- ดักจับทุกการอัญเชิญ
	slifer_curse(EVENT_SUMMON_SUCCESS)
	slifer_curse(EVENT_SPSUMMON_SUCCESS)
	slifer_curse(EVENT_FLIP_SUMMON_SUCCESS)
	
	-- 3. Bonus: Shuffle Hand/Backrow (Tactical Mode)
	if Duel.GetFlagEffect(tp,TACTICAL_FLAG_ID)>0 then
		local hg=Duel.GetFieldGroup(tp,0,LOCATION_HAND)
		local bg=Duel.GetMatchingGroup(s.backrow_filter,tp,0,LOCATION_ONFIELD,nil)
		
		if #hg>0 or #bg>0 then
			Duel.BreakEffect()
			local to_deck_group = Group.CreateGroup()
			
			-- เช็คการ์ดมือ
			if #hg>0 then
				Duel.ConfirmCards(tp,hg)
				local hand_targets=hg:Filter(s.hand_filter,nil)
				to_deck_group:Merge(hand_targets)
				Duel.ShuffleHand(1-tp)
			end
			-- เช็คหลังบ้าน
			if #bg>0 then
				to_deck_group:Merge(bg)
			end
			
			-- ส่งกลับเด็ค
			if #to_deck_group>0 then
				Duel.SendtoDeck(to_deck_group,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
			end
		end
	end
end

function s.slifer_filter(c,tp)
	return c:IsFaceup() and c:IsControler(1-tp)
end

function s.slifer_con(e,tp,eg,ep,ev,re,r,rp)
	-- ดึงตัวแปรกลางมาเช็ค
	local ammo_obj = e:GetLabelObject()
	if not ammo_obj or ammo_obj:GetLabel() <= 0 then
		e:Reset() -- ถ้ากระสุนหมดแล้ว ให้ลบเอฟเฟคดักจับทิ้งไปเลย
		return false
	end
	return eg:IsExists(s.slifer_filter,1,nil,tp)
end

function s.slifer_op(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local ammo_obj = e:GetLabelObject()
	local current_ammo = ammo_obj:GetLabel()
	
	if current_ammo <= 0 then return end
	
	local g=eg:Filter(s.slifer_filter,nil,tp)
	local dg=Group.CreateGroup()
	
	if #g>0 then
		Duel.Hint(HINT_CARD,0,id) 
		for tc in aux.Next(g) do
			local e1=Effect.CreateEffect(c)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_UPDATE_ATTACK)
			e1:SetValue(-2000)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD)
			tc:RegisterEffect(e1)
			
			if tc:GetAttack()<=1000 then
				dg:AddCard(tc)
			end
		end
		
		if #dg>0 then
			Duel.Destroy(dg,REASON_EFFECT)
		end
		
		-- ลดจำนวนกระสุนลง 1 นัด
		local new_ammo = current_ammo - 1
		ammo_obj:SetLabel(new_ammo)
		
		-- แจ้งเตือนจำนวนกระสุนที่เหลือ (Optional)
		-- Duel.Hint(HINT_MESSAGE, 1-tp, "Missile Ammo Left: "..new_ammo)
		
		-- ถ้ากระสุนหมด (0) ให้เคลียร์ทิ้ง
		if new_ammo <= 0 then
			ammo_obj:Reset()
			e:Reset()
		end
	end
end