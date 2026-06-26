<img width="1376" height="736" alt="Doctor-Patient Communication  Demo" src="https://github.com/user-attachments/assets/b6b52444-c191-45c7-bb3c-135d96339727" />#  Salesforce Real-Time Doctor–Patient Communication System using Platform Event Architecture

A real-time healthcare communication solution built on the Salesforce Platform using **Platform Event Architecture**. This application enables secure and instant communication between doctors and patients while providing intelligent appointment reminders, patient medical history tracking, live online/offline presence monitoring, and an integrated medical report dashboard.

The project demonstrates Salesforce event-driven architecture using **Platform Events (Publish–Subscribe Model)** to deliver real-time messaging without page refreshes.

---

#  Project Overview

This application provides a real-time communication platform where doctors and patients can interact instantly inside Salesforce.

Instead of relying on database polling or scheduled refreshes, the system uses **Salesforce Platform Events** to publish and subscribe to events, allowing both users to receive messages immediately.

In addition to real-time chat, the application offers intelligent healthcare features such as appointment reminders, patient report cards, medical history tracking, inbox notifications, and live online/offline presence monitoring. The system is designed to improve communication efficiency while providing doctors with quick access to important patient information.

---

#  Platform Event Architecture

This project is completely based on Salesforce's **Event-Driven Architecture**.

### Platform Events Used

* Doctor Message Platform Event
* Patient Message Platform Event
* Presence Status Platform Event

### Event Flow

Patient → Publish Platform Event → Event Bus → Doctor LWC

Doctor → Publish Platform Event → Event Bus → Patient LWC

Presence Update → Platform Event → Both Users Receive Online/Offline Status

This architecture enables asynchronous communication between users, reduces unnecessary server requests, and provides low-latency message delivery using Salesforce's native Event Bus.

---

#  Features

##  Real-Time Doctor–Patient Chat

* Instant two-way communication
* No page refresh required
* Built using Salesforce Platform Events
* Publish–Subscribe event architecture
* Native Salesforce implementation

The chat system provides seamless real-time messaging between doctors and patients, ensuring messages are delivered instantly through Platform Events without requiring manual page refreshes.

---

##  Doctor Dashboard

* View assigned patients
* Open patient conversation instantly
* View patient report card
* Access patient medical history
* Track appointment information

The dashboard provides doctors with a centralized workspace where they can monitor patient details, review medical history, and communicate efficiently from a single interface.

---

##  Patient Dashboard

* Start chat with doctor
* Receive doctor messages instantly
* View upcoming appointment reminder
* Receive notification when doctor replies

Patients can easily communicate with their assigned doctor while staying informed about upcoming appointments and receiving real-time notifications for new messages.

---

##  Smart Appointment Reminder

The application automatically displays the **nearest upcoming appointment**.

Features include:

* Shows only future appointments.
* Automatically hides reminders once the appointment time has passed.
* Automatically displays the next nearest future appointment.
* No expired appointment reminder is shown.
* Intelligent appointment filtering.
* Supports dynamic reminder updates.

This ensures that patients always see only relevant appointment reminders, improving usability and eliminating confusion caused by expired appointments.

---

##  Intelligent Time Conversion

Appointment reminders correctly convert appointment time into a comparable Salesforce time object before validation.

The application:

* Converts AM/PM appointment slots.
* Compares appointment time with the current system time.
* Filters expired appointments automatically.
* Displays only valid upcoming appointments.

This logic guarantees accurate appointment validation regardless of time format and ensures reminders remain synchronized with the current system time.

---

##  Patient Medical Report Card

Doctor can instantly view:

* Patient Profile
* Blood Group
* Age
* Gender
* Medical History
* Current Diagnosis
* Allergies
* Medications
* Vital Information
* Emergency Contact
* Previous Visit Summary

Everything is displayed inside one integrated patient report card, allowing doctors to quickly understand the patient's health condition before or during consultation.

---

##  Medical History Tracking

Doctor can review:

* Previous medical reports
* Historical diagnoses
* Previous treatments
* Prescription history
* Visit timeline

The medical history module provides a complete timeline of previous treatments and consultations, helping doctors make better-informed medical decisions.

---

##  Real-Time Inbox Notification

Patients receive:

* New incoming message notifications
* Unread message count
* Inbox visibility until the conversation is opened
* Automatic notification clearing after reading

The notification system ensures that patients never miss important doctor messages by maintaining unread notifications until the conversation is viewed.

---

##  Live Online / Offline Presence Tracking

The system tracks user activity in real time.

Features:

* Doctor Online Status
* Doctor Offline Status
* Patient Online Status
* Patient Offline Status
* Automatic status updates
* Live UI indicator

Using Platform Events, both doctors and patients can instantly view each other's availability, creating a more interactive and responsive communication experience.

---

##  Event-Driven Communication

* Publish Events
* Subscribe Events
* Low latency communication
* Real-time synchronization
* Native Salesforce Event Bus

The entire communication flow is powered by Salesforce's native Event Bus, enabling scalable, reliable, and real-time data synchronization between Lightning Web Components.

---

#  Technologies Used

* Salesforce Platform
* Apex
* Lightning Web Components (LWC)
* Platform Events
* EMP API
* SOQL
* Lightning Data Service
* HTML
* CSS
* JavaScript

---

#  Database Design

The application includes interconnected healthcare objects such as:

* Doctor
* Patient
* Appointment
* Medical Report
* Medical History
* Chat Messages
* Presence Status

The data model is designed to maintain relationships between healthcare records while supporting efficient retrieval of patient information and real-time communication.

<img width="1624" height="1950" alt="Doctor Patient Data Model " src="https://github.com/user-attachments/assets/8e68d5e7-063b-43e6-8659-b035cf4e94cb" />


---

#  Application Screenshots

## Doctor Dashboard

<img width="776" height="430" alt="image" src="https://github.com/user-attachments/assets/4d58f36f-2434-4c6c-abe2-986587d454f7" />


---

## Patient Dashboard

<img width="907" height="463" alt="image" src="https://github.com/user-attachments/assets/c3a19a63-aa06-436a-8984-3902663c9478" />


---

## Doctor Chat Window

<img width="899" height="282" alt="image" src="https://github.com/user-attachments/assets/eadc3a6a-734b-49a5-b62c-5055fc2651a5" />
<img width="890" height="398" alt="image" src="https://github.com/user-attachments/assets/e923d399-71b6-4a5e-906e-d360c2c3fb18" />


---

## Patient Chat Window

<img width="889" height="430" alt="image" src="https://github.com/user-attachments/assets/162ef6ec-6380-4bdf-90b8-b61cddaaa882" />


---

## Medical Report Card

<img width="712" height="605" alt="image" src="https://github.com/user-attachments/assets/c7474cf9-228b-47ef-b9a2-e2e701e9b136" />


---

## Appointment Reminder

<img width="508" height="160" alt="image" src="https://github.com/user-attachments/assets/ed24359e-d0b6-4e30-951b-226a550dcf84" />
<img width="885" height="107" alt="image" src="https://github.com/user-attachments/assets/f4d0781b-19e6-4b9d-b594-0228d677551f" />



---

## Inbox Notification

<img width="889" height="256" alt="image" src="https://github.com/user-attachments/assets/dec67d75-9850-4bd1-9179-e6c41acd4acf" />


---

## Online / Offline Presence

<img width="877" height="164" alt="image" src="https://github.com/user-attachments/assets/d99af52c-c578-4283-9fa2-2c17b90b8a15" />

<img width="892" height="152" alt="image" src="https://github.com/user-attachments/assets/dc00a504-3f71-4b0f-b0ab-baf20c5502ed" />


---

#  Project Demo

<img width="1376" height="736" alt="Doctor-Patient Communication  Demo" src="https://github.com/user-attachments/assets/cc95458f-52f6-4f9f-b11c-002eefe33185" />

---

#  What I Learned

Through this project, I gained practical experience in designing and developing real-time applications on the Salesforce Platform using an event-driven architecture. I strengthened my understanding of Platform Events, the Publish–Subscribe communication model, Lightning Web Components, Apex development, and EMP API integration for building low-latency real-time solutions.

Additionally, I improved my skills in Salesforce data modeling, SOQL optimization, asynchronous processing, component communication, appointment scheduling logic, time validation, and healthcare-focused UI/UX design. This project also enhanced my ability to build scalable, maintainable, and user-centric enterprise applications by following Salesforce development best practices.

---

#  Future Enhancements

* File and Image Sharing
* AI Health Assistant
* Push Notifications
* Mobile App Integration
* Multi-Doctor Consultation
* Appointment Rescheduling
* Electronic Prescription
* Medical Document Upload
* Conneting to Data cloud using RAG

---

#  Conclusion

This project demonstrates how Salesforce Platform Events can be leveraged to build scalable, event-driven, real-time healthcare applications. By combining Lightning Web Components, Apex, and the Publish–Subscribe architecture, the solution delivers secure communication, intelligent appointment management, live presence tracking, and comprehensive patient information in a seamless user experience. It showcases the capability of the Salesforce Platform to develop modern, responsive, and enterprise-grade healthcare solutions.


