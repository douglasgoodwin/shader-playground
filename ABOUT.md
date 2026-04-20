# About the Shader Playground

## What this is

This repository is the companion codebase to a course I teach at the California Institute of the Arts (CalArts) on *vibe coding* — using a large language model as a collaborator to write GLSL shaders for animation and cinema. It's the second AI-oriented class I've built for CalArts, and it grew out of a specific set of teaching problems. This document is meant as an orientation: what the playground is, why it exists, and the tradition it belongs to.

The shader runs in the browser. The code runs on the GPU. The LLM sits beside the artist as a programmer would. That's the whole premise.

## A short history of machines and art at CalArts

Computer-assisted image-making has a long history at CalArts, much of it predating the phrase in its current sense. Figures whose work at or near the school connects to this tradition include:

- **Film and video**: Ed Emshwiller, Adam Beckett, Pat O'Neill, and later John Lasseter and the early Pixar crew. Joanna Priestley made work as a student on the Cubicomp.
- **Electronic music and systems**: Morton Subotnick, James Tenney, Alison Knowles, David Rosenboom, Mark Trayle.
- **Video and image processing**: Nam June Paik; Stephen Beck's video weavings.

Mike Bryant has mentioned there's a stack of early CG work tucked somewhere in the library archive. I raise all of this because the class I teach is an attempt to continue a line, not to import a new technology into an art school. CalArts has been working with machines, procedurally and generatively, for a long time.

## From image generators to code

The first AI class I developed was image-first: DeepDream, GANs, and then Stable Diffusion through ComfyUI — a node-based interface that uses Python under the hood and bridges out to FFmpeg, POV-Ray, and other low-level tools. As a course it worked well, and it let me teach a kind of history, connecting early generative cinema to contemporary diffusion models.

Over several semesters, three problems hardened:

1. **Platform drag.** The CalArts Film/Video school is built on the Mac. Mac support for Stable Diffusion has improved, but remains patchy — Metal bridges exist, but ComfyUI graphs pulled from tutorials routinely break on macOS. I was rewriting examples every semester, and the last round was brutal.
2. **A shifting mood around AI.** There is growing unease in the CalArts community about using AI for image generation. A class that had been oversubscribed at the Claremont schools began to see its enrollments slip.
3. **Two pipelines that didn't really meet.** Even with ComfyUI bridging them, diffusion-based image generation and the Python code students were writing around it lived in largely separate worlds. The AI was a source of pictures, not a collaborator on a program.

I needed a new approach: something hardware-agnostic, something that did not raise the current set of objections to generative images, and something that used AI as a genuine collaborator rather than a content engine.

## Why GLSL shaders

GLSL — the OpenGL Shading Language — is a small, C-like language that runs directly on the GPU. A shader program is typically two small programs linked together: a **vertex shader** that positions geometry, and a **fragment shader** that colors pixels. It has built-in vector and matrix types (`vec2`, `vec3`, `vec4`, `mat4`) and is designed for graphics math.

For the average artist, this is arcane. That turns out to be exactly the point. Shaders are:

- **Small.** A working shader is tens to low-hundreds of lines. An LLM can reason about the whole program at once.
- **Well-represented in training data.** Decades of Shadertoy, Inigo Quilez's writing, and *The Book of Shaders* are already in the models' heads.
- **Instantly visible.** WebGL runs in any browser. Preview is immediate, the feedback loop is tight.
- **Light on resources.** Each prompt is more on par with asking an LLM to fix your email than with spinning up a diffusion pipeline. No GPU farm, no multi-gigabyte model downloads.
- **Procedural rather than generative.** The output is the artist's program. The LLM is a collaborator on that program — the experience is closer to working with a programmer than with an image engine.

Students report this feels different. The concerns that attach to diffusion do not attach here in the same way. The work is code they own, built by them, with assistance.

## The stack

```
LLM         = code collaborator
JS library  = orchestration layer
WebGL       = GPU interface
GLSL        = rendering logic
```

**WebGL** is the JavaScript API that gives you an OpenGL ES–style drawing pipeline inside an HTML `<canvas>`. You call WebGL functions (`gl.drawArrays`, `gl.uniform3f`, and so on) from JS to drive the GPU.

**Data flowing from JS into shaders:**
- **Attributes** — per-vertex arrays (positions, normals, UVs) stored in WebGL buffers.
- **Uniforms** — constant parameters per draw call (time, matrices, colors).
- **Textures** — images or data samplers passed to the fragment shader.

**Between shaders:** the vertex shader writes to `varying` / `out` variables; WebGL's rasterizer interpolates them and feeds them into the fragment shader as `varying` / `in`.

JavaScript libraries sit around WebGL as different kinds of scaffolding. Some hide boilerplate, some structure scenes, some make shader authoring easier, and some help an LLM turn prompts into runnable visual systems instead of isolated GLSL snippets.

## The classroom workflow

Students start from an existing example — there are more than two dozen sections in this repo, each with its own collection of shaders — and use an LLM of their choice to edit the code. Each example is paired with explicit file-path links into the pipeline, so a student can hand a prompt and a source file to the model and get a targeted edit back. Preview is immediate in the browser.

Around the core shader pipeline I've built:

- **Modular uploaders** for images, video, and 3D models (including OBJ).
- **A recorder** that captures shader output at 1080p, using the WebCodecs API for hardware-accelerated H.264.
- **A ladder of exercises** (`/exercises/`, covering ex1–ex11) that scaffolds GLSL from first principles through hash, noise, and raymarching — a self-guided track for students who want to understand what the LLM is doing, not just direct it.

The pedagogy is that the LLM lowers the floor but does not lower the ceiling. Students who want to stay prompt-driven can; students who want to dig into the code have a clear path.

## Relevance to production

This was built for a classroom, but the shape is useful beyond one. The same pattern — LLM as code collaborator on small, visible, GPU-bound programs, with an immediate in-browser preview and a video recorder — describes a fast, reviewable loop for generative motion graphics, title work, previsualization, and real-time visuals. Because the artist owns the source and the LLM edits it, the authorship story is clean in a way that diffusion pipelines often aren't.

## Running it

```bash
npm install
npm run dev
```

Then open the browser, pick a section, read the code, and prompt your way forward.

---

Happy to go deeper on any of this — the CalArts history, the classroom pedagogy, the technical pipeline, or the move away from diffusion — when we talk.
