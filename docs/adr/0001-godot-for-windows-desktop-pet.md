# Use Godot 4 for the Windows desktop pet

The project will use Godot 4 as its primary runtime because the core experience depends on 2D skeletal animation, layered pixel art, timed hit feedback, transparent desktop windows, and a Windows executable. A web stack could simplify settings screens, but Godot keeps the animation state machine and final desktop packaging in one runtime; the trade-off is that the settings UI will be built inside Godot.
