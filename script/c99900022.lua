-- Nikke Mica
-- ID: 99900022
local s,id=GetID()
local NIKKE_SET_ID = 0xc02

function s.initial_effect(c)
	-- 1. Special Summon from Hand (ลงฟรี)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.spcon)
	c:RegisterEffect(e1)

	-- 2. Search Level 3 or lower (Deck/GY)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_SUMMON_SUCCESS)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCountLimit(1,id+100)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)
	local e3=e2:Clone()
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e3)

	-- 3. Synchro Shortcut (UNLIMITED USE & FULL FIELD FIX)
	-- เอฟเฟกต์เรียก Synchro แบบทางลัด
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,1))
	e4:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e4:SetType(EFFECT_TYPE_IGNITION)
	e4:SetRange(LOCATION_MZONE)
	-- ไม่ใส่ SetCountLimit ตามที่ขอ
	e4:SetCost(s.syncost)
	e4:SetTarget(s.syntg)
	e4:SetOperation(s.synop)
	c:RegisterEffect(e4)
	
	-- 4. [AUTO] Non-Tuner for Nikke Synchro
	local e5=Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_SINGLE)
	e5:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e5:SetRange(LOCATION_MZONE)
	e5:SetCode(EFFECT_NONTUNER)
	e5:SetValue(s.ntval)
	c:RegisterEffect(e5)
end

function s.ntval(c,sc,tp) return sc:IsSetCard(NIKKE_SET_ID) end

-- [Effect 1] SP Summon
function s.spfilter(c) return c:IsFaceup() and c:IsSetCard(NIKKE_SET_ID) end
function s.spcon(e,c)
	if c==nil then return true end
	return Duel.GetLocationCount(c:GetControler(),LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.spfilter,c:GetControler(),LOCATION_MZONE,0,1,nil)
end

-- [Effect 2] Search (Level 3 or lower)
function s.thfilter(c) 
	return c:IsSetCard(NIKKE_SET_ID) and c:IsLevelBelow(3) and c:IsType(TYPE_MONSTER) and c:IsAbleToHand() 
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end

-- [Effect 3] Synchro Shortcut Logic (Full Field Fix Applied)
function s.matfilter(c)
	return c:IsRace(RACE_MACHINE) and c:IsAbleToGraveAsCost()
end

-- [แก้ไข] เพิ่ม lc_group เพื่อรับข้อมูลการ์ดที่จะหายไป
function s.synchrofilter(c,e,tp,lc_group)
	return c:IsSetCard(NIKKE_SET_ID) and c:IsType(TYPE_SYNCHRO) 
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_SYNCHRO,tp,false,false)
		-- คำนวณช่องว่างโดยหักลบ lc_group ออก
		and Duel.GetLocationCountFromEx(tp,tp,lc_group,c)>0
end

function s.syncost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	-- เช็ค: ตัวเอง + Machine อีก 1 ตัว
	if chk==0 then return c:IsAbleToGraveAsCost() 
		and Duel.IsExistingMatchingCard(s.matfilter,tp,LOCATION_MZONE,0,1,c) end
	
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g=Duel.SelectMatchingCard(tp,s.matfilter,tp,LOCATION_MZONE,0,1,1,c)
	g:AddCard(c)
	Duel.SendtoGrave(g,REASON_COST)
end

function s.syntg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then 
		-- [แก้ไข] ส่ง e:GetHandler() เข้าไปบอกว่า "ตัวนี้จะหายไปนะ" (แก้ปัญหาสนามเต็ม)
		return Duel.IsExistingMatchingCard(s.synchrofilter,tp,LOCATION_EXTRA,0,1,nil,e,tp,e:GetHandler()) 
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

function s.synop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	-- ส่ง nil เพราะตอนรันผล การ์ดหายไปจริงแล้ว ช่องว่างเกิดขึ้นจริง
	local g=Duel.SelectMatchingCard(tp,s.synchrofilter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp,nil)
	if #g>0 then
		Duel.SpecialSummon(g,SUMMON_TYPE_SYNCHRO,tp,tp,false,false,POS_FACEUP)
		g:GetFirst():CompleteProcedure()
	end
end