extends Node

var udp := PacketPeerUDP.new()

func _ready():
	var target_ip = "172.20.95.102"  # Replace with your server's IP
	var target_port = 5005           # Replace with your server's port

	var result = udp.connect_to_host(target_ip, target_port)
	if result != OK:
		print("Failed to connect to UDP server")
		return

	var message = "Hello from Godot!"
	udp.put_packet(message.to_utf8_buffer())

	print("Sent message to", target_ip, ":", message)
