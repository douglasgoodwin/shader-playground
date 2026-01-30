# Vibecoding: Teaching Artists a Third Way to Work with AI

**Publication:** The Conversation (pitch draft)
**Author:** Douglas Goodwin, Design Media Arts, UCLA
**Length:** ~1,800 words

**Standfirst:** While generative AI promises to make art for us, a growing number of artists want something different—tools that let them make art themselves. A new approach called "vibecoding" offers exactly that.

---

On the first day of my vibecoding course at CalArts, I asked my students what they thought about AI. The room got uncomfortable in a productive way.

"It's not black and white," one student said. "It's like saying glasses are for blind people, or elevators are for lazy people. I'd rather know something about it than just say it's for losers and never touch it."

Another student described using AI to transform old photographs of their mother into images that resembled themself at a younger age—a deeply personal project. "It really depends on intentionality," they said. "You can constantly look at it from different angles."

A third raised the issue most directly: "A lot of problems are caused by the abuse of data. Power needs to be regulated. But how do you define what should be fair?"

No one in the room was a cheerleader for AI. No one was refusing either. They were trying to figure out how to use these tools without losing something essential about why they make art in the first place.

That's what this course is about. Not whether AI is good or bad, but whether there's a way to work with it that preserves what artists actually value: process, intention, understanding, authorship.

---

## The finished-output problem

The most popular AI tools for artists—Midjourney, DALL-E, Runway—share a common design philosophy. You type a prompt, and the system generates a complete work. An image. A video. A finished thing.

This is efficient. It's also hollow.

Artists don't want finished things handed to them. They want to *make* something. The satisfaction of creative work comes from decisions accumulated over time: this color not that one, this curve adjusted, this element removed. When a tool skips the process and delivers a result, it turns artists into curators of AI output rather than authors of their own work.

I've heard artists describe using these tools as a "lottery"—you regenerate and regenerate until something acceptable appears. When it does, you can't fully explain it, reproduce it, or build on it. You selected it. You didn't make it.

Something essential is gone.

---

## Vibecoding as a different approach

"Vibecoding" is a term coined by Andrej Karpathy, the former head of AI at Tesla. The idea is simple: instead of asking AI to generate finished output, you have a conversation with it to write code together. The AI knows syntax, algorithms, common solutions. You know what you want to make and why.

The result is genuinely collaborative. You see every line of code. You can change anything. When something breaks, you debug it together. When something works, you understand why.

I chose to teach vibecoding through shaders—small programs that generate visual output in real time. Shaders are compact (often under 100 lines), universal (the same code runs in web browsers, game engines, and VJ software), and powerful enough to create professional-quality visual work. They're also unfamiliar to most artists, which levels the playing field. Everyone starts from zero.

In class, students describe what they want to see: "A swirling pattern of dots, organized by harmonics, with color shifting across the frame." Then they work with Claude or ChatGPT to write the shader that produces it. When the result isn't right—and it often isn't at first—they iterate. They learn to say things like "the gradient should go left to right, not top to bottom" or "I think we're using the wrong noise algorithm."

This is the opposite of the prompt lottery. Every choice belongs to the student. The AI contributes knowledge; the student contributes intention.

---

## New tools generate new images

There's a historical parallel here that clarifies what vibecoding actually is.

In his 1970 book *Expanded Cinema*, Gene Youngblood wrote about the experimental filmmaker Pat O'Neill: "New tools generate new images. In the historical context of image-making, the cinema is a new tool." O'Neill, a sculptor by training, found unique possibilities in cinema for exploring perceptual concepts he'd been applying to physical installations.

But O'Neill didn't just point a camera and shoot. He worked through highly technical processes: high-contrast bas-relief, positive/negative bi-pack printing, image "flopping" to create Rorschach-like mirror effects. He named his film *7362* after the high-speed Kodak emulsion on which it was shot—emphasizing the purely cinematic, purely technical nature of the work. He was, as Youngblood put it, a poet of "very technical chemistry and cinematic machines."

This is the better parallel for vibecoding. Belson worked more directly—paint, light, camera, vision. O'Neill worked *through* technical systems that required their own specialized knowledge. The optical printer and the contact printer were mediating layers between his vision and the final image. He had to learn their language to realize what he saw in his mind.

Claude is the new optical printer. Shaders are the new emulsion. The artist still provides the vision—the swirling forms, the color relationships, the rhythm—but the realization happens through technical processes that require vocabulary and understanding. You learn to speak in signed distance functions and noise algorithms the way O'Neill learned emulsion speeds and bi-pack registration.

The difference from Midjourney or Runway is structural. Those tools skip the technical mediation entirely. You describe a finished image; you receive a finished image. There's no contact printer to master, no chemistry to understand. With vibecoding, the technical layer remains—you're just learning it in conversation rather than alone in a darkroom.

---

## The grain of the medium

Every medium leaves traces of its process. CycleGAN has its characteristic smearing. Stable Diffusion has the uncanny smoothness, the melted hands, the watermark ghosts. What are the tells of vibecoded work?

O'Neill didn't hide the artifacts of his process—he foregrounded them. He named his film after the Kodak 7362 emulsion. The grain structure, the tonal response, the way the stock handled high contrast—these weren't incidental. They were the medium declaring itself.

The artifacts of *7362* were traceable: the physical texture of silver halide crystals in the high-speed stock; the flattening of tonal range into stark graphic shapes through high-contrast processing; the halos and color fringing from bi-pack registration; the accumulated fingerprint of each pass through the optical printer. O'Neill learned to work with these artifacts, to push the contrast until the nude figure became "as mechanical as the machinery." The artifacts weren't mistakes to be corrected. They were the vocabulary of the medium.

Vibecoding has its own artifacts, and they work similarly:

| O'Neill / Film | Vibecoding / Shaders |
|----------------|---------------------|
| Emulsion grain (7362 stock) | Training data density (where LLMs are confident) |
| High-contrast processing | Convergence toward common solutions |
| Bi-pack registration | The "seams" where different code patterns meet |
| Optical printing generations | Iteration artifacts—each conversation round shaping the code |
| Chemical color response | Familiar aesthetic patterns, standard palettes |

The crucial difference from Midjourney or Stable Diffusion: those artifacts are buried in latent space. You can't trace them, can't manipulate them, can't name your work after them. The artifact is disconnected from any process you control.

With vibecoding, like with O'Neill's optical printing, the artifacts are in the code. You can see the function Claude suggested. You can decide whether the noise algorithm is a feature or a crutch. You can name your shader after the technique the way O'Neill named his film after the emulsion.

The question for the vibecoding artist becomes the same question O'Neill faced: Do you work with the grain of the medium or against it? And can you tell the difference?

> **Sidebar: The Artifacts of Shader Code**
>
> Vibecoded shaders have their own characteristic "grain," shaped by where LLM training data is densest. Much of that density comes from one source: **Inigo Quilez**, a former Pixar engineer whose website and Shadertoy contributions have become the de facto curriculum for real-time graphics. His smooth minimum function, his cosine color palettes, his signed distance function library—these appear in nearly every shader tutorial online.
>
> **Convergence toward common solutions.** LLMs suggest what's well-documented. Ask for raymarching, and you'll get the standard setup. Ask for blending shapes, and you'll get Quilez's smooth min. Vibecoded work clusters around these known-good solutions because that's where the training data is dense. The "false summit" problem becomes an aesthetic artifact—you end up where many others got stuck.
>
> **The Book of Shaders aesthetic.** Since so much shader education flows through the same sources, there's a recognizable look: smooth signed distance functions, fbm noise layered in particular ways, the characteristic glow of emission effects. Not wrong, but familiar.
>
> **Absence of idiosyncrasy.** Hand-tuned shaders often have quirks—specific magic numbers, odd optimizations, accidents that became features. Vibecoded shaders might be "correct" in a generic way, lacking the weird specificity that comes from years of wrestling with a medium. The code is clean because it came from documentation, not from struggle.
>
> **Over-smoothness.** Shaders lean toward smooth mathematical functions by nature. Add an LLM's preference for well-behaved solutions, and you get work that might lack grit, grain, the productive noise of imperfection.
>
> But here's the difference from generative AI artifacts: the code is visible. You can see exactly where the artifacts come from and choose to keep or change them. The Stable Diffusion user can't edit the latent space. The vibecoder can open the shader and rewrite the noise function.
>
> So maybe the deepest artifact of vibecoding isn't visual—it's epistemological. The tell is whether the artist can explain every choice, or whether certain passages remain opaque even to them. "Claude suggested this and it worked" is its own kind of artifact—one you can choose to investigate or leave alone.

---

## Friction is the point

One of my students mentioned spending eight hours prompting an AI image generator, feeling more exhausted than satisfied. That's friction without payoff—effort spent spinning a slot machine.

Vibecoding involves friction too, but friction of a different kind. When the code breaks, you have to figure out why. When the AI suggests a solution that doesn't quite work, you have to redirect. You learn to recognize what I call "false summits"—moments when the AI leads you in circles because many people got stuck on the same problem before you.

This difficulty isn't a flaw. It's where judgment forms.

When friction disappears entirely—when you type a sentence and receive a finished painting—thinking doesn't speed up. It evaporates. You've delegated not just the labor but the decisions that make the labor meaningful.

Vibecoding keeps you in the decision-making seat. The AI handles what it's good at (remembering syntax, suggesting approaches, catching errors). You handle what humans are good at (knowing what you want, recognizing when something feels right, making aesthetic choices that reflect your own sensibility).

---

## The Luddite stance

On that first day of class, I also talked about the Luddites. Most people use "Luddite" as an insult—someone irrationally opposed to technology. But the actual Luddites were highly skilled weavers who understood exactly how the new machines worked. That's why they knew how to break them.

In 1812, the poet Lord Byron stood up in Parliament to defend them. These people are losing their livelihoods, he argued. Their only form of protest is breaking the machines. We shouldn't be executing them for it.

Parliament ignored him. But his speech helped catalyze the Romantic movement—a cultural response to industrialization that insisted on the value of individual experience and creative labor.

I think artists today can take a similar stance. Not refusal. Not uncritical adoption. Understanding. Learn how these systems work. See the seams. Then decide, from a position of knowledge, how or whether to use them.

---

## Practice, not answers

My course doesn't resolve the ethics of AI. Neither does vibecoding as a method. The students who worry about data exploitation, job displacement, and the concentration of power in a handful of companies—they're right to worry. Those problems are real and won't be solved by learning to write shaders.

But vibecoding offers something else: a practice. A way to engage with AI that doesn't require you to either reject it entirely or surrender to it. You stay in conversation. You keep making choices. You maintain the friction that lets judgment form.

"We don't need new answers," a colleague said to me recently. "We need new practices."

That's what I'm trying to teach. Not a position on AI, but a way of working that keeps the questions alive while still making things. Thinking is a practice. This is one way to keep practicing.

---

## Author Bio

Douglas Goodwin teaches experimental writing and creative technology at UCLA's Design Media Arts program. He has used computational methods to generate text and visual work for over two decades.

---

## Notes

- Draft prepared for The Conversation
- Structure: starts with teaching experience, ends with critical stance
- Incorporates student voices from CalArts vibecoding course (Winter 2026)
- Key themes: finished-output problem, friction as knowledge, practice vs. delegation, the Luddite parallel
- Added Gene Youngblood on Pat O'Neill as historical precedent (technical mediation, "new tools generate new images")
- Added "The grain of the medium" section comparing vibecoding artifacts to O'Neill's film stock artifacts
- Added sidebar on shader-specific artifacts and Inigo Quilez (Pixar)
