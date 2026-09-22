from mohingo_audio.speech import segments_for, split_labelled


def test_placeholders_become_pauses_and_keep_question():
    assert segments_for("My name is {name}.") == ["My name is"]
    assert segments_for("I'm {name}.") == ["I'm"]
    assert segments_for("Are you from {country}?") == ["Are you from?"]
    assert segments_for("I live in {place}.") == ["I live in"]


def test_slash_and_ellipsis():
    assert segments_for("my / your") == ["my", "your"]
    assert segments_for("Yes, I am. / No, I'm not.") == ["Yes, I am", "No, I'm not"]
    assert segments_for("What is ...?") == ["What is?"]
    assert segments_for("Where …?") == ["Where?"]


def test_plain_text_untouched():
    assert segments_for("Where do you live?") == ["Where do you live?"]
    assert segments_for("Good morning.") == ["Good morning."]


def test_split_labelled_only_on_known_speakers():
    known = {"Maya", "Omar"}
    assert split_labelled("Maya: Hi. I'm Maya. Omar: I'm Omar.", known) == [
        ("Maya", "Hi. I'm Maya."),
        ("Omar", "I'm Omar."),
    ]
    assert split_labelled("You are right: we used the wrong sauce.", known) is None
    assert split_labelled("Good morning.", known) is None
    assert split_labelled("Intro. Maya: Hi.", known) is None
