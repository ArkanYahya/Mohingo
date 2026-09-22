from mohingo_audio.cast import Cast


def test_cast_is_deterministic_and_reports_unmapped(tmp_path):
    p = tmp_path / "cast.json"
    p.write_text(
        '{"teacher":"af_bella","partner":"am_michael","speakers":{"Maya":"af_heart"},'
        '"female":["af_heart","af_sarah"],"male":["am_michael","am_fenrir"],'
        '"genders":{"Rania":"f","Faris":"m"}}',
        encoding="utf-8",
    )
    c = Cast.load(p)
    assert c.voice_for("_") == "af_bella"
    assert c.voice_for("partner") == "am_michael"
    assert c.voice_for("Maya") == "af_heart"
    assert c.voice_for("Rania") in {"af_heart", "af_sarah"}
    assert c.voice_for("Faris") in {"am_michael", "am_fenrir"}
    assert c.voice_for("Zork") == c.voice_for("Zork")
    assert c.unmapped == {"Rania", "Faris", "Zork"}
