# Titan-Walker
**Created by:** Harleen Ahluwalia, Peijun Zhao, Braedon Collett

## Project Overview
The Titan Walker project is a campus navigation app specifically designed for CSUF academic buildings. When users open the app, they are presented with a map highlighting all CSUF academic buildings with pins centered on each building. 

Users can log in as an admin by entering valid credentials through the settings button located in the top-right corner of the app. Admin users have full control over the pins on the map, including the ability to add, delete, edit coordinates, and open or close nodes.

Regular users can share their location with the system and search for the buildings they want to go to like Humanities or HUM. The system displays the shortest route to the desired building and gives them route by route directions and accurate expected distance and time to reach the building.

### General User Features
- View campus map with annotated buildings.
- Search for buildings by name like "Humanities" or "HUM".
- View building details, including accessibility status.
- Get walking directions with turn-by-turn instructions.
- Auto-tracking of user location and route updates.

### Admin Features
- **Login System:** Secure login with username and password.
  - Username: Admin
  - Password: password123
- **Editor Modes:**
  - **Write Mode:** Add new buildings directly on the map.
  - **Edit Mode:** Open or close building nodes.
  - **Delete Mode:** Remove buildings from the map.

## Instructions
### Running the App
1. Open the recent version of the project in **Xcode**.
2. Build and run either on a **simulator** or **an Iphone**.
3. Grant location access when prompted for real-time routing.

### Searching for a Building
- Tap the magnifying glass icon.
- Type building name (e.g., "Humanities" or "HUM").
- Tap **Go** and view the turn-by-turn directions, distance, and expected travel time.

### Admin Controls
1. Tap the gear icon to open login popup.
2. Enter credentials:
   - **Username:** Admin
   - **Password:** password123
3. Select editor mode:
   - **Write:** Tap map to add new buildings.
   - **Edit:** Tap building to open or close those nodes.
   - **Delete:** Tap building to remove it from the map.
4. Logout through the profile view.
