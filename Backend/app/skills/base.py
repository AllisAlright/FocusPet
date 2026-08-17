from __future__ import annotations

from dataclasses import dataclass
from typing import Protocol


@dataclass(frozen=True)
class SkillMetadata:
    name: str
    description: str


class FocusPetSkill(Protocol):
    metadata: SkillMetadata

    @property
    def name(self) -> str:
        ...

    @property
    def description(self) -> str:
        ...
