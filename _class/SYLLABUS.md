# VibeCoding with AI

**California Institute of the Arts — Program in Experimental Animation**

| | |
|---|---|
| **Course Codes** | FVEA-488-01 (Undergraduate) / FVEA-688-01 (Graduate) |
| **Schedule** | Thursdays, 9:00 AM – 12:00 PM |
| **Location** | Main Building F105 |
| **Instructor** | Douglas Goodwin (dgoodwin@calarts.edu) |
| **Semester** | Spring 2026 |

---

## Course Description

This studio course uses large language models (LLMs) as creative collaborators for writing inspectable, editable code that generates moving images. Rather than using AI to produce finished images, we will use AI to help us write and revise graphics code so that artistic decisions remain legible, attributable, and under your control. The primary medium is real-time GLSL shaders running in the browser, built and iterated through a modern creative-coding workflow (Vite, Node.js, Git). Students will translate poetic language, photographs, and everyday observations into animated behaviors such as color morphs, particle-like motion, procedural patterns, and audio-reactive structures. Outcomes may include standalone animations, projection-ready works, or components for integration with other creative software. No prior programming experience is required; the first weeks are dedicated to setup, fundamentals, and developing a reliable iteration loop.

---

## Learning Outcomes

By the end of the course, students will be able to:

- Use conversational programming effectively: specify intent, request minimal code changes, test, debug, and iterate
- Read and modify GLSL shaders with confidence (coordinates, color, SDF shapes, noise, animation, and basic 3D/raymarching concepts)
- Build and maintain a browser-based creative coding project using Vite, Node.js, and Git
- Produce documented, reproducible studies and experiments (including prompt logs and versioned code)
- Complete a polished final work suitable for screening/projection in the Bijou

---

## Required Tools

- A laptop capable of running a local dev server and a modern web browser (Chromebooks/iPads typically will not work for local development)
- A free LLM account (ChatGPT, Claude, or DeepSeek). Do not pay for subscriptions for this course; if you hit access limits, you can pair with a classmate or use alternatives provided in class.
- The course codebase: [shader-playground](https://github.com/douglasgoodwin/shader-playground) (provided)
- No paid software required

---

## Grading

| Component | Weight | What an "A" typically looks like |
|---|---|---|
| Weekly Exercises | 40% | Completed on time; functional code; visible iteration; clear intent and reflection |
| Prompt Documentation | 20% | Reproducible logs; specific prompts; what changed and why; screenshots/video evidence; citations |
| Final Project | 40% | Strong concept and craft; stable playback; technical ambition matched to scope; presentation-ready |

---

## Communication and Support

- **Primary channel** for announcements and links: Canvas
- **Email:** dgoodwin@calarts.edu
- **Response expectation:** within two business days (sooner during setup weeks when possible)
- **Technical help:** bring laptops to class; setup support is part of Weeks 1–2

---

## Weekly Schedule

Detail for each week is in the corresponding file (W01.md–W14.md).

| Week | Theme | Deliverable |
|------|-------|-------------|
| 01 | Welcome to Vibecoding | Visual music research (200–400 words); install dev server; start prompt log |
| 02 | Shader Exercises & First Vibecoding | Aspect-ratio fix study with prompt log; first shader video |
| 03 | The Exercise Shaders | Mashup shader combining ideas from two exercises |
| 04 | Visual Music: Music Video Exercise | 60–120 second visual-music study (random song + random technique) |
| 05 | Git, GitHub & Noise | Git branch/commit/push exercise; noise variation from ex10 |
| 06 | SDFs and Raymarching | 3D scene with at least two combined SDF shapes |
| 07 | Audio-Reactive Shaders (Midpoint) | Make an existing shader audio-reactive; recorded clip |
| 08 | Composition and Layering | 60–90 second recreation of Whitney's *Catalog*; written reflection |
| 09 | Performance, Live Visuals & Porting | 60-second live performance; shader port to TouchDesigner or other platform |
| 10 | Final Project Pitch | 3–5 minute pitch (concept, techniques, risks, fallback plan) |
| 11 | Final Project: Studio 1 | Working prototype |
| 12 | Final Project: Studio 2 | Refined iteration; peer feedback |
| 13 | Preparations | Presentation-ready piece; rehearsal in projection conditions |
| 14 | Bijou Show | Final screening |

---

## Prompt Log Template

Students must keep a Prompt Log for weekly exercises and all major project work. A simple Markdown file is sufficient.

**File name suggestion:** `prompt-log.md` (in your project repo)

### Entry Format

```
Date:
Project/Exercise:
Goal (1–2 sentences): What you wanted to change or achieve.

Context:
- File(s) edited:
- Starting behavior (what you observed):
- Constraint(s) (performance, readability, "minimal change," etc.):

Prompts (copy/paste):
1.
2.
3.

What you changed (be specific):
- Key code edits (describe or paste a short snippet)
- Parameters adjusted:

What you tested:
- What you tried in the browser/dev server:
- What broke (if anything) and how you fixed it:

Result (evidence):
- Screenshot/video filename or link:
- One sentence describing what improved:

Attribution/Citations (if applicable):
- External code/tutorials referenced:
- Non-original media used (audio/images/text):

Next steps (optional):
- One concrete thing to try next session:
```

---

## Policies

### Attendance

This is a studio course and depends on in-class making, feedback, and technical support. Attendance and active participation are essential. More than two unexcused absences may affect your grade. If you anticipate an absence, communicate as early as possible.

### Late Work

Assignments are due at the times listed. Late submissions are accepted up to one week late with reduced credit unless prior arrangements are made with the instructor. Work submitted more than one week late may receive minimal or no credit, depending on the assignment's role in the course sequence.

### Academic Integrity and Responsible Use of AI

Using AI tools (LLMs) to generate and modify code is the core methodology of this course and is encouraged. However, the expectation is that AI is used to support your learning and decision-making, not to replace it.

You are responsible for understanding what you submit and being able to explain how it works.

**Required documentation** for major assignments (and strongly recommended weekly):

- Maintain a prompt log and revision notes (what you asked, what changed, what you tested, what you learned).
- Keep your work versioned in Git so your iteration history is visible.

**Respect for authorship and intellectual property:**

- Do not use AI tools to imitate living artists' styles, produce "in the style of" work, or to generate final images intended to substitute for an artist's labor or signature look.
- Prefer workflows that produce inspectable code and procedural systems rather than opaque "final output" imagery.
- Do not input copyrighted media (including other artists' images, films, or proprietary assets) into AI systems in ways that violate rights or permissions.
- Cite sources for any non-original media (audio, images, text) and for significant external code borrowed or adapted (including from tutorials, repos, or generated snippets you did not fully author).

**Collaboration:**

- Collaboration is encouraged when explicitly allowed, but submitted work must clearly credit collaborators and distinguish shared components from individual contributions.

### Accessibility

Students requiring accommodations should contact the instructor and CalArts Disability Services as early as possible so we can coordinate support in a timely way.

Disability Services (DSO): dso@calarts.edu | 661-388-0665 | Room F201H
https://calarts.edu/life-calarts/student-services/disability-services

### Classroom Climate

We aim to build a supportive environment for risk-taking and critique. Use preferred names/pronouns, respect self-identifications, and be mindful of differences in power and vulnerability. Disagreement is welcome; disrespect is not. If something in discussion or work feels harmful, speak with the instructor and/or use appropriate CalArts resources.

---
## LAND ACKNOWLEDGEMENT (CalArts)
The CalArts main campus sits on the unceded ancestral lands of the Chaguayavitam, the people of Chaguayanga, whose present-day descendants are citizens of the Fernandeño Tataviam Band of Mission Indians. They have been here for millennia and will forever call this place home. Through meaningful partnership and collaboration, CalArts is committed to lifting up their stories, culture, and community. Land acknowledgement page (including guidance on use and a link to the full statement): https://calarts.edu/equity-and-diversity-idea/land-acknowledgement 

## COVID-19 / RESPIRATORY HEALTH AND SAFETY (CalArts)
Students must adhere to current CalArts campus directives related to respiratory illness mitigation (including COVID-19). Refusal to do so may result in the student being asked to leave the classroom and/or being referred through appropriate student conduct channels.
Current CalArts guidance, including exposure, testing, isolation, masking, and reporting instructions (healthcompliance@calarts.edu):
https://calarts.edu/life-calarts/student-services/health-and-well-being/respiratory-health-and-safety-guidelines 

## COMMITMENT TO DIVERSITY AND SAFER SPACES (CalArts)
We understand the classroom as a space for practicing freedom; where one may challenge psychic, social, and cultural borders and create meaningful artistic expressions. To do so we must acknowledge and embrace the different identities and backgrounds we inhabit. This means that we will use preferred pronouns, respect self-identifications, and be mindful of special needs. Disagreement is encouraged and supported; however, our differences affect our conceptualization and experience of reality, and it is important to remember that certain gender, race, sex, and class identities are more privileged while others are undermined and marginalized. Consequently, this can make some people feel more protected or more vulnerable during debates and discussions.
A collaborative effort between students and the instructor is needed to create a supportive learning environment. While everyone should feel free to experiment creatively and conceptually, if a class member points out that something you have said or shared with the group is offensive, avoid being defensive; instead approach the discussion as a valuable opportunity to learn. If you feel that something said in discussion or included in a piece of work is harmful, you are encouraged to speak with the instructor and/or contact the appropriate CalArts resource.

Related CalArts resources:
- Equity and Diversity (IDEA): https://calarts.edu/about-calarts/equity-and-diversity-idea 
- Community Rights and Responsibilities: https://calarts.edu/life-calarts/student-services/community-rights-and-responsibilities 

(Statement adapted from voidLab: https://github.com/voidlab/diversity-statement)
  
## DISABILITY ACCOMMODATIONS (CalArts Disability Services)
Students seeking academic accommodations based on disability should contact CalArts Disability Services (Disability Services Office, DSO).
Email: dso@calarts.edu | Phone: 661-388-0665 | Room: F201H
https://calarts.edu/life-calarts/student-services/disability-services 

## WRITING SUPPORT (CalArts Writing Center)
The Writing Center is available to CalArts students for one-on-one writing support (in-person or virtual). Support can include course writing, artist statements, grant applications, resumes, and related materials.
https://calarts.edu/academic-support/writing-center 

## INCLUSIVITY AND REPORTING CONCERNS (CalArts)
CalArts provides Institute-wide resources, information, and initiatives related to inclusion, diversity, equity, and access (IDEA). If you experience anything in this course that does not support an inclusive environment, please communicate with the instructor. You may also contact the Institute resources below for support and reporting pathways:

- Equity and Diversity (IDEA): https://calarts.edu/about-calarts/equity-and-diversity-idea 
- Prohibited Discrimination, Harassment, and Sexual Misconduct (policies and reporting support): https://calarts.edu/policies-calarts/institute-policies/prohibited-discrimination-harassment-and-sexual-misconduct 

## ACADEMIC INTEGRITY AND STUDENT CONDUCT (CalArts)
CalArts is a community of artists and scholars. Students are expected to demonstrate academic honesty and integrity in all work submitted. Academic misconduct includes (but is not limited to) cheating, fabrication, plagiarism, and facilitating academic misconduct. Alleged violations are handled through Institute processes (including the Office of the Provost and/or the relevant School, as applicable), and may also fall under the CalArts Student Code of Conduct. 
Key references:

- CalArts Student Code of Conduct: https://calarts.edu/home/policies-calarts/student-affairs-policies/calarts-student-code-conduct 
- Academic Misconduct (Catalog): https://catalog.calarts.edu/academic-policies/academic-misconduct 

## TITLE IX AND SEXUAL RESPECT (CalArts)
CalArts prohibits sex-based discrimination, including sexual harassment, sexual assault, dating and domestic violence, and stalking. If you have experienced or been affected by sexual misconduct or harassment, resources are available.

Title IX Coordinator (CalArts): Dionne Simmons
Email: titleix@calarts.edu , dsimmons@calarts.edu
Phone: (661) 291-3019
https://calarts.edu/life-calarts/student-services/sexual-respect 

Confidential resources (students): CalArts lists campus confidential resources and a confidential student resource advocate.
https://calarts.edu/life-calarts/student-services/sexual-respect/resources-and-support/campus-confidential-resources 

## PSYCHOLOGICAL HEALTH, WELL-BEING, AND RESILIENCE (CalArts)
CalArts recognizes that students may feel overwhelmed by academic, creative, social, and personal demands. Support resources include counseling and wellness services, as well as additional “where to go for help” guidance for a range of needs.

- Counseling and 24/7 support line details: https://calarts.edu/life-calarts/student-services/health-and-well-being/counseling 
- “Where to go for help” resource hub: https://calarts.edu/life-calarts/student-services/health-and-well-being/where-go-help