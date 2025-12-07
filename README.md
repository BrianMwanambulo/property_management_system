# Property Management System

A Flutter-based mobile application for managing rental properties. This application helps landlords and property managers to streamline their property management tasks, from tracking rent payments to handling maintenance requests.

## Key Features

*   **User Authentication:** Secure user login and registration using Firebase Authentication.
*   **Property Listings:** Add, view, and manage property listings with details such as address, rent amount, and photos.
*   **Maintenance Requests:** Tenants can submit maintenance requests with descriptions and photos. Property managers can track and update the status of these requests.
*   **Rent Payment Tracking:** Record and track rent payments from tenants.
*   **Dashboard:** An overview of key information, such as vacant properties, overdue rents, and new maintenance requests.
*   **Image Uploads:** Upload property photos and images for maintenance requests using Firebase Storage.
*   **Offline Support:** The app is designed to work offline, with data synchronized once a connection is available.

## Getting Started

### Prerequisites

*   [Flutter SDK](https://flutter.dev/docs/get-started/install)
*   [Firebase Account](https://firebase.google.com/) and a new Firebase project.

### Installation

1.  **Clone the repository:**
    ```sh
    git clone https://github.com/your-username/property_management_system.git
    cd property_management_system
    ```
2.  **Set up Firebase:**
    *   Follow the instructions to add Firebase to your Flutter app for both Android and iOS: [https://firebase.google.com/docs/flutter/setup](https://firebase.google.com/docs/flutter/setup)
    *   You will need to add your own `google-services.json` for Android and `GoogleService-Info.plist` for iOS.
3.  **Install dependencies:**
    ```sh
    flutter pub get
    ```
4.  **Run the app:**
    ```sh
    flutter run
    ```

## Technologies Used

*   **Flutter:** The UI toolkit for building natively compiled applications for mobile, web, and desktop from a single codebase.
*   **Firebase:**
    *   **Firebase Authentication:** For user authentication.
    *   **Cloud Firestore:** A NoSQL database for storing property and user data.
    *   **Firebase Storage:** For storing images and other files.
    *   **Firebase Cloud Messaging:** For push notifications.
*   **Provider:** For state management.
*   **Image Picker:** For selecting images from the device's gallery or camera.
*   **Carousel Slider:** For creating interactive carousels.
*   **Intl:** For internationalization and localization.
*   **Shared Preferences:** For local storage.
*   **Connectivity Plus:** For checking network connectivity.