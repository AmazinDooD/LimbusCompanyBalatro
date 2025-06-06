SMODS.Atlas {
    key = "lcb_jokers",
    path = "jokers.png",
    px = 71,
    py = 95
}

SMODS.Atlas {
    key = "lcb_tags",
    path = "tags.png",
    px = 34,
    py = 34
}

SMODS.Atlas {
    key = "lcb_boosters",
    path = "boosters.png",
    px = 71,
    py = 95
}

SMODS.Atlas {
    key = "modicon",
    path = "modicon.png",
    px = 34,
    py = 34
}

SMODS.Atlas {
    key = "sins",
    path = "sins.png",
    px = 256,
    py = 256
}

SMODS.Atlas {
    key = "ego",
    path = "ego.png",
    px = 71,
    py = 95
}

SMODS.ConsumableType{
    key = "lcb_ego",
    primary_colour = HEX("EB8334"),
    secondary_colour = HEX("E8572B"),
    loc_txt = { -- No clue how to do this with localization files.
        name = "E.G.O.",
        collection = "E.G.O. Cards",
        undiscovered = {
            name = "Not Discovered",
            text = {
                "Purchase or use",
                "this card in an",
                "unseeded run to",
                "learn what it does",
            },
        }
    },
    collection_rows = {4,4},
    shop_rate = 0.5,
    cards = {
        ["c_lcb_la_sangre"] = true
    }
}

SMODS.UndiscoveredSprite {
    key = "lcb_ego",
    atlas = "ego",
    pos = {x=0,y=0},
    overlay_pos = {x=-4,y=1}
}

-- TODO: All O sinners (remaining Yi Sang, Faust, Hong Lu)
-- Start with Shi Ishmael for the OO sinners

-- Holding M is for the weak, now i can just type "eval _R()" and win
function _R() SMODS.restart_game() end

local lcb_config = SMODS.current_mod.config
local magic_bullet_texts = {
    "It really is as you say; this is a magic bullet that will never miss.",
    "My bullet inevitably flies in the same direction, its trajectory preordained. There are no coincidences.",
    "There's no going back when I've already come this far by firing the bullet. Even if this road I walk is an inevitable path to inferno.",
    "Do not seek my mercy, for only desolation awaits those who stand in my path.",
    "Remain unshaken. Grant silence to all that stands before you. Follow the land horizon.",
    "The despairing heart is burnt black, never to fade away. Only the shearing cold floods within.",
    "Though it was despair that I sought, the bullet's trajectory… is predetermined!" -- *dies*
}
-- nothing here
local unsuspicious_text = "힘들었어요? 지쳤어요. 쉬고 싶어요? 배고파요. 나가고 싶어요?     잘리고 싶어요? 뼈가 녹아요. 살이 터져요? 죽지는 않아요.    죄송합니다. 그만하겠습니다."

local function sin_to_text(sin)
    local sins = { "Wrath", "Lust", "Sloth", "Gluttony", "Gloom", "Pride", "Envy" }
    return sins[sin]
end

local function has_value(tab, val)
    for i, v in ipairs(tab) do
        if v == val then
            return true
        end
    end
    return false
end

local function index_of(arr, val)
    for i, v in ipairs(arr) do
        if v == val then
            return i
        end
    end
    return nil
end

function G.FUNCS.lcb_switch_pack_music(arg)
    lcb_config.limbus_pack_music = arg.to_key
    SMODS.save_mod_config(SMODS.current_mod)
end

local function create_sin_uibox()
    local text = ""
    for i=1,7 do text = text..sin_to_text(i)..": "..G.GAME.lcb_sins[i]..(i~= 7 and ", " or "") end
    return {n = G.UIT.ROOT, config = {align = "cr", colour = G.C.CLEAR}, nodes = {
        {n=G.UIT.R, config = {align = "cm", padding = 3}, nodes = { -- Don't ask me why the padding is 3, i changed it for testing and then aligned the text but forgot to change it back
            { n = G.UIT.T, config = { text = text, colour = G.C.UI.TEXT_LIGHT, scale = 0.3 } }
        }}
    }}
end

local function update_sin_uibox()
    if G.UIDEF.lcb_sins then G.UIDEF.lcb_sins.config.object:remove() end
    local sin_text = UIBox {
        definition = create_sin_uibox(),
        config = { align = "cm", major = G.ROOM_ATTACH, offset = {x=-1.3,y=-6}}
    }
    local sin_obj = { n = G.UIT.O, config = { object = sin_text } }
    G.UIDEF.lcb_sins = sin_obj
end

local igo = Game.init_game_object
function Game:init_game_object()
    local ret = igo(self)
    ret.lcb_blind_effects = {tremor = 0, rupture = {0,0}} -- Tremor only has Potency here
    -- The first value is Potency, the second is Count
    -- !! Rupture: Each card gives (Rupture * 10) Chips and decreases count by 1 (DONE)
    -- !! Time Moratorium: After playing a hand, sets Chips and Mult to 0
    --                     On last hand of round, gives (Total chips and mult collected * 1.2) split evenly between Chips and Mult
    -- !! Charge: just decreases by 1 after hand is played lol
    -- !! Poise: gives X(1 + potency / 4) Mult, decreases count by 1 (on joker) (DONE)
    -- !! Sinking & Burn still left to do
    -- yeugh i have no ideas for sinking
    ret.lcb_sins = {0,0,0,0,0,0,0}
    -- The sin is a number from 1 to 7, 1 being wrath, 2 being lust etc.
    -- Using a skill of the said sin gives you one of that sin
    -- E.G.O. skills consume sins for better effects
    -- E.G.O. are obtained from packs or shop
    ret.pool_flags.cannot_spawn = true -- Anything with the no_pool_flag of this just, won't spawn
    return ret
end

-- Add an ego resource and refresh the UIBox
function add_ego_resource(sin, count)
    if not sin or not count or not G.GAME or not G.GAME.lcb_blind_effects then return nil end
    local sins = { "Wrath", "Lust", "Sloth", "Gluttony", "Gloom", "Pride", "Envy" }
    if has_value(sins,sin) then G.GAME.lcb_sins[index_of(sins, sin)] = G.GAME.lcb_sins[index_of(sins, sin)] + count
    else G.GAME.lcb_sins[sin] = G.GAME.lcb_sins[sin] + count end
    update_sin_uibox()
end

-- Colours
G.C.SIN_WRATH = HEX("c62d14")
G.C.SIN_LUST = HEX("ce5c12")
G.C.SIN_SLOTH = HEX("e38800")
G.C.SIN_GLUTTONY = HEX("669b10")
G.C.SIN_GLOOM = HEX("14788d")
G.C.SIN_PRIDE = HEX("0a5294")
G.C.SIN_ENVY = HEX("8f1fc3")

G.C.ZAYIN = HEX("7a570f")
G.C.TETH = HEX("975817")
G.C.HE = HEX("a75900")
G.C.WAW = HEX("ac4704")
-- aleph doesnt exist yet

function SMODS.current_mod.config_tab()
    local sprite = Sprite(34, 34, 1, 1, G.ASSET_ATLAS["lcb_modicon"])
    local config_nodes = {n=G.UIT.ROOT, config = {align = "cm", colour = G.C.L_BLACK, minw = 4, minh = 4}, nodes = {
        {n = G.UIT.C, config = {align = "cm"}, nodes = {}}
    }}
    config_nodes.nodes[1].nodes[1] = create_toggle{
        label = "Does Don Quixote do the funny?",
        ref_table = lcb_config,
        ref_value = "don_is_funny"
    }
    config_nodes.nodes[1].nodes[2] = create_option_cycle{
        label = "Limbus Pack Music",
        w = 6.3,
        scale = 0.9,
        options = {
            "Extraction Theme",
            "Abnormality Extraction Theme",
            "Oh Crab, So Crab",
            "La Mancha Carnival",
            "A Midspring Night's Dream 2",
            unsuspicious_text,
        },
        opt_callback = "lcb_switch_pack_music",
        current_option = lcb_config.limbus_pack_music
    }
    config_nodes.nodes[1].nodes[3] = {
        n = G.UIT.R, config = { align = "cm"}, nodes = {{
            n = G.UIT.O, config = { object = sprite, juice = true}
        }}
    }
    return config_nodes
end

function SMODS.current_mod.reset_game_globals(run_start)
    --[[
    G.GAME.lcb_blind_effects.burn = {0,0}
    G.GAME.lcb_blind_effects.bleed = {0,0}
    if run_start then
        add_tag(Tag("tag_lcb_burn_indicator"))
        add_tag(Tag("tag_lcb_bleed_indicator"))
        add_tag(Tag("tag_lcb_poise_indicator"))
    end
    if G.GAME.blind and G.GAME.blind.boss then G.GAME.lcb_blind_effects.poise = {0,0} end
    ]]
    update_sin_uibox()
    G.GAME.lcb_blind_effects.tremor = 0
    G.GAME.lcb_blind_effects.rupture = {0,0}
end

local function skill_switch(context, card)
    if not context or not card or not card.ability or not card.ability.extra then return nil end
    if context.after then
        card.ability.extra.times_skill_used = card.ability.extra.times_skill_used + 1
        local sin = card.ability.extra.sin[card.ability.extra.current_skill]
        G.GAME.lcb_sins[sin] = G.GAME.lcb_sins[sin] + 1
        if (card.ability.extra.times_skill_used == 3 and card.ability.extra.current_skill == 1) or
        (card.ability.extra.times_skill_used == 2 and card.ability.extra.current_skill == 2) or
        (card.ability.extra.times_skill_used == 1 and card.ability.extra.current_skill == 3) then
            card.ability.extra.times_skill_used = 0
            card.ability.extra.current_skill = card.ability.extra.current_skill + 1
            if card.ability.extra.current_skill == 4 then card.ability.extra.current_skill = 1 end
        end
        sendInfoMessage(sin_to_text(sin).." sin granted, you now have "..G.GAME.lcb_sins[sin])
        update_sin_uibox()
    end
end

local function modify_blind(blind_mod)
    G.E_MANAGER:add_event(Event({
        trigger = 'after',
        delay = 0.1,
        func = function()
            G.GAME.blind.chips = math.floor(G.GAME.blind.chips * blind_mod)
            G.GAME.blind.chip_text = number_format(G.GAME.blind.chips)

            local chips_UI = G.hand_text_area.blind_chips
            G.FUNCS.blind_chip_UI_scale(G.hand_text_area.blind_chips)
            G.HUD_blind:recalculate()
            chips_UI:juice_up()

            if not silent then play_sound('lcb_bleed') end
            return true
        end
    }))
end

local function modify_blind_add(blind_mod) modify_blind((G.GAME.blind.chips + blind_mod) / G.GAME.blind.chips) end

SMODS.Rarity {
    key = "tier_i",
    badge_colour = HEX("f9c400")
}

SMODS.Rarity {
    key = "tier_ii",
    badge_colour = HEX("f9c400")
}

SMODS.Rarity {
    key = "tier_iii",
    badge_colour = HEX("fcbe38")
}

SMODS.Rarity {
    key = "tier_iv",
    badge_colour = HEX("fff465")
}

SMODS.Rarity {
    key = "tier_v",
    badge_colour = HEX("fff465")
}

SMODS.Rarity {
    key = "o",
    badge_colour = HEX("a96d37")
}

SMODS.Rarity {
    key = "oo",
    badge_colour = HEX("e5931e")
}

SMODS.Rarity {
    key = "ooo",
    badge_colour = HEX("f3c131")
}

-- dundun......
SMODS.Sound {
    key = "tremor_burst",
    path = "limbus_tremor_burst.mp3",
    pitch = 1
}

-- Limbus Pack Music --

SMODS.Sound {
    key = "music_extraction_theme",
    path = "Extraction Theme 2.wav",
    pitch = 1, -- why do i have to do this?
    -- definetly not yoinked from aikoyori's shenanigans, what are you talking about
    select_music_track = function()
        if not SMODS.OPENED_BOOSTER or lcb_config.limbus_pack_music ~= 1 then return false end
        return G.booster_pack and not G.booster_pack.REMOVED and
            SMODS.OPENED_BOOSTER.config.center.key == "p_lcb_limbus_pack" or
            SMODS.OPENED_BOOSTER.config.center.key == "p_lcb_three_star_pack" and 100 or nil
    end,
}

SMODS.Sound {
    key = "music_abnormality_extration",
    path = "Abnormality Choice Theme.wav",
    pitch = 1,
    select_music_track = function()
        if not SMODS.OPENED_BOOSTER or lcb_config.limbus_pack_music ~= 2 then return false end
        return G.booster_pack and not G.booster_pack.REMOVED and
            SMODS.OPENED_BOOSTER.config.center.key == "p_lcb_limbus_pack" or
            SMODS.OPENED_BOOSTER.config.center.key == "p_lcb_three_star_pack" and 100 or nil
    end,
}

-- bless your ears, listen to this
SMODS.Sound {
    key = "music_oh_crab_so_crab",
    path = "Oh Crab, So Crab.wav",
    pitch = 1,
    select_music_track = function()
        if not SMODS.OPENED_BOOSTER or lcb_config.limbus_pack_music ~= 3 then return false end
        return G.booster_pack and not G.booster_pack.REMOVED and
            SMODS.OPENED_BOOSTER.config.center.key == "p_lcb_limbus_pack" or
            SMODS.OPENED_BOOSTER.config.center.key == "p_lcb_three_star_pack" and 100 or nil
    end,
}

SMODS.Sound {
    key = "music_la_mancha_carnival",
    path = "La Mancha Carnival.wav",
    pitch = 1,
    select_music_track = function()
        if not SMODS.OPENED_BOOSTER or lcb_config.limbus_pack_music ~= 4 then return false end
        return G.booster_pack and not G.booster_pack.REMOVED and
            SMODS.OPENED_BOOSTER.config.center.key == "p_lcb_limbus_pack" or
            SMODS.OPENED_BOOSTER.config.center.key == "p_lcb_three_star_pack" and 100 or nil
    end,
}

SMODS.Sound {
    key = "music_midspring_dream",
    path = "A Midspring Night’s Dream 2.wav",
    pitch = 1,
    select_music_track = function()
        if not SMODS.OPENED_BOOSTER or lcb_config.limbus_pack_music ~= 5 then return false end
        return G.booster_pack and not G.booster_pack.REMOVED and
            SMODS.OPENED_BOOSTER.config.center.key == "p_lcb_limbus_pack" or
            SMODS.OPENED_BOOSTER.config.center.key == "p_lcb_three_star_pack" and 100 or nil
    end,
}

SMODS.Sound {
    key = "music_the_funny_library_of_ruina_thing_that_probably_no_one_will_get",
    path = "the library.mp3",
    pitch = 1,
    select_music_track = function()
        if not SMODS.OPENED_BOOSTER or lcb_config.limbus_pack_music ~= 6 then return false end
        return G.booster_pack and not G.booster_pack.REMOVED and
            SMODS.OPENED_BOOSTER.config.center.key == "p_lcb_limbus_pack" or
            SMODS.OPENED_BOOSTER.config.center.key == "p_lcb_three_star_pack" and 100 or nil
    end,
}


-- LIMBUS COMPANYYYYYYYYYYYYYYYYYYYYYYY
SMODS.Sound {
    key = "limbus_company_yayy",
    path = "LIMBUS.mp3"
}

-- average london experience
SMODS.Sound {
    key = "bleed",
    path = "tingtang_honglu_skill2-2.wav"
}

SMODS.Booster {
    key = "limbus_pack",
    config = {extra = 3, choose = 1},
    cost = 12,
    weight = 0.3,
    atlas = "lcb_boosters",
    pos = {x=0,y=0},
    group_key = "k_lcb_limbus_pack",
    create_card = function(self, card, i)
        local random = pseudorandom("limbus_booster")
        local rarity = (random <= 0.7 and "lcb_o" or random <= 0.95 and "lcb_oo") or "lcb_ooo"
        -- !! TODO: REMEMBER TO DELETE THIS WHEN I ADD OOO RARITY JOKERS!!!!!!!!!!!!!!!!!!!
        if rarity == "lcb_ooo" then rarity = "lcb_oo" end

        return SMODS.create_card{
            set = "Joker",
            rarity = rarity
        }
    end
}

SMODS.Booster {
    key = "three_star_pack",
    config = { extra = 2, choose = 1 },
    cost = 40,
    weight = 0.3,
    atlas = "lcb_boosters",
    pos = { x = 1, y = 0 },
    group_key = "k_lcb_three_star_pack",
    create_card = function(self, card, i)
        --[[
        return SMODS.create_card {
            set = "Joker",
            rarity = "lcb_ooo",
            skip_materialize = true
        }]]
        return SMODS.create_card {
            set = "Joker",
            key = "j_joker"
        }
    end
}


SMODS.Consumable{
    key = "la_sangre",
    set = "lcb_ego",
    atlas = "ego",
    pos = {x=1,y=0},
    config = {extra = {active = false}},
    cost = 10,
    loc_vars = function(self, info_queue, card)
        info_queue[#info_queue+1] = {
            set = "Other",
            key = "bleed"
        }
        return {
            vars = {
                card.ability.extra.active and "Active!" or "Inactive",
                colours = {card.ability.extra.active and G.C.GREEN or G.C.RED}
            }
        }
    end,
    can_use = function(self, card)
        return G.GAME.lcb_sins[2] >= 2 and G.GAME.lcb_sins[6] >= 2 and #SMODS.find_card("j_lcb_don_quixote") ~= 0 and not card.ability.extra.active
    end,
    use = function(self, card, area)
        local _card = SMODS.add_card{key="c_lcb_la_sangre", set="Ego"}
        _card.ability.extra.active = true
        G.GAME.lcb_sins[2] = G.GAME.lcb_sins[2] - 2
        G.GAME.lcb_sins[6] = G.GAME.lcb_sins[6] - 2
        update_sin_uibox()
        card_eval_status_text(card, "extra", nil, nil, nil, {message="Active!"})
    end,
    calculate = function(self, card, context)
        if card.ability.extra.active then
            if context.after then
                G.E_MANAGER:add_event(Event({
                    trigger = 'after',
                    delay = 0.3,
                    blockable = false,
                    func = function()
                        play_sound('tarot1')
                        card:start_dissolve(nil, false, 2)
                        G.jokers:remove_card(card)
                        card = nil
                        return true;
                    end
                }))
            end
            if context.before then
                modify_blind(0.3)
            end
        end
    end
}

SMODS.Consumable {
    key = "magic_bullet",
    set = "lcb_ego",
    atlas = "ego",
    pos = { x = 2, y = 0 },
    config = { extra = { active = false, magic_bullet = 0} },
    cost = 10,
    loc_vars = function(self, info_queue, card)
        info_queue[#info_queue + 1] = { set = "Other", key = "magic_bullet_1" }
        info_queue[#info_queue + 1] = { set = "Other", key = "magic_bullet_2" }
        info_queue[#info_queue + 1] = { set = "Other", key = "magic_bullet_3" }
        info_queue[#info_queue + 1] = { set = "Other", key = "magic_bullet_4" }
        info_queue[#info_queue + 1] = { set = "Other", key = "magic_bullet_5" }
        info_queue[#info_queue + 1] = { set = "Other", key = "magic_bullet_6" }
        info_queue[#info_queue + 1] = { set = "Other", key = "magic_bullet_7" }
        return {
            vars = {
                card.ability.extra.active and "Active!" or "Inactive",
                colours = { card.ability.extra.active and G.C.GREEN or G.C.RED }
            }
        }
    end,
    can_use = function(self, card)
        return G.GAME.lcb_sins[2] >= 2 and G.GAME.lcb_sins[6] >= 2 and #SMODS.find_card("j_lcb_outis") ~= 0 and
        not card.ability.extra.active
    end,
    use = function(self, card, area)
        local _card = SMODS.add_card { key = "c_lcb_magic_bullet", set = "Ego" }
        _card.ability.extra.active = true
        G.GAME.lcb_sins[2] = G.GAME.lcb_sins[2] - 2
        G.GAME.lcb_sins[6] = G.GAME.lcb_sins[6] - 2
        update_sin_uibox()
        card_eval_status_text(card, "extra", nil, nil, nil, { message = "Active!" })
        -- TODO: set the magic bullet value here (card.ability.extra.magic_bullet)
    end,
    calculate = function(self, card, context)
        if card.ability.extra.active then
            if context.after then
                if card.ability.extra.magic_bullet == 7 then
                    local outis_card
                    for i in G.GAME.jokers.cards do
                        if string.match(i.config.center.key, "outis") then outis_card = i; break end
                    end
                    -- so that i dont crash the game
                    if not outis_card then sendInfoMessage("what the fuck did you do, where is my outis card","LCB")
                    else
                        G.E_MANAGER:add_event(Event({
                            trigger = 'after',
                            delay = 0.3,
                            blockable = false,
                            func = function()
                                play_sound('tarot1')
                                card:start_dissolve(nil, false, 2)
                                G.jokers:remove_card(outis_card)
                                card = nil
                                return true;
                            end
                        }))
                    end
                end
                G.E_MANAGER:add_event(Event({
                    trigger = 'after',
                    delay = 0.3,
                    blockable = false,
                    func = function()
                        play_sound('tarot1')
                        card:start_dissolve(nil, false, 2)
                        G.jokers:remove_card(card)
                        card = nil
                        return true;
                    end
                }))
            end
            if context.joker_main then
                -- do the shtuff
                if card.ability.extra.magic_bullet == 1 then
                    
                elseif card.ability.extra.magic_bullet == 2 then

                elseif card.ability.extra.magic_bullet == 3 then

                elseif card.ability.extra.magic_bullet == 4 then

                elseif card.ability.extra.magic_bullet == 5 then

                elseif card.ability.extra.magic_bullet == 6 then

                else
                    -- hoo boy
                    local xmult = 20

                end
            end
        end
    end
}


SMODS.Joker {
    key = "white_gossypium",
    rarity = "lcb_tier_ii",
    atlas = "lcb_jokers",
    pos = {x=0,y=0},
    config = { extra = { required_score = 50, reached_requirement = false, blind_increase = 1.2, blind_decrease = 0.9 } },
    loc_vars = function(self, info_queue, card)
        return {
            vars = {
                (card.ability.extra.blind_increase - 1) * 100,
                (1 - card.ability.extra.blind_decrease) * 100
            }
        }
    end,
    calculate = function(self, card, context)
        if context.after and hand_chips and mult and G.GAME.chips >= (hand_chips * mult) + math.floor(G.GAME.blind.chips / 2) and card.ability.extra.reached_requirement == false then
            modify_blind(card.ability.extra.blind_increase)
            card.ability.extra.reached_requirement = true
            card_eval_status_text(card, "extra", nil, nil, nil, {message = "Active!"})
        end
        if context.before and card.ability.extra.reached_requirement then
            modify_blind(card.ability.extra.blind_decrease)
            card_eval_status_text(card, "extra", nil, nil, nil, {message = "Bleed!"})
        end
        if context.setting_blind then card.ability.extra.reached_requirement = false end
    end
}

SMODS.Joker {
    key = "ardent_flower",
    rarity = "lcb_tier_iii",
    atlas = "lcb_jokers",
    pos = {x=1,y=0},
    config = {extra = {}},
    loc_vars = function(self, info_queue, card)
        info_queue[#info_queue + 1] = {
            key = "effect_applies",
            set = "Other"
        }
    end,
    calculate = function(self, card, context)
        if context.other_joker then
            if G.jokers.cards[1] == context.other_joker or G.jokers.cards[2] == context.other_joker and context.other_joker ~= card then
                local blind_mod = (100 - G.GAME.round_resets.ante * context.other_joker.config.center.rarity) / 100
                if blind_mod * 100 > 30 then blind_mod = 0.3 end
                modify_blind(blind_mod)
                card_eval_status_text(card, "extra", nil, nil, nil, {message = "Burn!"})
                G.E_MANAGER:add_event(Event({
                    trigger = "after",
                    delay = 0.1,
                    func = function()
                        context.other_joker:juice_up(0.5, 0.5)
                        return true
                    end
                }))
            end
        end
    end
}

SMODS.Joker {
    key = "voodoo_doll",
    rarity = "lcb_tier_i",
    atlas = "lcb_jokers",
    pos = {x=2,y=0},
    config = {extra = {xmult = 2}},
    loc_vars = function(self, info_queue, card)
        info_queue[#info_queue+1] = {
            key = "blind_start",
            set = "Other"
        }
        return {vars = {card.ability.extra.xmult}}
    end,
    calculate = function(self, card, context)
        if context.setting_blind then
            modify_blind_add(-5) -- real
            card_eval_status_text(card, "extra", nil, nil, nil, {message = "Blind Reduced by 5!"})
        end
        if hand_chips and mult and G.GAME.chips + (hand_chips * mult) >= math.floor(G.GAME.blind.chips / 2) and context.joker_main then
            return {
                x_mult = card.ability.extra.xmult,
                card = card
            }
        end
    end
}

SMODS.Joker {
    key = "don_quixote",
    rarity = "lcb_o",
    atlas = "lcb_jokers",
    pos = {x=3,y=0},
    config = {extra = {current_skill = 1, times_skill_used = 0, skill2_effect_active = false, sin={2,7,3}}},
    loc_vars = function(self, info_queue, card)
        info_queue[#info_queue + 1] = {
            key = "reuse",
            set = "Other"
        }
        info_queue[#info_queue + 1] = {
            key = "bleed",
            set = "Other"
        }
        return {vars = {
            (card.ability.extra.current_skill == 1 and "[Joust]" or card.ability.extra.current_skill == 2 and "[Galloping Tilt]") or "[For Justice!]"
            },
            main_end = {
                { n = G.UIT.O, config = { object = Sprite(34, 34, 0.75, 0.75, G.ASSET_ATLAS["lcb_sins"], { x = 1, y = 0 }) } },
                { n = G.UIT.O, config = { object = Sprite(34, 34, 0.75, 0.75, G.ASSET_ATLAS["lcb_sins"], { x = 6, y = 0 }) } },
                { n = G.UIT.O, config = { object = Sprite(34, 34, 0.75, 0.75, G.ASSET_ATLAS["lcb_sins"], { x = 2, y = 0 }) } },
            }
        }
    end,
    calculate = function(self, card, context)
        skill_switch(context, card)
        if context.joker_main then
            if lcb_config.don_is_funny then play_sound("lcb_limbus_company_yayy") end
            if card.ability.extra.current_skill == 1 then
                local mult = hand_chips * mult >= 0.3 * G.GAME.blind.chips and 50 or 25
                return {
                    mult = mult,
                    card = card
                }
            elseif card.ability.extra.current_skill == 2 then
                if card.ability.extra.skill2_effect_active then
                    modify_blind(0.8)
                    card_eval_status_text(card, "extra", nil, nil, nil, { message = "Blind Reduced by 20%" })
                    card.ability.extra.skill2_effect_active = false
                else
                    modify_blind(0.9)
                    card_eval_status_text(card, "extra", nil, nil, nil, { message = "Blind Reduced by 10%" })
                    card.ability.extra.skill2_effect_active = true
                end
            else
                for i=1,2 do
                    if pseudorandom("don_quixote") > 0.5 then
                        modify_blind(0.95)
                        card_eval_status_text(card, "extra", nil, nil, nil, {message = "Blind Reduced by 5%"})
                    end
                end
                modify_blind(0.9)
                card_eval_status_text(card, "extra", nil, nil, nil, { message = "Blind Reduced by 10%" })
            end
        end
    end
}

SMODS.Joker {
    key = "rodya",
    rarity = "lcb_o",
    atlas = "lcb_jokers",
    pos = {x=4,y=0},
    config = {extra = {current_skill = 1, times_skill_used = 0, percent_lowered = 0, sin={4,6,1}}},
    loc_vars = function(self, info_queue, card)
        info_queue[#info_queue + 1] = {
            key = "reuse",
            set = "Other"
        }
        info_queue[#info_queue+1] = {
            key = "bleed",
            set = "Other"
        }
        return {vars = {
                (card.ability.extra.current_skill == 1 and "[Strike Down]" or card.ability.extra.current_skill == 2 and "[Axe Combo]") or "[Slay]"
            },
            main_end = {
                { n = G.UIT.O, config = { object = Sprite(34, 34, 0.75, 0.75, G.ASSET_ATLAS["lcb_sins"], { x = 3, y = 0 }) } },
                { n = G.UIT.O, config = { object = Sprite(34, 34, 0.75, 0.75, G.ASSET_ATLAS["lcb_sins"], { x = 5, y = 0 }) } },
                { n = G.UIT.O, config = { object = Sprite(34, 34, 0.75, 0.75, G.ASSET_ATLAS["lcb_sins"], { x = 0, y = 0 }) } },
            }
        }
    end,
    calculate = function(self, card, context)
        skill_switch(context, card)
        if context.joker_main then
            if card.ability.extra.current_skill == 1 then
                modify_blind(0.9)
                card_eval_status_text(card, "extra", nil, nil, nil, { message = "Blind Reduced by 10%" })
                card.ability.extra.percent_lowered = card.ability.extra.percent_lowered + 10
            elseif card.ability.extra.current_skill == 2 then
                modify_blind(0.8)
                card_eval_status_text(card, "extra", nil, nil, nil, { message = "Blind Reduced by 20%" })
                card.ability.extra.percent_lowered = card.ability.extra.percent_lowered + 20
                if pseudorandom("rodya") > 0.5 then
                    return {
                        mult = 25,
                        card = card
                    }
                end
            else
                for i = 1, 3 do
                    if pseudorandom("rodya") > 0.5 then
                        modify_blind(0.95)
                        card_eval_status_text(card, "extra", nil, nil, nil, { message = "Blind Reduced by 5%" })
                        card.ability.extra.percent_lowered = card.ability.extra.percent_lowered + 5
                    end
                end
                if card.ability.extra.percent_lowered >= 30 then
                    return {
                        xmult = 1.7,
                        card = card
                    }
                end
            end
        end
        if context.setting_blind then card.ability.extra.percent_lowered = 0 end
    end
}

SMODS.Joker {
    key = "mersault",
    rarity = "lcb_o",
    atlas = "lcb_jokers",
    pos = {x=5,y=0},
    config = {extra = {current_skill = 1, times_skill_used = 1, sin={3,6,5}}},
    loc_vars = function(self, info_queue, card)
        info_queue[#info_queue+1] = {
            key = "tremor",
            set = "Other"
        }
        info_queue[#info_queue+1] = {
            key = "tremor_burst",
            set = "Other"
        }
        info_queue[#info_queue+1] = {
            key = "reuse",
            set = "Other"
        }
        return {
            vars = {
                (card.ability.extra.current_skill == 1 and "[Un, Deux]" or card.ability.extra.current_skill == 2 and "[Nailing Fist]") or
                "[Des Coups]",
                G.GAME.lcb_blind_effects.tremor
            },
            main_end = {
                { n = G.UIT.O, config = { object = Sprite(34, 34, 0.75, 0.75, G.ASSET_ATLAS["lcb_sins"], { x = 2, y = 0 }) } },
                { n = G.UIT.O, config = { object = Sprite(34, 34, 0.75, 0.75, G.ASSET_ATLAS["lcb_sins"], { x = 5, y = 0 }) } },
                { n = G.UIT.O, config = { object = Sprite(34, 34, 0.75, 0.75, G.ASSET_ATLAS["lcb_sins"], { x = 4, y = 0 }) } },
            }
        }
    end,
    calculate = function(self, card, context)
        skill_switch(context, card)
        if context.joker_main then
            if card.ability.extra.current_skill == 1 then
                G.GAME.lcb_blind_effects.tremor = G.GAME.lcb_blind_effects.tremor + 2
                if G.GAME.lcb_blind_effects.tremor > 99 then G.GAME.lcb_blind_effects.tremor = 99 end
                card_eval_status_text(card, "extra", nil, nil, nil, { message = "+2 Tremor" })
            elseif card.ability.extra.current_skill == 2 then
                if G.GAME.lcb_blind_effects.tremor ~= 0 then
                    local xmult = 1 + G.GAME.lcb_blind_effects.tremor / 2
                    G.GAME.lcb_blind_effects.tremor = 0
                    return {
                        xmult = xmult,
                        card = card,
                        message = "Tremor Burst!",
                        sound = "lcb_tremor_burst"
                    }
                else
                    return {
                        chips = 50,
                        message = localize { type = 'variable', key = 'a_chips', vars = { 50 } },
                        card = card
                    }
                end
            else
                for i = 1, 3 do
                    if pseudorandom("mersualt") > 0.5 then
                        G.GAME.lcb_blind_effects.tremor = G.GAME.lcb_blind_effects.tremor + 1
                        if G.GAME.lcb_blind_effects.tremor > 99 then G.GAME.lcb_blind_effects.tremor = 99 end
                        card_eval_status_text(card, "extra", nil, nil, nil, { message = "+1 Tremor" })
                    end
                end
                G.GAME.lcb_blind_effects.tremor = G.GAME.lcb_blind_effects.tremor + 2
                if G.GAME.lcb_blind_effects.tremor > 99 then G.GAME.lcb_blind_effects.tremor = 99 end
                card_eval_status_text(card, "extra", nil, nil, nil, { message = "+2 Tremor" })
            end
        end
    end
}

SMODS.Joker {
    key = "ishmael",
    rarity = "lcb_o",
    pos = {x=0,y=1},
    atlas = "lcb_jokers",
    config = {extra = {current_skill = 1, times_skill_used = 0, tremor_burst_doubled = false, sin={1,4,5}}},
    loc_vars = function(self, info_queue, card)
        info_queue[#info_queue + 1] = {
            key = "tremor",
            set = "Other"
        }
        info_queue[#info_queue + 1] = {
            key = "tremor_burst",
            set = "Other"
        }
        info_queue[#info_queue+1] = {
            key = "bleed",
            set = "Other"
        }
        return {
            vars = {
                (card.ability.extra.current_skill == 1 and "[Loggerhead]" or card.ability.extra.current_skill == 2 and "[Slide]") or
                "[Shield Bash]",
                G.GAME.lcb_blind_effects.tremor
            },
            main_end = {
                { n = G.UIT.O, config = { object = Sprite(34, 34, 0.75, 0.75, G.ASSET_ATLAS["lcb_sins"], { x = 0, y = 0 }) } },
                { n = G.UIT.O, config = { object = Sprite(34, 34, 0.75, 0.75, G.ASSET_ATLAS["lcb_sins"], { x = 3, y = 0 }) } },
                { n = G.UIT.O, config = { object = Sprite(34, 34, 0.75, 0.75, G.ASSET_ATLAS["lcb_sins"], { x = 4, y = 0 }) } },
            }
        }
    end,
    calculate = function(self, card, context)
        skill_switch(context, card)
        if context.joker_main then
            if card.ability.extra.current_skill == 1 then
                G.GAME.lcb_blind_effects.tremor = G.GAME.lcb_blind_effects.tremor + 1
                if G.GAME.lcb_blind_effects.tremor > 99 then G.GAME.lcb_blind_effects.tremor = 99 end
                card_eval_status_text(card, "extra", nil, nil, nil, { message = "+1 Tremor" })
            elseif card.ability.extra.current_skill == 2 then
                if hand_chips * mult >= 0.4 * G.GAME.blind.chips then card.ability.extra.tremor_burst_doubled = true end
                G.GAME.lcb_blind_effects.tremor = G.GAME.lcb_blind_effects.tremor + 3
                if G.GAME.lcb_blind_effects.tremor > 99 then G.GAME.lcb_blind_effects.tremor = 99 end
                card_eval_status_text(card, "extra", nil, nil, nil, { message = "+3 Tremor" })
            else
                if G.GAME.lcb_blind_effects.tremor ~= 0 then
                    local xmult = 1 + G.GAME.lcb_blind_effects.tremor / 2
                    if card.ability.extra.tremor_burst_doubled then xmult = xmult * 2 end
                    G.GAME.lcb_blind_effects.tremor = 0
                    modify_blind(0.9)
                    card_eval_status_text(card, "extra", nil, nil, nil, { message = "Blind Reduced by 10%" })
                    return {
                        xmult = xmult,
                        card = card,
                        message = "Tremor Burst!",
                        sound = "lcb_tremor_burst"
                    }
                else
                    modify_blind(0.8)
                    card_eval_status_text(card, "extra", nil, nil, nil, { message = "Blind Reduced by 20%" })
                end
            end
        end
    end
}

SMODS.Joker {
    key = "sinclair",
    rarity = "lcb_o",
    pos = {x=1,y=1},
    atlas = "lcb_jokers",
    config = {extra = {current_skill = 1, times_skill_used = 0, won_last = false, sin={6,1,7}}},
    loc_vars = function(self, info_queue, card)
        info_queue[#info_queue + 1] = {
            key = "rupture",
            set = "Other"
        }
        info_queue[#info_queue+1] = {
            key = "reuse",
            set = "Other"
        }
        return {
            vars = {
                (card.ability.extra.current_skill == 1 and "[Downward Swing]" or card.ability.extra.current_skill == 2 and "[Halberd Combo]") or
                "[Ravaging Cut]",
                G.GAME.lcb_blind_effects.rupture[1],
                G.GAME.lcb_blind_effects.rupture[2]
            },
            main_end = {
                { n = G.UIT.O, config = { object = Sprite(34, 34, 0.75, 0.75, G.ASSET_ATLAS["lcb_sins"], { x = 5, y = 0 }) } },
                { n = G.UIT.O, config = { object = Sprite(34, 34, 0.75, 0.75, G.ASSET_ATLAS["lcb_sins"], { x = 0, y = 0 }) } },
                { n = G.UIT.O, config = { object = Sprite(34, 34, 0.75, 0.75, G.ASSET_ATLAS["lcb_sins"], { x = 6, y = 0 }) } },
            }
        }
    end,
    calculate = function(self, card, context)
        skill_switch(context, card)
        if context.individual and context.cardarea == G.play then
            local active = G.GAME.lcb_blind_effects.rupture[1] > 0 and G.GAME.lcb_blind_effects.rupture[2] > 0
            G.GAME.lcb_blind_effects.rupture[2] = G.GAME.lcb_blind_effects.rupture[2] - 1
            if active then return {
                    chips = G.GAME.lcb_blind_effects.rupture[1] * 10,
                    card = card,
                    message = "Rupture! +"..G.GAME.lcb_blind_effects.rupture[1] * 10,
                    colour = G.C.CHIPS
                }
            end
        end
        if context.joker_main then
            if card.ability.extra.current_skill == 1 then
                G.GAME.lcb_blind_effects.rupture[1] = G.GAME.lcb_blind_effects.rupture[1] + 2
                G.GAME.lcb_blind_effects.rupture[2] = G.GAME.lcb_blind_effects.rupture[2] + 1
                if G.GAME.lcb_blind_effects.rupture[2] ~= 1 then G.GAME.lcb_blind_effects.rupture[2] = 1 end
                if G.GAME.lcb_blind_effects.rupture[1] > 99 then G.GAME.lcb_blind_effects.rupture[1] = 99 end
                card_eval_status_text(card, "extra", nil, nil, nil, { message = "+2 Rupture Potency" })
                card_eval_status_text(card, "extra", nil, nil, nil, { message = "+1 Rupture Count" })
            elseif card.ability.extra.current_skill == 2 then
                if card.ability.extra.won_last then
                    return {
                        mult = 50,
                        card = card
                    }
                else
                    return {
                        mult = 20,
                        card = card
                    }
                end
            else
                for i = 1, 3 do
                    if pseudorandom("sinclair") > 0.5 then
                        G.GAME.lcb_blind_effects.rupture[2] = G.GAME.lcb_blind_effects.rupture[2] + 1
                        if G.GAME.lcb_blind_effects.rupture[2] > 99 then G.GAME.lcb_blind_effects.rupture[2] = 99 end
                        card_eval_status_text(card, "extra", nil, nil, nil, { message = "+1 Rupture Count" })
                    end
                end
                if card.ability.extra.won_last then
                    return {
                        mult = 30,
                        card = card
                    }
                else
                    return {
                        mult = 10,
                        card = card
                    }
                end
            end 
        end
        if context.end_of_round and not context.game_over and context.main_eval then
            if G.GAME.current_round.hands_left <= 2 then card.ability.extra.won_last = true else card.ability.extra.won_last = false end
        end
    end
}

SMODS.Joker {
    key = "heathcliff",
    rarity = "lcb_o",
    pos = {x=2,y=1},
    atlas = "lcb_jokers",
    config = {extra = {current_skill = 1, times_skill_used = 0, sin = {7,1,2}}},
    loc_vars = function(self, info_queue, card)
        info_queue[#info_queue+1] = {
            key = "tremor",
            set = "Other"
        }
        info_queue[#info_queue+1] = {
            key = "tremor_burst",
            set = "Other"
        }
        return {
            vars = {
                (card.ability.extra.current_skill == 1 and "[Bat Bash]" or card.ability.extra.current_skill == 2 and "[Smackdown]") or
                "[Upheaval]",
                G.GAME.lcb_blind_effects.tremor
            },
            main_end = {
                { n = G.UIT.O, config = { object = Sprite(34, 34, 0.75, 0.75, G.ASSET_ATLAS["lcb_sins"], { x = 6, y = 0 }) } },
                { n = G.UIT.O, config = { object = Sprite(34, 34, 0.75, 0.75, G.ASSET_ATLAS["lcb_sins"], { x = 0, y = 0 }) } },
                { n = G.UIT.O, config = { object = Sprite(34, 34, 0.75, 0.75, G.ASSET_ATLAS["lcb_sins"], { x = 1, y = 0 }) } },
            }
        }
    end,
    calculate = function(self, card, context)
        skill_switch(context, card)
        if context.joker_main then
            if card.ability.extra.current_skill == 1 then
                G.GAME.lcb_blind_effects.tremor = G.GAME.lcb_blind_effects.tremor + 3
                if G.GAME.lcb_blind_effects.tremor > 99 then G.GAME.lcb_blind_effects.tremor = 99 end
                card_eval_status_text(card, "extra", nil, nil, nil, { message = "+3 Tremor" })
            elseif card.ability.extra.current_skill == 2 then
                if pseudorandom("heathcliff") > 0.5 then
                    G.GAME.lcb_blind_effects.tremor = G.GAME.lcb_blind_effects.tremor + 2
                    if G.GAME.lcb_blind_effects.tremor > 99 then G.GAME.lcb_blind_effects.tremor = 99 end
                    card_eval_status_text(card, "extra", nil, nil, nil, { message = "+2 Tremor" })
                end
                return {
                    mult = 25,
                    card = card
                }
            else
                if G.GAME.lcb_blind_effects.tremor ~= 0 then
                    local xmult = 1 + G.GAME.lcb_blind_effects.tremor / 2
                    G.GAME.lcb_blind_effects.tremor = 0
                    if pseudorandom("heathcliff") > 0.5 then
                        return {
                            mult = 25,
                            xmult = xmult,
                            card = card,
                            message = "Tremor Burst!",
                            sound = "lcb_tremor_burst"
                        }
                    else
                        return {
                            xmult = xmult,
                            card = card,
                            message = "Tremor Burst!",
                            sound = "lcb_tremor_burst"
                        }
                    end
                end
            end
        end
    end
}

SMODS.Joker {
    key = "ryoshu", -- i am NOT typing ōū every time
    rarity = "lcb_o",
    pos = {x=3,y=1},
    atlas = "lcb_jokers",
    config = {extra = {current_skill = 1, times_skill_used = 0, skill2_effect_active = false, poise = {0,0}, sin={4,2,6}}},
    loc_vars = function(self, info_queue, card)
        info_queue[#info_queue + 1] = {
            key = "poise",
            set = "Other"
        }
        return {
            vars = {
                (card.ability.extra.current_skill == 1 and "[Paint]" or card.ability.extra.current_skill == 2 and "[Splatter]") or
                "[Brushstroke]",
                card.ability.extra.poise[1],
                card.ability.extra.poise[2]
            },
            main_end = {
                { n = G.UIT.O, config = { object = Sprite(34, 34, 0.75, 0.75, G.ASSET_ATLAS["lcb_sins"], { x = 3, y = 0 }) } },
                { n = G.UIT.O, config = { object = Sprite(34, 34, 0.75, 0.75, G.ASSET_ATLAS["lcb_sins"], { x = 1, y = 0 }) } },
                { n = G.UIT.O, config = { object = Sprite(34, 34, 0.75, 0.75, G.ASSET_ATLAS["lcb_sins"], { x = 5, y = 0 }) } },
            }
        }
    end,
    calculate = function(self, card, context)
        skill_switch(context, card)
        if context.joker_main then
            if card.ability.extra.current_skill == 1 then
                if card.ability.extra.poise[2] <= 0 then card.ability.extra.poise[2] = 1 end
                card.ability.extra.poise[1] = card.ability.extra.poise[1] + 2
                card.ability.extra.poise[2] = card.ability.extra.poise[2] + 1
                card_eval_status_text(card, "extra", nil, nil, nil, { message = "+2 Poise Potency" })
                card_eval_status_text(card, "extra", nil, nil, nil, { message = "+1 Poise Count" })
            elseif card.ability.extra.current_skill == 2 then
                if card.ability.extra.skill2_effect_active then
                    if card.ability.extra.poise[2] <= 0 then card.ability.extra.poise[2] = 1 end
                    card.ability.extra.poise[1] = card.ability.extra.poise[1] + 3
                    card_eval_status_text(card, "extra", nil, nil, nil, { message = "+3 Poise Potency" })
                end
            elseif card.ability.extra.poise[1] >= 5 then
                if card.ability.extra.poise[2] <= 0 then card.ability.extra.poise[2] = 1 end
                card.ability.extra.poise[2] = card.ability.extra.poise[2] * 2
                card_eval_status_text(card, "extra", nil, nil, nil, { message = "×2 Poise Count" })
            end
            if card.ability.extra.poise[2] > 0 then
                card.ability.extra.poise[2] = card.ability.extra.poise[2] - 1
                if card.ability.extra.poise[2] <= 0 then card.ability.extra.poise = {0,0} end
                return {
                    xmult = 1 + (card.ability.extra.poise[1] + 1) / 4,
                    card = card,
                    message = "Poise!"
                }
            else card.ability.extra.poise = {0,0} end
        end
        if context.before and card.ability.extra.current_skill == 3 then
            card.ability.extra.poise[2] = card.ability.extra.poise[2] + 2
            if card.ability.extra.poise[1] <= 0 then card.ability.extra.poise[1] = 1 end
            card_eval_status_text(card, "extra", nil, nil, nil, { message = "+2 Poise Count" })
        end
        if context.after then
            if hand_chips * mult <= G.GAME.blind.chips * 0.2 then card.ability.extra.skill2_effect_active = true else card.ability.extra.skill2_effect_active = false end
        end
    end
}

SMODS.Joker {
    key = "outis",
    rarity = "lcb_o",
    pos = {x=4,y=1},
    atlas = "lcb_jokers",
    config = {extra = {current_skill = 1, times_skill_used = 0, last_hand_more_than_half = false, sin = {4,6,5}}},
    loc_vars = function(self, info_queue, card)
        info_queue[#info_queue + 1] = {
            key = "rupture",
            set = "Other"
        }
        return {
            vars = {
                (card.ability.extra.current_skill == 1 and "[Pulled Blade]" or card.ability.extra.current_skill == 2 and "[Backslash]") or
                "[Piercing Thrust]",
                G.GAME.lcb_blind_effects.rupture[1],
                G.GAME.lcb_blind_effects.rupture[2]
            },
            main_end = {
                { n = G.UIT.O, config = { object = Sprite(34, 34, 0.75, 0.75, G.ASSET_ATLAS["lcb_sins"], { x = 3, y = 0 }) } },
                { n = G.UIT.O, config = { object = Sprite(34, 34, 0.75, 0.75, G.ASSET_ATLAS["lcb_sins"], { x = 5, y = 0 }) } },
                { n = G.UIT.O, config = { object = Sprite(34, 34, 0.75, 0.75, G.ASSET_ATLAS["lcb_sins"], { x = 4, y = 0 }) } },
            }
        }
    end,
    calculate = function(self, card, context)
        skill_switch(context, card)
        if context.individual and context.cardarea == G.play then
            local active = G.GAME.lcb_blind_effects.rupture[1] > 0 and G.GAME.lcb_blind_effects.rupture[2] > 0
            G.GAME.lcb_blind_effects.rupture[2] = G.GAME.lcb_blind_effects.rupture[2] - 1
            if active then
                return {
                    chips = G.GAME.lcb_blind_effects.rupture[1] * 10,
                    card = card,
                    message = "Rupture! +" .. G.GAME.lcb_blind_effects.rupture[1] * 10,
                    colour = G.C.CHIPS
                }
            end
        end
        if context.joker_main then
            if card.ability.extra.current_skill == 1 then
                if pseudorandom("outis") > 0.5 then
                    G.GAME.lcb_blind_effects.rupture[1] = G.GAME.lcb_blind_effects.rupture[1] + 1
                    card_eval_status_text(card, "extra", nil, nil, nil, { message = "+1 Rupture Potency" })
                end
                G.GAME.lcb_blind_effects.rupture[2] = G.GAME.lcb_blind_effects.rupture[2] + 2
                if G.GAME.lcb_blind_effects.rupture[2] ~= 1 then G.GAME.lcb_blind_effects.rupture[2] = 1 end
                if G.GAME.lcb_blind_effects.rupture[1] > 99 then G.GAME.lcb_blind_effects.rupture[1] = 99 end
                card_eval_status_text(card, "extra", nil, nil, nil, { message = "+2 Rupture Count" })
            elseif card.ability.extra.current_skill == 2 then
                if card.ability.extra.last_hand_more_than_half then
                    G.GAME.lcb_blind_effects.rupture[2] = G.GAME.lcb_blind_effects.rupture[2] + 2
                    if G.GAME.lcb_blind_effects.rupture[2] ~= 1 then G.GAME.lcb_blind_effects.rupture[2] = 1 end
                    if G.GAME.lcb_blind_effects.rupture[1] > 99 then G.GAME.lcb_blind_effects.rupture[1] = 99 end
                    card_eval_status_text(card, "extra", nil, nil, nil, { message = "+2 Rupture Count" })
                end
                return {
                    mult = 50,
                    card = card
                }
            else
                if hand_chips and mult and G.GAME.chips + (hand_chips * mult) >= math.floor(G.GAME.blind.chips / 2) then
                    G.GAME.lcb_blind_effects.rupture[1] = G.GAME.lcb_blind_effects.rupture[1] + 1
                    card_eval_status_text(card, "extra", nil, nil, nil, { message = "+1 Rupture Potency" })
                end
                G.GAME.lcb_blind_effects.rupture[2] = G.GAME.lcb_blind_effects.rupture[2] + 1
                if G.GAME.lcb_blind_effects.rupture[2] ~= 1 then G.GAME.lcb_blind_effects.rupture[2] = 1 end
                if G.GAME.lcb_blind_effects.rupture[1] > 99 then G.GAME.lcb_blind_effects.rupture[1] = 99 end
                card_eval_status_text(card, "extra", nil, nil, nil, { message = "+1 Rupture Count" })
            end
        end
        if context.after then
            if hand_chips * mult >= 0.5 * G.GAME.blind.chips then card.ability.extra.last_hand_more_than_half = true else card.ability.extra.last_hand_more_than_half = false end
        end
    end
}

SMODS.Joker {
    key = "gregor",
    rarity = "lcb_o",
    pos = {x=5,y=1},
    atlas = "lcb_jokers",
    config = {extra = {current_skill = 1, times_skill_used = 0, sin = {5,4,3}}},
    loc_vars = function(self, info_queue, card)
        info_queue[#info_queue + 1] = {
            key = "rupture",
            set = "Other"
        }
        return {
            vars = {
                (card.ability.extra.current_skill == 1 and "[Swipe]" or card.ability.extra.current_skill == 2 and "[Jag]") or
                "[Chop Up]",
                G.GAME.lcb_blind_effects.rupture[1],
                G.GAME.lcb_blind_effects.rupture[2]
            },
            main_end = {
                { n = G.UIT.O, config = { object = Sprite(34, 34, 0.75, 0.75, G.ASSET_ATLAS["lcb_sins"], { x = 4, y = 0 }) } },
                { n = G.UIT.O, config = { object = Sprite(34, 34, 0.75, 0.75, G.ASSET_ATLAS["lcb_sins"], { x = 3, y = 0 }) } },
                { n = G.UIT.O, config = { object = Sprite(34, 34, 0.75, 0.75, G.ASSET_ATLAS["lcb_sins"], { x = 2, y = 0 }) } },
            }
        }
    end,
    calculate = function(self, card, context)
        skill_switch(context, card)
        if context.individual and context.cardarea == G.play then
            local active = G.GAME.lcb_blind_effects.rupture[1] > 0 and G.GAME.lcb_blind_effects.rupture[2] > 0
            G.GAME.lcb_blind_effects.rupture[2] = G.GAME.lcb_blind_effects.rupture[2] - 1
            if active then
                return {
                    chips = G.GAME.lcb_blind_effects.rupture[1] * 10,
                    card = card,
                    message = "Rupture! +" .. G.GAME.lcb_blind_effects.rupture[1] * 10,
                    colour = G.C.CHIPS
                }
            end
        end
        if context.joker_main then
            if card.ability.extra.current_skill == 1 then
                if pseudorandom("gregor") > 0.5 then
                    G.GAME.lcb_blind_effects.rupture[1] = G.GAME.lcb_blind_effects.rupture[1] + 4
                    if G.GAME.lcb_blind_effects.rupture[2] ~= 1 then G.GAME.lcb_blind_effects.rupture[2] = 1 end
                    if G.GAME.lcb_blind_effects.rupture[1] > 99 then G.GAME.lcb_blind_effects.rupture[1] = 99 end
                    card_eval_status_text(card, "extra", nil, nil, nil, { message = "+4 Rupture" })
                end
            elseif card.ability.extra.current_skill == 2 then
                if pseudorandom("gregor") > 0.5 then
                    G.GAME.lcb_blind_effects.rupture[2] = G.GAME.lcb_blind_effects.rupture[2] + 1
                    if G.GAME.lcb_blind_effects.rupture[2] ~= 1 then G.GAME.lcb_blind_effects.rupture[2] = 1 end
                    if G.GAME.lcb_blind_effects.rupture[1] > 99 then G.GAME.lcb_blind_effects.rupture[1] = 99 end
                    card_eval_status_text(card, "extra", nil, nil, nil, { message = "+1 Rupture Count" })
                else
                    G.GAME.lcb_blind_effects.rupture[2] = G.GAME.lcb_blind_effects.rupture[2] + 2
                    G.GAME.lcb_blind_effects.rupture[1] = G.GAME.lcb_blind_effects.rupture[1] + 2
                    if G.GAME.lcb_blind_effects.rupture[2] ~= 1 then G.GAME.lcb_blind_effects.rupture[2] = 1 end
                    if G.GAME.lcb_blind_effects.rupture[1] > 99 then G.GAME.lcb_blind_effects.rupture[1] = 99 end
                    card_eval_status_text(card, "extra", nil, nil, nil, { message = "+2 Rupture Count" })
                    card_eval_status_text(card, "extra", nil, nil, nil, { message = "+2 Rupture Potency" })
                end
            else
                if pseudorandom("gregor") > 0.75 then
                    G.GAME.lcb_blind_effects.rupture[2] = G.GAME.lcb_blind_effects.rupture[2] - 1
                    if G.GAME.lcb_blind_effects.rupture[2] ~= 1 then G.GAME.lcb_blind_effects.rupture[2] = 1 end
                    if G.GAME.lcb_blind_effects.rupture[1] > 99 then G.GAME.lcb_blind_effects.rupture[1] = 99 end
                    ease_discard(1)
                    card_eval_status_text(card, "extra", nil, nil, nil, { message = "+1 Discard", colour = G.C.RED })
                    card_eval_status_text(card, "extra", nil, nil, nil, { message = "-1 Rupture Count" })
                end
                if G.GAME.lcb_blind_effects.rupture[1] > 0 and G.GAME.lcb_blind_effects.rupture[2] > 0 then
                    return {
                        chips = 60,
                        card = card,
                        colour = G.C.CHIPS,
                        message = "+60 Chips"
                    }
                end
            end
        end
    end
}

SMODS.Joker {
    key = "hong_lu",
    rarity = "lcb_o",
    pos = {x=0,y=2},
    atlas = "lcb_jokers",
    config = { extra = { current_skill = 1, times_skill_used = 0, sin = { 6, 3, 2 } } },
}

SMODS.Joker {
    key = "faust",
    rarity = "lcb_o",
    pos = {x=1,y=2},
    atlas = "lcb_jokers",
    config = { extra = { current_skill = 1, times_skill_used = 0, sin = { 6, 3, 4 } } },
}

SMODS.Joker {
    key = "yi_sang",
    rarity = "lcb_o",
    pos = {x=2,y=2},
    atlas = "lcb_jokers",
    config = { extra = { current_skill = 1, times_skill_used = 0, sin = { 5, 7, 3 } } },
}

SMODS.Joker {
    key = "shi_ishmael",
    rarity = "lcb_oo",
    pos = {x=3,y=2},
    atlas = "lcb_jokers",
    config = { extra = { current_skill = 1, times_skill_used = 0, sin = { 7, 2, 1 }, poise = {0,0}} },
    loc_vars = function(self, info_queue, card)
        info_queue[#info_queue + 1] = {
            key = "poise",
            set = "Other"
        }
        return {
            vars = {
                (card.ability.extra.current_skill == 1 and "[Flying Sword]" or card.ability.extra.current_skill == 2 and "[Flashing Strike]") or
                "[Catch Breath]",
                card.ability.extra.poise[1],
                card.ability.extra.poise[2]
            },
            main_end = {
                { n = G.UIT.O, config = { object = Sprite(34, 34, 0.75, 0.75, G.ASSET_ATLAS["lcb_sins"], { x = 6, y = 0 }) } },
                { n = G.UIT.O, config = { object = Sprite(34, 34, 0.75, 0.75, G.ASSET_ATLAS["lcb_sins"], { x = 1, y = 0 }) } },
                { n = G.UIT.O, config = { object = Sprite(34, 34, 0.75, 0.75, G.ASSET_ATLAS["lcb_sins"], { x = 0, y = 0 }) } },
            }
        }
    end,
    calculate = function(self, card, context)
        skill_switch(context, card)
        if context.joker_main then
            if card.ability.extra.current_skill == 1 then
                if G.GAME.chips <= math.floor(G.GAME.blind.chips * 0.5) then
                    card.ability.extra.poise[1] = card.ability.extra.poise[1] + 5
                    if card.ability.extra.poise[2] == 0 then card.ability.extra.poise[2] = card.ability.extra.poise[2] + 1 end
                    card_eval_status_text(card, "extra", nil, nil, nil, { message = "+5 Poise Potency" })
                else
                    card.ability.extra.poise[1] = card.ability.extra.poise[1] + 2
                    if card.ability.extra.poise[2] == 0 then card.ability.extra.poise[2] = card.ability.extra.poise[2] + 1 end
                    card_eval_status_text(card, "extra", nil, nil, nil, { message = "+2 Poise Potency" })
                end
            elseif card.ability.extra.current_skill == 2 then
                if G.GAME.chips <= math.floor(G.GAME.blind.chips * 0.5) then
                    card.ability.extra.poise[2] = card.ability.extra.poise[2] + 4
                    card_eval_status_text(card, "extra", nil, nil, nil, { message = "+4 Poise Count" })
                else
                    card.ability.extra.poise[2] = card.ability.extra.poise[2] + 2
                    card_eval_status_text(card, "extra", nil, nil, nil, { message = "+2 Poise Count" })
                end
            else
                if psuedorandom("shi_ishmael") > 0.5 then
                    card.ability.extra.poise[2] = card.ability.extra.poise[2] + 2
                    card_eval_status_text(card, "extra", nil, nil, nil, { message = "+2 Poise Count" })
                end
                if card.ability.extra.poise[2] >= 5 then
                    card.ability.extra.poise[1] = card.ability.extra.poise[1] * 2.5
                    card_eval_status_text(card, "extra", nil, nil, nil, { message = "×2.5 Poise Potency" })
                end
                if G.GAME.chips <= math.floor(G.GAME.blind.chips * 0.25) then
                    card.ability.extra.poise[2] = card.ability.extra.poise[2] + 2
                    card_eval_status_text(card, "extra", nil, nil, nil, { message = "+2 Poise Count" })
                end
            end
            if card.ability.extra.poise[2] > 0 then
                card.ability.extra.poise[2] = card.ability.extra.poise[2] - 1
                if card.ability.extra.poise[2] == 0 then card.ability.extra.poise[1] = 0 end
                return {
                    xmult = 1 + card.ability.extra.poise[1] / 4,
                    card = card,
                    message = "Poise!"
                }
            else card.ability.extra.poise[1] = 0 end
        end
    end
}

--[[
SMODS.Joker {
    key = "effect_testing",
    rarity = "lcb_tier_v",
    atlas = "lcb_jokers",
    pos = {x=4,y=4},
    config = {extra = "Poise"},
    loc_vars = function(self, info_queue, card)
        info_queue[#info_queue+1] = {
            key = "blind_start",
            set = "Other"
        }
        return {vars = {card.ability.extra}}
    end,
    calculate = function(self, card, context)
        if context.setting_blind then
            G.GAME.lcb_blind_effects[card.ability.extra:lower()][1] = 5
            G.GAME.lcb_blind_effects[card.ability.extra:lower()][2] = 5
            card_eval_status_text(card, "extra", nil, nil, nil, {message = "yoink"})
        end
    end
}

SMODS.Tag {
    key = "burn_indicator",
    atlas = "lcb_tags",
    pos = {x=0,y=0},
    config = {type = "after"},
    loc_vars = function(self, card, context)
        if G.GAME.lcb_blind_effects then return {
            vars = {
                G.GAME.lcb_blind_effects.burn[1],
                G.GAME.lcb_blind_effects.burn[2]
        }} else
            return { vars = { "N/A", "N/A" } }
        end
    end,
    in_pool = function(_, _) return false end,
    apply = function(self, tag, context)
        if context.type == tag.ability.type then
            modify_blind((100 - G.GAME.lcb_blind_effects.burn[1]) / 100)
            G.GAME.lcb_blind_effects.burn[2] = G.GAME.lcb_blind_effects.burn[2] - 1
            if G.GAME.lcb_blind_effects.burn[2] == 0 then G.GAME.lcb_blind_effects.burn[1] = 0 end
            tag:juice_up()
            return {}
        end
    end
}

SMODS.Tag {
    key = "bleed_indicator",
    atlas = "lcb_tags",
    pos = { x = 1, y = 0 },
    loc_vars = function(self, card, context)
        if G.GAME.lcb_blind_effects then return {
            vars = {
                G.GAME.lcb_blind_effects.bleed[1],
                G.GAME.lcb_blind_effects.bleed[2]
        }} else
            return { vars = { "N/A", "N/A" }}
        end
    end,
    in_pool = function(_, _) return false end,
    apply = function(self, tag, context)
        if context.type == "individual" and context.cardarea == G.play and G.GAME.lcb_blind_effects.bleed[1] ~= 0 and G.GAME.lcb_blind_effects.bleed[2] ~= 0 then
            G.E_MANAGER:add_event(Event({
                trigger = "after",
                delay = 0.1,
                func = function()
                    modify_blind((100 - G.GAME.lcb_blind_effects.bleed[1] / 4) / 100)
                    G.GAME.lcb_blind_effects.bleed[2] = G.GAME.lcb_blind_effects.bleed[2] - 1
                    if G.GAME.lcb_blind_effects.bleed[2] == 0 then G.GAME.lcb_blind_effects.bleed[1] = 0 end
                    tag:juice_up()
                end
            }))
            
        end
    end
}

SMODS.Tag {
    key = "poise_indicator",
    atlas = "lcb_tags",
    pos = { x = 0, y = 1 },
    loc_vars = function(self, card, context)
        if G.GAME.lcb_blind_effects then return {
            vars = {
                G.GAME.lcb_blind_effects.poise[1],
                G.GAME.lcb_blind_effects.poise[2]
        }} else
            return { vars = { "N/A", "N/A" } }
        end
    end,
    in_pool = function(_, _) return false end,
    apply = function(self, tag, context)
        if context.type == "joker_main" then 
            if psuedorandom("lcbpoise") > 1 / G.GAME.lcb_blind_effects.poise[1] then
                return {
                    xmult = G.GAME.lcb_blind_effects.poise[1] / 10 + 1,
                    effect = nil,
                    card = G.hand.cards[1] -- you cant put a tag here
                }
            else
                card_eval_status_text(G.hand.cards[1], "extra", nil, nil, nil, {message = "Nope!"})
            end
        end
    end
}
]]