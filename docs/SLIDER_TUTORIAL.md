# Tutorial: Adding Custom Sliders to Your Shaders

This tutorial shows you how to add interactive controls to any shader in the playground. We'll add a "Twist" parameter to the plasma shader as an example.

## The Data Flow

```
HTML Slider → SliderManager → WebGL uniform → GLSL shader
```

There are **3 files** you'll touch:
1. `playground/index.html` — add the slider UI
2. `src/main.js` — add one line to SliderManager config
3. `src/shaders/plasma.glsl` — use the uniform in your shader

---

## Step 1: Declare the Uniform in Your Shader

Open `src/shaders/plasma.glsl` and add your new uniform with the other declarations:

```glsl
precision mediump float;

uniform vec2 u_resolution;
uniform float u_time;
uniform vec2 u_mouse;
uniform vec3 u_ripples[10];
uniform vec3 u_rippleColors[10];
uniform float u_speed;
uniform float u_intensity;
uniform float u_scale;
uniform float u_twist;    // ← ADD THIS LINE
```

Then use it somewhere in your shader. For example, add a twist distortion to the UV coordinates:

```glsl
void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution;

    // ADD: Twist distortion based on distance from center
    vec2 centered = uv - 0.5;
    float dist = length(centered);
    float angle = dist * u_twist * 10.0;  // u_twist controls twist amount
    float s = sin(angle);
    float c = cos(angle);
    uv = vec2(c * centered.x - s * centered.y,
              s * centered.x + c * centered.y) + 0.5;

    // ... rest of shader continues with twisted uv
```

---

## Step 2: Add the Slider to HTML

Open `playground/index.html` and add a new slider in the `#sliders` div:

```html
<div id="sliders">
  <label>
    <span>Speed</span>
    <input type="range" id="speed" min="0.1" max="3" step="0.1" value="1">
  </label>
  <label>
    <span>Intensity</span>
    <input type="range" id="intensity" min="0.1" max="3" step="0.1" value="0.7">
  </label>
  <label>
    <span>Scale</span>
    <input type="range" id="scale" min="0.2" max="3" step="0.1" value="1">
  </label>
  <!-- ADD THIS -->
  <label>
    <span>Twist</span>
    <input type="range" id="twist" min="0" max="2" step="0.1" value="0">
  </label>
</div>
```

**Slider attributes:**
- `min` / `max` — the range of values
- `step` — increment size (0.1 = one decimal place)
- `value` — default starting value

---

## Step 3: Wire Up the JavaScript

Open `src/main.js` and make two small changes:

### 3a. Add to the SliderManager config (around line 76):

```javascript
const sliders = new SliderManager({
    speed:     { selector: '#speed',     default: 1 },
    intensity: { selector: '#intensity', default: 0.7 },
    scale:     { selector: '#scale',     default: 1 },
    twist:     { selector: '#twist',     default: 0 },    // ← ADD THIS
})
```

### 3b. Add the uniform location (around line 48, inside the for loop):

```javascript
uniforms[name] = {
    resolution: gl.getUniformLocation(program, 'u_resolution'),
    time: gl.getUniformLocation(program, 'u_time'),
    mouse: gl.getUniformLocation(program, 'u_mouse'),
    ripples: gl.getUniformLocation(program, 'u_ripples'),
    rippleColors: gl.getUniformLocation(program, 'u_rippleColors'),
    speed: gl.getUniformLocation(program, 'u_speed'),
    intensity: gl.getUniformLocation(program, 'u_intensity'),
    scale: gl.getUniformLocation(program, 'u_scale'),
    twist: gl.getUniformLocation(program, 'u_twist'),    // ← ADD THIS
}
```

That's it! The `sliders.applyUniforms(gl, u)` call in the render loop automatically sends all slider values to the shader.

---

## Step 4: Test It

Run `npm run dev` and go to the Playground. You should see your new Twist slider. Move it and watch the plasma distort.

---

## SliderManager Reference

### Basic Usage

```javascript
import { SliderManager } from './controls.js'

const sliders = new SliderManager({
    paramName: { selector: '#slider-id', default: 1.0 },
})
```

### Options

| Option | Type | Description |
|--------|------|-------------|
| `selector` | string | CSS selector for the input element (required) |
| `default` | number/boolean | Default value (required) |
| `type` | string | `'range'` (default) or `'checkbox'` |
| `uniform` | string | Override the uniform key lookup (see below) |

### Checkbox Example

```javascript
const sliders = new SliderManager({
    showLines: { selector: '#showLines', default: false, type: 'checkbox' },
    invert:    { selector: '#invert',    default: false, type: 'checkbox' },
})
```

Checkboxes are sent to shaders as `1.0` (checked) or `0.0` (unchecked).

### Custom Uniform Names

By default, `applyUniforms()` looks for `locations[paramName]`. Use the `uniform` option when your locations object uses a different key:

```javascript
// If your uniforms object has: { dotDensity: gl.getUniformLocation(...) }
// But you want the param called 'density':
const sliders = new SliderManager({
    density: { selector: '#density', default: 1.0, uniform: 'dotDensity' },
})
```

### Methods

| Method | Description |
|--------|-------------|
| `sliders.params` | Get all current values as an object |
| `sliders.get(name)` | Get a single parameter value |
| `sliders.set(name, value)` | Set a value programmatically (updates UI too) |
| `sliders.reset()` | Reset all parameters to defaults |
| `sliders.applyUniforms(gl, locations)` | Send all values to WebGL uniforms |

---

## Other Utilities in controls.js

### setupRecording

One-liner to add video recording capability:

```javascript
import { setupRecording } from './controls.js'

const recorder = setupRecording(canvas)  // Binds #record-btn and 'R' key
```

Options:
- `buttonSelector` — default `'#record-btn'`
- `keyboardShortcut` — default `'r'` (set to `null` to disable)

### MouseTracker

Reusable mouse position tracking with Y-flip for WebGL:

```javascript
import { MouseTracker } from './controls.js'

const mouse = new MouseTracker(canvas)

// In render loop:
mouse.applyUniform(gl, u.mouse)  // Sends vec2 to u_mouse
```

---

## Quick Reference: Uniform Types

| GLSL Type | JavaScript Call | Example |
|-----------|-----------------|---------|
| `float` | `gl.uniform1f(loc, value)` | `gl.uniform1f(u.twist, 0.5)` |
| `vec2` | `gl.uniform2f(loc, x, y)` | `gl.uniform2f(u.mouse, 100, 200)` |
| `vec3` | `gl.uniform3f(loc, x, y, z)` | `gl.uniform3f(u.color, 1.0, 0.0, 0.5)` |
| `vec4` | `gl.uniform4f(loc, x, y, z, w)` | `gl.uniform4f(u.rect, 0, 0, 1, 1)` |
| `float[]` | `gl.uniform1fv(loc, array)` | `gl.uniform1fv(u.values, new Float32Array([...]))` |

---

## Using Claude Code to Add Sliders

You can ask Claude Code to do this for you. Example prompts:

> "Add a slider called 'Rotation' to the plasma shader that rotates the entire pattern. Range 0 to 6.28 (2π)."

> "Add a color picker uniform to the voronoi shader so I can change the cell color."

> "Make the hexgrid shader respond to a new 'Gap' parameter that controls spacing between hexagons."

Claude Code can see all the files and will make the coordinated edits across HTML, JS, and GLSL.

---

## Challenge Exercises

1. **Add a "Zoom" slider** to `kaleidoscope.glsl` that scales the pattern from the center

2. **Add a "Segments" slider** to control how many radial segments the kaleidoscope has (hint: use `floor()` to make it discrete)

3. **Add a "Hue Shift" slider** that rotates the color palette over time (hint: convert RGB to HSV, add offset, convert back)

---

## Troubleshooting

**Slider shows but has no effect:**
- Check that the param name in SliderManager matches the key in your uniforms object
- Check browser console for WebGL errors
- Verify the uniform location is being fetched in the uniforms object

**Shader won't compile:**
- Check for typos in the uniform declaration
- Make sure you're using the uniform somewhere (unused uniforms are optimized out, but that's okay)

**Value range seems wrong:**
- Adjust `min`, `max`, `step` in the HTML
- Consider whether your shader math expects 0-1, 0-10, or some other range
