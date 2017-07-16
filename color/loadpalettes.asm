INCLUDE "color/data/mappalettes.asm"
INCLUDE "color/data/map_palette_sets.asm"
INCLUDE "color/data/map_palette_assignments.asm"
INCLUDE "color/data/roofpalettes.asm"

; Load colors for new map and tile placement
LoadTilesetPalette:
	push bc
	push de
	push hl
	ld a,[rSVBK]
	ld d,a
	xor a
	ld [rSVBK],a
	ld a,[wCurMapTileset] ; Located in wram bank 0
	ld b,a
	ld a,$02
	ld [rSVBK],a
	push de ; push previous wram bank

	ld a,1
	ld [W2_TileBasedPalettes],a

	ld a,b ; Get wCurMapTileset
	push af
	ld d,0
	ld e,a
	sla e
	sla e
	sla e
	ld hl, MapPaletteSets
	add hl,de
	ld d,h
	ld e,l
	ld hl,W2_BgPaletteData ; palette data to be copied to wram at hl
	ld b,$08
.nextPalette
	ld c,$08
	ld a,[de] ; # at de is the palette index for MapPalettes
	inc de
	push de
	ld d,0
	ld e,a
	sla e
	rl d
	sla e
	rl d
	sla e
	rl d
	push hl
	ld hl, MapPalettes
	add hl,de
	ld d,h
	ld e,l ; de now points to map's palette data
	pop hl
.nextColor
	ld a,[de]
	inc de
	ld [hli],a
	dec c
	jr nz,.nextColor
	pop de
	dec b
	jr nz,.nextPalette

	; Start copying palette assignments
	pop af	; Retrieve wCurMapTileset
	ld hl,$0000
	cp $00
	jr z,.doneMultiplication
	ld c,a
	ld de,$0060	; Each palette assignment takes $60 bytes
.addLoop
	add hl,de
	dec c
	jr nz,.addLoop
.doneMultiplication:
	ld bc, MapPaletteAssignments
	add hl,bc
	push hl
	pop de ; de points to MapPaletteAssignments
	ld hl, W2_TilesetPaletteMap
	ld b,$60
.copyLoop
	ld a,[de]
	inc de
	ld [hli],a
	dec b
	jr nz,.copyLoop

	; Set the remaining values to 7 for text
	ld b,$a0
	ld a,7
.fillLoop
	ld [hli],a
	dec b
	jr nz,.fillLoop

	; Exception:
	; Tile $78, which is either a pokeball (in the PC), or an unused japanese character.
	ld a, 3
	ld [W2_TilesetPaletteMap + $78], a

	; Retrieve former wram bank
	pop af
	ld b,a

	xor a
	ld [rSVBK],a
	ld a,[wCurMapTileset]
	ld c,a

	ld a,b
	ld [rSVBK],a ; Restore previous wram bank

	ld a,c
	and a ; Check whether tileset 0 is loaded
	call z, LoadTownPalette
	cp PLATEAU ; tileset 0 isn't the only outside tileset
	call z, LoadTownPalette

	pop hl
	pop de
	pop bc
	ret

; Towns have different roof colors while using the same tileset
LoadTownPalette:
	ld a,[rSVBK]
	ld b,a
	xor a
	ld [rSVBK],a

	ld a, [wCurMap]
	add a
	ld c,a

	ld a,$02
	ld [rSVBK],a
	push bc ; push previous wram bank

	push de
	push hl
	ld hl, RoofPalettes
	ld b, 0
	add hl, bc
	ld e, [hl]
	inc hl
	ld d, [hl]
	ld hl, W2_BgPaletteData + $32
	ld b,$04
.copyLoop
	ld a,[de]
	inc de
	ld [hli],a
	dec b
	jr nz,.copyLoop
	pop hl
	pop de

	ld a, [wCurMap]
	ld [W2_TownMapLoaded],a

	pop af
	ld [rSVBK],a ; Restore wram bank
	ret
