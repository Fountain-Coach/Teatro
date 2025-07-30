## 12. Storyboard DSL
_Define scenes and transitions declaratively._

The Storyboard DSL describes sequences of `Scene` declarations separated by optional `Transition` steps.  Each `Scene` wraps a view tree representing a single app state.  A `Transition` specifies how to move from one scene to the next—via cross‑fades or tweens—and how many frames the animation spans.

### Overview

1. **Scene** – Defines a named view state.  Scenes are declared inside a `Storyboard` builder block.
2. **Transition** – Describes the animation between two scenes.  The DSL currently supports `crossfade` or `tween` styles with a frame count and optional easing curve.
3. **Storyboard** – Collects scenes and transitions into a time line.  Calling `frames()` expands the storyboard into a flat array of renderable frames.
4. **CodexStoryboardPreviewer** – Generates a plain‑text prompt that enumerates each frame.  This allows Codex to reason about the intended UI flow without needing a graphical renderer.

### Example

```swift
import Teatro

// Define states and animations using the DSL

let storyboard = Storyboard {
    Scene("Intro") {
        VStack(alignment: .center) {
            Text("Welcome", style: .bold)
        }
    }

    // Fade to the next state over ten frames
    Transition(style: .crossfade, frames: 10)
    Scene("End") {
        Text("Goodbye")
    }
}

// Generate a preview prompt for Codex

let prompt = CodexStoryboardPreviewer.prompt(storyboard)
print(prompt)
```

Running this code prints a multi‑line text prompt.  Each section begins with `Frame N:` followed by the rendered view.  The prompt can be fed back into Codex so the agent can reason about the sequence of states and transitions before producing a final UI or animation.

The array returned by `storyboard.frames()` can now be passed to
`SVGAnimator.renderAnimatedSVG(storyboard:)` to produce an animated vector
timeline:

```swift
let svg = SVGAnimator.renderAnimatedSVG(storyboard: storyboard)
```

### Runtime Use

`Storyboard.frames()` can now be played back with `TeatroPlayerView`. Provide a
matching `MIDISequence` to drive timing and the view will render each frame in
real-time. GPT prompts are encouraged to generate both the storyboard and its
MIDI sequence so Codex can synchronize visuals and sound.




``````text
©\ 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
``````
