extends SceneTree

func _init():
	var images = [
		"res://assets/seed/seed1.png",
		"res://assets/seed/seed2.png",
		"res://assets/seed/seed3.png"
	]
	
	for path in images:
		var img = Image.load_from_file(ProjectSettings.globalize_path(path))
		if img != null:
			if img.get_format() != Image.FORMAT_RGBA8:
				img.convert(Image.FORMAT_RGBA8)
				
			var w = img.get_width()
			var h = img.get_height()
			
			# 단순한 하얀색 배경 제거 (Flood Fill 기반 혹은 좌상단 픽셀 색상 기준)
			# 좌상단 픽셀을 배경색으로 간주
			var bg_color = img.get_pixel(0, 0)
			
			# 허용 오차
			var tolerance = 0.1
			
			for y in range(h):
				for x in range(w):
					var c = img.get_pixel(x, y)
					if abs(c.r - bg_color.r) < tolerance and abs(c.g - bg_color.g) < tolerance and abs(c.b - bg_color.b) < tolerance and c.a > 0.0:
						c.a = 0.0
						img.set_pixel(x, y, c)
						
			img.save_png(ProjectSettings.globalize_path(path))
			print("Processed: ", path)
		else:
			print("Failed to load: ", path)
			
	quit()
