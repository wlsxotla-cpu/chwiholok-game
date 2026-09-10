extends RefCounted

const WEAPON_ICONS := {
	"slash": "res://assets/ui/weapon_icons/slash.png",
	"aura": "res://assets/ui/weapon_icons/aura.png",
	"pierce": "res://assets/ui/weapon_icons/pierce.png",
	"shuriken": "res://assets/ui/weapon_icons/shuriken.png",
	"fireball": "res://assets/ui/weapon_icons/fireball.png",
	"orbit": "res://assets/ui/weapon_icons/orbit.png",
	"boomerang": "res://assets/ui/weapon_icons/boomerang.png",
	"beam": "res://assets/ui/weapon_icons/beam.png",
	"lightning": "res://assets/ui/weapon_icons/lightning.png",
	"heaven_blade": "res://assets/ui/weapon_icons/heaven_blade.png",
	"piercing_calamity": "res://assets/ui/weapon_icons/piercing_calamity.png",
	"whirl_storm": "res://assets/ui/weapon_icons/whirl_storm.png",
	"thunder_formation": "res://assets/ui/weapon_icons/thunder_formation.png",
	"halberd": "res://assets/ui/weapon_icons/halberd.png",
	"swordshield": "res://assets/ui/weapon_icons/swordshield.png",
	"rapier": "res://assets/ui/weapon_icons/rapier.png",
	"spear": "res://assets/ui/weapon_icons/spear.png",
	"curse": "res://assets/ui/weapon_icons/curse.png",
	"cataclysm_guard": "res://assets/ui/weapon_icons/cataclysm_guard.png",
	"sky_piercer": "res://assets/ui/weapon_icons/sky_piercer.png",
	"hellcurse_flame": "res://assets/ui/weapon_icons/hellcurse_flame.png",
}

const PASSIVE_ICONS := {
	"power_scroll": "res://assets/ui/passive_icons/power_scroll.png",
	"body_scroll": "res://assets/ui/passive_icons/body_scroll.png",
	"agility_scroll": "res://assets/ui/passive_icons/agility_scroll.png",
	"haste_scroll": "res://assets/ui/passive_icons/haste_scroll.png",
	"gather_scroll": "res://assets/ui/passive_icons/gather_scroll.png",
	"vanguard_scroll": "res://assets/ui/passive_icons/vanguard_scroll.png",
	"finesse_scroll": "res://assets/ui/passive_icons/finesse_scroll.png",
	"curse_scroll": "res://assets/ui/passive_icons/curse_scroll.png",
}

const WEAPON_NAMES := {
	"slash": "회전베기",
	"aura": "호신강기",
	"pierce": "관통시",
	"fireball": "화염구 장판",
	"shuriken": "표창난사",
	"orbit": "어검비행",
	"boomerang": "회류표",
	"beam": "일자검기",
	"lightning": "뇌전장",
	"heaven_blade": "천지개벽검",
	"piercing_calamity": "멸겁관천검",
	"whirl_storm": "선풍만리표",
	"thunder_formation": "뇌검진",
	"halberd": "패왕할버드",
	"swordshield": "호심검방",
	"rapier": "연환자검",
	"spear": "만금창",
	"curse": "귀곡저주",
	"cataclysm_guard": "패왕진천격",
	"sky_piercer": "관천쾌섬창",
	"hellcurse_flame": "귀화망령진",
}

const PASSIVE_NAMES := {
	"power_scroll": "파산도결",
	"body_scroll": "철갑신공",
	"agility_scroll": "비연신법",
	"haste_scroll": "연격지결",
	"gather_scroll": "채기흡자결",
	"vanguard_scroll": "패왕비급",
	"finesse_scroll": "쾌검비급",
	"curse_scroll": "귀곡비급",
}

const FUSION_PAIRS := {
	"heaven_blade": ["slash", "aura"],
	"piercing_calamity": ["pierce", "beam"],
	"whirl_storm": ["shuriken", "boomerang"],
	"thunder_formation": ["orbit", "lightning"],
	"cataclysm_guard": ["swordshield", "halberd"],
	"sky_piercer": ["rapier", "spear"],
	"hellcurse_flame": ["curse", "fireball"],
}

const EVOLUTION_PASSIVE := {
	"slash": "power_scroll",
	"aura": "body_scroll",
	"pierce": "power_scroll",
	"fireball": "gather_scroll",
	"shuriken": "agility_scroll",
	"orbit": "power_scroll",
	"boomerang": "agility_scroll",
	"beam": "haste_scroll",
	"lightning": "body_scroll",
	"halberd": "vanguard_scroll",
	"swordshield": "vanguard_scroll",
	"rapier": "finesse_scroll",
	"spear": "finesse_scroll",
	"curse": "curse_scroll",
}

const EVOLVED_NAMES := {
	"slash": "폭풍베기",
	"aura": "파극호신강기",
	"pierce": "만천화우시",
	"fireball": "겁화지옥진",
	"shuriken": "만화표창진",
	"orbit": "천검진",
	"boomerang": "만리회선표",
	"beam": "무형검기",
	"lightning": "천둔뇌영",
	"halberd": "파천할버드",
	"swordshield": "금강불괴검방",
	"rapier": "만검자류",
	"spear": "관천금창",
	"curse": "만귀곡성",
}

const BASE_WEAPON_GUIDE := [
	["slash", "회전베기", "자기 주변 원형 범위를 주기적으로 베어냄. 기본 광역 근접기."],
	["aura", "호신강기", "아주 짧은 주기로 주변을 밀쳐내며 데미지. 밀집한 적 처리에 강함."],
	["pierce", "관통시", "가장 가까운 적에게 관통탄 발사. 레벨업할수록 관통 수 증가."],
	["fireball", "화염구 장판", "적 위치에 불바다 장판을 소환해 지속 데미지."],
	["shuriken", "표창난사", "가까운 적 방향으로 표창 여러 개를 부채꼴로 발사."],
	["orbit", "어검비행", "검이 캐릭터 주위를 계속 회전하며 스치는 적에게 데미지."],
	["boomerang", "회류표", "던지면 날아갔다 돌아오는 표창. 왕복 경로의 적을 다시 타격."],
	["beam", "일자검기", "정면으로 긴 직선 검기 발사, 일직선상의 모든 적 관통."],
	["lightning", "뇌전장", "주변 적 중 무작위로 여러 명에게 번개 낙뢰."],
	["halberd", "패왕할버드", "묵직한 폴암을 크게 휘둘러 넓은 범위에 강한 넉백. 진악 전용 시작 무기."],
	["swordshield", "호심검방", "주변을 방패로 강하게 밀쳐내며 가격, 넉백이 매우 강함. 레벨이 오를수록 받는 피해도 줄여줌. 소운 전용 시작 무기."],
	["rapier", "연환자검", "가장 가까운 적 한 명에게 빠르게 연속 찌르기. 민서 전용 시작 무기."],
	["spear", "만금창", "정면으로 창을 길게 내질러 일직선상의 적을 관통. 만냥 전용 시작 무기."],
	["curse", "귀곡저주", "무작위 적 여러 명에게 저주를 걸어 데미지. 사마획 전용 시작 무기(무기 없이 술법으로 싸움)."],
]

const FUSION_GUIDE := [
	["heaven_blade", "천지개벽검", "회전베기 + 호신강기", "더 크고 강한 범위 베기 + 강력한 넉백. 보유 중엔 적의 화살을 검으로 막아냄"],
	["piercing_calamity", "멸겁관천검", "관통시 + 일자검기", "사거리 훨씬 긴 초강력 관통 검기"],
	["whirl_storm", "선풍만리표", "표창난사 + 회류표", "훨씬 많은 표창을 동시에 투척"],
	["thunder_formation", "뇌검진", "어검비행 + 뇌전장", "회전검 + 번개 낙뢰를 동시 운용하는 복합 무기"],
	["cataclysm_guard", "패왕진천격", "호심검방 + 패왕할버드", "훨씬 넓은 범위에 압도적인 넉백을 가하는 최강의 방어형 타격기"],
	["sky_piercer", "관천쾌섬창", "연환자검 + 만금창", "사거리와 폭이 크게 늘어난 초강력 관통 찌르기"],
	["hellcurse_flame", "귀화망령진", "귀곡저주 + 화염구 장판", "더 많은 적에게 저주의 화염을 전이시키는 복합 마법"],
]

const EVOLUTION_GUIDE := [
	["파산도결", "공격력 +12%", "회전베기→폭풍베기 / 관통시→만천화우시 / 어검비행→천검진"],
	["철갑신공", "최대체력 +25", "호신강기→파극호신강기 / 뇌전장→천둔뇌영"],
	["비연신법", "이동속도 +10%", "표창난사→만화표창진 / 회류표→만리회선표"],
	["연격지결", "공격속도 +10%", "일자검기→무형검기"],
	["채기흡자결", "수집 반경 +15%", "화염구 장판→겁화지옥진"],
	["패왕비급", "공격력 +12%", "패왕할버드→파천할버드 / 호심검방→금강불괴검방"],
	["쾌검비급", "이동속도 +10%", "연환자검→만검자류 / 만금창→관천금창"],
	["귀곡비급", "수집 반경 +15%", "귀곡저주→만귀곡성"],
]
