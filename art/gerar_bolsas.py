# Gera as imagens do item "Bolsa de Uniforme" (D170–D179) no Blender, sem interface:
#
#   blender -b -P art/gerar_bolsas.py -- <pasta_de_saida> [tamanho]
#
# Um único modelo 3D de bolsa (corpo acolchoado, zíper, alças, tampas laterais e etiqueta);
# muda só a cor e o símbolo da etiqueta. Saída: PNG com fundo transparente (padrão 256 x 256).

import bpy
import bmesh
import math
import os
import sys
from mathutils import Vector

argv = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else []
OUT = os.path.abspath(argv[0] if argv else os.path.join(os.path.dirname(__file__), 'render'))
SIZE = int(argv[1]) if len(argv) > 1 else 256
os.makedirs(OUT, exist_ok=True)

# nome do arquivo, cor do tecido, cor da etiqueta, símbolo
VARIANTS = [
    ('uniform_bag',          (0.392, 0.000, 0.902), (0.95, 0.95, 0.97), 'cabide'),
    ('uniform_bag_policia',  (0.030, 0.070, 0.220), (0.85, 0.70, 0.20), 'escudo'),
    ('uniform_bag_hospital', (0.700, 0.040, 0.050), (0.97, 0.97, 0.97), 'cruz'),
    ('uniform_bag_mecanica', (0.950, 0.420, 0.020), (0.10, 0.10, 0.11), 'chave'),
]


def srgb_to_linear(c):
    return tuple(((x + 0.055) / 1.055) ** 2.4 if x > 0.04045 else x / 12.92 for x in c)


def clear_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def material(name, color, roughness=0.75, sheen=0.4, bump=0.0, metallic=0.0):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nodes, links = mat.node_tree.nodes, mat.node_tree.links
    bsdf = nodes.get('Principled BSDF')
    bsdf.inputs['Base Color'].default_value = (*color, 1.0)
    bsdf.inputs['Roughness'].default_value = roughness
    bsdf.inputs['Metallic'].default_value = metallic
    if 'Sheen Weight' in bsdf.inputs:
        bsdf.inputs['Sheen Weight'].default_value = sheen
    if bump > 0:
        # Trama do tecido: ruído fino + ondas cruzadas.
        coord = nodes.new('ShaderNodeTexCoord')
        noise = nodes.new('ShaderNodeTexNoise')
        noise.inputs['Scale'].default_value = 180.0
        noise.inputs['Detail'].default_value = 4.0
        wave = nodes.new('ShaderNodeTexWave')
        wave.inputs['Scale'].default_value = 90.0
        mix = nodes.new('ShaderNodeMath')
        mix.operation = 'ADD'
        bmp = nodes.new('ShaderNodeBump')
        bmp.inputs['Strength'].default_value = bump
        links.new(coord.outputs['Object'], noise.inputs['Vector'])
        links.new(coord.outputs['Object'], wave.inputs['Vector'])
        links.new(noise.outputs['Fac'], mix.inputs[0])
        links.new(wave.outputs['Fac'], mix.inputs[1])
        links.new(mix.outputs[0], bmp.inputs['Height'])
        links.new(bmp.outputs['Normal'], bsdf.inputs['Normal'])
    return mat


def add_mod(obj, kind, **props):
    mod = obj.modifiers.new(kind.lower(), kind)
    for k, v in props.items():
        setattr(mod, k, v)
    return mod


def shade_smooth(obj):
    for p in obj.data.polygons:
        p.use_smooth = True


def body(mat):
    bpy.ops.mesh.primitive_cube_add(size=1)
    o = bpy.context.object
    o.name = 'Corpo'
    o.scale = (1.55, 0.78, 0.70)
    bpy.ops.object.transform_apply(scale=True)
    add_mod(o, 'BEVEL', width=0.20, segments=8, limit_method='NONE')
    add_mod(o, 'SUBSURF', levels=2, render_levels=3)
    # Leve "afundado" no topo, como bolsa de tecido cheia.
    simple = add_mod(o, 'SIMPLE_DEFORM', deform_method='BEND', angle=math.radians(-6), deform_axis='Y')
    shade_smooth(o)
    o.data.materials.append(mat)
    return o


def end_caps(body_obj, mat, xs=(-0.60, 0.60), radius=0.022):
    # Debrum costurado nas pontas: corta o corpo já modelado nessas posições e transforma o
    # contorno do corte num cordão (curva com espessura). Segue o formato exato da bolsa.
    dg = bpy.context.evaluated_depsgraph_get()
    source = bpy.data.meshes.new_from_object(body_obj.evaluated_get(dg))
    for x in xs:
        bm = bmesh.new()
        bm.from_mesh(source)
        res = bmesh.ops.bisect_plane(bm, geom=bm.verts[:] + bm.edges[:] + bm.faces[:], plane_co=(x, 0, 0), plane_no=(1, 0, 0))
        cut = [e for e in res['geom_cut'] if isinstance(e, bmesh.types.BMEdge)]
        out = bmesh.new()
        remap = {}
        for e in cut:
            for v in e.verts:
                if v not in remap:
                    remap[v] = out.verts.new(v.co)
            out.edges.new((remap[e.verts[0]], remap[e.verts[1]]))
        bm.free()
        mesh = bpy.data.meshes.new('Debrum')
        out.to_mesh(mesh)
        out.free()
        o = bpy.data.objects.new('Debrum', mesh)
        bpy.context.collection.objects.link(o)
        o.matrix_world = body_obj.matrix_world.copy()
        bpy.ops.object.select_all(action='DESELECT')
        o.select_set(True)
        bpy.context.view_layer.objects.active = o
        bpy.ops.object.convert(target='CURVE')
        o.data.bevel_depth = radius
        o.data.bevel_resolution = 4
        o.data.materials.append(mat)
    bpy.data.meshes.remove(source)


def zipper(dark, metal):
    # Faixa do zíper ao longo do topo + puxador.
    bpy.ops.mesh.primitive_cube_add(size=1)
    z = bpy.context.object
    z.scale = (1.20, 0.055, 0.02)
    z.location = (0, 0, 0.352)
    add_mod(z, 'BEVEL', width=0.008, segments=2)
    z.data.materials.append(dark)
    bpy.ops.mesh.primitive_cube_add(size=1)
    p = bpy.context.object
    p.scale = (0.05, 0.03, 0.012)
    p.location = (0.45, 0.0, 0.372)
    add_mod(p, 'BEVEL', width=0.006, segments=2)
    p.data.materials.append(metal)
    bpy.ops.mesh.primitive_cube_add(size=1)
    t = bpy.context.object
    t.scale = (0.03, 0.10, 0.008)
    t.location = (0.45, 0.075, 0.37)
    t.rotation_euler = (math.radians(-20), 0, 0)
    add_mod(t, 'BEVEL', width=0.004, segments=2)
    t.data.materials.append(metal)


def handle(x, mat):
    # Alça em arco atravessando a bolsa (meio toro em pé).
    bpy.ops.mesh.primitive_torus_add(major_radius=0.26, minor_radius=0.042, major_segments=64, minor_segments=16)
    o = bpy.context.object
    o.rotation_euler = (0, math.radians(90), 0)
    o.scale = (1.0, 1.0, 1.0)
    o.location = (x, 0, 0.30)
    o.scale = (1, 1.0, 0.8)
    # Achatar a seção da alça (fita).
    bpy.ops.object.transform_apply(rotation=True, scale=True)
    for v in o.data.vertices:
        if v.co.z < -0.02:
            v.co.z = -0.02
    shade_smooth(o)
    o.data.materials.append(mat)
    # Presilhas onde a alça encontra o corpo.
    for sy in (-1, 1):
        bpy.ops.mesh.primitive_cube_add(size=1)
        c = bpy.context.object
        c.scale = (0.11, 0.02, 0.12)
        c.location = (x, sy * 0.305, 0.215)
        c.rotation_euler = (sy * math.radians(-28), 0, 0)
        add_mod(c, 'BEVEL', width=0.01, segments=2)
        c.data.materials.append(mat)


def polygon_object(name, pts, depth, mat, location, rotation):
    me = bpy.data.meshes.new(name)
    bm = bmesh.new()
    verts = [bm.verts.new((x, y, 0)) for x, y in pts]
    face = bm.faces.new(verts)
    ext = bmesh.ops.extrude_face_region(bm, geom=[face])
    for v in [e for e in ext['geom'] if isinstance(e, bmesh.types.BMVert)]:
        v.co.z += depth
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(me)
    bm.free()
    o = bpy.data.objects.new(name, me)
    bpy.context.collection.objects.link(o)
    o.location = location
    o.rotation_euler = rotation
    add_mod(o, 'BEVEL', width=0.004, segments=2, limit_method='ANGLE')
    o.data.materials.append(mat)
    return o


def wrench_points(rotate_deg=40):
    # Chave de boca: cabo reto e uma cabeça aberta em cada ponta (contorno sem cruzamentos).
    R, w, h, cx = 0.36, 0.13, 0.12, 0.74
    t1 = math.pi - math.asin(h / R)
    t2 = math.asin(w / R)

    def arc(c, a0, a1, n=10):
        return [(c + R * math.cos(a0 + (a1 - a0) * i / n), R * math.sin(a0 + (a1 - a0) * i / n)) for i in range(n + 1)]

    right = arc(cx, t1, t2) + [(cx + 0.02, w), (cx + 0.02, -w)] + arc(cx, -t2, -t1)
    left = [(-x, -y) for x, y in right]  # cabeça da esquerda = mesma, girada 180°
    pts = right + left
    r = math.radians(rotate_deg)
    k = 0.92 / (cx + R)
    return [((x * math.cos(r) - y * math.sin(r)) * k, (x * math.sin(r) + y * math.cos(r)) * k) for x, y in pts]


def symbol(kind, mat, base_loc, rot):
    s = 0.105
    if kind == 'escudo':
        pts = [(-1, 0.9), (0, 1.1), (1, 0.9), (0.95, -0.1), (0.55, -0.7), (0, -1.05), (-0.55, -0.7), (-0.95, -0.1)]
    elif kind == 'cruz':
        a, b = 0.32, 1.0
        pts = [(-a, b), (a, b), (a, a), (b, a), (b, -a), (a, -a), (a, -b), (-a, -b), (-a, -a), (-b, -a), (-b, a), (-a, a)]
    elif kind == 'chave':
        pts = wrench_points()
    else:  # cabide
        pts = [(-1.05, -0.55), (1.05, -0.55), (1.05, -0.4), (0.12, 0.3), (0.12, 0.55), (0.3, 0.72),
               (0.3, 0.95), (0.0, 1.12), (-0.3, 0.95), (-0.18, 0.88), (0.0, 0.98), (0.14, 0.88),
               (0.14, 0.78), (-0.04, 0.62), (-0.04, 0.3), (-0.82, -0.4), (0.82, -0.4), (0.82, -0.43), (-1.05, -0.43)]
        # Contorno simples (o polígono acima tem uma "janela"); usa só a silhueta externa.
        pts = [(-1.05, -0.55), (1.05, -0.55), (1.05, -0.38), (0.12, 0.32), (0.12, 0.56), (0.32, 0.74),
               (0.30, 0.97), (0.0, 1.13), (-0.30, 0.97), (-0.16, 0.87), (0.0, 0.97), (0.14, 0.86),
               (0.14, 0.78), (-0.06, 0.62), (-0.06, 0.32), (-1.05, -0.38)]
    pts = [(x * s, y * s) for x, y in pts]
    return polygon_object('Simbolo', pts, 0.012, mat, base_loc, rot)


def patch(fabric_color, label_color, kind):
    # Etiqueta frontal costurada + símbolo em relevo.
    border = material('Borda', tuple(min(1, c * 0.35) for c in label_color), roughness=0.6)
    label = material('Etiqueta', label_color, roughness=0.55, sheen=0.2)
    sym = material('SimboloMat', fabric_color, roughness=0.45)
    rot = (math.radians(90), 0, 0)
    bpy.ops.mesh.primitive_cube_add(size=1)
    b = bpy.context.object
    b.scale = (0.40, 0.34, 0.014)
    b.rotation_euler = rot
    b.location = (0.0, -0.392, 0.01)
    add_mod(b, 'BEVEL', width=0.03, segments=4)
    b.data.materials.append(border)
    bpy.ops.mesh.primitive_cube_add(size=1)
    l = bpy.context.object
    l.scale = (0.36, 0.30, 0.014)
    l.rotation_euler = rot
    l.location = (0.0, -0.40, 0.01)
    add_mod(l, 'BEVEL', width=0.025, segments=4)
    l.data.materials.append(label)
    symbol(kind, sym, (0.0, -0.409, 0.01), rot)


def lights_and_camera():
    scene = bpy.context.scene
    world = bpy.data.worlds.new('Mundo')
    world.use_nodes = True
    world.node_tree.nodes['Background'].inputs['Color'].default_value = (0.05, 0.05, 0.06, 1)
    world.node_tree.nodes['Background'].inputs['Strength'].default_value = 0.35
    scene.world = world

    def area(name, loc, energy, size, color=(1, 1, 1)):
        bpy.ops.object.light_add(type='AREA', location=loc)
        lt = bpy.context.object
        lt.name = name
        lt.data.energy = energy
        lt.data.size = size
        lt.data.color = color
        direction = Vector((0, 0, 0.05)) - lt.location
        lt.rotation_euler = direction.to_track_quat('-Z', 'Y').to_euler()

    area('Principal', (-2.2, -2.6, 2.6), 330, 2.2)
    area('Preenchimento', (2.6, -1.8, 1.2), 90, 2.5, (0.85, 0.9, 1.0))
    area('Contorno', (0.8, 2.6, 2.4), 420, 1.6)

    bpy.ops.object.camera_add(location=(-1.9, -2.75, 1.55))
    cam = bpy.context.object
    cam.data.lens = 50
    target = Vector((0.0, 0.0, 0.02))
    cam.rotation_euler = (target - cam.location).to_track_quat('-Z', 'Y').to_euler()
    scene.camera = cam
    return cam


def frame_object(cam, margin=1.08):
    # Afasta/aproxima a câmera até a bolsa caber no quadro com margem.
    bpy.context.view_layer.update()
    pts = []
    for o in bpy.context.scene.objects:
        if o.type == 'MESH':
            dg = bpy.context.evaluated_depsgraph_get()
            ev = o.evaluated_get(dg)
            me = ev.to_mesh()
            pts += [ev.matrix_world @ v.co for v in me.vertices]
            ev.to_mesh_clear()
    from bpy_extras.object_utils import world_to_camera_view
    scene = bpy.context.scene
    target = Vector((0.0, 0.0, 0.02))
    for _ in range(40):
        bpy.context.view_layer.update()
        cs = [world_to_camera_view(scene, cam, p) for p in pts]
        xs = [c.x for c in cs]
        ys = [c.y for c in cs]
        span = max(max(xs) - min(xs), max(ys) - min(ys))
        if abs(span - 1 / margin) < 0.01:
            break
        d = cam.location - target
        cam.location = target + d * (span * margin)
    # Centraliza no quadro.
    cs = [world_to_camera_view(scene, cam, p) for p in pts]
    cx = (max(c.x for c in cs) + min(c.x for c in cs)) / 2 - 0.5
    cy = (max(c.y for c in cs) + min(c.y for c in cs)) / 2 - 0.5
    cam.data.shift_x = cx
    cam.data.shift_y = cy


def render_settings():
    scene = bpy.context.scene
    scene.render.engine = 'CYCLES'
    scene.cycles.device = 'CPU'
    scene.cycles.samples = 96
    scene.cycles.use_denoising = True
    scene.render.film_transparent = True
    scene.render.resolution_x = SIZE
    scene.render.resolution_y = SIZE
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = 'PNG'
    scene.render.image_settings.color_mode = 'RGBA'
    scene.view_settings.view_transform = 'Standard'
    scene.view_settings.look = 'None'


for name, fabric, label_color, kind in VARIANTS:
    clear_scene()
    lin = srgb_to_linear(fabric)
    fabric_mat = material('Tecido', lin, roughness=0.78, sheen=0.5, bump=0.12)
    trim = material('Acabamento', tuple(c * 0.45 for c in lin), roughness=0.7, sheen=0.3, bump=0.08)
    dark = material('Ziper', (0.015, 0.015, 0.017), roughness=0.5)
    metal = material('Metal', (0.75, 0.75, 0.78), roughness=0.25, metallic=1.0)
    strap = material('Alca', (0.02, 0.02, 0.025), roughness=0.65, sheen=0.3, bump=0.1)
    corpo = body(fabric_mat)
    end_caps(corpo, trim)
    zipper(dark, metal)
    handle(-0.28, strap)
    handle(0.28, strap)
    patch(lin, srgb_to_linear(label_color), kind)
    cam = lights_and_camera()
    render_settings()
    frame_object(cam)
    bpy.context.scene.render.filepath = os.path.join(OUT, name + '.png')
    bpy.ops.render.render(write_still=True)
    if name == 'uniform_bag':
        bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT, 'bolsa.blend'))
    print('[gerar_bolsas] ok', name)
