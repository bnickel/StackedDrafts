# StackedDrafts

This is a Swift implementation of Mail.app style drafting.  Things are a little messy right now because I just want to ship the damn thing.  Coming soon to Stack Exchange.app!*

## What's cool about this?

- So long as you include the `OpenDraftsIndicatorView` somewhere on your screen, this runs fairly autonomously.  The singleton draft manager handles offscreen view controllers.
- State restoration is supported.  You just need to encode the shared instance:

  ```swift
  func application(application: UIApplication, willEncodeRestorableStateWithCoder coder: NSCoder) {
      coder.encodeObject(OpenDraftsManager.sharedInstance)
  }
  ```
- VoiceOver support.
- Minimal visual glitching.*

<sub>* Not guaranteed.</sub>

## Try it out!

Open the playground and run the demo.

## Just watch the demo!

[YouTube](https://youtu.be/EqRjBatPkTU)

## Credits

- I stole ideas from [NextFaze/NFSafariTabs](https://github.com/NextFaze/NFSafariTabs).
