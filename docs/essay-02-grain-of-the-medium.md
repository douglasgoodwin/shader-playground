# The Grain of the Medium: Artifacts of Vibecoded Shaders

**Publication:** TBD (more technical venue—*Art in America*, *Leonardo*, *Rhizome*, or book chapter)
**Author:** Douglas Goodwin, Design Media Arts, UCLA
**Length:** ~1,200 words

**Standfirst:** Every medium leaves traces of its process. What are the characteristic artifacts of AI-assisted shader code—and how do they compare to the artifacts of experimental film?

---

## Why shaders?

I chose to teach vibecoding through shaders for strategic reasons. Shaders are compact—often under 100 lines—which means you can hold the whole program in your head and read every line. They're universal: the same GLSL code runs in web browsers, game engines, VJ software, and phones. They provide immediate visual feedback, so errors are obvious and successes are undeniable.

But shaders also carry a historical lineage that matters. They connect to the tradition of visual music—John Whitney, Jordan Belson, Pat O'Neill—artists who used computational and optical systems to generate images that couldn't exist any other way. When students learn shaders, they're not just learning a technical skill. They're entering a conversation that's been going on since the 1960s.

And shaders are unfamiliar to most artists, which levels the playing field. Everyone starts from zero. There's no baggage, no "I already know how to do this." The learning is visible.

---

## Pat O'Neill and technical mediation

In his 1970 book *Expanded Cinema*, Gene Youngblood wrote about the experimental filmmaker Pat O'Neill: "New tools generate new images. In the historical context of image-making, the cinema is a new tool."

O'Neill didn't just point a camera and shoot. He worked through highly technical processes: high-contrast bas-relief, positive/negative bi-pack printing, image "flopping" to create Rorschach-like mirror effects. He named his film *7362* after the high-speed Kodak emulsion on which it was shot—emphasizing the purely cinematic, purely technical nature of the work. Youngblood called him a poet of "very technical chemistry and cinematic machines."

This is the right parallel for vibecoding with shaders. The AI assistant is the new optical printer. Shaders are the new emulsion. The artist still provides the vision—the swirling forms, the color relationships, the rhythm—but the realization happens through technical processes that require vocabulary and understanding. You learn to speak in signed distance functions and noise algorithms the way O'Neill learned emulsion speeds and bi-pack registration.

---

## The artifacts of 7362

Every medium leaves traces of its process. O'Neill didn't hide those traces—he foregrounded them. He named his film after the emulsion. The artifacts were the vocabulary of the medium:

- **Emulsion grain**: the physical texture of silver halide crystals, visible especially in the high-speed stock, giving the image a particular density and shimmer
- **High-contrast bas-relief**: flattening tonal range into stark black and white, turning continuous forms into graphic shapes
- **Bi-pack color shifts**: the registration (and mis-registration) of positive and negative layers producing halos, color fringing, unexpected chromatic interactions
- **Optical printing generations**: each pass through the contact printer degrading and transforming, accumulating the fingerprint of the machine

These artifacts were traceable—you could point to the chemistry, the optics, the mechanics. They were also manipulable. O'Neill learned to work with them, to push the contrast until the nude figure became "as mechanical as the machinery." The artifacts weren't mistakes to be corrected. They were the medium declaring itself.

---

## The artifacts of vibecoded shaders

Vibecoded shaders have their own characteristic "grain," shaped by where LLM training data is densest. The comparison:

| O'Neill / Film | Vibecoding / Shaders |
|----------------|---------------------|
| Emulsion grain (7362 stock) | Training data density (where LLMs are confident) |
| High-contrast processing | Convergence toward common solutions |
| Bi-pack registration | The "seams" where different code patterns meet |
| Optical printing generations | Iteration artifacts—each conversation round shaping the code |
| Chemical color response | Familiar aesthetic patterns, standard palettes |

**Convergence toward common solutions.** LLMs suggest what's well-documented. The standard raymarching setup. The smooth minimum function. The cosine color palettes that appear in every Shadertoy tutorial. Vibecoded work clusters around these known-good solutions because that's where the training data is dense. The "false summit" problem becomes an aesthetic artifact—you end up where many others got stuck.

**The Book of Shaders aesthetic.** Since so much shader education flows through the same sources, there's a recognizable look: smooth signed distance functions, fbm noise layered in particular ways, the characteristic glow of emission effects. Not wrong, but familiar.

**Absence of idiosyncrasy.** Hand-tuned shaders often have quirks—specific magic numbers, odd optimizations, accidents that became features. Vibecoded shaders might be "correct" in a generic way, lacking the weird specificity that comes from years of wrestling with a medium. The code is clean because it came from documentation, not from struggle.

**Over-smoothness.** Shaders lean toward smooth mathematical functions by nature. Add an LLM's preference for well-behaved solutions, and you get work that might lack grit, grain, the productive noise of imperfection.

---

## Inigo Quilez and the weight of influence

Much of the density in shader training data comes from one source: **Inigo Quilez**, a former Pixar engineer whose website and Shadertoy contributions have become the de facto curriculum for real-time graphics.

His smooth minimum function appears in nearly every raymarching tutorial. His cosine color palette function is ubiquitous. His signed distance function library—spheres, boxes, toruses, boolean operations—forms the foundation of most procedural 3D work. When you ask an LLM to help you blend two shapes smoothly, you're almost certainly going to get Quilez's solution.

This isn't a criticism of Quilez—his work is elegant, well-documented, and freely shared. But it means that vibecoded shaders carry his fingerprints whether the artist knows it or not. The grain of the medium includes the influence of its most prolific teacher.

The question becomes: do you recognize when you're using a Quilez function? Do you understand why it works? Can you modify it, or are you treating it as a black box inside your supposedly transparent code?

---

## The epistemological artifact

The crucial difference from Midjourney or Stable Diffusion: those artifacts are buried in latent space. You can't trace them, can't manipulate them, can't name your work after them. The artifact is disconnected from any process you control.

With vibecoding, like with O'Neill's optical printing, the artifacts are in the code. You can see the function Claude suggested. You can decide whether the noise algorithm is a feature or a crutch. You can name your shader after the technique the way O'Neill named his film after the emulsion.

But here's the deeper question: the artifact of vibecoding might not be visual at all. It might be epistemological. The tell is whether the artist can explain every choice, or whether certain passages remain opaque even to them.

"Claude suggested this and it worked" is its own kind of artifact—a moment where the code is visible but the reasoning isn't. The vibecoding artist has to decide: investigate that passage until you understand it, or leave it as a trusted black box within your otherwise transparent process.

The question for the vibecoding artist becomes the same question O'Neill faced: Do you work with the grain of the medium or against it? And can you tell the difference?

---

## Author Bio

Douglas Goodwin teaches experimental writing and creative technology at UCLA's Design Media Arts program, where he runs courses on vibecoding and computational cinema. He has used computational methods to generate text and visual work for over two decades.

---

## Notes

- More technical companion to "Vibecoding: Teaching Artists a Third Way to Work with AI"
- Suitable for *Leonardo*, *Rhizome*, *Art in America*, or as book chapter
- Key themes: technical mediation, artifacts as vocabulary, O'Neill/7362 parallel, Inigo Quilez's influence
- Could expand with specific code examples for even more technical venues
