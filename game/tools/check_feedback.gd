extends SceneTree
## In-game feedback (feedback.gd, F 2026-11-21): the payload and the checks are pure.
##   - the payload carries the message, the subject, the source, build, device, place and language,
##     and the email only when there is one; a message is cut at MESSAGE_MAX;
##   - a message under MESSAGE_MIN characters and a bad email are refused, an empty email is fine;
##   - the form url is the Formspree "In-game feedback" form over https;
##   - every reason has words in both languages.
## Prints `check_feedback: OK` (exit 0) or the problems (exit 1). No map, no network.
##   godot --headless --path game --script res://tools/check_feedback.gd

const Feedback := preload("res://scripts/feedback.gd")
const Lang := preload("res://scripts/lang.gd")

var problems: Array[String] = []


func _initialize() -> void:
	var p := Feedback.payload("  It crashes at Rondo  ", "", "Śródmieście · car at 1, 2", "English", "v1", "iPhone")
	for k in ["message", "_subject", "source", "build", "device", "where", "language"]:
		if not p.has(k):
			problems.append("payload lacks %s" % k)
	if p.get("message") != "It crashes at Rondo":
		problems.append("the message is not trimmed")
	if p.has("email"):
		problems.append("an empty email is sent")
	if not Feedback.payload("hello", " a@b.pl ", "", "", "", "").has("email"):
		problems.append("a given email is lost")
	if Feedback.payload("x".repeat(Feedback.MESSAGE_MAX + 50), "", "", "", "", "")["message"].length() != Feedback.MESSAGE_MAX:
		problems.append("a long message is not cut")
	if Feedback.accepts("hi", "") != "short":
		problems.append("a two-letter message is accepted")
	if Feedback.accepts("works fine", "") != "":
		problems.append("a good message with no email is refused")
	for bad in ["abc", "a@b", "a b@c.pl", "@c.pl", "a@c."]:
		if Feedback.accepts("works fine", bad) != "email":
			problems.append("email '%s' is accepted" % bad)
	if Feedback.accepts("works fine", "me@example.com") != "":
		problems.append("a good email is refused")
	if not Feedback.FORM_URL.begins_with("https://formspree.io/f/"):
		problems.append("the form url is not a Formspree https url")
	for r in ["short", "email", "wait", "fail", "sending", "ok"]:
		for code in [Lang.PL, Lang.EN]:
			Lang.code = code
			if Feedback.reason_words(r) == "":
				problems.append("no words for %s in %s" % [r, code])
	if problems.is_empty():
		print("check_feedback: OK")
		quit(0)
	else:
		for q in problems:
			print("  " + q)
		print("check_feedback: %d problem(s)" % problems.size())
		quit(1)
