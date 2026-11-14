## Next Stop: explore Space

Choose a question you want to answer about the Moon. Will you look for ice near the south pole, photograph craters to make a map, or use radar to see what lies beneath the surface? Your job is to build a spacecraft that can collect the evidence and send it home.

## Playing your first mission

1.Choose your equipment.-Read the Mission brief, then head to the assembly bench. Click a part to see how it changes your spacecraft's cost, weight, and power use. Click a **+** on the spacecraft to fit it. A camera is a good starting point for a mapping mission.
2.Get ready to launch.- Pick a rocket that can lift your spacecraft and an orbit that takes it over your target. You can ask the three reviewers to check your design before you fly. At launch, press **Enter** as the arrow crosses the green band. If you miss, catch it on the way back.
3.Collect data and send it home.-Click **Observe** to take a measurement. It goes into **Storage** aboard your spacecraft. When the current slot is green, click **Downlink** to send data to Earth and earn science points. You get one action per slot. If the battery is low, use **Charge** in sunlight. If the instruments get too hot, use **Safe** to cool them down. Press **P** whenever you need time to think. 4. **Handle the solar storm.** At slot 5, the clock stops until you make a choice. Shield your solar panels to protect their power output, or collect particle data and accept a drop in power for the rest of the flight. 5. **See how your design did.** The flight ends when you reach your science goal or run out of slots. The review shows how much data reached Earth and how much stayed on board. If you collected plenty but couldn't send it all home, try the same mission with a stronger antenna and compare the results. ## Around the mission center Use **WASD** to walk, **Shift** to run, and **Space** to jump. Drag to turn the camera, scroll to zoom, and press **V** to switch views. Press **E** to use a nearby station and **Esc** to return to the hall. **Save** and **Load** use a local save on your computer. ## Starting the game On 64-bit Windows, extract the ZIP and double-click **Play.cmd**. The game runs offline and opens at the **Mission brief**. To edit the project, open **project.godot** in Godot 4.7.2 and press **F5** to play.

# Where to find things

To open the game in Godot, select `project.godot`. Open `Center.tscn` to see how the mission center is laid out. The astronaut and building models are in `assets/`, and `player.gd` controls how you move around the hall.

If you're looking for the gameplay code, start with `mission.gd`. It works out how much power a scan uses, how much data fits on board, and how many points you earn when you send that data back to Earth. To change a number, like the price of a camera or the capacity of a battery, look in `classroom.json`.

The rest is split up by what you're doing in the game. `ship_bay.gd` handles fitting parts to the spacecraft, `design_review.gd` scores the design, and `flight_deck.gd` handles launch and ignition timing. Once you're in orbit, the four action buttons are in `orbit_game.gd`. The crater photography activity has its own script, `lunar_flyby.gd`.

For the mission brief, checklist, and results screen, look in `ui.gd`. You'll also see small `.uid` files next to the scripts. Godot uses those to keep track of the files, so you can leave them as they are.

# Use of SI tools(See si-disclosure.json for the full lis)

we used OpenAI Codex to help write and test the Godot code for spacecraft assembly, launch timing, and orbital operations.
The budgets, equipment costs, and science scores in `classroom.json` are values used for gameplay. The ignition sound is generated in Godot by code written with help from Codex.

# Play on Windows
1. Open the latest release from the **Releases** section and download **Next-Stop-Deep-Space-v1.1-Windows.zip** under **Assets**.
2. Right-click the downloaded ZIP and choose **Extract All**, then click **Extract**.
3. Open the extracted **Next Stop Deep Space** folder and double-click **Play.cmd**. The game will open at the mission selection screen.

# PPT demo
https://docs.google.com/presentation/d/1DT2vLgXTOslIP66KmEWqNI7sef_tabpz/edit?usp=sharing&ouid=112161989016219199790&rtpof=true&sd=true