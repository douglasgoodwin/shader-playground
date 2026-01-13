# [Painting with Math | Inigo Quilez](https://www.youtube.com/watch?v=F1ax1iJTHFs&t=3307s)
## Wookash Podcast

+ [Heart Created with Math](https://www.youtube.com/watch?v=aNR4n0i2ZlM)
+ [Skull Shader](https://www.shadertoy.com/view/4XsfDs)
+ [Youtube Channel](https://www.youtube.com/channel/UCdmAhiG8HQDlz8uyekw4ENw)
+ [http://iquilezles.org/](http://iquilezles.org/)


Inigo Quilez is a pioneering figure in real-time computer graphics, known for constructing complex visual worlds entirely from mathematical functions. His background spans the demoscene, Pixar, Oculus Story Studio, and Adobe, and he is the creator of ShaderToy. Before his studio career, he built live music visualizations for San Francisco clubs, often working through the night after his day job. The interview is framed as a technically dense conversation, aimed at unpacking what it means to “render with equations” rather than traditional 3D pipelines.

Quilez explains that while his professional work largely involves conventional product development—C++ programming, rendering architecture, and systems design—his public reputation comes from an alternative approach to image creation. Instead of modeling geometry, UV mapping, and texturing, he generates scenes directly through code, treating images as pure mathematical functions of space. This functional, stateless approach resembles shaders conceptually, even when implemented in C++ rather than on the GPU.

This method reached its most demanding real-world test during his time at Pixar around 2010. Contrary to the assumption that film studios enjoy unlimited computational resources, production constraints were severe: only 2 GB of memory were available for entire environments such as forests, rivers, rocks, and terrain. Traditional asset pipelines would have exceeded these limits. To solve this, Quilez bypassed geometry and texture assets altogether, hard-coding environments procedurally using mathematical functions evaluated directly at render time.

He describes this work as an extension of practices developed much earlier in the demoscene, a European-rooted culture where programmers, artists, and musicians collaborate to create audiovisual works under extreme constraints. In some competitions, entire four-minute audiovisual pieces—including code, graphics, and music—must fit into 4 kilobytes. These restrictions force a fusion of algorithmic thinking, low-level assembly programming, compression theory, and aesthetic judgment.

Quilez recounts how demoscene production often involves writing assembly code with compression in mind, arranging instructions to maximize redundancy for dictionary-based compressors. Floating-point values are deliberately truncated to improve compression ratios, sacrificing imperceptible precision to save bytes. Tools such as Crinkler—an advanced executable compressor used in the demoscene—replace standard linkers and embed decompression logic directly into the final binary.

At Pixar, these skills translated into a procedural system informally named Wonder Moss, first developed for the film Brave. The tool generated moss, vegetation, rocks, and terrain volumetrically, based on mathematical rules tied to slope, altitude, surface normals, and environmental parameters such as wind direction. Rather than artists sculpting millions of polygons, Quilez wrote C++ plugins for RenderMan that generated detail on demand, tightly integrated with Pixar’s micropolyon rendering pipeline.

This workflow demanded shot-specific customization. Instead of building reusable tools, Quilez often modified code directly for individual shots, inserting conditional logic to solve local compositional problems. While politically challenging within a studio environment that favored repeatability and abstraction, he describes this period as the most creatively fulfilling of his career—an intense collaboration between mathematical thinking and visual design.

A critical turning point came when Quilez joined Oculus Story Studio. Initially skeptical of early consumer VR due to low resolution, poor color reproduction, and visual instability, he was nonetheless drawn to the creative challenge of defining a cinematic language for virtual reality. Traditional film grammar—framing, cuts, controlled viewpoints—breaks down when viewers can freely look around. Lighting, sound cues, and spatial staging became primary tools for directing attention.

At Oculus, Quilez worked on real-time VR films such as Henry, implementing custom forward rendering pipelines inside Unreal Engine to avoid temporal anti-aliasing and flicker. Drawing on pre-physically-based rendering techniques from Pixar, he emphasized artistic control over physical correctness, using colorized ambient occlusion, painterly lighting cheats, and analytic light volumes computed through math rather than simulation.

The project Dear Angelica marked a deeper conceptual shift. Rejecting photorealism entirely, the team embraced an illustrated, memory-like aesthetic. Inspired by Tilt Brush, Quilez proposed abandoning conventional 3D tools altogether and instead building a system that allowed a traditionally trained 2D artist to draw directly in 3D space. This led to the creation of Quill, a VR painting tool in which strokes become polygon strips rendered without lighting—shadows, highlights, and depth are all painted explicitly by the artist.

Quilez identifies this moment as transformative. Rather than using GPU power to chase ever-greater realism, he saw its potential to lower barriers to creation and radically expand who can make 3D content. He contrasts the relatively small population of trained 3D artists with the vast global community of 2D illustrators and designers, arguing that future graphics tools should prioritize expressive accessibility over technical sophistication.

The interview concludes with broader reflections on software design. Quilez expresses skepticism toward modern C++ abstractions such as smart pointers, singletons, and opaque ownership models. Trained as an electrical engineer, he prefers systems where data flow is explicit and traceable, likening software components to visible wires on a circuit board. For him, clarity of control and understanding outweigh theoretical safety, especially in performance-critical graphics systems.

Throughout the conversation, a consistent philosophy emerges: mathematics is not the subject of the work but the medium. Whether compressing a demo into 4 kilobytes, rendering a forest inside 2 GB, or enabling an illustrator to paint memories in VR, Quilez treats code as a brush—one that can either entrench technical barriers or dissolve them entirely.

---


## Mathematical rendering as a production workflow

Inigo Quilez consistently frames his work not as a rejection of production pipelines, but as an alternative location within them. His core move is to relocate creative complexity away from assets (meshes, textures, files on disk) and into procedures evaluated at render time. In practice, this means that environments are not stored; they are computed.

At Pixar, this approach emerged not from aesthetic ideology but from hardware constraints. Entire backgrounds—forests, mountains, rocks, moss—had to fit into roughly 2 GB of memory, at a time when RenderMan was rasterizing via micropolygons and streaming geometry tile by tile. Traditional scanned assets were infeasible: a single hero tree could contain millions of polygons and large texture sets. Quilez’s solution was to replace asset databases with mathematical functions parameterized by space.

His workflow therefore began with extremely lightweight inputs: a coarse terrain mesh defining altitude and surface normals, plus a small set of global parameters. Every other detail—grass length, color variation, moss density, rock placement—was derived analytically from those inputs. Instead of “placing” objects, he evaluated conditional rules: slope above a threshold suppresses grass, flatter areas permit it; older grass is rendered browner; normals facing wind directions influence animation amplitude. These were not shaders in the GPU sense, but C++ functions embedded directly in RenderMan plugins, evaluated during micropolygon shading.

Crucially, this work was shot-specific. Quilez did not build a generalized tool exposed to artists; he was the tool. When a blade of grass intersected a character’s foot, the fix was not an exclusion volume placed by a set dresser—it was an if statement added for that shot. This extreme hard-coding violated standard production norms, but allowed rapid, precise control under tight constraints.


## Demoscene techniques as industrial practice

The demoscene background is essential to understanding how Quilez thinks about efficiency. In that culture, compression, runtime behavior, and aesthetics are inseparable. His description of 4 KB demos reveals a workflow in which code is written for compressibility, not just correctness. Instructions are reordered to maximize opcode repetition; floating-point constants are bit-truncated to introduce runs of zeros; even parameter order in Win32 API calls is chosen to improve dictionary compression.

This mindset transferred directly to film production. Memory was not abstract; it was budget. Precision was negotiable if the perceptual effect survived. The idea that you could lose half the mantissa of a floating-point value without visible consequences shows a deep understanding of where numerical fidelity actually matters—and where it does not.

Importantly, Quilez does not romanticize this as clever hacking. He treats it as a practical extension of algorithmic thinking: if a generative process yields high apparent complexity from low informational input, it is inherently better suited to constrained systems than explicit description. This logic underpins all of his later work, even when constraints shift from memory to frame time or user experience.


RenderMan, micropolygons, and procedural density

A subtle but important detail in his Pixar workflow is how well it aligned with RenderMan’s architecture. RenderMan diced geometry into patches, then into micropolygons approximately the size of a pixel, shading them in object space before splatting into the framebuffer. Because shading occurred before rasterization, Quilez’s procedural systems could generate fine detail without ever allocating dense geometry in memory.

This meant that trees, moss, and rocks did not “exist” as meshes. They existed as mathematical density fields evaluated at shading time. The cost scaled with screen coverage, not world complexity. Distant detail naturally collapsed, closer detail expanded, and nothing required storage beyond the current tile being rendered. His innovations worked because they cooperated with the renderer’s signal-processing assumptions rather than fighting them.


## Anti-aliasing trauma and the rejection of flicker

A formative failure at Pixar shaped Quilez’s later decisions: early experiments porting demoscene ray-marching techniques into film production produced unacceptable flickering. While demoscene audiences tolerated aliasing as part of the medium, film projection magnified these artifacts into fatal flaws. Being forced to abandon months of work instilled a lasting intolerance for temporal instability.

This experience explains his later hostility to temporal anti-aliasing in VR and Unreal Engine. TAA’s reliance on motion vectors and history buffers conflicted with his need for crisp, stable imagery at 90 Hz. His solution—forward rendering with supersampling and coverage masks—was not fashionable, but it was predictable. Predictability, for Quilez, consistently outranks theoretical optimality.


## VR rendering: repurposing old cheats under new constraints

At Oculus Story Studio, Quilez consciously resurrected pre-PBR lighting philosophy. Rather than letting physically based systems place highlights and shadows wherever equations dictated, he reintroduced artistic overrides: separate directions for lighting and shadowing, colorized ambient occlusion, and intentionally non-physical saturation in concave areas.

Technically, this was implemented through analytic light volumes defined by mathematical falloff functions. Instead of many lights with shadow maps, he evaluated closed-form expressions that returned color contributions based on distance to abstract “brushes” in space. Because everything had to run inside an 11-millisecond frame budget (for stereo 90 Hz), these functions were optimized for minimal arithmetic and zero texture bandwidth.

Here, the demoscene mindset reappears: fewer data fetches, more math. The GPU becomes a calculator rather than a database lookup engine.


## Quill: shifting innovation from rendering to creation

The most significant innovation described in the interview is not visual but procedural: Quill’s abandonment of lighting and surface semantics altogether. Instead of treating strokes as surfaces to be shaded, Quill treats them as ink in space. Volumes are suggested by accumulation, color, and overlap—not by normals, BRDFs, or light transport.

Workflow-wise, this has far-reaching implications. Because strokes are polygon strips generated from tracked controller motion, topology can be messy, self-intersecting, and non-manifold without consequence. No UVs, no edge loops, no concern for curvature continuity. Transparency is approximated through multisample coverage masks, not alpha blending.

This design choice offloads responsibility from algorithms to artists. Shadows are painted, not computed. Depth cues are intentional marks, not emergent properties. The technical system recedes, enabling someone with zero 3D background to produce spatially coherent worlds.

For Quilez, this marks a philosophical pivot: GPU power should be spent reducing conceptual friction, not increasing fidelity. The innovation lies less in rendering equations than in deciding which equations to remove from the process entirely.


## Programming style as epistemology

Finally, his views on C++ are not incidental complaints but reflect a deeper epistemology. He rejects abstractions that obscure control flow and ownership, arguing that they prevent programmers from seeing the system. His preference for explicit data movement mirrors his visual philosophy: what matters is not elegance in isolation, but perceptual and cognitive clarity.

In both graphics and software architecture, Quilez favors systems where causality is legible—where one can trace how an input becomes an output, how a stroke becomes a form, how a parameter affects an image. This consistency across domains is perhaps the most telling detail of the interview.


## Synthesis

Across demoscene demos, Pixar forests, VR films, and Quill, a single workflow logic persists:

+ Encode complexity procedurally, not descriptively
+ Spend computation where perception is sensitive, economize elsewhere
+ Prefer stability over cleverness
+ Replace automation with empowerment when tools block expression

His innovations are therefore less about inventing new graphics tricks and more about relocating agency—away from pipelines and toward mathematical and human intuition.

