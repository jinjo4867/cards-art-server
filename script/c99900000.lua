-- Nikke Rapi
-- ID: 99900000
local s,id=GetID()
local NIKKE_SET_ID = 0xc02
local ENCOUNTER_CARD_ID = 99900003

function s.initial_effect(c)
	-- 1. Special Summon (No Nikke) - From Hand/GY
	-- ตรงกับข้อความใน DataEditorX ช่องที่ [0] : "Special Summon (No 'Nikke')"
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0)) 
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_HAND+LOCATION_GRAVE)
	e1:SetCountLimit(1,id) -- เทิร์นละ 1 ครั้ง (นับแยกกับเอฟเฟค 4)
	e1:SetCondition(s.spcon_empty)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	-- 2. Search Effect (When Normal Summoned)
	-- ตรงกับข้อความใน DataEditorX ช่องที่ [1] : "Add 1 'Nikke' monster"
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e2:SetType(EFFECT_TYPE_TRIGGER_O+EFFECT_TYPE_SINGLE)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_SUMMON_SUCCESS)
	e2:SetRange(LOCATION_MZONE)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)

	-- 3. Search Effect (When Special Summoned)
	local e3=e2:Clone()
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	e3:SetRange(LOCATION_MZONE)
	c:RegisterEffect(e3)

	-- 4. Special Summon (With Encounter) - From Hand
	-- ตรงกับข้อความใน DataEditorX ช่องที่ [2] : "Special Summon (Control 'Encounter')"
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,2)) 
	e4:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e4:SetType(EFFECT_TYPE_IGNITION)
	e4:SetRange(LOCATION_HAND)
	e4:SetCountLimit(1,id+100) -- เทิร์นละ 1 ครั้ง (คนละโควตากับเอฟเฟค 1)
	e4:SetCondition(s.spcon_encounter)
	e4:SetTarget(s.sptg)
	e4:SetOperation(s.spop)
	c:RegisterEffect(e4)
end

-- ==================================================================
-- Filters
-- ==================================================================
function s.faceup_nikke_filter(c)
	return c:IsFaceup() and c:IsSetCard(NIKKE_SET_ID)
end

function s.faceup_encounter_filter(c)
	return c:IsFaceup() and c:IsCode(ENCOUNTER_CARD_ID)
end

-- ==================================================================
-- Logic 1: SS (No Nikke)
-- ==================================================================
function s.spcon_empty(e,tp,eg,ep,ev,re,r,rp)
	-- เช็คว่าไม่มีมอนสเตอร์ Nikke บนสนาม (ถ้ามี Encounter ที่เป็นเวทมนตร์อยู่ ก็ยังกดได้)
	return not Duel.IsExistingMatchingCard(s.faceup_nikke_filter,tp,LOCATION_MZONE,0,1,nil)
end

-- ==================================================================
-- Logic 2 & 3: Searcher
-- ==================================================================
function s.thfilter(c)
	return c:IsSetCard(NIKKE_SET_ID) and c:IsLevelBelow(4) and c:IsType(TYPE_MONSTER) and c:IsAbleToHand()
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

-- ==================================================================
-- Logic 4: SS (With Encounter)
-- ==================================================================
function s.spcon_encounter(e,tp,eg,ep,ev,re,r,rp)
	-- เช็คว่ามีการ์ด Encounter หงายหน้าอยู่บนสนาม (จะเป็นเวทหรือมอนก็ได้)
	return Duel.IsExistingMatchingCard(s.faceup_encounter_filter,tp,LOCATION_ONFIELD,0,1,nil)
end

-- ==================================================================
-- Shared SS Operation
-- ==================================================================
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
	end
end