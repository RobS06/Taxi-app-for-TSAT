# Tsat_app
Basic app
# TSAT Taxi Application

TSAT is a full-stack taxi booking application prototype designed to run on a local machine. It features a cross-platform frontend built with Flutter and a backend API powered by Node.js. It connects to a MySQL database and utilizes external APIs for real-time routing and geocoding.



## Key Features

  * **User Authentication:** Secure user registration and login system using JSON Web Tokens (JWT).
  * **Postcode-Based Ride Booking:** Users can enter pickup and dropoff postcodes to define their journey.
  * **Real-time Route Display:** Draws the optimal driving route on an OpenStreetMap map interface.
  * **Fare Estimation:** Automatically calculates an estimated fare based on the route distance.
  * **Live Driver Tracking Simulation:** Uses WebSockets to simulate a driver's movement on the map and provide live status updates.
  * **Local Notifications:** Sends notifications to the user for key ride events like "Ride Accepted" and "Driver Arrived".
  * **Mock Payment:** A simulated payment screen to complete the booking flow.
  * **Ride History & Reviews:** A full system for users to view their past rides and leave a star rating and comment for completed journeys.
  * **User Profile Management:** A dedicated section for users to view their details and update their password.



## Technology Stack

  * **Frontend:** Flutter (Dart)
  * **Backend:** Node.js, Express.js, WebSockets (`ws`)
  * **Database:** MySQL
  * **External APIs & Services:**
  * **Routing:** OpenRouteService API
  * **Geocoding:** Nominatim Public API (OpenStreetMap)



## Prerequisites

Before you begin, you must have the following software installed on your computer:

  * [ ] **Node.js** (LTS version recommended)
  * [ ] **Flutter SDK** (Latest stable version)
  * [ ] **MySQL Server** and **MySQL Workbench**
  * [ ] **Git** (Required by Flutter for package management)
  * [ ] A code editor like **Visual Studio Code** or **Android Studio**
  * [ ] A free **OpenRouteService API Key** from their [developer website](https://www.google.com/search?q=https://openrouteservice.org/dev/%23/signup).



## Installation & Setup

### 1\. Backend Setup (`tsat_backend` folder)

1.  **Install Dependencies:** Open a terminal, navigate into the `tsat_backend` folder, and run:

       bash
    npm install


2.  **Create the Database:**

      * Open **MySQL Workbench** and connect to your local server.
      * Create a new schema (database) by clicking the icon that looks like a cylinder with a `+`. Name it exactly **`tsat_db`**.
      * Open a new query tab, paste the SQL script below, and execute it by clicking the lightning bolt icon (⚡) to create all the necessary tables.


      sql
    CREATE SCHEMA IF NOT EXISTS `tsat_db`;
    USE `tsat_db`;

    CREATE TABLE `users` (
      `id` INT NOT NULL AUTO_INCREMENT,
      `name` VARCHAR(255) NOT NULL,
      `email` VARCHAR(255) NOT NULL UNIQUE,
      `phone_number` VARCHAR(45) NOT NULL UNIQUE,
      `password_hash` VARCHAR(255) NOT NULL,
      `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
      PRIMARY KEY (`id`)
    );

    CREATE TABLE `rides` (
      `id` INT NOT NULL AUTO_INCREMENT,
      `user_id` INT NOT NULL,
      `pickup_address` VARCHAR(255) NOT NULL,
      `dropoff_address` VARCHAR(255) NOT NULL,
      `fare` DECIMAL(10, 2) NOT NULL,
      `status` ENUM('requested', 'completed', 'cancelled') NOT NULL,
      `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
      PRIMARY KEY (`id`),
      FOREIGN KEY (user_id) REFERENCES users(id)
    );

    CREATE TABLE `reviews` (
      `id` INT NOT NULL AUTO_INCREMENT,
      `ride_id` INT NOT NULL,
      `user_id` INT NOT NULL,
      `rating` INT NOT NULL,
      `comment` TEXT NULL,
      `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
      PRIMARY KEY (`id`),
      FOREIGN KEY (ride_id) REFERENCES rides(id),
      FOREIGN KEY (user_id) REFERENCES users(id)
    );
    


3.  **Configure Environment Variables:**

      * In the `tsat_backend` folder, create a new file named `.env`.
      * Paste the following into it, replacing the placeholder values with your actual credentials.
             env
        DB_PASSWORD=YOUR_MYSQL_PASSWORD_HERE
        ORS_API_KEY=YOUR_OPENROUTESERVICE_API_KEY_HERE
        

### 2\. Frontend Setup (`tsat_app` folder)

1.  **Install Dependencies:** Open a *new* terminal, navigate into the `tsat_app` folder, and run:

       bash
    flutter pub get
    

2.  **Configure Server IP Address:**

      * This is essential for allowing a mobile device to connect to your local server.
      * Open a terminal and run `ipconfig` (on Windows) or `ifconfig` (on macOS/Linux) to find your computer's **IPv4 Address** (e.g., `192.168.1.100`).
      * In the Flutter project, open the file `lib/config.dart`.
      * Replace the placeholder IP address with the one you just found.



## Running the Application

To run the full application, you need **two separate terminals** running at the same time.

1.  **Start the Backend Server:**

      * In your first terminal, navigate to the **`tsat_backend`** folder.
      * Run the command: `node server.js`
      * Keep this terminal open.

2.  **Run the Flutter App:**

      * In your second terminal, navigate to the **`tsat_app`** folder.
      * Make sure you have an Android emulator running, a physical device connected, or a web browser (`chrome`) selected.
      * Run the command: `flutter run`



## Troubleshooting Guide

### Frontend / Connection Errors

  * **Symptom:** The app freezes on the login/signup screen, or you see errors like `Could not connect to the server`, `ClientException: Failed to fetch`, or the network request status is `(pending)`.

  * **Cause:** This is a network connection failure. Your Flutter app cannot reach your Node.js backend server.

  * **Solution Checklist:**

    1.  **Is your Node.js server running?** Look at its terminal. It must be open and show the `TSAT server is running...` message.
    2.  **Are you on a mobile device?** Make sure you have replaced the placeholder in `lib/config.dart` with your computer's correct local IP address.
    3.  **Is a Firewall blocking the connection?** This is the most common cause. You must create a firewall rule to allow `node.exe` to communicate through both **Private** and **Public** networks. Also check third-party antivirus software (McAfee, Norton, etc.).
    4.  **Are you on the same network?** Your phone and computer must be connected to the same Wi-Fi network.

  * **Symptom:** `FormatException: SyntaxError: Unexpected token <, "<!DOCTYPE"...`

  * **Cause:** Your app received an HTML error page instead of JSON data. This usually means an API key is wrong or an endpoint was not found (`404 Not Found`).

  * **Solution:** Check the **Node.js server terminal** for a detailed error log (e.g., `ORS ROUTING ERROR`). This will tell you the real cause. Make sure your `ORS_API_KEY` in the `.env` file is correct and active.

### Project Configuration Errors

  * **Symptom:** In VS Code, you see hundreds of errors, starting with `Target of URI doesn't exist: 'package:flutter/material.dart'`.
  * **Cause:** Your code editor is out of sync with the Flutter SDK.
  * **Solution:**
    1.  Make sure you have opened the `tsat_app` folder (not its parent) as the root workspace in your editor.
    2.  In the `tsat_app` terminal, run `flutter clean`, then `flutter pub get`.
    3.  Restart your code editor or run the `Dart: Restart Analysis Server` command (`Ctrl+Shift+P`).

### Backend & Database Errors

  * **Symptom:** In the app, you see `Server error during signup`, and the server terminal shows `Access denied for user 'root'@'localhost'`.

  * **Cause:** The password in your `.env` file is incorrect.

  * **Solution:** Verify the `DB_PASSWORD` in your `.env` file matches your MySQL Workbench password.

  * **Symptom:** The MySQL service in `services.msc` "starts and then stops".

  * **Cause:** The MySQL data directory is corrupted.

  * **Solution:** The most reliable fix is a **clean reinstallation of MySQL**. Uninstall all MySQL components, manually delete the folders in `C:\Program Files\MySQL` and `C:\ProgramData\MySQL`, restart, and then reinstall.

