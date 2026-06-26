# Platform Events

This project uses three Salesforce High-Volume Platform Events to enable real-time communication and presence tracking.

---

# 1. Doctor Message Platform Event

| Property             | Value                |
| -------------------- | -------------------- |
| **Label**            | Doctor Message       |
| **API Name**         | `Doctor_Message__e`  |
| **Object Name**      | `Doctor_Message`     |
| **Event Type**       | High Volume          |
| **Publish Behavior** | Publish After Commit |

### Fields

| Field Label       | API Name               | Data Type              |
| ----------------- | ---------------------- | ---------------------- |
| Doctor Name       | `Doctor_Name__c`       | Text(255)              |
| Doctor Record Id  | `Doctor_Record_Id__c`  | Text(255)              |
| Patient Name      | `Patient_Name__c`      | Text(255)              |
| Patient Record Id | `Patient_Record_Id__c` | Text(255)              |
| Message           | `Message__c`           | Long Text Area (32768) |
| Message Time      | `Message_Time__c`      | Date/Time              |
| Session Id        | `Session_Id__c`        | Text(255)              |

---

# 2. Patient Message Platform Event

| Property             | Value                |
| -------------------- | -------------------- |
| **Label**            | Patient Message      |
| **API Name**         | `Patient_Message__e` |
| **Object Name**      | `Patient_Message`    |
| **Event Type**       | High Volume          |
| **Publish Behavior** | Publish After Commit |

### Fields

| Field Label       | API Name               | Data Type              |
| ----------------- | ---------------------- | ---------------------- |
| Doctor Name       | `Doctor_Name__c`       | Text(255)              |
| Doctor Record Id  | `Doctor_Record_Id__c`  | Text(255)              |
| Patient Name      | `Patient_Name__c`      | Text(255)              |
| Patient Record Id | `Patient_Record_Id__c` | Text(255)              |
| Message           | `Message__c`           | Long Text Area (32768) |
| Message Time      | `Message_Time__c`      | Date/Time              |
| Session Id        | `Session_Id__c`        | Text(255)              |

---

# 3. Presence Status Platform Event

| Property             | Value                |
| -------------------- | -------------------- |
| **Label**            | Presence Status      |
| **API Name**         | `Presence_Status__e` |
| **Object Name**      | `Presence_Status`    |
| **Event Type**       | High Volume          |
| **Publish Behavior** | Publish After Commit |

### Fields

| Field Label     | API Name             | Data Type |
| --------------- | -------------------- | --------- |
| Record Id       | `Record_Id__c`       | Text(255) |
| Record Name     | `Record_Name__c`     | Text(255) |
| Session Id      | `Session_Id__c`      | Text(255) |
| Is user doctor  | `Is_user_doctor__c`  | Checkbox  |
| Is user patient | `Is_user_patient__c` | Checkbox  |
| Is Online       | `Is_Online__c`       | Checkbox  |
| Last Seen       | `Last_Seen__c`       | Date/Time |
