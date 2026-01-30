# **WHITNEY ETUDE: Harmonic Oscillation**
### Week 3–4 (After Oscillation Toolkit, before Noise)
**Due:** End of Week 4  
**Weight:** Part of weekly exercises (8%)

***

## **Assignment Brief**

John Whitney used simple harmonic motion as his primary compositional tool. By layering multiple oscillators at different frequencies and phase relationships, he created the optical equivalent of musical harmony—what he called "visual music."

Your task: **Reconstruct the feeling of Whitney's harmonic principle in a single GLSL shader.**

You won't replicate a specific piece. Instead, you'll work from a *description* of harmonic motion and negotiate with an LLM toward a shader that embodies it.

***

## **The Constraint**

Pick one of these Whitney-inspired vibe briefs:

1. **Two-Orbit Precession**  
   A fast, tight circle orbits a slower, larger circle. The colors shift through a cycle while the orbits interact.

2. **Concentric Harmonic Pulse**  
   Multiple rings expand and contract from the center at different speeds, creating an interference pattern. Some rings are "in phase" (synchronized), others offset.

3. **Spiraling Descent**  
   A point spirals outward while rotating inward—like watching a vinyl record or a hypnotic spiral. The motion should feel controlled, not random.

4. **Lissajous Landscape**  
   Two independent oscillators control X and Y motion, creating a parametric curve that changes shape as ratios shift. Think of it as a living, breathing graph.

***

## **Your Process**

### Phase 1: Describe (1–2 hours)

Choose your vibe. Write 3–5 sentences describing:
- **What oscillates?** (point, circle, rings, curve)
- **How many independent rhythms?** (fast / slow, primary / secondary)
- **What is the *feel*?** (meditative, mechanical, liquid, hypnotic)
- **Color behavior:** Does it change, pulse, cycle?

*Example:* "I want concentric rings expanding from the center. Two rings pulse in sync (the main beat), while a third one moves at half-speed, creating a slow interference pattern. The colors should shift through warm tones as the rings expand, cool tones as they contract."

Save this description.

### Phase 2: Code with LLM (2–3 hours)

Using Claude Code or similar:

1. **Start with understanding:**  
   > "In GLSL, how do I create a circle at the center that oscillates in size based on time? Show me a simple example."

2. **Build your first oscillator:**  
   > "Write a shader that draws a circle at the center whose radius pulses between 0.1 and 0.5 over 3 seconds. Use `sin(time)` to control it."

3. **Add a second oscillator at a different rhythm:**  
   > "Add a second circle that oscillates at twice the frequency of the first. Make it a different color and slightly offset from the center (maybe 0.2 units to the right)."

4. **Refine the motion:**  
   > "The motion feels jerky. Smooth it out using `smoothstep()` or `mix()` instead of sharp transitions. Also, slow the whole thing down by 0.5x."

5. **Adjust for your vibe:**  
   > "The colors are too bright. Replace them with a cosine palette that cycles through deep blues and warm oranges as time progresses."

6. **Document each prompt.** Keep a text file with the prompt and one or two lines about what you learned.

### Phase 3: Iterate by Hand (1–2 hours)

Once you have working code:
- Change a parameter manually (e.g., frequency ratio, color offset, circle position) and observe the result.
- Ask yourself: Does this match my vibe description? If not, what's off?
- Make one intentional tweak: "That's good, but I want the second oscillator to move *slower*" or "The color cycle is too fast."
- Use the LLM for one final refinement if needed.

***

## **What to Submit**

1. **Your description** (3–5 sentences, saved in a comment at the top of your shader)
2. **The shader code** (`whitney_etude.glsl`)
3. **Prompt log** (a `.txt` file with your 5–6 key prompts and one-line reflections on each)
4. **A 15–30 second MP4 recording** (press **R** in the playground)

***

## **Evaluation Rubric**

| Criterion              | Excellent (10–9)                                             | Good (8–7)                                                   | Adequate (6–5)                                               | Needs Work (4–0)                                             |
| ---------------------- | ------------------------------------------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ |
| **Vibe Match**         | The shader clearly embodies the described harmonic behavior. Motion feels intentional and the described feeling comes across. | The core idea is there, but one element (rhythm, color, composition) is off or underdeveloped. | The shader works technically, but the vibe is unclear or doesn't match the brief. | Shader runs but doesn't relate to the description or feels random. |
| **Harmonic Integrity** | Two or more distinct oscillators interact clearly. Frequency relationships or phase offsets are audible as visual rhythm. | Two oscillators present, but their relationship is subtle or not well-defined. | One main oscillation; second oscillator is minimal or unclear. | Only one oscillation or no clear periodic motion.            |
| **LLM Collaboration**  | Prompts are specific and progress logically. Reflections show learning (e.g., "I didn't know how to smooth transitions; using `smoothstep()` made a huge difference"). | Prompts are adequate. Reflections are present but brief.     | Prompts are vague or repetitive. Reflections are minimal.    | Few prompts documented or reflections are absent.            |
| **Code Legibility**    | Code is readable. Variables are named meaningfully. Comments explain key functions or parameters. | Code works. Some comments present. Variable names are mostly clear. | Code works but is hard to follow. Minimal comments.          | Code is illegible or non-functional.                         |

***

***

# **VISUAL MUSIC RESPONSE: The Whitney Homage**
### Week 7–10 (Final Project Option)
**Due:** End of Week 10  
**Weight:** Final Project (40%)

***

## **Assignment Brief**

In *Digital Harmony*, John Whitney wrote: "Motion is the only thing that makes sense of form." He believed that animated form itself—mathematical, precise, and layered—could express what only music had expressed before: the experience of harmony, rhythm, tension, and resolution.

Your task: **Create an original shader that is in conversation with Whitney's visual music tradition—but that uses techniques or ideas that Whitney *couldn't* have made.**

This is not pastiche. This is a homage that breaks the form.

***

## **Required Elements**

Your shader must include:

1. **At least one explicit Whitney lineage element**—choose *one* of these:
   - Harmonic oscillators (from Whitney Etude or similar)
   - Parametric curves or Lissajous figures
   - Concentric or radial symmetry with rotation
   - Cosine-palette color cycling
   - Iterative or recursive geometry (fractals)
   - Mechanical precision + organic variation

2. **At least one deliberate departure** from Whitney—something that **couldn't** exist in analog/mechanical form:
   - Noise-driven chaos layered over harmonic order
   - Screen-space distortions or raymarched 3D space
   - Procedural audio-reactivity (if you integrate FFT)
   - Constraint-based or impossible geometry (SDFs)
   - Multi-octave fractals or deep iteration
   - Stochastic or probabilistic layering

3. **A clear emotional register**—the piece should feel like *something*:
   - Meditative, tense, playful, transcendent, unsettling, celebratory, etc.
   - Your mood choice should be evident from motion, color, and composition.

4. **Intentional composition**:
   - Foreground, subject, and background or atmosphere (as in Week 9)
   - Visual hierarchy—the viewer's eye knows where to look
   - A sense of progression or development over time (not static; not random noise)

***

## **Your Process**

### Phase 1: Lineage Statement (1–2 hours)

Write a **1-page document** that addresses:

- **Which Whitney idea are you starting from?** (Oscillators? Parametric curves? Radial symmetry?) Include one or two sentences from Whitney's writing or your own analysis of why that idea appeals to you.
  
- **How does your shader embody that idea?** Be specific. If you chose harmonic oscillators, name the frequencies and phase relationships. If you chose parametric curves, describe the curve type (Lissajous, spiral, etc.).

- **What are you breaking?** Describe the deliberate departure. Explain what would have been impossible in Whitney's era and why *you* chose to add it.

- **Why does the break matter to your piece?** How does the impossible element change the feeling or meaning of the harmonic foundation?

*Example:*  
> "I'm starting with Whitney's idea of concentric circles oscillating at harmonic ratios—a visual analog to musical chords. Specifically, I'm using 1:2:3 frequency ratios (fundamental, octave, twelfth). My departure: I'm layering 3D Perlin noise across these circles, so the harmonic order gets disrupted by controlled chaos. The noise doesn't overwhelm the oscillations—it breathes with them. This feels more like watching a machine malfunction in a beautiful, musical way than a perfectly wound mechanical toy. That tension between order and decay is what I'm after."

***

### Phase 2: Build the Shader (6–8 hours over 4 weeks)

You've already learned most of what you need. Use the LLM strategically:

**Weeks 7–8:** Establish the Whitney foundation
- Get your primary oscillators, curves, or geometry working cleanly
- Get the color palette and overall tone dialed in
- Prompts: "How do I create three concentric circles at frequencies 1, 2, 3?" or "Build me a parametric Lissajous curve with interactive frequency ratios."

**Weeks 8–9:** Layer the departure
- Integrate noise, distortion, or 3D geometry
- Make sure the departure *enhances* the foundation, doesn't replace it
- Prompts: "How do I add 2D noise to this oscillating circle without destroying the oscillation?" or "Layer a raymarched sphere behind my fractals."

**Week 10:** Compose and refine
- Add your three visual layers (foreground, subject, background)
- Adjust timing, color grading, emphasis
- Prompts: "Add fog/distance-based color shift to sell depth" or "The motion is too fast—slow down the main oscillation by 0.5x."

**Document your major prompts** (at least 8–10) and reflections.

***

### Phase 3: Final Polish (2–3 hours)

- Record a 30–60 second MP4 of the final shader
- Make sure the piece runs smoothly and the emotional register is clear
- Optional: Write a 3–5 minute artist statement (not required, but appreciated in critique)

***

## **What to Submit**

1. **`whitney_homage.glsl`** – Your final shader code (well-commented)
2. **`lineage_statement.md`** – Your 1-page reflection (750–1000 words)
3. **`prompt_log.txt`** – Your major prompts and one-line reflections (8–10 entries minimum)
4. **`whitney_homage.mp4`** – A 30–60 second recording
5. **Optional: `artist_statement.md`** – Your 3–5 minute reflection on the piece

***

## **Evaluation Rubric**

| Criterion                      | Excellent (9–10)                                             | Good (7–8)                                                   | Adequate (5–6)                                               | Needs Work (0–4)                                             |
| ------------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ |
| **Lineage Clarity**            | The Whitney element is obvious and clearly articulated in code and statement. Specific technical choices (frequencies, curve types, symmetries) show understanding. | The Whitney influence is recognizable. Statement identifies the core idea but lacks some technical specificity. | The Whitney connection is vague or overstated. Lineage statement is underdeveloped. | No clear lineage or lineage statement is absent/insufficient. |
| **Intentional Departure**      | The break from Whitney is audible/visible and meaningfully integrated. It doesn't replace the harmonic foundation; it complicates or extends it. | The departure is present and visible, but could be more deeply integrated or conceptually justified. | The departure exists but feels tacked on or underdeveloped.  | No deliberate departure or it contradicts the foundation.    |
| **Emotional Register**         | The piece has a clear, compelling mood. Motion, color, and composition all reinforce the same feeling. Critique will understand what the artist intended. | The mood is identifiable. Most elements (motion, color, composition) support it; one may be unclear. | The mood is ambiguous or inconsistent across elements.       | No discernible emotional intent. Feels random or incoherent. |
| **Composition & Depth**        | Foreground, subject, background are visually distinct. Eye movement is guided. Sense of progression or development over time is clear. | Three layers are present but may blend or feel less distinct. Development is present but subtle. | Composition is flat or lacks clear hierarchy. Development is minimal. | Poor or absent composition. No sense of depth or progression. |
| **Technical Ambition**         | Shader combines multiple sophisticated techniques (raymarching + noise + oscillators, or fractals + color grading + layers). Code is clean and efficient. | Two or three advanced techniques combined competently. Code is readable with minor inefficiencies. | One advanced technique or multiple basics competently executed. Code is functional. | Limited technical scope or code is difficult to follow.      |
| **LLM Collaboration Evidence** | Prompts show clear progression from concept to refinement. Reflections reveal learning and iteration (e.g., "I misunderstood how domain repetition works; the LLM's second explanation made it click"). | Prompts present and generally logical. Reflections show engagement and some learning. | Prompts are present but generic or repetitive. Reflections are minimal. | Few or no prompts documented. Collaboration process is opaque. |
| **Code & Documentation**       | Code is well-commented. Variable names are clear. Shader structure is easy to follow. Comments explain non-obvious choices. | Code is mostly clear. Comments are present for key sections. Some variable names could be more descriptive. | Code runs but is hard to follow. Minimal or unclear comments. | Code is illegible or insufficiently commented.               |

***

## **Critique Prompts** (for discussion on Week 10)

Be prepared to discuss:

- What did you learn about Whitney's harmonic thinking by trying to recreate it?
- Why did you choose the specific departure you did? What were other options you considered?
- What surprised you about the LLM collaboration? What did it misunderstand? What did that teach you?
- If you had 2 more weeks, what would you change?
- How does this piece relate to your broader artistic interests?

***

***

## **Notes on Implementation**

Both assignments are designed to fit your existing philosophy:

- **They start from description, not imitation.** Students articulate what they want to express (vibe brief, lineage statement) *before* they code. This aligns with your principle: "if you can describe a visual idea in words, you can express it in GLSL."

- **LLM collaboration is documented as learning.** The prompt logs become evidence of thinking, not cheating. Students reflect on what the LLM got wrong, what it clarified, what they discovered.

- **Whitney is a lineage, not a cage.** The homage assignment explicitly requires a break—it's not about reproducing Whitney perfectly, but understanding him well enough to move beyond him.

- **Grading echoes your existing rubric** (artistic merit, technical ambition, learning demonstrated). The only additions are "vibe match" and "lineage clarity," which are specific to these Whitney-focused pieces.

Feel free to adjust tone, language, or rubric weights to match your voice. Want me to tweak anything?

Sources
[1] SYLLABUS.md https://ppl-ai-file-upload.s3.amazonaws.com/web/direct-files/attachments/9784680/78bf5880-d89a-4819-bbf9-3ff1f6592ccf/SYLLABUS.md