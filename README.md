# elephant-acoustic-sim
This Repository contains the Simulation Code for the Acoustic Detection of Elephants to Prevent Poaching at Dzanga-Sangha National Park, part of a paper for SPIE COnference 2026.

## Features of this Simulation:
### Environment & Mapping
* The simulation uses a user-defined polygon boundary mapped to the exact shape of the Dzanga-Sangha National Park, ensuring agents (elephants, poachers) only move within the actual park limits.
* Simulation is scaled using a Meters-to-Pixels function. Hence, the area of the national park, speeds of the elephants and poachers, ranges of the mic are based on real-world values.
* 5 mapped villages (Nola, Salo, Bayanga, Lidjombo, Mossipa) act as physical repulsion zones for elephants and starting points for the poachers (Red Zones).
* Dzanga Bai is mapped as a designated tourist zone that attracts elephants but repels the poachers (Green Zone).
### Agents (Elephants, Poachers) and Microphone Configurations 
* Movement vectors are based on real-world averages. Elephants travel at 4km/hr and Poachers at 2km/hr through the national park.
* A velocity-blending mathematical model is used to take wide, gradual turns, preventing stagnation and mimicking realistic movements.
* Poachers are randomized to spawn from the red zones or from outside the boundaries of the park to maximize the threat variance.
* Microphones can detect Elephant Rumbles upto ** 4km away**, as these are low-frequency infrasound rumbles that travel far in a dense forest.
* Microphones can detect Poachers **2.3kms away**, as these are high-frequency sounds that can't travel as much as elephant rumbles.
### Interception and Incident Response
* Microphones are placed to detect Poachers before the Poachers can poach the Elephants in the Park. If a poacher and an elephant are detected by the same microphone, then an Alert is issued by that mic and a Ranger is dispatched to that mic location.
* Microphones can store information of an elephant detection for upto 4 hours (in simulation time). If a poacher is detected by the same mic in this duration, the mic issues an Alert.
* When an Alert is issued, a Ranger is dispatched from the nearest Village (Red Zone) to nuetralize the Poacher. The ranger is assumed to move in a car at 20km/hr to that location.
* **Success:** A poacher is nuetralized when the Ranger reaches the Poacher's position. The poacher is stopped and turns into a Green Star in the Simulation.
* **Failure:** If a poacher slips through the mic ranges and reaches close to an elephant (~1.5 km), then the elephant is assumed to be Poached (as the elephant is now spotted by the poacher). The elephant turns into a Red Cross in the Simulation.
### Acoustic Sensor Network
* The simulation allows Users to test out **4 distinct microphone placement algorithms**
  - Uniform Spread: Mics are placed uniformly all across the entire park
  - Red Zones Fortress: Tight rings of mics are placed around the Red and Green Zones
  - Perimeter Defense: Mics are placed only around the boundaries of the park
  - Optimized Interception: 50% of the mics are placed around the red zones and 50% of the mics are placed along the boundaries of the park
* Microphones have a 90% probability threshold (based on our ML models developed) every 1 second in simulation time. This means that there is a 10% failure window where elephants or poachers may not be detected by the mic.
### Visualization and UI
* A real-time sidebar reports the total counts of safe elephants, poached elephants, active poachers, and neutralized poachers.
* Play/Pause toggle button that freezes and resumes the simulation physics, allows the User to analyze specific encounters and explain the simulation.
* A Time-Lapse Slider allows the User to speed up or slow down the simulation in real-time.
### Snippet of the Simulation
<img width="1087" height="879" alt="image" src="https://github.com/user-attachments/assets/e8447d03-e913-4544-99d5-976999ad2c7d" />
