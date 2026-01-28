# GLSL Shaders for Experimental Animation
### CalArts MFA Program | 16-Week Semester

**Prerequisites:** None (LLMs bridge the technical gap)
**Tools:** This shader playground, Claude Code or similar LLM, VS Code
**References:**
- [The Book of Shaders](https://thebookofshaders.com) - Patricio Gonzalez Vivo
- [Inigo Quilez's articles](https://iquilezles.org/articles/) and [Shadertoy](https://shadertoy.com)
- `wookash_inigoquilez.md` in this repo (IQ's philosophy)

---

## Part I: Foundations

---

## Week 1: The Pixel as Canvas

**Concept:** Every pixel runs the same program simultaneously. You're not drawing—you're describing *what color each point should be*.

**Read:**
- Book of Shaders: Chapters 1-3 (Hello World, Uniforms, Running your shader)
- `EXERCISES.md` Part 1.1 and 1.3

**In-Class:**
- Run `npm run dev`, explore the Playground tab
- Study `plasma.glsl` - classic demoscene color cycling
- Discuss: How is this different from frame-by-frame animation?

**Hands-On Exercises** (Exercises tab → Basics):
- **Ex 1.1 - Color Mixing:** RGB values, `vec3`, making colors from numbers
- **Ex 1.2 - Gradient Position:** Using `uv` coordinates to vary color across the screen

**LLM Exercise:**
> "Create a shader that makes the screen pulse between two colors of my choice based on time"

**Assignment:** Complete both Basics exercises. Then use Claude Code to create 3 variations of a simple time-based color shader. Document your prompts and what you learned from each iteration.

---

## Week 2: Variables and Coordinates

**Concept:** Storing values, combining operations, and understanding the UV coordinate system that underpins everything.

**Read:**
- Book of Shaders: Chapter 5 (Shaping Functions)

**Hands-On Exercises** (Exercises tab → Variables):
- **Ex 2.1 - Store & Reuse:** Saving values in variables, building up expressions
- **Ex 2.2 - Order Matters:** How operation order changes the result

**Study:**
- `kaleidoscope.glsl` - how coordinate transformations create visual complexity

**LLM Exercise:**
> "Explain what happens to a shader when I change `gl_FragCoord.xy / u_resolution` to `gl_FragCoord.xy / u_resolution - 0.5`"

**Assignment:** Complete both Variables exercises. Experiment with centering coordinates and observe how it changes existing shaders.

---

## Week 3: The Math Toolkit

**Concept:** `sin`, `mix`, `step`, and `smoothstep` — a small set of functions that produce most of the visual effects you'll ever need.

**Read:**
- Book of Shaders: Chapter 5 continued
- `EXERCISES.md` Part 1.2 (wave forms)

**Hands-On Exercises** (Exercises tab → Math):
- **Ex 3.1 - Sin Wave:** Using `sin()` to create wave patterns
- **Ex 3.2 - Mix Blend:** Interpolating between values with `mix()`
- **Ex 3.3 - Step Cutoff:** Hard edges with `step()` and `smoothstep()`

**Study:**
- Whitney collection: `permutations.glsl` - Lissajous figures built from sin/cos

**LLM Exercise:**
> "Show me what `smoothstep(0.3, 0.7, x)` looks like compared to `step(0.5, x)` — visualize both as color bands"

**Assignment:** Complete all Math exercises. Create a shader that uses at least two of `sin`, `mix`, and `step` together in a single composition.

---

## Week 4: Drawing Shapes

**Concept:** Distance as the universal drawing tool. If you can measure how far a pixel is from a shape, you can draw that shape.

**Read:**
- IQ: [Distance Functions](https://iquilezles.org/articles/distfunctions2d/)

**Hands-On Exercises** (Exercises tab → Shapes):
- **Ex 4.1 - Circle:** Using `length()` and `step()` to draw a circle from distance
- **Ex 4.2 - Multiple Circles:** Positioning shapes at different UV coordinates
- **Ex 4.3 - Rectangle:** Building a rectangle from absolute value and step

**Study:**
- `hexgrid.glsl` - hexagonal tiling from distance calculations

**LLM Exercise:**
> "Draw a rounded rectangle in a shader using distance fields"

**Assignment:** Complete all Shapes exercises. Create a composition with at least 3 different shapes positioned deliberately on screen.

---

## Week 5: Animation

**Concept:** Time as a material. Everything that moves in a shader is a function of `u_time`.

**Hands-On Exercises** (Exercises tab → Animation):
- **Ex 5.1 - Pulsing Circle:** Animating radius with `sin(u_time)`
- **Ex 5.2 - Moving Circle:** Animating position over time
- **Ex 5.3 - Color Cycle:** Time-based color shifts

**Study:**
- `ripple.glsl` - concentric waves from interaction points
- `firefly.glsl` - procedural particle animation

**LLM Exercise:**
> "Add a second layer of slower, larger waves to this ripple shader with a different color"

**Assignment:** Complete all Animation exercises. Then create a "visual instrument" — a shader where mouse position controls multiple oscillating parameters. Think of it as a single-frame synthesizer.

---

## Week 6: Symmetry and Grids

**Concept:** Folding space with `abs()` and repeating it with `mod()`. A single shape becomes a pattern.

**Hands-On Exercises** (Exercises tab → Symmetry & Grids):
- **Ex 6.1 - Two Halves:** Horizontal and vertical symmetry with `abs()`
- **Ex 6.2 - Four Quadrants:** Folding the plane into mirrored quadrants
- **Ex 7.1 - Row of Circles:** Horizontal repetition with `mod()` and `fract()`
- **Ex 7.2 - Grid of Circles:** 2D tiling patterns

**Study:**
- `tiles.glsl` - tiling patterns
- `kaleidoscope.glsl` - polar symmetry

**LLM Exercise:**
> "Convert this shader from Cartesian to polar coordinates and add rotation over time"

**Assignment:** Complete all Symmetry and Grids exercises. Create a shader that tiles the screen in an unexpected way. Experiment with `mod()`, `fract()`, and coordinate transformations.

---

## Week 7: Functions and Challenges

**Concept:** Encapsulating logic into reusable functions. Combining everything learned so far.

**Hands-On Exercises** (Exercises tab → Functions & Challenges):
- **Ex 8.1 - Circle Function:** Encapsulating drawing logic into reusable functions
- **Ex 8.2 - Ring Function:** Building on functions to create ring shapes
- **Challenge A - Traffic Light:** Combine circles, color, and time-based switching
- **Challenge B - Loading Spinner:** Rotation and animated arcs
- **Challenge C - Gradient Sunset:** Layered gradients and color blending
- **Challenge D - Spotlight:** Mouse-driven lighting with distance falloff

**LLM Exercise:**
> "Refactor this shader so the repeated drawing code becomes a function I can call with different parameters"

**Assignment:** Complete both Functions exercises and attempt all 4 Challenges. The challenges are open-ended — push them beyond the TODO prompts.

---

## Part II: Intermediate Techniques

---

## Week 8: Color as Emotion

**Concept:** Cosine palettes, HSV manipulation, color cycling as animation. From this week on, you'll work in the Playground tab and create your own shaders with custom controls.

**Read:**
- Book of Shaders: Chapter 6 (Colors)
- IQ: [Palettes](https://iquilezles.org/articles/palettes/)
- `SLIDER_TUTORIAL.md` — how to add interactive sliders to your shaders (HTML → JS → GLSL data flow)

**Study:**
- `whitney/fractal.glsl` - cosine palette animation
- `drive.glsl` - layered bokeh with color grading

**LLM Exercise:**
> "Replace this shader's color scheme with a cosine palette. Give me controls for the palette parameters."

**Assignment:** Take one of your previous shaders and completely transform its mood through color alone. Create "day" and "night" versions. Add at least one custom slider to control a parameter of your choice (follow `SLIDER_TUTORIAL.md`).

---

## Week 9: Noise and Organic Form

**Concept:** Deterministic randomness. Noise functions create the illusion of natural chaos.

**Read:**
- Book of Shaders: Chapters 10-11 (Random, Noise)
- IQ: [Value Noise Derivatives](https://iquilezles.org/articles/morenoise/)

**Study:**
- `noise.glsl` - "boiling methane sea" with 3D Perlin noise
- `voronoi.glsl` - cellular patterns

**LLM Exercise:**
> "Layer multiple octaves of noise at different scales to create a more complex texture (fractal Brownian motion)"

**Assignment:** Create an "environment" shader — clouds, water, fire, or something invented. Focus on selling the material through motion.

---

## Week 10: Introduction to Raymarching

**Concept:** Describing 3D space through distance — if you know how far away the nearest surface is, you can safely step that far.

**Read:**
- IQ: [Ray Marching Primitives](https://iquilezles.org/articles/distfunctions/)
- IQ: [Soft Shadows](https://iquilezles.org/articles/rmshadows/)

**Study:**
- `geometries/raymarch.glsl` - smooth-blended primitives with `smin()`
- `geometries/oscillate.glsl` - animated deformation

**LLM Exercise:**
> "Add a second sphere to this raymarched scene and blend them smoothly together"

**Assignment:** Create a simple raymarched scene with 2-3 primitives. Focus on composition and the "feel" of the space, not complexity.

---

## Week 11: Signed Distance Functions (SDFs)

**Concept:** Mathematical sculptures. Combine, subtract, repeat, and deform shapes through pure math.

**Read:**
- IQ: [Distance Functions](https://iquilezles.org/articles/distfunctions/) (the comprehensive list)
- IQ: [Domain Repetition](https://iquilezles.org/articles/sdfrepetition/)

**Study:**
- `geometries/gyroid.glsl` - triply periodic minimal surface
- `geometries/cylinder.glsl` - infinite repetition with `mod()`
- `geometries/penrose.glsl` - impossible geometry

**LLM Exercise:**
> "Create an infinite grid of rounded cubes using domain repetition, with slight variations in each"

**Assignment:** Design an "impossible space" — use SDFs to create geometry that couldn't exist physically. The Whitney brothers called this "visual music."

---

## Week 12: Fractals and Iteration

**Concept:** Self-similarity through repetition. Small rules create infinite complexity.

**Read:**
- IQ: [Mandelbulb](https://iquilezles.org/articles/mandelbulb/)
- Book of Shaders: Chapter 13 (Fractals) if available

**Study:**
- `geometries/mandelbulb.glsl` - 3D Mandelbrot extension
- `whitney/fractal.glsl` - iterative UV transformation

**LLM Exercise:**
> "Animate the power parameter of this Mandelbulb to morph between different fractal shapes"

**Assignment:** Create a fractal animation that tells a story through its transformation. Consider: birth, growth, decay, rebirth.

---

## Week 13: Composition and Layering

**Concept:** Complex imagery through simple layers. Depth, atmosphere, and the "drive shader" technique.

**Read:**
- Review `wookash_inigoquilez.md` on layered composition
- IQ: [Fog](https://iquilezles.org/articles/fog/)

**Study:**
- `drive.glsl` - rain, bokeh, reflections as separate layers
- `firefly.glsl` - particle systems and procedural animation

**LLM Exercise:**
> "Add atmospheric fog to this raymarched scene that gets thicker with distance"

**Assignment:** Create a "scene" with at least 3 distinct visual layers (foreground, subject, background/atmosphere). This is your final project concept draft.

---

## Part III: Final Projects

---

## Week 14: Proposals and Prototyping

**Concept:** Synthesis. Create a shader that expresses something personal.

**Final Project Options:**
1. **Visual Music:** A shader that responds to audio input (can use LLM to help with FFT integration)
2. **Impossible Landscape:** A raymarched environment that couldn't exist
3. **Abstract Narrative:** A shader that transforms over time to suggest a story
4. **Whitney Homage:** A new piece in the Digital Harmony tradition

**In-Class:**
- Present project proposals (concept, reference images, technical approach)
- Begin prototyping core shader logic
- Identify technical risks early

**Assignment:** Working prototype of the primary visual effect for your final project.

---

## Week 15: Studio and Feedback

**In-Class:**
- Work session with individual feedback
- Peer critique in small groups
- Troubleshooting and refinement

**Focus:**
- Does the piece have a clear emotional register?
- Is the motion purposeful or arbitrary?
- Where can complexity be reduced without losing the idea?

**Assignment:** Near-final version of your project. Record a 30-second MP4 capture for critique.

---

## Week 16: Final Presentations

**In-Class:**
- Final project screenings
- Group critique and discussion

**Critique Focus:**
- Does the piece have a clear emotional register?
- Is the motion purposeful or arbitrary?
- What does the LLM collaboration reveal about your creative process?

**Deliverables:**
- Final shader code committed to your branch
- 30-60 second recorded MP4
- Written reflection on your LLM collaboration process (1-2 pages)

---

## LLM Collaboration Guidelines

### Effective Prompting for Shaders

**Good prompts include:**
- The current code context
- What you want to change/add
- The aesthetic goal ("more organic," "sharper edges," "dreamy")
- Technical constraints ("keep it under 100 raymarching steps")

**Example progression:**
1. "What does this line do?" (understanding)
2. "How would I make this rotate?" (learning)
3. "Add rotation controlled by mouse X position" (implementation)
4. "The rotation is too fast and jerky—smooth it out" (refinement)

### When LLMs Struggle

Shaders are highly mathematical. LLMs may:
- Generate syntactically correct but visually wrong code
- Misunderstand coordinate spaces
- Produce inefficient solutions

**Always:** Run the code, observe the result, iterate. The visual feedback loop is your teacher.

---

## Grading

- **Weekly Exercises (40%)** - Completion and iteration
- **Prompt Documentation (20%)** - Quality of LLM dialogue, learning demonstrated
- **Final Project (40%)** - Artistic merit, technical ambition, personal voice

---

## Resources in This Repository

- **Exercises tab** (`/exercises/`) - 23 scaffolded shader exercises with TODO prompts, organized by topic
- `EXERCISES.md` - Progressive exercises analyzing existing playground shaders
- `SLIDER_TUTORIAL.md` - How to add custom interactive controls
- `wookash_inigoquilez.md` - Deep dive on IQ's philosophy
- All shader source in `src/shaders/` - commented and readable
- Press **R** to record any shader as MP4
- Use **Left/Right arrows** in the Exercises tab to step through exercises sequentially

---

## Philosophy: LLMs as Creative Partners

This course treats the LLM as a collaborator and translator—students focus on *what* they want to express while the LLM helps with *how*. The technical understanding comes through iteration and observation, not memorization.

The goal is not to become a GLSL expert, but to develop:
- Visual intuition for mathematical relationships
- The ability to articulate aesthetic goals precisely
- A feedback loop between imagination and implementation

As John Whitney wrote: "I knew that if I could describe a visual idea in words, I could express it in calculus." Today, we can express it in natural language, and the LLM helps bridge to code.
