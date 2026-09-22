"""Which voice reads which role. Global, so a character sounds the same in every level."""
import hashlib
import json

from .speakables import PARTNER, TEACHER


class Cast:
    def __init__(self, data: dict):
        self.teacher: str = data["teacher"]
        self.partner: str = data["partner"]
        self.speakers: dict[str, str] = data.get("speakers", {})
        self.female: list[str] = data["female"]
        self.male: list[str] = data["male"]
        self.genders: dict[str, str] = data.get("genders", {})
        # Roles that had no explicit voice, so the run can list them.
        self.unmapped: set[str] = set()

    @classmethod
    def load(cls, path) -> "Cast":
        return cls(json.load(open(path, encoding="utf-8")))

    def voice_for(self, role: str) -> str:
        if role == TEACHER:
            return self.teacher
        if role == PARTNER:
            return self.partner
        if role in self.speakers:
            return self.speakers[role]
        self.unmapped.add(role)
        h = int(hashlib.sha1(role.encode("utf-8")).hexdigest(), 16)
        gender = self.genders.get(role) or ("f" if h % 2 == 0 else "m")
        pool = self.female if gender == "f" else self.male
        return pool[h % len(pool)]
