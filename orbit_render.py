#!/usr/bin/env python3
"""Render a camera orbit around a Wavefront OBJ file.

Usage:
    blender --background --python orbit_render.py -- model.obj [output_dir]

Arguments:
    model.obj   Path to the OBJ file
    output_dir  Output directory for frames (default: ./orbit_frames)

Renders 96 frames at 12fps, 1920x1080.
Stitch with: ffmpeg -framerate 12 -i orbit_frames/%04d.png -c:v libx264 -pix_fmt yuv420p orbit.mp4
"""

import bpy
import math
import sys
import os
from mathutils import Vector

# Parse arguments after "--"
argv = sys.argv
args = argv[argv.index("--") + 1:] if "--" in argv else []

if not args:
    print(__doc__)
    sys.exit(1)

obj_path = os.path.abspath(args[0])
output_dir = os.path.abspath(args[1]) if len(args) > 1 else os.path.join(os.getcwd(), "orbit_frames")

TOTAL_FRAMES = 96
FPS = 12
RES_X = 1920
RES_Y = 1080

# Clear default scene
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete()

# Import OBJ and rotate upright (Y-up → Z-up)
bpy.ops.wm.obj_import(filepath=obj_path, forward_axis='NEGATIVE_Z', up_axis='Y')
bpy.context.view_layer.update()

# Calculate bounding center and radius
coords = [
    obj.matrix_world @ Vector(c)
    for obj in bpy.context.scene.objects if obj.type == 'MESH'
    for c in obj.bound_box
]
center = sum(coords, Vector()) / len(coords)
radius = max((c - center).length for c in coords) * 2.5

# Add camera
bpy.ops.object.camera_add()
cam = bpy.context.object
bpy.context.scene.camera = cam

# Track-to constraint so camera always faces the model
empty = bpy.data.objects.new('Target', None)
bpy.context.collection.objects.link(empty)
empty.location = center
track = cam.constraints.new('TRACK_TO')
track.target = empty
track.track_axis = 'TRACK_NEGATIVE_Z'
track.up_axis = 'UP_Y'

# Keyframe circular orbit
bpy.context.scene.frame_start = 1
bpy.context.scene.frame_end = TOTAL_FRAMES
bpy.context.scene.render.fps = FPS

for i in range(TOTAL_FRAMES):
    angle = 2 * math.pi * i / TOTAL_FRAMES
    cam.location = center + Vector((
        math.cos(angle) * radius,
        math.sin(angle) * radius,
        radius * 0.5,
    ))
    cam.keyframe_insert('location', frame=i + 1)

# Lighting
bpy.ops.object.light_add(type='SUN', location=(0, 0, radius * 2))

# Render settings
scene = bpy.context.scene
scene.render.resolution_x = RES_X
scene.render.resolution_y = RES_Y
scene.render.image_settings.file_format = 'PNG'

os.makedirs(output_dir, exist_ok=True)
scene.render.filepath = os.path.join(output_dir, "")

# Render all frames
bpy.ops.render.render(animation=True)
print(f"\nDone! {TOTAL_FRAMES} frames saved to {output_dir}/")
