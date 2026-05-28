# elephant-acoustic-sim
This repository contains the Simulation code for the Acoustic Detection of Elephants to Prevent Poaching at Dzanga-Sangha National Park, part of a paper for SPIE Conference 2026.

## Features of this Simulation:
### Environment & Mapping
* The simulation uses a user-defined polygon boundary mapped to the exact shape of the Dzanga-Sangha National Park, ensuring agents (elephants, poachers) only move within the actual park limits.
* The simulation is scaled using a Meters-to-Pixels function. Hence, the area of the national park, speeds of the elephants and poachers, ranges of the mics are based on real-world values.
* 5 mapped villages (Nola, Salo, Bayanga, Lidjombo, Mossipa) act as physical repulsion zones for elephants and starting points for the poachers (Red Zones).
* Dzanga Bai is mapped as a designated tourist zone that attracts elephants but repels the poachers (Green Zone).
### Agents (Elephants, Poachers) and Microphone Configurations 
* Movement vectors are based on real-world averages. **Elephants travel at 4 km/hr and Poachers at 2 km/hr through the national park.**
* A velocity-blending mathematical model is used to take wide, gradual turns, preventing stagnation and mimicking realistic movements.
* Poachers are randomized to spawn from the red zones or from outside the boundaries of the park to maximize the threat variance.
* Elephants within poaching range (~1.5 km) but not yet poached are shown in bright yellow (Threatened state), making close encounters visually distinct from safe roaming.
* Microphones can detect Elephant Rumbles up to **4km away**, as these are low-frequency infrasound rumbles that travel far in a dense forest.
* Microphones can detect Poachers **200m away**, as these are high-frequency sounds that cannot travel as much as elephant rumbles.
### Interception and Incident Response
* Microphones are placed to detect Poachers before the Poachers can poach the Elephants in the Park. If a poacher and an elephant are detected by the same microphone, then an Alert is issued by that mic and a Ranger is dispatched to that mic location.
* Microphones can store information of an elephant detection for up to 4 hours (in simulation time). If a poacher is detected by the same mic in this duration, the mic issues an alert.
* When an alert is issued, a ranger is dispatched from the nearest village (Red Zone) to neutralize the Poacher. The ranger is assumed to move in a car at **20 km/hr** to that location.
* **Success:** A poacher is neutralized when the ranger reaches the Poacher's position. The poacher is stopped and turns into a Green Star in the simulation.
* **Failure:** If a poacher slips through the mic ranges and reaches within 100m of an elephant, there is a probabilistic encounter roll that is perfomed at 85% success rate. Based on the probability value of that encounter, the elephant is either Poached (Red Cross in simulation) or the Elephant escapes (turns yellow and back to blue). If the elephant escapes, it flees in the opposite direction to the poacher, ensuring separation more than ~3km before another attempt.
### Acoustic Sensor Network
* The simulation allows Users to test out **4 distinct microphone placement algorithms**
  - Uniform Spread: Mics are placed uniformly all across the entire park.
  - Red Zones Fortress: Tight rings of mics are placed around the Red and Green Zones.
  - Perimeter Defense: Mics are placed only around the boundaries of the park.
  - Optimized Interception: 50% of the mics are placed around the red zones and 50% of the mics are placed along the boundaries of the park.
* Microphones have a 90% probability threshold (based on our ML models developed) every 1 second in simulation time. This means that there is a 10% failure window where elephants or poachers may not be detected by the mic.
### Visualization and UI
* A real-time sidebar reports the total counts of safe elephants, poached elephants, active poachers, and neutralized poachers.
* A play/pause toggle button that freezes and resumes the simulation physics, allows the user to analyze specific encounters and explain the simulation.
* A Time-Lapse Slider allows the user to speed up or slow down the simulation in real-time.
### Snippet of the Simulation
<img width="1087" height="879" alt="image" src="https://github.com/user-attachments/assets/e8447d03-e913-4544-99d5-976999ad2c7d" />
