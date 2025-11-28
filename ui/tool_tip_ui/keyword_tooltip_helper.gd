extends RefCounted
class_name KeywordTooltipHelper

const KEYWORD_STATUSES := {
	"attuned": preload("res://resources/data/statuses/attuned.tres"),
	"attunement": preload("res://resources/data/statuses/attunement.tres"),
	"burn": preload("res://resources/data/statuses/burned.tres"),
	"burned": preload("res://resources/data/statuses/burned.tres"),
	"weakened": preload("res://resources/data/statuses/weakened.tres"),
}

const KEYWORD_DESCRIPTIONS := {
	"exhaust": "Removed from combat after use."
}

static var _bold_regex: RegEx


static func build_keyword_tooltips(text: String) -> Array[Dictionary]:
	var keywords := _extract_bold_keywords(text)
	var tooltips: Array[Dictionary] = []
	var seen: Dictionary = {}

	for keyword in keywords:
		var normalized := keyword.strip_edges().to_lower()
		if normalized.is_empty() or seen.has(normalized):
			continue

		var tooltip_text := _get_tooltip_for_keyword(normalized)
		if tooltip_text.is_empty():
			continue

		var display_keyword := keyword.strip_edges()
		if display_keyword.is_empty():
			display_keyword = normalized.capitalize()

		tooltips.append({
			"keyword": display_keyword,
			"text": tooltip_text
		})
		seen[normalized] = true

	return tooltips


static func _extract_bold_keywords(text: String) -> Array[String]:
	var keywords: Array[String] = []
	var regex := _get_bold_regex()
	var matches := regex.search_all(text)

	for match in matches:
		keywords.append(match.get_string(1))

	return keywords


static func _get_tooltip_for_keyword(keyword: String) -> String:
	if KEYWORD_STATUSES.has(keyword):
		var status: Status = KEYWORD_STATUSES[keyword].duplicate()
		return status.get_tooltip()

	if KEYWORD_DESCRIPTIONS.has(keyword):
		return KEYWORD_DESCRIPTIONS[keyword]

	return ""


static func _get_bold_regex() -> RegEx:
	if _bold_regex == null:
		_bold_regex = RegEx.new()
		_bold_regex.compile("\\[b\\]([^\\[]+)\\[/b\\]")

	return _bold_regex
