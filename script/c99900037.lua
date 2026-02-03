-- Nayuta Assemble
-- ID: 99900037
local s,id=GetID()
local ID_TOKEN = 99900038 -- Nikke Nayuta (Link-1)
local ID_BOSS  = 99900039 -- Pioneer Nikke Nayuta
local ID_NIKKE = 0xc02  -- Set code for Nikke

function s.initial_effect(c)
	-- Activate Effect (Quick-Play)
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TODECK+CATEGORY_TOKEN)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_END_PHASE)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

function s.nikke_check(c) 
	return c:IsSetCard(ID_NIKKE) 
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	local g=Duel.GetFieldGroup(tp,LOCATION_MZONE,0)
	if chk==0 then 
		return Duel.GetMZoneCount(tp,g)>0 
		and Duel.IsPlayerCanSpecialSummonMonster(tp,ID_TOKEN,0,TYPE_TOKEN+TYPE_LINK,900,0,1,RACE_MACHINE,ATTRIBUTE_WIND)
		and Duel.CheckLPCost(tp, math.floor(Duel.GetLP(tp)/2))
		and Duel.IsExistingMatchingCard(s.nikke_check, tp, LOCATION_EXTRA+LOCATION_GRAVE, 0, 1, nil)
	end
	
	Duel.PayLPCost(tp, math.floor(Duel.GetLP(tp)/2))
	Duel.SetChainLimit(aux.FALSE)
	
	Duel.SetOperationInfo(0,CATEGORY_TODECK,nil,1,tp,LOCATION_MZONE)
	Duel.SetOperationInfo(0,CATEGORY_TOKEN,nil,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,0)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	-- 1. Shuffle Monsters
	local g=Duel.GetFieldGroup(tp,LOCATION_MZONE,0)
	if #g>0 then
		Duel.SendtoDeck(g,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
	end
	
	-- 2. Summon 1st Batch Tokens
	local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
	if ft<=0 then return end
	if Duel.IsPlayerAffectedByEffect(tp,CARD_BLUEEYES_SPIRIT) then ft=1 end
	
	for i=1,ft do
		local token=Duel.CreateToken(tp,ID_TOKEN)
		Duel.SpecialSummonStep(token,0,tp,tp,false,false,POS_FACEUP)
	end
	Duel.SpecialSummonComplete()
	
	-- 3. Watcher (Phase 1)
	Duel.RegisterFlagEffect(tp,id,RESET_PHASE+PHASE_END+RESET_SELF_TURN,0,1000,1)
	
	local e2=Effect.CreateEffect(e:GetHandler())
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e2:SetCode(EVENT_LEAVE_FIELD)
	e2:SetCondition(s.check_con)
	e2:SetOperation(s.check_op)
	e2:SetReset(RESET_PHASE+PHASE_END+RESET_SELF_TURN, 1000)
	Duel.RegisterEffect(e2,tp)
end

-- ============================================================================
-- WATCHER LOGIC
-- ============================================================================
function s.check_filter(c) return c:IsCode(ID_TOKEN) end

function s.check_con(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.check_filter,1,nil) 
		and Duel.GetMatchingGroupCount(Card.IsCode,tp,LOCATION_MZONE,0,nil,ID_TOKEN) == 0
end

function s.check_op(e,tp,eg,ep,ev,re,r,rp)
	local state = Duel.GetFlagEffectLabel(tp,id)
	local c = e:GetHandler()
	
	if not state then return end 

	if state == 1 then
		-- [End Phase 1] -> Start Phase 2
		Duel.Hint(HINT_CARD,0,id)
		
		-- Summon 2nd Batch
		local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
		if ft>0 then
			if Duel.IsPlayerAffectedByEffect(tp,CARD_BLUEEYES_SPIRIT) then ft=1 end
			for i=1,ft do
				local token=Duel.CreateToken(tp,ID_TOKEN)
				Duel.SpecialSummonStep(token,0,tp,tp,false,false,POS_FACEUP)
			end
			Duel.SpecialSummonComplete()
		end
		
		-- Prepare Boss Logic
		local has_boss = Duel.IsExistingMatchingCard(Card.IsCode, tp, LOCATION_EXTRA+LOCATION_GRAVE+LOCATION_REMOVED+LOCATION_ONFIELD, 0, 1, nil, ID_BOSS)
		if not has_boss then
			local boss_token = Duel.CreateToken(tp, ID_BOSS)
			Duel.Remove(boss_token, POS_FACEUP, REASON_EFFECT)
			Duel.Hint(HINT_CARD,0,ID_BOSS) 
		end
		
		Duel.SetFlagEffectLabel(tp,id,2)
		
	elseif state == 2 then
		-- [End Phase 2] -> Grand Finale
		Duel.Hint(HINT_CARD,0,id)
		
		-- 1. Clear Field
		local g_all = Duel.GetFieldGroup(tp,LOCATION_ONFIELD,LOCATION_ONFIELD)
		local g_opp_field = Duel.GetFieldGroup(tp,0,LOCATION_ONFIELD) 
		local search_count = 0 
		
		if #g_opp_field > 0 then
			 search_count = #g_opp_field
		end

		if #g_all > 0 then
			Duel.SendtoDeck(g_all,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
		end
			
		-- 2. Forced Search
		if search_count > 0 then
			Duel.BreakEffect()
			
			local g_deck = Duel.GetFieldGroup(tp,0,LOCATION_DECK)
			if #g_deck < search_count then search_count = #g_deck end
			
			if search_count > 0 then
				-- เปิดเด็คฝ่ายตรงข้าม (เพื่อให้เราเลือกได้)
				Duel.ConfirmCards(tp, g_deck)
				
				Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
				local g_search = g_deck:Select(tp, search_count, search_count, nil)
				
				if #g_search > 0 then
					-- ส่งเข้ามือเจ้าของ (nil)
					Duel.SendtoHand(g_search, nil, REASON_EFFECT)
					
					-- [GLITCH FIX] ลบ ConfirmCards ออก
					-- Duel.ConfirmCards(1-tp, g_search)
					
					-- สับเด็คฝ่ายตรงข้าม
					Duel.ShuffleDeck(1-tp)
					Duel.ShuffleHand(1-tp)
				end
			end
		end
		
		-- 3. Summon Boss
		Duel.BreakEffect()
		local g_boss = Duel.GetMatchingGroup(Card.IsCode, tp, LOCATION_EXTRA+LOCATION_GRAVE+LOCATION_REMOVED, 0, nil, ID_BOSS)
		
		if #g_boss > 0 then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
			local tc = g_boss:Select(tp,1,1,nil):GetFirst()
			if tc then
				if tc:IsLocation(LOCATION_GRAVE+LOCATION_REMOVED) then
					Duel.SendtoDeck(tc,nil,SEQ_DECKTOP,REASON_EFFECT)
				end
				
				local e1=Effect.CreateEffect(e:GetHandler())
				e1:SetType(EFFECT_TYPE_SINGLE)
				e1:SetCode(EFFECT_CANNOT_DISABLE_SPSUMMON)
				e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
				e1:SetReset(RESET_EVENT+RESETS_STANDARD)
				tc:RegisterEffect(e1,true)
				
				Duel.SpecialSummon(tc,0,tp,tp,true,false,POS_FACEUP)
			end
		end
		
		Duel.ResetFlagEffect(tp,id)
		e:Reset()
	end
end