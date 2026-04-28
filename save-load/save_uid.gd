class_name SaveUid

## Centralizes the "carry a UID across Resource.duplicate()" idiom used by save/load.
## Godot's Resource.duplicate() does NOT preserve resource_path (uniqueness conflict).
## We carry the source UID via Resource meta instead, on a known key.

const META_KEY: StringName = &"save_uid"


## Returns the source-template UID as text, or "" if not derivable.
## Reads resource_path first (set on freshly-loaded templates), then falls back
## to META_KEY meta (set on duplicates by tag_duplicate).
static func resolve(res: Resource) -> String:
	if res.resource_path != "":
		var uid := ResourceLoader.get_resource_uid(res.resource_path)
		if uid != ResourceUID.INVALID_ID:
			return ResourceUID.id_to_text(uid)
	return res.get_meta(META_KEY, "")


## Stamps `copy` with `original`'s UID so `copy` can still serialize after duplicate().
## Pass freshly-duplicated resources here; no-op if `original` has no resolvable UID.
static func tag_duplicate(original: Resource, copy: Resource) -> void:
	var uid_text := resolve(original)
	if uid_text != "":
		copy.set_meta(META_KEY, uid_text)
