# Shader Exercises: Learning to Code with Visuals

These exercises progress from simple modifications to writing original code. Each exercise has starter code with `// TODO` comments marking what you need to complete.

**All exercises are available in the Exercises tab** — run `npm run dev` and navigate to `/exercises/`. Use Left/Right arrow keys to step through them sequentially.

**How to use these:**
1. Open the Exercises tab in your browser
2. Open the matching `.glsl` file in `src/shaders/exercises/` in your editor
3. Read the TODO comments and the guidance below
4. Edit the file, save, and see instant results (hot reload)

**Each exercise below includes a "By Hand" section** — a walkthrough of the concepts and thinking needed to solve it without an LLM.

---

## Level 1: Change Values

No new code — just modify existing numbers to understand cause and effect.

### Exercise 1.1: Color Mixing

**File:** `src/shaders/exercises/ex1-1-color-mixing.glsl`

```glsl
vec3 color = vec3(1.0, 0.0, 0.0);  // Currently red
```

**Goal:** Change the numbers to make pure blue, then yellow, then your favorite color.

**By Hand:**

`vec3(r, g, b)` takes three numbers from `0.0` to `1.0` — red, green, and blue. These work like light mixing, not paint mixing:

| Color | R | G | B |
|-------|---|---|---|
| Red | 1.0 | 0.0 | 0.0 |
| Green | 0.0 | 1.0 | 0.0 |
| Blue | 0.0 | 0.0 | 1.0 |
| Yellow | 1.0 | 1.0 | 0.0 |
| Cyan | 0.0 | 1.0 | 1.0 |
| Magenta | 1.0 | 0.0 | 1.0 |
| White | 1.0 | 1.0 | 1.0 |
| Black | 0.0 | 0.0 | 0.0 |

To make any color, think: "How much red light? How much green? How much blue?" For a soft teal, you might try `vec3(0.2, 0.7, 0.6)`.

---

### Exercise 1.2: Gradient Position

**File:** `src/shaders/exercises/ex1-2-gradient-position.glsl`

```glsl
float brightness = uv.x;
```

**Goal:** Swap `uv.x` for `uv.y`, try `(uv.x + uv.y) / 2.0`, try `1.0 - uv.x`.

**By Hand:**

`uv` is the position of the current pixel, normalized to 0-1:
- `uv.x` = 0 at the left edge, 1 at the right edge
- `uv.y` = 0 at the bottom, 1 at the top

When you write `float brightness = uv.x`, each pixel's brightness equals its horizontal position. The result: a gradient from black (left) to white (right).

- `uv.y` makes the gradient vertical (black at bottom, white at top)
- `(uv.x + uv.y) / 2.0` averages both axes — a diagonal gradient
- `1.0 - uv.x` reverses the gradient (white at left, black at right) because subtracting from 1 flips the range

---

## Level 2: Assignment & Sequence

Learn that code runs top to bottom, and variables store values for later use.

### Exercise 2.1: Store and Reuse

**File:** `src/shaders/exercises/ex2-1-store-and-reuse.glsl`

**Goal:** Create three `float` variables for red, green, and blue, then use them in `gl_FragColor`.

**By Hand:**

In GLSL, you declare a variable with its type and name, then assign a value:

```glsl
float red = uv.x;      // red increases from left to right
float green = uv.y;    // green increases from bottom to top
float blue = 0.5;      // blue stays constant everywhere
```

After creating these three lines, delete the `gl_FragColor = vec4(0.0);` line and uncomment the one above it:

```glsl
gl_FragColor = vec4(red, green, blue, 1.0);
```

The result: a colorful gradient where position determines the red and green channels, with a constant blue tint. The bottom-left corner is dark blue-ish (low red, low green, 0.5 blue). The top-right is white-ish (high red, high green, 0.5 blue).

---

### Exercise 2.2: Order Matters

**File:** `src/shaders/exercises/ex2-2-order-matters.glsl`

```glsl
value = uv.x;        // Line A: set value to horizontal position (0 to 1)
value = value * 2.0;  // Line B: double it (0 to 2)
value = value - 0.5;  // subtract 0.5 (-0.5 to 1.5)
```

**Goal:** Predict the output, then swap Lines A and B and predict again.

**By Hand:**

Trace through the math for a pixel at `uv.x = 0.25`:
- Original order: `0.25` → `0.5` → `0.0` (just barely black)
- Swapped (multiply first, then set): `0.0` → `0.0` → `0.25` → result is `0.25 - 0.5 = -0.25`

Wait — if you swap A and B, Line B now runs first: `value = value * 2.0` multiplies `0.0 * 2.0 = 0.0` (value was initialized to 0). Then Line A overwrites it with `uv.x`. So the multiply has no effect and you get `uv.x - 0.5`.

The lesson: operations only matter if they act on meaningful data. Multiplying zero is always zero. The *order* of assignments determines which operations actually contribute to the result.

---

## Level 3: Built-in Functions

Learn to use functions that transform values.

### Exercise 3.1: The sin() Wave

**File:** `src/shaders/exercises/ex3-1-sin-wave.glsl`

```glsl
float wave = sin(uv.x * 10.0);
wave = (wave + 1.0) / 2.0;
```

**Goal:** Change `10.0` to other values, then add `u_time` to animate.

**By Hand:**

`sin()` returns a smooth wave between -1 and 1. The number multiplied by `uv.x` controls *frequency* — how many wave cycles fit across the screen:
- `sin(uv.x * 1.0)` — barely one cycle (smooth gradient)
- `sin(uv.x * 10.0)` — 10 cycles (~10 stripes)
- `sin(uv.x * 50.0)` — 50 cycles (dense stripes)

The `(wave + 1.0) / 2.0` converts the -1...1 range to 0...1, because colors can't be negative.

To animate, add `u_time` inside the `sin()`:

```glsl
float wave = sin(uv.x * 10.0 + u_time);
```

This shifts the wave's phase over time, making stripes scroll. `u_time` increases steadily, so the `+` shifts the wave to the left. Use `- u_time` to scroll right. Multiply `u_time` by a factor to control speed: `u_time * 3.0` is triple speed.

---

### Exercise 3.2: The mix() Blend

**File:** `src/shaders/exercises/ex3-2-mix-blend.glsl`

```glsl
vec3 color = mix(colorA, colorB, 0.5);
```

**Goal:** Replace `0.5` with `uv.x`, `uv.y`, or `(uv.x + uv.y) / 2.0`.

**By Hand:**

`mix(a, b, t)` does linear interpolation:
- `t = 0.0` → returns `a` (100% red)
- `t = 1.0` → returns `b` (100% blue)
- `t = 0.5` → returns the average (purple)

When `t` is a constant, the whole screen is one color. When `t` varies per pixel, you get a gradient:

- `mix(colorA, colorB, uv.x)` — red on the left, blue on the right, blending across
- `mix(colorA, colorB, uv.y)` — red at the bottom, blue at the top
- `mix(colorA, colorB, (uv.x + uv.y) / 2.0)` — diagonal gradient

You can also change `colorA` and `colorB` to any colors you want. Try `vec3(1.0, 0.8, 0.0)` (gold) and `vec3(0.2, 0.0, 0.4)` (deep purple).

---

### Exercise 3.3: The step() Cutoff

**File:** `src/shaders/exercises/ex3-3-step-cutoff.glsl`

```glsl
float cutoff = step(0.5, uv.x);
```

**Goal:** Move the edge, make it horizontal, combine two `step()` calls.

**By Hand:**

`step(edge, x)` is the simplest decision function:
- If `x < edge` → returns `0.0` (black)
- If `x >= edge` → returns `1.0` (white)

It's a hard binary cutoff. Changing the edge value moves where the split happens:
- `step(0.3, uv.x)` — 30% black, 70% white
- `step(0.7, uv.x)` — 70% black, 30% white

For a horizontal split, use `uv.y`:
```glsl
float cutoff = step(0.5, uv.y);
```

To make a corner (only the top-right quadrant is white), multiply two step calls:
```glsl
float corner = step(0.5, uv.x) * step(0.5, uv.y);
```
Multiplication works like AND: both must be 1.0 for the result to be 1.0.

---

## Level 4: Shapes with Math

Shapes are just math questions: "is this pixel inside or outside?"

### Exercise 4.1: Circle

**File:** `src/shaders/exercises/ex4-1-circle.glsl`

```glsl
float dist = length(uv - center);
float circle = 0.0;  // Replace this line
```

**Goal:** Use `step()` to turn the distance into a circle.

**By Hand:**

`length(uv - center)` measures the distance from the current pixel to the center point. Pixels near the center have a small distance; pixels far away have a large one.

A circle is all pixels whose distance is *less than* the radius. Use `step()` to ask "is distance >= radius?":

```glsl
float circle = 1.0 - step(radius, dist);
```

Why `1.0 -`? Because `step(radius, dist)` returns 1 when `dist >= radius` (outside the circle). We want the opposite: 1 inside, 0 outside. So we flip it.

To change the circle: modify `center` to move it, modify `radius` to resize it. Try `vec2(0.3, 0.7)` for a circle in the top-left area.

---

### Exercise 4.2: Multiple Circles

**File:** `src/shaders/exercises/ex4-2-multiple-circles.glsl`

```glsl
float circle2 = 0.0;  // TODO: Calculate like circle1
float circle3 = 0.0;  // TODO: Calculate like circle1
```

**Goal:** Complete circle2 and circle3 using the same pattern as circle1.

**By Hand:**

Circle1 is already done: `1.0 - step(radius, length(uv - center1))`. Apply the same formula with different centers:

```glsl
float circle2 = 1.0 - step(radius, length(uv - center2));
float circle3 = 1.0 - step(radius, length(uv - center3));
```

The `max()` at the end combines them — if *any* circle covers a pixel, it's white. This is a *union* of shapes. You could also try `circle1 + circle2 + circle3` for additive blending, but `max()` avoids values exceeding 1.0.

Try changing the centers to make a triangle formation: `vec2(0.5, 0.7)`, `vec2(0.3, 0.3)`, `vec2(0.7, 0.3)`.

---

### Exercise 4.3: Rectangle

**File:** `src/shaders/exercises/ex4-3-rectangle.glsl`

```glsl
float insideRight = 0.0;   // TODO: 1 if we're before the right edge
float insideBottom = 0.0;  // TODO: similar for bottom
float insideTop = 0.0;     // TODO: similar for top
```

**Goal:** Complete the four edge checks, then multiply them together.

**By Hand:**

A rectangle means the pixel must pass four tests:
1. Past the left edge: `step(left, uv.x)` → 1 when `uv.x >= 0.3`
2. Before the right edge: `1.0 - step(right, uv.x)` → 1 when `uv.x < 0.7`
3. Above the bottom edge: `step(bottom, uv.y)` → 1 when `uv.y >= 0.4`
4. Below the top edge: `1.0 - step(top, uv.y)` → 1 when `uv.y < 0.6`

The trick for "before" an edge: `step()` returns 1 when you're *past* it, so `1.0 - step()` returns 1 when you're *before* it.

```glsl
float insideRight = 1.0 - step(right, uv.x);
float insideBottom = step(bottom, uv.y);
float insideTop = 1.0 - step(top, uv.y);
```

Multiplying all four together acts as AND logic — the pixel is white only if all four conditions are true.

---

## Level 5: Animation with Time

Use `u_time` to create movement.

### Exercise 5.1: Pulsing Circle

**File:** `src/shaders/exercises/ex5-1-pulsing-circle.glsl`

```glsl
float radius = 0.3;  // Replace with animated version
```

**Goal:** Make the radius change over time using `sin(u_time)`.

**By Hand:**

`sin(u_time)` oscillates between -1 and 1. To convert this into a useful radius range:

1. Pick a base radius (the center of the oscillation): `0.25`
2. Pick an amplitude (how much it varies): `0.15`
3. Combine: `0.25 + 0.15 * sin(u_time)`

This oscillates between `0.25 - 0.15 = 0.1` and `0.25 + 0.15 = 0.4`.

```glsl
float radius = 0.25 + 0.15 * sin(u_time);
```

The general formula for oscillating any value: `center + amplitude * sin(u_time * speed)`. Multiply `u_time` by a larger number to pulse faster.

---

### Exercise 5.2: Moving Circle

**File:** `src/shaders/exercises/ex5-2-moving-circle.glsl`

```glsl
vec2 center = vec2(0.5, 0.5);  // Replace with animated version
```

**Goal:** Make the center trace a circular path.

**By Hand:**

`sin()` and `cos()` together produce circular motion — this is the fundamental connection between trigonometry and circles:

```glsl
vec2 center = vec2(
    0.5 + 0.2 * sin(u_time),
    0.5 + 0.2 * cos(u_time)
);
```

- `0.5` is the center of the path (middle of the screen)
- `0.2` is the orbit radius (how far the circle travels)
- `sin` for x and `cos` for y traces a circle because that's the definition of a circle in polar coordinates

Try different orbit sizes, or use different speeds for x and y (`sin(u_time * 2.0)` for x, `cos(u_time)` for y) to get a Lissajous figure instead of a circle.

---

### Exercise 5.3: Color Cycle

**File:** `src/shaders/exercises/ex5-3-color-cycle.glsl`

```glsl
float red = 0.5;    // TODO: (sin(u_time) + 1.0) / 2.0
float green = 0.5;  // TODO: (sin(u_time * 1.3) + 1.0) / 2.0
float blue = 0.5;   // TODO: (sin(u_time * 1.7) + 1.0) / 2.0
```

**Goal:** Animate each color channel at a different speed.

**By Hand:**

Each channel oscillates independently. The `+ 1.0) / 2.0` converts from -1...1 to 0...1 (colors must be positive):

```glsl
float red   = (sin(u_time) + 1.0) / 2.0;
float green = (sin(u_time * 1.3) + 1.0) / 2.0;
float blue  = (sin(u_time * 1.7) + 1.0) / 2.0;
```

The different multipliers (1.0, 1.3, 1.7) mean the channels go in and out of phase with each other. This creates a smoothly cycling color palette. If all three used the same speed, you'd just get a brightness pulse (grayscale).

Try more dramatic differences: `1.0, 2.0, 3.0`. Or add offsets: `sin(u_time + 1.0)` to shift the starting phase.

---

## Level 6: Conditionals & Logic

Make decisions in code.

### Exercise 6.1: Two Halves

**File:** `src/shaders/exercises/ex6-1-two-halves.glsl`

```glsl
if (uv.x < 0.5) {
    color = vec3(0.0);  // TODO: Set to red
} else {
    color = vec3(0.0);  // TODO: Set to blue
}
```

**Goal:** Set red and blue colors in the if/else branches.

**By Hand:**

This is the simplest conditional — split the screen in half. Replace the `vec3(0.0)` values:

```glsl
if (uv.x < 0.5) {
    color = vec3(1.0, 0.0, 0.0);  // Red on the left
} else {
    color = vec3(0.0, 0.0, 1.0);  // Blue on the right
}
```

`vec3(1.0, 0.0, 0.0)` is red (full red channel, no green, no blue).

Note: In shaders, `if` statements work but aren't always the best approach. The GPU prefers math like `step()` and `mix()` because it processes many pixels in parallel. But for learning, `if` is perfectly clear and fine to use.

---

### Exercise 6.2: Four Quadrants

**File:** `src/shaders/exercises/ex6-2-four-quadrants.glsl`

```glsl
color = vec3(uv.x, uv.y, 0.0);  // Replace with your quadrant logic
```

**Goal:** Color four quadrants: top-left red, top-right green, bottom-left blue, bottom-right yellow.

**By Hand:**

Nest two levels of `if` statements — first split left/right, then split top/bottom within each:

```glsl
if (uv.x < 0.5) {
    // Left half
    if (uv.y < 0.5) {
        color = vec3(0.0, 0.0, 1.0);  // Bottom-left: blue
    } else {
        color = vec3(1.0, 0.0, 0.0);  // Top-left: red
    }
} else {
    // Right half
    if (uv.y < 0.5) {
        color = vec3(1.0, 1.0, 0.0);  // Bottom-right: yellow
    } else {
        color = vec3(0.0, 1.0, 0.0);  // Top-right: green
    }
}
```

Remember that `uv.y < 0.5` is the *bottom* half (y starts at 0 at the bottom in shaders, unlike most screen coordinates).

---

## Level 7: Loops & Repetition

Repeat actions with `for` loops.

### Exercise 7.1: Row of Circles

**File:** `src/shaders/exercises/ex7-1-row-of-circles.glsl`

```glsl
float x = 0.5;  // Replace with calculated position
```

**Goal:** Space 5 circles evenly across the screen.

**By Hand:**

You need x positions at 0.1, 0.3, 0.5, 0.7, 0.9 (evenly spread with margins). The loop variable `i` goes 0, 1, 2, 3, 4. Convert it to a position:

```glsl
float x = 0.1 + fi * 0.2;
```

The math: start at `0.1`, add `0.2` for each circle. So `i=0` → `0.1`, `i=1` → `0.3`, `i=2` → `0.5`, etc.

General formula for spacing `n` items across a range: `start + fi * spacing` where `spacing = (end - start) / (n - 1)`.

To make it more interesting, try varying the y position too: `float y = 0.5 + 0.1 * sin(fi * 2.0);` creates an arc.

---

### Exercise 7.2: Grid of Circles

**File:** `src/shaders/exercises/ex7-2-grid-of-circles.glsl`

```glsl
float x = 0.0;  // TODO: Calculate based on col
float y = 0.0;  // TODO: Calculate based on row
```

**Goal:** Place circles in a 4x4 grid.

**By Hand:**

Same spacing idea as 7.1, but now applied to both axes. Convert `row` and `col` to floats and calculate positions:

```glsl
float x = 0.125 + float(col) * 0.25;
float y = 0.125 + float(row) * 0.25;
```

The math: for 4 items across a 0-1 range, each cell is `1.0 / 4.0 = 0.25` wide. The center of the first cell is at `0.125` (half a cell width). Each subsequent cell adds `0.25`.

Alternative: `float x = (float(col) + 0.5) / 4.0;` — this divides the screen into 4 columns and centers within each one. Same result, maybe clearer intent.

---

## Level 8: Functions

Organize code into reusable pieces.

### Exercise 8.1: Circle Function

**File:** `src/shaders/exercises/ex8-1-circle-function.glsl`

```glsl
float drawCircle(vec2 uv, vec2 center, float radius) {
    float dist = length(uv - center);
    return 0.0;  // Replace this
}
```

**Goal:** Complete the function so it returns 1.0 inside the circle, 0.0 outside.

**By Hand:**

You already know the circle formula from Exercise 4.1. The function just wraps it:

```glsl
float drawCircle(vec2 uv, vec2 center, float radius) {
    float dist = length(uv - center);
    return 1.0 - step(radius, dist);
}
```

The function takes in *parameters* (uv, center, radius) and returns a value. Now `main()` can call it three times with different arguments instead of repeating the same code. This is the core idea of functions: name a computation, reuse it with different inputs.

---

### Exercise 8.2: Ring Function

**File:** `src/shaders/exercises/ex8-2-ring-function.glsl`

```glsl
float drawRing(vec2 uv, vec2 center, float innerRadius, float outerRadius) {
    return 0.0;  // Replace this
}
```

**Goal:** A ring is the area between two concentric circles — subtract the inner from the outer.

**By Hand:**

Draw a big circle (outer boundary), draw a small circle (inner boundary), subtract:

```glsl
float drawRing(vec2 uv, vec2 center, float innerRadius, float outerRadius) {
    float dist = length(uv - center);
    float outer = 1.0 - step(outerRadius, dist);
    float inner = 1.0 - step(innerRadius, dist);
    return outer - inner;
}
```

`outer` is 1 everywhere inside the big circle. `inner` is 1 everywhere inside the small circle. Subtracting removes the small circle from the big one, leaving only the ring between them.

This is *constructive solid geometry* (CSG) — building complex shapes by combining simple ones. The same principle powers the raymarched 3D scenes later in the course.

---

## Challenge Projects

Combine everything you've learned. These are open-ended — the TODOs give you a starting point, but push beyond them.

### Challenge A: Traffic Light

**File:** `src/shaders/exercises/challenge-a-traffic-light.glsl`

**Goal:** Three circles stacked vertically (red, yellow, green) that cycle which one is lit.

**By Hand:**

The key pieces you need:
1. **Three circles** at `y = 0.75`, `y = 0.5`, `y = 0.25` (the `drawCircle` pattern from Ex 4.2)
2. **Time-based cycling** with `mod(u_time, 3.0)` — this gives a number that repeats 0→3
3. **Which light is on** — use `step()` to check which third of the cycle you're in:

```glsl
float cycle = mod(u_time, 3.0);
float redOn    = 1.0 - step(1.0, cycle);         // on when cycle < 1
float yellowOn = step(1.0, cycle) * (1.0 - step(2.0, cycle));  // on when 1 <= cycle < 2
float greenOn  = step(2.0, cycle);                // on when cycle >= 2
```

4. **Dim vs bright** — multiply each light shape by its on/off state, using a dim level for "off":

```glsl
float brightness = dimLevel + (1.0 - dimLevel) * onState;
```

---

### Challenge B: Loading Spinner

**File:** `src/shaders/exercises/challenge-b-loading-spinner.glsl`

**Goal:** A ring that only shows a partial arc, rotating over time.

**By Hand:**

The key new concept is `atan(y, x)`, which returns the *angle* of a pixel relative to the center (-PI to PI):

1. **Make a ring** — use the ring technique from Ex 8.2: `step()` with inner and outer radius
2. **Get the angle** — `atan(centered.y, centered.x)` gives each pixel's angle
3. **Mask part of the ring** — compare the pixel's angle to a rotating threshold:

```glsl
float ring = (1.0 - step(outerRadius, dist)) * step(innerRadius, dist);
float angle = atan(centered.y, centered.x);  // -PI to PI
float spinner = step(sin(angle - u_time * 2.0), 0.5);
float result = ring * spinner;
```

The `sin(angle - u_time)` creates a smooth cutoff that rotates. Experiment with different formulas — `step(0.0, sin(angle - u_time * 2.0))` gives a half-circle that spins.

---

### Challenge C: Gradient Sunset

**File:** `src/shaders/exercises/challenge-c-gradient-sunset.glsl`

**Goal:** Horizontal bands of color blending into each other: dark blue (top) → pink → orange → dark (bottom).

**By Hand:**

Use `smoothstep()` to create soft transition zones, then `mix()` to blend between colors:

```glsl
float t1 = smoothstep(0.0, 0.3, uv.y);   // ground to orange zone
float t2 = smoothstep(0.3, 0.5, uv.y);   // orange to pink zone
float t3 = smoothstep(0.5, 1.0, uv.y);   // pink to dark blue zone

vec3 color = mix(darkGround, orange, t1);
color = mix(color, pink, t2);
color = mix(color, darkBlue, t3);
```

`smoothstep(edge0, edge1, x)` returns 0 below `edge0`, 1 above `edge1`, and smoothly ramps between them. By layering multiple `mix()` calls, each one blends from the previous result to the next color.

Adjust the edge values (0.3, 0.5, etc.) to move where the transitions happen. A lower value pushes the transition down, a higher value pushes it up.

---

### Challenge D: Interactive Spotlight

**File:** `src/shaders/exercises/challenge-d-spotlight.glsl`

**Goal:** A bright circle follows the mouse, illuminating a base scene.

**By Hand:**

The mouse position is already converted to UV coordinates. Use distance and `smoothstep()`:

```glsl
float spotlight = 1.0 - smoothstep(0.0, 0.3, dist);
```

This creates a soft falloff: fully bright at the mouse position, fading to zero at 0.3 units away. Then apply it to the scene with ambient light:

```glsl
vec3 finalColor = sceneColor * (ambient + spotlight);
```

The `ambient` term (0.1) ensures the scene is never completely black. The spotlight adds brightness on top. Because you're *multiplying* the scene color, the spotlight reveals the underlying gradient pattern rather than just adding white light.

Try changing the spotlight radius (the `0.3` in smoothstep), or make it colored: `sceneColor * (ambient + spotlight * vec3(1.0, 0.9, 0.7))` for warm light.

---

## Starter Code Files

All exercises are available as ready-to-use `.glsl` files in `src/shaders/exercises/`, and accessible through the **Exercises tab** at `/exercises/`.

### Level 1: Change Values
- `ex1-1-color-mixing.glsl` — Modify RGB values to create different colors
- `ex1-2-gradient-position.glsl` — Experiment with UV coordinates

### Level 2: Assignment & Sequence
- `ex2-1-store-and-reuse.glsl` — Practice creating and using variables
- `ex2-2-order-matters.glsl` — Understand execution order

### Level 3: Built-in Functions
- `ex3-1-sin-wave.glsl` — Create wave patterns with sin()
- `ex3-2-mix-blend.glsl` — Blend colors with mix()
- `ex3-3-step-cutoff.glsl` — Create hard edges with step()

### Level 4: Shapes with Math
- `ex4-1-circle.glsl` — Draw your first circle
- `ex4-2-multiple-circles.glsl` — Combine multiple shapes
- `ex4-3-rectangle.glsl` — Build rectangles with step()

### Level 5: Animation with Time
- `ex5-1-pulsing-circle.glsl` — Animate radius over time
- `ex5-2-moving-circle.glsl` — Move shapes with sin/cos
- `ex5-3-color-cycle.glsl` — Create color animations

### Level 6: Conditionals & Logic
- `ex6-1-two-halves.glsl` — Split screen with if/else
- `ex6-2-four-quadrants.glsl` — Nested conditionals

### Level 7: Loops & Repetition
- `ex7-1-row-of-circles.glsl` — Draw shapes in a loop
- `ex7-2-grid-of-circles.glsl` — Nested loops for grids

### Level 8: Functions
- `ex8-1-circle-function.glsl` — Create reusable shape functions
- `ex8-2-ring-function.glsl` — Build complex shapes from simple ones

### Challenge Projects
- `challenge-a-traffic-light.glsl` — Animated traffic light with state cycling
- `challenge-b-loading-spinner.glsl` — Rotating ring using atan()
- `challenge-c-gradient-sunset.glsl` — Multi-color gradient blending
- `challenge-d-spotlight.glsl` — Mouse-interactive lighting effect
