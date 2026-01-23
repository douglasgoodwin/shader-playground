# GLSL Shaders for Experimental Animation
### CalArts MFA Program | 10-Week Syllabus

**Prerequisites:** None (LLMs bridge the technical gap)
**Tools:** This shader playground, Claude Code or similar LLM, VS Code
**References:**
- [The Book of Shaders](https://thebookofshaders.com) - Patricio Gonzalez Vivo
- [Inigo Quilez's articles](https://iquilezles.org/articles/) and [Shadertoy](https://shadertoy.com)
- `wookash_inigoquilez.md` in this repo (IQ's philosophy)

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

**LLM Exercise:**
> "Create a shader that makes the screen pulse between two colors of my choice based on time"

**Assignment:** Use Claude Code to create 3 variations of a simple time-based color shader. Document your prompts and what you learned from each iteration.

---

## Week 2: Coordinates and Transformation

**Concept:** UV space, aspect ratio correction, polar coordinates as expressive tools.

**Read:**
- Book of Shaders: Chapter 5 (Shaping Functions)
- IQ: [Distance Functions](https://iquilezles.org/articles/distfunctions2d/)

**Study:**
- `kaleidoscope.glsl` - polar coordinates and radial symmetry
- `hexgrid.glsl` - hexagonal tiling mathematics

**LLM Exercise:**
> "Convert this shader from Cartesian to polar coordinates and add rotation over time"

**Assignment:** Create a shader that tiles the screen in an unexpected way. Experiment with `mod()`, `fract()`, and coordinate transformations.

---

## Week 3: The Oscillation Toolkit

**Concept:** `sin`, `cos`, `fract`, `smoothstep` as the building blocks of all motion.

**Read:**
- Book of Shaders: Chapter 5 continued
- `EXERCISES.md` Part 1.2 (wave forms)

**Study:**
- `ripple.glsl` - concentric waves from interaction points
- Whitney collection: `permutations.glsl` - Lissajous figures

**LLM Exercise:**
> "Add a second layer of slower, larger waves to this ripple shader with a different color"

**Assignment:** Create a "visual instrument" - a shader where mouse position controls multiple oscillating parameters. Think of it as a single-frame synthesizer.

---

## Week 4: Noise and Organic Form

**Concept:** Deterministic randomness. Noise functions create the illusion of natural chaos.

**Read:**
- Book of Shaders: Chapters 10-11 (Random, Noise)
- IQ: [Value Noise Derivatives](https://iquilezles.org/articles/morenoise/)

**Study:**
- `noise.glsl` - "boiling methane sea" with 3D Perlin noise
- `voronoi.glsl` - cellular patterns

**LLM Exercise:**
> "Layer multiple octaves of noise at different scales to create a more complex texture (fractal Brownian motion)"

**Assignment:** Create an "environment" shader - clouds, water, fire, or something invented. Focus on selling the material through motion.

---

## Week 5: Color as Emotion

**Concept:** Cosine palettes, HSV manipulation, color cycling as animation.

**Read:**
- Book of Shaders: Chapter 6 (Colors)
- IQ: [Palettes](https://iquilezles.org/articles/palettes/)

**Study:**
- `whitney/fractal.glsl` - cosine palette animation
- `drive.glsl` - layered bokeh with color grading

**LLM Exercise:**
> "Replace this shader's color scheme with a cosine palette. Give me controls for the palette parameters."

**Assignment:** Take one of your previous shaders and completely transform its mood through color alone. Create "day" and "night" versions.

---

## Week 6: Introduction to Raymarching

**Concept:** Describing 3D space through distance—if you know how far away the nearest surface is, you can safely step that far.

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

## Week 7: Signed Distance Functions (SDFs)

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

**Assignment:** Design an "impossible space" - use SDFs to create geometry that couldn't exist physically. The Whitney brothers called this "visual music."

---

## Week 8: Fractals and Iteration

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

## Week 9: Composition and Layering

**Concept:** Complex imagery through simple layers. Depth, atmosphere, and the "drive shader" technique.

**Read:**
- Review `wookash_inigoquilez.md` on layered composition
- IQ: [Fog](https://iquilezles.org/articles/fog/)

**Study:**
- `drive.glsl` - rain, bokeh, reflections as separate layers
- `firefly.glsl` - particle systems and procedural animation

**LLM Exercise:**
> "Add atmospheric fog to this raymarched scene that gets thicker with distance"

**Assignment:** Create a "scene" with at least 3 distinct visual layers (foreground, subject, background/atmosphere). This is your portfolio piece draft.

---

## Week 10: Final Projects

**Concept:** Synthesis. Create a shader that expresses something personal.

**Final Project Options:**
1. **Visual Music:** A shader that responds to audio input (can use LLM to help with FFT integration)
2. **Impossible Landscape:** A raymarched environment that couldn't exist
3. **Abstract Narrative:** A shader that transforms over time to suggest a story
4. **Whitney Homage:** A new piece in the Digital Harmony tradition

**Critique Focus:**
- Does the piece have a clear emotional register?
- Is the motion purposeful or arbitrary?
- What does the LLM collaboration reveal about your creative process?

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

- `EXERCISES.md` - Progressive exercises with solutions
- `SLIDER_TUTORIAL.md` - How to add custom interactive controls
- `wookash_inigoquilez.md` - Deep dive on IQ's philosophy
- All shader source in `src/shaders/` - commented and readable
- Press **R** to record any shader as MP4

---

## Philosophy: LLMs as Creative Partners

This course treats the LLM as a collaborator and translator—students focus on *what* they want to express while the LLM helps with *how*. The technical understanding comes through iteration and observation, not memorization.

The goal is not to become a GLSL expert, but to develop:
- Visual intuition for mathematical relationships
- The ability to articulate aesthetic goals precisely
- A feedback loop between imagination and implementation

As John Whitney wrote: "I knew that if I could describe a visual idea in words, I could express it in calculus." Today, we can express it in natural language, and the LLM helps bridge to code.
