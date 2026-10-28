class_name MatchDefinition
extends Resource
## Data-only match rules shared by the host-authoritative lifecycle service.

@export_range(10.0, 3600.0) var match_duration: float = 120.0
@export_range(1.0, 30.0) var warmup_duration: float = 3.0
@export_range(1, 1000) var score_limit: int = 10
