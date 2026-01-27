# Shader Exercises: Learning to Code with Visuals

These exercises progress from simple modifications to writing original code. Each exercise has starter code with `// TODO` comments marking what you need to complete.

**How to use these:**
1. Create a new `.glsl` file in `src/shaders/`
2. Copy the starter code
3. Complete the TODOs
4. Import it in `main.js` to test (or ask Claude to help wire it up)

---

## Level 1: Change Values

No new code - just modify existing numbers to understand cause and effect.

### Exercise 1.1: Color Mixing

```glsl
precision mediump float;
uniform vec2 u_resolution;

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution;

    // This creates a color. RGB values go from 0.0 to 1.0
    // TODO: Change these numbers to make the screen:
    //   a) Pure blue
    //   b) Yellow (hint: red + green = yellow)
    //   c) Your favorite color
    vec3 color = vec3(1.0, 0.0, 0.0);  // Currently red

    gl_FragColor = vec4(color, 1.0);
}
```

### Exercise 1.2: Gradient Position

```glsl
precision mediump float;
uniform vec2 u_resolution;

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution;

    // uv.x goes from 0 (left) to 1 (right)
    // uv.y goes from 0 (bottom) to 1 (top)

    // TODO: Change uv.x to uv.y - what happens?
    // TODO: Try (uv.x + uv.y) / 2.0 - what does this create?
    // TODO: Try 1.0 - uv.x - what changes?
    float brightness = uv.x;

    gl_FragColor = vec4(vec3(brightness), 1.0);
}
```

---

## Level 2: Assignment & Sequence

Learn that code runs top to bottom, and variables store values for later use.

### Exercise 2.1: Store and Reuse

```glsl
precision mediump float;
uniform vec2 u_resolution;

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution;

    // TODO: Create a variable called 'red' and set it to uv.x
    // float red = ???;

    // TODO: Create a variable called 'green' and set it to uv.y
    // float green = ???;

    // TODO: Create a variable called 'blue' and set it to 0.5
    // float blue = ???;

    // TODO: Uncomment this line after creating the variables above
    // gl_FragColor = vec4(red, green, blue, 1.0);

    gl_FragColor = vec4(0.0);  // Delete this line when done
}
```

### Exercise 2.2: Order Matters

```glsl
precision mediump float;
uniform vec2 u_resolution;

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution;

    float value = 0.0;

    // These lines run in order, top to bottom
    // TODO: Predict what color you'll see, then run it
    // TODO: Swap lines A and B - what changes?

    value = uv.x;        // Line A
    value = value * 2.0; // Line B
    value = value - 0.5;

    gl_FragColor = vec4(vec3(value), 1.0);
}
```

---

## Level 3: Built-in Functions

Learn to use functions that transform values.

### Exercise 3.1: The sin() Wave

```glsl
precision mediump float;
uniform vec2 u_resolution;
uniform float u_time;

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution;

    // sin() takes a number and returns a wave between -1 and 1
    // We convert it to 0-1 range with: (sin(x) + 1.0) / 2.0

    // TODO: Change the 10.0 to other numbers (try 1, 5, 20, 50)
    //       What does this number control?
    float wave = sin(uv.x * 10.0);

    // Convert from -1,1 to 0,1
    wave = (wave + 1.0) / 2.0;

    // TODO: Add u_time to make it animate:
    //       sin(uv.x * 10.0 + u_time)

    gl_FragColor = vec4(vec3(wave), 1.0);
}
```

### Exercise 3.2: The mix() Blend

```glsl
precision mediump float;
uniform vec2 u_resolution;

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution;

    vec3 colorA = vec3(1.0, 0.0, 0.0);  // Red
    vec3 colorB = vec3(0.0, 0.0, 1.0);  // Blue

    // mix(a, b, t) blends between a and b
    // when t=0, you get a. when t=1, you get b. when t=0.5, you get halfway.

    // TODO: Replace 0.5 with uv.x to create a gradient
    // TODO: Try uv.y instead
    // TODO: Try (uv.x + uv.y) / 2.0
    vec3 color = mix(colorA, colorB, 0.5);

    gl_FragColor = vec4(color, 1.0);
}
```

### Exercise 3.3: The step() Cutoff

```glsl
precision mediump float;
uniform vec2 u_resolution;

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution;

    // step(edge, x) returns 0.0 if x < edge, 1.0 if x >= edge
    // It's like asking: "is x past the edge?"

    // TODO: Change 0.5 to 0.3, then 0.7 - what moves?
    float cutoff = step(0.5, uv.x);

    // TODO: Make a horizontal line instead (hint: use uv.y)

    // TODO: Combine both to make a corner:
    //       float corner = step(0.5, uv.x) * step(0.5, uv.y);

    gl_FragColor = vec4(vec3(cutoff), 1.0);
}
```

---

## Level 4: Shapes with Math

Learn that shapes are just math questions: "is this pixel inside or outside?"

### Exercise 4.1: Circle

```glsl
precision mediump float;
uniform vec2 u_resolution;

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution;

    // A circle is all points within a certain distance from center
    vec2 center = vec2(0.5, 0.5);
    float radius = 0.3;

    // length() measures distance between two points
    float dist = length(uv - center);

    // TODO: We have the distance. Now we need to ask:
    //       "Is this pixel inside the circle (dist < radius)?"
    //       Use step() to create a sharp edge:
    //       float circle = 1.0 - step(radius, dist);
    float circle = 0.0;  // Replace this line

    gl_FragColor = vec4(vec3(circle), 1.0);
}
```

### Exercise 4.2: Multiple Circles

```glsl
precision mediump float;
uniform vec2 u_resolution;

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution;

    // TODO: Create three circles at different positions
    //       Hint: copy the circle code three times with different centers

    vec2 center1 = vec2(0.3, 0.5);
    vec2 center2 = vec2(0.5, 0.5);  // TODO: Change position
    vec2 center3 = vec2(0.7, 0.5);  // TODO: Change position
    float radius = 0.15;

    float circle1 = 1.0 - step(radius, length(uv - center1));
    float circle2 = 0.0;  // TODO: Calculate like circle1
    float circle3 = 0.0;  // TODO: Calculate like circle1

    // Combine: if any circle contains this pixel, show white
    float result = max(circle1, max(circle2, circle3));

    gl_FragColor = vec4(vec3(result), 1.0);
}
```

### Exercise 4.3: Rectangle

```glsl
precision mediump float;
uniform vec2 u_resolution;

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution;

    // A rectangle: x must be between left and right edges
    //              AND y must be between bottom and top edges

    float left = 0.3;
    float right = 0.7;
    float bottom = 0.4;
    float top = 0.6;

    // TODO: Complete these checks using step()
    // step(edge, x) returns 1.0 when x >= edge
    float insideLeft = step(left, uv.x);     // 1 if we're past the left edge
    float insideRight = 0.0;   // TODO: 1 if we're before the right edge
                               // Hint: 1.0 - step(right, uv.x)
    float insideBottom = 0.0;  // TODO: similar for bottom
    float insideTop = 0.0;     // TODO: similar for top

    // All conditions must be true (multiply them)
    float rect = insideLeft * insideRight * insideBottom * insideTop;

    gl_FragColor = vec4(vec3(rect), 1.0);
}
```

---

## Level 5: Animation with Time

Learn to use `u_time` to create movement.

### Exercise 5.1: Pulsing Circle

```glsl
precision mediump float;
uniform vec2 u_resolution;
uniform float u_time;

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution;

    vec2 center = vec2(0.5, 0.5);

    // TODO: Make the radius change over time
    //       sin(u_time) goes from -1 to 1
    //       We want radius to go from 0.1 to 0.4
    //       Formula: base + amplitude * sin(u_time)
    //       Try: 0.25 + 0.15 * sin(u_time)
    float radius = 0.3;  // Replace with animated version

    float dist = length(uv - center);
    float circle = 1.0 - step(radius, dist);

    gl_FragColor = vec4(vec3(circle), 1.0);
}
```

### Exercise 5.2: Moving Circle

```glsl
precision mediump float;
uniform vec2 u_resolution;
uniform float u_time;

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution;

    // TODO: Make the center move over time
    //       sin(u_time) for x, cos(u_time) for y creates a circular path
    //       Scale it down: 0.5 + 0.2 * sin(u_time)
    vec2 center = vec2(0.5, 0.5);  // Replace with animated version

    float radius = 0.1;
    float dist = length(uv - center);
    float circle = 1.0 - step(radius, dist);

    gl_FragColor = vec4(vec3(circle), 1.0);
}
```

### Exercise 5.3: Color Cycle

```glsl
precision mediump float;
uniform vec2 u_resolution;
uniform float u_time;

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution;

    // TODO: Animate each color channel with different speeds
    //       Use sin() with different multipliers on u_time
    //       Remember to convert from -1,1 to 0,1
    float red = 0.5;    // TODO: (sin(u_time) + 1.0) / 2.0
    float green = 0.5;  // TODO: (sin(u_time * 1.3) + 1.0) / 2.0
    float blue = 0.5;   // TODO: (sin(u_time * 1.7) + 1.0) / 2.0

    gl_FragColor = vec4(red, green, blue, 1.0);
}
```

---

## Level 6: Conditionals & Logic

Learn to make decisions in code.

### Exercise 6.1: Two Halves

```glsl
precision mediump float;
uniform vec2 u_resolution;

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution;

    vec3 color;

    // TODO: Complete the if statement
    //       If uv.x < 0.5, make color red
    //       Otherwise, make color blue
    if (uv.x < 0.5) {
        color = vec3(0.0);  // TODO: Set to red
    } else {
        color = vec3(0.0);  // TODO: Set to blue
    }

    gl_FragColor = vec4(color, 1.0);
}
```

### Exercise 6.2: Four Quadrants

```glsl
precision mediump float;
uniform vec2 u_resolution;

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution;

    vec3 color;

    // TODO: Use nested if statements to color four quadrants:
    //       Top-left: red
    //       Top-right: green
    //       Bottom-left: blue
    //       Bottom-right: yellow (1,1,0)
    //
    // Hint: First check if uv.x < 0.5 (left vs right)
    //       Then inside each branch, check uv.y < 0.5 (bottom vs top)

    color = vec3(uv.x, uv.y, 0.0);  // Replace with your quadrant logic

    gl_FragColor = vec4(color, 1.0);
}
```

---

## Level 7: Loops & Repetition

Learn to repeat actions with `for` loops.

### Exercise 7.1: Row of Circles

```glsl
precision mediump float;
uniform vec2 u_resolution;

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution;

    float result = 0.0;
    float radius = 0.08;

    // TODO: Complete the loop to draw 5 circles in a row
    for (int i = 0; i < 5; i++) {
        // Convert i to float for math
        float fi = float(i);

        // TODO: Calculate x position so circles are evenly spaced
        //       Hint: x should go from 0.1 to 0.9
        //       Try: 0.1 + fi * 0.2
        float x = 0.5;  // Replace with calculated position
        float y = 0.5;

        vec2 center = vec2(x, y);
        float dist = length(uv - center);
        float circle = 1.0 - step(radius, dist);

        // Add this circle to our result
        result = max(result, circle);
    }

    gl_FragColor = vec4(vec3(result), 1.0);
}
```

### Exercise 7.2: Grid of Circles

```glsl
precision mediump float;
uniform vec2 u_resolution;

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution;

    float result = 0.0;
    float radius = 0.05;

    // TODO: Nested loops for a 4x4 grid
    //       Outer loop for rows (y), inner loop for columns (x)
    for (int row = 0; row < 4; row++) {
        for (int col = 0; col < 4; col++) {
            float x = 0.0;  // TODO: Calculate based on col
            float y = 0.0;  // TODO: Calculate based on row

            vec2 center = vec2(x, y);
            float dist = length(uv - center);
            float circle = 1.0 - step(radius, dist);
            result = max(result, circle);
        }
    }

    gl_FragColor = vec4(vec3(result), 1.0);
}
```

---

## Level 8: Functions

Learn to organize code into reusable pieces.

### Exercise 8.1: Circle Function

```glsl
precision mediump float;
uniform vec2 u_resolution;

// TODO: Complete this function that returns 1.0 inside the circle, 0.0 outside
float drawCircle(vec2 uv, vec2 center, float radius) {
    float dist = length(uv - center);
    // TODO: Return the circle value using step()
    return 0.0;  // Replace this
}

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution;

    // Once your function works, these should draw three circles
    float c1 = drawCircle(uv, vec2(0.25, 0.5), 0.15);
    float c2 = drawCircle(uv, vec2(0.5, 0.5), 0.15);
    float c3 = drawCircle(uv, vec2(0.75, 0.5), 0.15);

    float result = max(c1, max(c2, c3));

    gl_FragColor = vec4(vec3(result), 1.0);
}
```

### Exercise 8.2: Ring Function

```glsl
precision mediump float;
uniform vec2 u_resolution;

// A ring is the area between two circles (outer minus inner)
float drawRing(vec2 uv, vec2 center, float innerRadius, float outerRadius) {
    // TODO: Draw a circle with outerRadius
    // TODO: Draw a circle with innerRadius
    // TODO: Subtract inner from outer to get a ring
    return 0.0;  // Replace this
}

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution;

    float ring = drawRing(uv, vec2(0.5, 0.5), 0.2, 0.3);

    gl_FragColor = vec4(vec3(ring), 1.0);
}
```

---

## Challenge Projects

Combine everything you've learned.

### Project A: Traffic Light

Create a shader with three circles stacked vertically (red, yellow, green). Use `u_time` to cycle which one is "lit" (bright) while others are dim.

### Project B: Loading Spinner

Create a ring that rotates around the center. Hint: Use `atan(y, x)` to get the angle of each pixel, and compare to a rotating threshold.

### Project C: Gradient Sunset

Create horizontal bands of color that blend into each other (dark blue at top, orange/pink in middle, dark at bottom). Use `mix()` and `smoothstep()`.

### Project D: Interactive Spotlight

Use `u_mouse` to create a bright circular area that follows the cursor. Outside the spotlight should be darker.

---

## Getting Help

When stuck, try asking Claude:

> "My circle isn't showing. Here's my code: [paste code]. What's wrong?"

> "How do I make this shape rotate over time?"

> "I want to draw a triangle. What's the math for that?"

The LLM can see your code and explain what's happening or suggest fixes.
