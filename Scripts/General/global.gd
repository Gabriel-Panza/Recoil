extends Node

signal pecado_changed(new_pecado)

var pecado = 1:
	set(value):
		if value != pecado:
			pecado = value
			pecado_changed.emit(pecado)
