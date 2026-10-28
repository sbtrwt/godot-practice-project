class_name HurtboxComponent
extends Node
## Receives validated combat hits and signals them to the owning entity.

signal hit_received(amount: int, attacker_id: int)


func receive_hit(amount: int, attacker_id: int) -> void:
	if amount <= 0:
		return
	hit_received.emit(amount, attacker_id)
