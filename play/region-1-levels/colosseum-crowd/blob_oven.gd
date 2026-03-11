class_name BlobOven

## adapted from  https://github.com/MDIVS/GodotTextureOverlapper
## merge textures by overlapping them and returns a new, merged image
static func bake(textures: Array[Texture2D]) -> ImageTexture:
	var images: Array[Image]
	for t in textures:
		var image = t.get_image()
		image.convert(Image.FORMAT_RGBA8)
		images.push_back(image)
	
	var merged_image: Image
	merged_image = Image.create_from_data(images[0].get_width(), images[0].get_height(), false, Image.FORMAT_RGBA8, images[0].get_data())
	
	for layer in images:
		merged_image.blend_rect(layer, Rect2(Vector2(0, 0), layer.get_size()), Vector2(0, 0))

	return ImageTexture.create_from_image(merged_image)
