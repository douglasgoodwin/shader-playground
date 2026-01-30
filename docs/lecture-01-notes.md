# Lecture 1: Introduction to Vibecoding

## What is Vibecoding?

Vibecoding is a recently coined term, invented by Andrej Karpathy (formerly at Google). The idea is that LLMs (large language models) can help with code because they've absorbed the entire web—all the help anyone has ever given on Stack Overflow goes into training these models. Not only that, but they understand the context of code nearby that might be helpful.

If you can "vibe" your way into the right area—where people have been discussing how to do certain things with shaders, for example—the AI can generate code for you.

## The False Summit Problem

The biggest danger with AI coding is what I call a "false summit." Anyone who's done mountain climbing knows this—you're hiking along, thinking you're close to the top. You can see it. You hike for hours, reach what you thought was the summit, and see an even bigger peak beyond.

This happens with AI too. You'll be having a conversation with Claude or ChatGPT, and it takes you into situations where it gives you the wrong solution—the one lots of people had—because that's what's in the training data. Many people got stuck, couldn't get through, and circled around the wrong answer. That gets captured too.

You have to develop awareness of when this is happening. When you're going around in circles, sometimes you have to walk away. You may even want to start a new session—get a fresh landscape.

**Tips:**
- Ask the "dumb" question—it will take you down a different road
- Everything you type becomes part of the conversation landscape
- If you've been banging your head against the wall, start fresh

## Recommended Tools

- **Claude Code** - Really good, recommended for this class
- **ChatGPT** - Also good, useful for second opinions
- Other options exist if you prefer something "less evil"

## Class Discussion: AI and Art

Key points raised by students:
- **Accessibility** - AI opens up creative possibilities without expensive equipment
- **Ethical concerns** - Using others' likenesses, data sourcing
- **Job displacement** - Uncertainty about future employment
- **Intentionality matters** - How you use the tool affects the ethics
- **Tools don't define you** - Better to understand technology than reject it outright
- **It's not black and white** - Most people feel complicated about it

The consensus: We're in a gray area. The best approach is to learn about it, understand it, and then make informed choices about how (or whether) to use it.

## The Luddites: Historical Context

You've probably heard "Luddite" used as an insult—someone who refuses technology. But the actual Luddites are exactly who we should be discussing.

**The Real Story:**
- Possibly named after "Ned Ludd" (probably fictional)
- Highly skilled artisans, mostly weavers
- Being put out of work by machines that could do their jobs faster
- Working in mills under terrible conditions
- Their only form of protest was breaking the machines
- They organized in secret, wrote pamphlets signed "General Ludd"
- Had special hammers, knew exactly how to break the machines

**The Consequences:**
- Britain changed the law so breaking a machine was punishable by execution
- 20-30 people were publicly hanged
- It was meant as a deterrent

**Why This Matters:**
We may feel kinship with the Luddites. We want to know how this stuff works so we can talk about it, comment on it, participate—or if we need to break the machine, we want to know how.

## Lord Byron's Defense (1812)

At 28 years old, Lord Byron stood up in the House of Lords to defend the Luddites:
- These people are losing their livelihoods
- They can't pay for food
- It was illegal to be poor (poorhouses were essentially jails)
- Their only form of protest is breaking machines
- We should not be executing them

Parliament's response: "Thank you for your moving speech. No, we're going to keep hanging them."

But it struck a chord and helped organize the Romantic literature movement.

## Recommended Reading

- **Lord Byron's Address to Parliament** - Short and powerful
- **Cory Doctorow's Guardian article** (last month) - About how Silicon Valley is trying to make us "centaurs" (horse body, human mind) but we're actually becoming "reverse centaurs" where our minds serve the technology

## Eliza: The First Chatbot

**Joseph Weizenbaum** (late 1950s, Harvard) created Eliza—a sham AI meant as a critique.

**How it works:**
- Rogerian-style therapy bot
- Takes a bit of your text and turns it into a question
- Looks for about 40 keywords (father, mother, happy, etc.)
- Generates grammatically correct responses
- Always brings back something you said
- Doesn't flatter or tell you you're done

**The irony:** Weizenbaum was horrified that machines could pretend to be human. But his own students—the ones he was preaching to about the dangers—were secretly using Eliza for actual therapy.

**Is Eliza AI?** Not really. But it's perhaps a "part" of AI—the catching/collecting information part. It engages us, which makes it seem smarter than it is.

## The Loebner Prize

An annual competition to fool judges into thinking a computer program is human.

**Two awards:**
- Most Human AI
- Most Human Human (consistently scored as human by judges)

**The winner's strategy:** The program that finally won pretended to be a young boy from Uruguay who didn't speak English very well. Broken English, funny affect, dodging questions—it was all social hack, not good AI.

**Lesson:** You don't need to make really great AI. Make a persuasive one.

This is why so many AI images (lemur in astronaut suit on Mars) work—they're not persuasive long-term, but they're exciting and selectable in the moment.

## Git and GitHub Basics

**Why "Git"?**
- Named by Linus Torvalds (creator of Linux)
- Refers to Monty Python humor (also why Python is called Python)
- "Git" is British slang for an illegitimate child

**The Origin Story:**
Linus was frustrated with existing source code management. He locked himself in a room for a weekend and emerged with Git—now the universal system for managing collaborative software development.

**Key Concepts:**
- **Repository** - Where all your code lives
- **Commit** - A saved change with a message
- **History** - You can go back to any previous state
- Red lines = removed, Green lines = added

**Why it matters:** If things were going well last night but everything this morning is bad, you can abandon it and go back.

## The Book of Shaders

Your reference book: [thebookofshaders.com](https://thebookofshaders.com)

A lovely, incomplete, free online text about how shaders work.

**What you need to know:**
- The vocabulary (uniforms, fragment shaders, etc.)
- The concepts (so you can describe problems to Claude)
- Color space (0 to 1, not 0 to 255—allows more resolution)

**Why shaders?**
- Talk directly to your GPU (graphics processing unit)
- Bypass programming bottlenecks
- Crazy fast
- Draw the entire screen at once

**History:** Pixar's Renderman played a role in developing shaders. It's like writing a texture that can touch everything in the frame.

## Visual Music

**Key Figures:**
- **John Whitney** (and his brother and son) - Local to LA, worked adjacent to defense industry, had access to big computers
- **Jordan Belson**
- **Mary Ellen Bute**
- **Lillian Schwartz**
- **Jules Engel** - Founder of CalArts Experimental Animation Program
- **Oscar Fischinger**
- **Len Lye**

**What Whitney Did:**
- Worked with vector-based monitors
- Realized he could make animation
- Coded directly, filmed frame by frame
- Found ways to colorize the output
- Developed the genre of "computational cinema"

**The Context:** This work came from places like Bell Labs, Rand Corporation, Systems Development Corporation—places with computers powerful enough to do this AND launch nuclear missiles.

**Your Assignment:** Look at visual music this week. Find things you like. Think about how you might describe them to Claude.

**Mid-term Project:** Pick a bit from a Whitney film and reproduce it with a shader.

## Shader Demos Overview

**Whitney Collection:**
- Lapis - Swirling dots, color fields organized by frame dimensions
- Permutations - Rainbow patterns
- Matrix, Arabesque, Columna, Spiral - From Whitney's films
- Music Box - Code from Whitney's 1970s book, converted to shader

**Geometry:**
- Mandelbulb - 3D version of Mandelbrot set (infinite self-similar patterns)
- Ray marching - Primitive shapes that merge organically based on proximity
- Bridget Riley-inspired Op Art

**ASCII Rendering:**
- Patterns mapped to ASCII characters
- Adjustable contrast
- Can render 3D geometry as ASCII

**Features:**
- All demos have sliders (added by asking Claude)
- All can record to MP4 (added by asking Claude)
- Mouse interaction changes camera/parameters

## Setup Requirements

To run the shader playground:
1. Download the code from GitHub
2. Install Node.js/NPM
3. Run `npm run dev`
4. Open the local URL in your browser

**For Claude Code:**
- Costs ~$17/month (Pro plan)
- Free tier available to start
- Course funding available as grants—write a paragraph about why you need it

## Exercises

Simple exercises to understand the vocabulary:
- Color mixing
- Gradients
- Understanding how numbers (0-1) map to colors

**Why do exercises?**
You need the language to talk to Claude. It's all about the conversation. If the AI is misbehaving, you need to be able to say things like:
- "I think there's a problem with the color space"
- "Maybe we're using the wrong noise algorithm"
- "The gradient should go left to right, not top to bottom"

## Homework

1. **Look at visual music** - Whitney, Belson, Bute, Schwartz, etc.
2. **Write a few sentences** if you need help paying for Claude Code
3. **Think about how to describe** what you see in visual music

## Key Takeaways

- Vibecoding is real and it's pretty good
- Watch out for false summits—know when to start fresh
- The Luddites weren't anti-technology; they were protecting their livelihoods
- Persuasion matters more than perfection in AI
- Shaders are fast, universal, and foundational
- Learn the vocabulary so you can have productive conversations with AI
- Visual music is our starting point for shader work
